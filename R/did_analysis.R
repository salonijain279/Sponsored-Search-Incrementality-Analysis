script_args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_args[grep("^--file=", script_args)])
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)


prepare_did <- function(data, intervention_week = 13) {
  required <- c("week", "platform", "organic_traffic", "sponsored_traffic")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }
  if (!"google" %in% data$platform) {
    stop("The treated platform 'google' is missing")
  }
  if (!any(data$week < intervention_week) || !any(data$week >= intervention_week)) {
    stop("Data must include both pre- and post-intervention weeks")
  }

  data$treated <- as.integer(data$platform == "google")
  data$post <- as.integer(data$week >= intervention_week)
  data$total_traffic <- data$organic_traffic + data$sponsored_traffic
  data
}


coefficient_row <- function(model, term, outcome, specification) {
  model_summary <- summary(model)$coefficients
  if (!term %in% rownames(model_summary)) {
    stop("Coefficient not found: ", term)
  }
  data.frame(
    specification = specification,
    outcome = outcome,
    estimate = unname(model_summary[term, "Estimate"]),
    std_error = unname(model_summary[term, "Std. Error"]),
    p_value = unname(model_summary[term, "Pr(>|t|)"]),
    row.names = NULL
  )
}


estimate_did_effects <- function(data, intervention_week = 13) {
  prepared <- prepare_did(data, intervention_week)
  outcomes <- c("total_traffic", "organic_traffic", "sponsored_traffic")
  rows <- list()

  for (outcome in outcomes) {
    basic_formula <- as.formula(paste(outcome, "~ treated * post"))
    basic_model <- lm(basic_formula, data = prepared)
    rows[[length(rows) + 1]] <- coefficient_row(
      basic_model, "treated:post", outcome, "Basic DiD"
    )

    twfe_formula <- as.formula(
      paste(outcome, "~ treated:post + factor(platform) + factor(week)")
    )
    twfe_model <- lm(twfe_formula, data = prepared)
    rows[[length(rows) + 1]] <- coefficient_row(
      twfe_model, "treated:post", outcome, "Platform + week fixed effects"
    )
  }

  do.call(rbind, rows)
}


primary_effects <- function(effect_table) {
  primary <- effect_table[
    effect_table$specification == "Platform + week fixed effects",
    c("outcome", "estimate")
  ]
  setNames(primary$estimate, primary$outcome)
}


traffic_decomposition <- function(effect_table) {
  effects <- primary_effects(effect_table)
  required <- c("total_traffic", "organic_traffic", "sponsored_traffic")
  if (!all(required %in% names(effects))) {
    stop("Effect table is missing a required traffic outcome")
  }

  paid_clicks <- -effects[["sponsored_traffic"]]
  organic_substitution <- effects[["organic_traffic"]]
  incremental_visits <- -effects[["total_traffic"]]
  if (paid_clicks <= 0 || organic_substitution < 0 || incremental_visits < 0) {
    stop("Estimated effects do not match the expected ads-off direction")
  }

  identity_error <- paid_clicks - organic_substitution - incremental_visits
  data.frame(
    metric = c(
      "Counterfactual paid clicks per week",
      "Clicks shifting to organic search",
      "Genuinely incremental visits",
      "Incremental share of paid clicks",
      "Decomposition identity error"
    ),
    value = c(
      paid_clicks,
      organic_substitution,
      incremental_visits,
      incremental_visits / paid_clicks,
      identity_error
    )
  )
}


compare_roi <- function(
  effect_table,
  conversion_rate = 0.12,
  margin_per_conversion = 21,
  cost_per_click = 0.60
) {
  decomposition <- traffic_decomposition(effect_table)
  value_for <- function(metric) {
    decomposition$value[decomposition$metric == metric]
  }

  paid_clicks <- value_for("Counterfactual paid clicks per week")
  incremental_visits <- value_for("Genuinely incremental visits")
  weekly_cost <- paid_clicks * cost_per_click
  revenue_per_visit <- conversion_rate * margin_per_conversion

  naive_revenue <- paid_clicks * revenue_per_visit
  causal_revenue <- incremental_visits * revenue_per_visit
  data.frame(
    approach = c("Naive click-attribution ROI", "DiD incremental ROI"),
    visits_credited_to_ads = c(paid_clicks, incremental_visits),
    estimated_weekly_revenue = c(naive_revenue, causal_revenue),
    estimated_weekly_cost = c(weekly_cost, weekly_cost),
    estimated_roi_pct = c(
      (naive_revenue - weekly_cost) / weekly_cost * 100,
      (causal_revenue - weekly_cost) / weekly_cost * 100
    )
  )
}


