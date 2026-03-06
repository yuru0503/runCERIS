# Identify the Best Environmental Window from CERIS Results

Finds the window and parameter with the maximum absolute correlation
from a CERIS search result.

## Usage

``` r
ceris_identify_best(ceris_result, params, min_window = 7)
```

## Arguments

- ceris_result:

  Data.frame from `ceris_search`

- params:

  Character vector of parameter names

- min_window:

  Minimum window size in days (default 7)

## Value

A list with components:

- param_name:

  Name of the best environmental parameter

- dap_start:

  Start day of the best window

- dap_end:

  End day of the best window

- correlation:

  Correlation value at the best window

- neg_log_p:

  -log10(p-value) at the best window

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
result <- ceris_search(env_mean_trait, d$env_params, params, max_days = 80)
best <- ceris_identify_best(result, params)
best$param_name
#> [1] "PTS"
best$dap_start
#> [1] 9
best$dap_end
#> [1] 16
# }
```
