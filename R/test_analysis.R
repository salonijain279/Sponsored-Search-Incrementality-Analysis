script_arg <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_arg[grep("^--file=", script_arg)])
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)

source(file.path(root, "R", "generate_data.R"))
source(file.path(root, "R", "did_analysis.R"))

data <- build_synthetic_search_data()
result <- estimate_did(data)
manual <- manual_did(data)

stopifnot(nrow(data) == 48)
stopifnot(result$effect < -2500)
stopifnot(abs(result$effect - manual) < 1e-8)
stopifnot(roi_summary(data, result$effect)$estimated_roi_pct > 0)

message("All causal-analysis checks passed.")