placebo_check <- function(data, intervention_week = 13, placebo_week = 9) {
  prepared <- prepare_did(data, intervention_week)
  pre_data <- prepared[prepared$week < intervention_week, ]
  pre_data$placebo_post <- as.integer(pre_data$week >= placebo_week)
  placebo_model <- lm(total_traffic ~ treated * placebo_post, data = pre_data)
  coefficient_row(
    placebo_model,
    "treated:placebo_post",
    "total_traffic",
    paste("Placebo intervention at week", placebo_week)
  )
}


pretrend_check <- function(data, intervention_week = 13) {
  prepared <- prepare_did(data, intervention_week)
  pre_data <- prepared[prepared$week < intervention_week, ]
  model <- lm(total_traffic ~ treated * week, data = pre_data)
  coefficient_row(
    model,
    "treated:week",
    "total_traffic",
    "Pre-period treated-group slope difference"
  )
}


plot_parallel_trends <- function(data, output_path, intervention_week = 13) {
  prepared <- prepare_did(data, intervention_week)
  grouped <- aggregate(
    total_traffic ~ week + treated,
    data = prepared,
    FUN = mean
  )
  grouped$group <- ifelse(grouped$treated == 1, "Google (ads paused)", "Comparison platforms")

  png(output_path, width = 1100, height = 650)
  treated <- grouped[grouped$treated == 1, ]
  control <- grouped[grouped$treated == 0, ]
  plot(
    treated$week,
    treated$total_traffic,
    type = "b",
    col = "#C8102E",
    pch = 16,
    ylim = range(grouped$total_traffic),
    xlab = "Week",
    ylab = "Average weekly total traffic",
    main = "Parallel traffic trends before the ad interruption"
  )
  lines(control$week, control$total_traffic, type = "b", col = "#005B99", pch = 17)
  abline(v = intervention_week - 0.5, lty = 2)
  legend(
    "topleft",
    c("Google (ads paused)", "Comparison platforms"),
    col = c("#C8102E", "#005B99"),
    pch = c(16, 17),
    lty = 1
  )
  dev.off()
}


plot_decomposition <- function(decomposition, output_path) {
  metrics <- c(
    "Counterfactual paid clicks per week",
    "Clicks shifting to organic search",
    "Genuinely incremental visits"
  )
  values <- decomposition$value[match(metrics, decomposition$metric)]
  png(output_path, width = 1000, height = 650)
  positions <- barplot(
    values,
    names.arg = c("Paid clicks", "Organic substitution", "Incremental visits"),
    col = c("#4C78A8", "#72B7B2", "#F58518"),
    ylim = c(0, max(values) * 1.12),
    ylab = "Estimated weekly visits",
    main = "What happens when branded search ads are paused"
  )
  text(
    positions,
    values,
    labels = format(round(values), big.mark = ",", scientific = FALSE),
    pos = 3
  )
  dev.off()
}


run_analysis <- function(input_path, output_dir, intervention_week = 13) {
  data <- read.csv(input_path)
  effects <- estimate_did_effects(data, intervention_week)
  decomposition <- traffic_decomposition(effects)
  roi <- compare_roi(effects)
  placebo <- placebo_check(data, intervention_week)
  pretrend <- pretrend_check(data, intervention_week)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  write.csv(effects, file.path(output_dir, "did_effects.csv"), row.names = FALSE)
  write.csv(decomposition, file.path(output_dir, "traffic_decomposition.csv"), row.names = FALSE)
  write.csv(roi, file.path(output_dir, "roi_comparison.csv"), row.names = FALSE)
  write.csv(placebo, file.path(output_dir, "placebo_check.csv"), row.names = FALSE)
  write.csv(pretrend, file.path(output_dir, "pretrend_check.csv"), row.names = FALSE)
  plot_parallel_trends(data, file.path(output_dir, "parallel_trends.png"), intervention_week)
  plot_decomposition(decomposition, file.path(output_dir, "traffic_decomposition.png"))

  invisible(list(
    effects = effects,
    decomposition = decomposition,
    roi = roi,
    placebo = placebo,
    pretrend = pretrend
  ))
}


if (sys.nframe() == 0) {
  run_analysis(
    file.path(root, "data", "synthetic_search_traffic.csv"),
    file.path(root, "outputs")
  )
}
