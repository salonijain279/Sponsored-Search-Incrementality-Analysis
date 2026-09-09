# Sponsored Search Incrementality Analysis

I used an interruption in branded sponsored-search advertising as a natural experiment to answer a question that platform attribution cannot: **how much paid-search traffic was genuinely incremental?**

The campaign ran across four search platforms. Sponsored ads stopped unexpectedly on one platform while the other three continued normally, creating a treatment and comparison design for Difference-in-Differences (DiD).

## Key findings from the completed analysis

| Measure | Estimate |
|---|---:|
| Weekly traffic lost when sponsored ads stopped | **9,911 visits** |
| DiD coefficient p-value | **0.0074** |
| Advertised platform's pre-interruption paid clicks | 6,123 per week |
| Conventional click-attribution ROI | 320.0% |
| DiD-based incremental ROI | **579.8%** |

The DiD estimate shows that total traffic fell by approximately 9,911 weekly visits beyond the change observed on comparison platforms. Using that incremental effect, a 12% conversion probability, a $21 contribution margin, and a $0.60 cost per sponsored click produces an estimated ROI of 579.8%.

The result is larger than the click-attribution estimate because the natural experiment captures the effect on total visits, not only clicks recorded as sponsored. That interpretation depends on the comparison platforms providing a credible counterfactual.

## Analytical design

I used:

- one treated platform where sponsored ads stopped;
- three comparison platforms where ads continued;
- a pre/post interaction model on total traffic;
- pre-trend and placebo diagnostics; and
- a financial translation from incremental visits to contribution and ROI.

The core model is:

```text
Total traffic = platform effect + post-period effect
              + treated × post + error
```

The interaction coefficient is the estimated traffic change attributable to the ad interruption.

## Reproducible implementation

The licensed source dataset is not included. `R/authorized_case_analysis.R` runs the original-schema workflow when an authorized local file is available.

The repository also includes a fully synthetic panel so the complete DiD pipeline, diagnostics, charts, and accounting checks can be reproduced without publishing restricted data. Synthetic outputs demonstrate the method and are not the reported case results.

```bash
# Reproduce the public synthetic demonstration
Rscript R/generate_data.R
Rscript R/did_analysis.R
Rscript R/test_analysis.R

# Run the original-schema workflow with an authorized local file
Rscript R/authorized_case_analysis.R /path/to/did_sponsored_ads.csv outputs/case
Rscript R/test_authorized_case_analysis.R
```

## Repository structure

```text
R/authorized_case_analysis.R       Original-schema DiD and ROI workflow
R/generate_data.R                  Public synthetic panel generator
R/did_analysis.R                   Reproducible diagnostics and decomposition
R/test_analysis.R                  Synthetic-pipeline checks
R/test_authorized_case_analysis.R  Original-schema function checks
data/README.md                     Data provenance and schema boundary
results/verified_case_findings.csv Results retained from the completed analysis
outputs/                           Synthetic demonstration outputs and charts
```

## Causal interpretation

The DiD estimate is credible when:

- treated and comparison traffic would have followed parallel trends without the interruption;
- no other treated-platform shock occurred at the same time;
- the comparison platforms were unaffected by the interruption; and
- the interruption timing was not chosen in response to traffic performance.

## Tools and skills

`R` · Difference-in-Differences · natural experiments · fixed effects · pre-trend checks · placebo tests · marketing incrementality · ROI

## Collaboration

The original analysis was completed with **Shivanshu Dagur**. I maintain this repository and rewrote the workflow for clear, reusable presentation.
