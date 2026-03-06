# Forecast Phenotypes for New Environments

Predicts phenotypes for a set of environments using models trained on a
different set of environments (e.g., year-to-year prediction).

## Usage

``` r
forecast_next_year(exp_trait, env_mean_trait, trn_env)
```

## Arguments

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame with env_code, meanY, kPara

- trn_env:

  Character vector of training environment codes

## Value

Data.frame with columns: env_code, line_code, Prd_trait_mean,
Prd_trait_kPara, Obs_trait, Line_mean

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
trn_env <- env_mean_trait$env_code[1:5]
fc_result <- forecast_next_year(exp_trait, env_mean_trait, trn_env)
head(fc_result)
#>   env_code line_code Prd_trait_mean Prd_trait_kPara Obs_trait Line_mean
#> 1     IA13       E10        103.432          91.363  89.73960  72.45786
#> 2     KS12       E10         97.544          87.523 107.93970  72.45786
#> 3     IA13      E100         77.983          72.745  84.28180  67.19408
#> 4     KS12      E100         75.932          71.618  69.38350  67.19408
#> 5     IA13      E101         88.496          78.754  83.53581  67.31058
#> 6     KS12      E101         84.469          76.430  87.69770  67.31058
# }
```
