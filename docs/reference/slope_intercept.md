# Calculate Reaction Norm Slopes and Intercepts

Fits linear regressions of individual line phenotypes against an
environmental covariate (kPara) and/or the environmental mean.

## Usage

``` r
slope_intercept(exp_trait, env_mean_trait, type = "kPara")
```

## Arguments

- exp_trait:

  Data.frame from `prepare_trait_data` with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame from `compute_env_means` with meanY and kPara columns

- type:

  Character; one of "kPara" (default), "mean", or "both"

## Value

Data.frame with line_code and slope/intercept columns depending on type:

- "kPara": Intcp_para_adj, Intcp_para, Slope_para, R2_para

- "mean": Intcp_mean, Slope_mean

- "both": all columns above

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
si <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
head(si)
#>   line_code Intcp_para_adj Intcp_para Slope_para R2_para
#> 1       E10        79.9955   -60.2250     9.7216  0.7316
#> 2      E100        69.9480    21.6207     3.3506  0.5428
#> 3      E101        72.5409   -18.2309     6.2933  0.8704
#> 4      E102        66.4430    -4.4025     4.9118  0.9075
#> 5      E103        87.9326  -101.4857    13.1325  0.5643
#> 6      E104        77.3758   -58.8275     9.4430  0.6546
```
