# Measuring the Incremental Impact of Sponsored Search

An R Difference-in-Differences case study that estimates how much website traffic and ROI branded paid-search advertising actually creates.

## Business question

When sponsored ads are paused on one search platform, how much traffic is truly lost after accounting for organic substitution and the market-wide time trend?

## Why causal inference matters

A naive ROI calculation credits every sponsored click to advertising. That ignores visitors who would have clicked the organic result anyway. This analysis uses an ad interruption as a natural experiment:

- one platform is the treated group;
- three unaffected platforms form the comparison group;
- pre-treatment trends establish the counterfactual;
- the treatment-by-post interaction estimates incremental impact.

## Data

The included generator creates a **synthetic dataset with the same analytical structure as the academic case but no copied case observations or instructional material**.

## Run

```bash
Rscript R/generate_data.R
Rscript R/did_analysis.R
Rscript R/test_analysis.R
```

Outputs:

- `outputs/did_coefficients.csv`
- `outputs/roi_summary.csv`
- `outputs/parallel_trends.png`

## Methods

`R` · Difference-in-Differences · natural experiments · regression · counterfactual reasoning · ROI

## Interpretation boundary

The DiD estimate is causal only when the design assumptions are credible, especially parallel pre-trends and absence of treatment-specific concurrent shocks.
