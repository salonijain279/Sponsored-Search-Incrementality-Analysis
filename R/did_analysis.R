script_arg <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_arg[grep("^--file=", script_arg)])
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)


prepare_did <- function(data) {
  required <- c("week", "platform", "organic_traffic", "sponsored_traffic")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }
  data$treated <- as.integer(data$platform == "google")
  data$after <- as.integer(data$week >= 10)
  data$total_traffic <- data$organic_traffic + data$sponsored_traffic
  data
}


estimate_did <- function(data) {
  prepared <- prepare_did(data)
  model <- lm(total_traffic ~ treated * after, data = prepared)
  list(data = prepared, model = model, effect = unname(coef(model)[["treated:after"]]))
}


manual_did <- function(data) {
  prepared <- prepare_did(data)
  means <- aggregate(
    total_traffic ~ treated + after,
    data = prepared,
    FUN = mean
  )
  get_mean <- function(treated_value, after_value) {
    means$total_traffic[means$treated == treated_value & means$after == after_value]
  }
  (get_mean(1, 1) - get_mean(1, 0)) -
    (get_mean(0, 1) - get_mean(0, 0))
}


roi_summary <- function(data, effect, conversion_rate = 0.12, margin = 21, cpc = 0.60) {
  prepared <- prepare_did(data)
  pre_sponsored <- mean(
    prepared$sponsored_traffic[prepared$treated == 1 & prepared$after == 0]
  )
  incremental_visits <- abs(effect)
  revenue <- incremental_visits * conversion_rate * margin
  cost <- pre_sponsored * cpc
  data.frame(
    incremental_visits_per_week = incremental_visits,
    estimated_weekly_revenue = revenue,
    estimated_weekly_cost = cost,
    estimated_roi_pct = (revenue - cost) / cost * 100
  )
}


run_analysis <- function(input_path, output_dir) {
  data <- read.csv(input_path)
  result <- estimate_did(data)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  coefficients <- data.frame(
    term = names(coef(result$model)),
    estimate = unname(coef(result$model)),
    std_error = sqrt(diag(vcov(result$model))),
    row.names = NULL
  )
  write.csv(coefficients, file.path(output_dir, "did_coefficients.csv"), row.names = FALSE)
  write.csv(roi_summary(data, result$effect), file.path(output_dir, "roi_summary.csv"), row.names = FALSE)

  png(file.path(output_dir, "parallel_trends.png"), width = 1100, height = 650)
  prepared <- result$data
  treated <- aggregate(total_traffic ~ week, prepared[prepared$treated == 1, ], mean)
  control <- aggregate(total_traffic ~ week, prepared[prepared$treated == 0, ], mean)
  plot(
    treated$week,
    treated$total_traffic,
    type = "b",
    col = "#C8102E",
    pch = 16,
    xlab = "Week",
    ylab = "Average total traffic",
    main = "Synthetic parallel-trends diagnostic"
  )
  lines(control$week, control$total_traffic, type = "b", col = "#005B99", pch = 17)
  abline(v = 9.5, lty = 2)
  legend("topleft", c("Treated platform", "Control platforms"), col = c("#C8102E", "#005B99"), pch = c(16, 17), lty = 1)
  dev.off()

  message("Estimated weekly treatment effect: ", round(result$effect))
  invisible(result)
}


if (sys.nframe() == 0) {
  run_analysis(
    file.path(root, "data", "synthetic_search_traffic.csv"),
    file.path(root, "outputs")
  )
}
