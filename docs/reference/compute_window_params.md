# Compute environmental covariate values for a window

For each environment, calculates the mean of each environmental
parameter over a specified DAP window.

## Usage

``` r
compute_window_params(env_mean_trait, env_params, dap_start, dap_end, params)
```

## Arguments

- env_mean_trait:

  Data.frame with env_code column

- env_params:

  Data.frame with env_code, DAP, and parameter columns

- dap_start:

  Start day of window

- dap_end:

  End day of window

- params:

  Character vector of parameter column names

## Value

Data.frame env_mean_trait with added kPara column (first param) and a
`window_params` attribute containing all parameter averages

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
head(env_mean_trait[, c("env_code", "meanY", "kPara")])
#>   env_code    meanY    kPara
#> 1     PR12 56.77317 12.01122
#> 2     PR11 56.85371 11.94220
#> 3    PR14S 60.45186 13.88512
#> 4     KS11 73.81378 15.59537
#> 5     IA14 74.44027 15.87439
#> 6     KS12 80.02100 15.60634
```
