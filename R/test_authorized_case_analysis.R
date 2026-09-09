script_args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_args[grep("^--file=", script_args)])
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
source(file.path(root, "R", "authorized_case_analysis.R"))

weeks <- 1:12
platforms <- c("goog", "bing", "yahoo", "ask")
data <- expand.grid(week = weeks, platform = platforms)
data$avg_spons <- 4000 + 150 * data$week
data$avg_org <- 5000 + 200 * data$week
treated_post <- data$platform == "goog" & data$week >= 10
data$avg_spons[treated_post] <- 0
data$avg_org[treated_post] <- data$avg_org[treated_post] - 1200

results <- analyze_authorized_case(data)
values <- setNames(results$summary$value, results$summary$metric)

stopifnot(nrow(data) == 48)
stopifnot(values[["DiD traffic effect"]] < 0)
stopifnot(values[["Incremental weekly visits"]] > 0)
stopifnot(values[["Pre-interruption sponsored clicks"]] > 0)
stopifnot(is.finite(values[["Incremental ROI"]]))

message("All original-schema sponsored-search checks passed.")
