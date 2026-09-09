prepare_case_data <- function(data, treated_platform = "goog", interruption_week = 10) {
  required <- c("platform", "week", "avg_spons", "avg_org")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }
  if (anyNA(data[required])) stop("Required fields cannot contain missing values")
  if (!treated_platform %in% data$platform) stop("Treated platform is missing")
  if (!any(data$week < interruption_week) || !any(data$week >= interruption_week)) {
    stop("Data must contain pre- and post-interruption weeks")
  }

  result <- data
  result$treated <- as.integer(result$platform == treated_platform)
  result$post <- as.integer(result$week >= interruption_week)
  result$total_traffic <- result$avg_spons + result$avg_org
  result
}

analyze_authorized_case <- function(
  data,
  treated_platform = "goog",
  interruption_week = 10,
  conversion_probability = 0.12,
  contribution_margin = 21,
  cost_per_sponsored_click = 0.60
) {
  prepared <- prepare_case_data(data, treated_platform, interruption_week)
  model <- lm(total_traffic ~ treated * post, data = prepared)
  row <- summary(model)$coefficients["treated:post", ]
  incremental_visits <- -unname(row["Estimate"])
  paid_clicks <- mean(
    prepared$avg_spons[prepared$treated == 1 & prepared$post == 0]
  )
  weekly_cost <- paid_clicks * cost_per_sponsored_click
  incremental_contribution <- incremental_visits *
    conversion_probability * contribution_margin
  roi_pct <- (incremental_contribution - weekly_cost) / weekly_cost * 100

  summary <- data.frame(
    metric = c(
      "DiD traffic effect",
      "DiD p-value",
      "Incremental weekly visits",
      "Pre-interruption sponsored clicks",
      "Estimated weekly media cost",
      "Estimated incremental contribution",
      "Incremental ROI"
    ),
    value = c(
      unname(row["Estimate"]),
      unname(row["Pr(>|t|)"]),
      incremental_visits,
      paid_clicks,
      weekly_cost,
      incremental_contribution,
      roi_pct
    )
  )
  list(data = prepared, model = model, summary = summary)
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2) {
    stop(
      "Usage: Rscript R/authorized_case_analysis.R <input.csv> <output_dir>"
    )
  }
  results <- analyze_authorized_case(read.csv(args[1]))
  dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
  write.csv(results$summary, file.path(args[2], "case_summary.csv"), row.names = FALSE)
  message("Case analysis complete. Results written to ", normalizePath(args[2]))
}
