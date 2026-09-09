# Data

The licensed source dataset is not redistributed. An authorized source file for the completed analysis must contain `platform`, `week`, `avg_spons`, and `avg_org`.

`synthetic_search_traffic.csv` is a separate public demonstration containing 16 weeks of organic and sponsored traffic for one treated search platform and three comparison platforms.

The data generator creates parallel pre-intervention trends. Starting in Week 13, branded ads are paused on the treated platform: some paid clicks shift to the organic result and the remaining incremental visits disappear. This known data-generating process makes it possible to test whether the analysis recovers the intended causal decomposition.

Run the following command to reproduce the file:

```bash
Rscript R/generate_data.R
```

The public dataset is entirely synthetic and contains no observations from the completed case analysis.
