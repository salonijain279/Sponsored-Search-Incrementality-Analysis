build_synthetic_search_data <- function(seed = 6441, intervention_week = 13) {
  set.seed(seed)

  platforms <- c("google", "bing", "yahoo", "ask")
  weeks <- 1:16
  data <- expand.grid(
    week = weeks,
    platform = platforms,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  organic_base <- c(google = 12000, bing = 7200, yahoo = 5100, ask = 3600)
  sponsored_base <- c(google = 6000, bing = 2600, yahoo = 1800, ask = 1100)
  organic_time <- 95 * data$week + 140 * sin(data$week / 2)
  sponsored_time <- 20 * data$week + 25 * cos(data$week / 3)

  data$organic_traffic <- organic_base[data$platform] +
    organic_time + rnorm(nrow(data), mean = 0, sd = 55)
  data$sponsored_traffic <- sponsored_base[data$platform] +
    sponsored_time + rnorm(nrow(data), mean = 0, sd = 22)

  ads_off <- data$platform == "google" & data$week >= intervention_week
  paid_clicks_without_outage <- data$sponsored_traffic[ads_off]

  # When branded ads disappear, 70% of paid clicks move to the free organic result.
  # The remaining 30% are genuinely incremental visits that disappear with the ads.
  data$organic_traffic[ads_off] <- data$organic_traffic[ads_off] +
    0.70 * paid_clicks_without_outage
  data$sponsored_traffic[ads_off] <- 0

  data$organic_traffic <- round(pmax(data$organic_traffic, 0))
  data$sponsored_traffic <- round(pmax(data$sponsored_traffic, 0))
  data[order(data$week, data$platform), ]
}


if (sys.nframe() == 0) {
  script_args <- commandArgs(trailingOnly = FALSE)
  script_path <- sub("^--file=", "", script_args[grep("^--file=", script_args)])
  root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)
  dir.create(file.path(root, "data"), recursive = TRUE, showWarnings = FALSE)
  output_path <- file.path(root, "data", "synthetic_search_traffic.csv")
  write.csv(build_synthetic_search_data(), output_path, row.names = FALSE)
  message("Wrote synthetic search traffic to ", output_path)
}
