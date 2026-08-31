script_args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_args[grep("^--file=", script_args)])
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)

source(file.path(root, "R", "generate_data.R"))
source(file.path(root, "R", "did_analysis.R"))

data <- build_synthetic_search_data()
effects <- estimate_did_effects(data)
decomposition <- traffic_decomposition(effects)
roi <- compare_roi(effects)
placebo <- placebo_check(data)
pretrend <- pretrend_check(data)

value_for <- function(metric) {
  decomposition$value[decomposition$metric == metric]
}

stopifnot(nrow(data) == 64)
stopifnot(nrow(effects) == 6)
stopifnot(value_for("Counterfactual paid clicks per week") > 6000)
stopifnot(value_for("Clicks shifting to organic search") > 4000)
stopifnot(value_for("Genuinely incremental visits") > 1500)
stopifnot(abs(value_for("Decomposition identity error")) < 1e-8)
stopifnot(value_for("Incremental share of paid clicks") > 0.25)
stopifnot(value_for("Incremental share of paid clicks") < 0.35)
stopifnot(roi$estimated_roi_pct[roi$approach == "Naive click-attribution ROI"] > 300)
stopifnot(roi$estimated_roi_pct[roi$approach == "DiD incremental ROI"] > 0)
stopifnot(roi$estimated_roi_pct[roi$approach == "DiD incremental ROI"] < 50)
stopifnot(placebo$p_value > 0.05)
stopifnot(pretrend$p_value > 0.05)

message("All sponsored-search causal-analysis checks passed.")
