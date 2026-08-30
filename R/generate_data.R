build_synthetic_search_data <- function(seed = 42) {
  set.seed(seed)
  platforms <- c("google", "bing", "yahoo", "ask")
  data <- expand.grid(
    week = 1:12,
    platform = platforms,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  platform_base <- c(google = 52000, bing = 18000, yahoo = 12000, ask = 8000)
  platform_sponsored <- c(google = 6200, bing = 2400, yahoo = 1500, ask = 900)

  data$organic_traffic <- platform_base[data$platform] +
    data$week * 650 +
    rnorm(nrow(data), mean = 0, sd = 350)
  data$sponsored_traffic <- platform_sponsored[data$platform] +
    data$week * 35 +
    rnorm(nrow(data), mean = 0, sd = 80)

  treated_period <- data$platform == "google" & data$week >= 10
  data$sponsored_traffic[treated_period] <- 0
  # Some paid clicks substitute into organic traffic, but not enough to offset the loss.
  data$organic_traffic[treated_period] <- data$organic_traffic[treated_period] + 2600

  data$organic_traffic <- round(pmax(data$organic_traffic, 0))
  data$sponsored_traffic <- round(pmax(data$sponsored_traffic, 0))
  data[order(data$week, data$platform), ]
}


if (sys.nframe() == 0) {
  root <- normalizePath(file.path(dirname(commandArgs(trailingOnly = FALSE)[grep("--file=", commandArgs(trailingOnly = FALSE))]), ".."), mustWork = FALSE)
  root <- sub("^--file=", "", root)
  root <- normalizePath(file.path(dirname(root), ".."), mustWork = FALSE)
  dir.create(file.path(root, "data"), recursive = TRUE, showWarnings = FALSE)
  output <- file.path(root, "data", "synthetic_search_traffic.csv")
  write.csv(build_synthetic_search_data(), output, row.names = FALSE)
  message("Wrote synthetic search data to ", output)
}
