# Measuring the Incremental Impact of Sponsored Search

I used this R case study to estimate how much website traffic and ROI branded paid-search advertising actually created, rather than crediting every sponsored click to the campaign.

## The question I asked

When sponsored ads are paused on one search platform, how much traffic is truly lost after accounting for organic substitution and the market-wide time trend?

## Why causal inference matters

A naive ROI calculation credits every sponsored click to advertising. I wanted to account for visitors who might have clicked the organic result anyway, so I treated an ad interruption as a natural experiment:

- one platform is the treated group;
- three unaffected platforms form the comparison group;
- pre-treatment trends establish the counterfactual;
- the treatment-by-post interaction estimates incremental impact.

## Data

I wrote the included generator to create a synthetic dataset with the same analytical structure as the academic case. It contains no copied observations or instructional material.

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
