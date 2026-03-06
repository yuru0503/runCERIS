# Line-Level Leave-One-Out Cross-Validation

For each line, leaves out one environment at a time and predicts the
phenotype using both environmental mean and environmental parameter
regressions.

## Usage

``` r
loocv(exp_trait, env_mean_trait)
```

## Arguments

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame with env_code, meanY, kPara

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
loo_result <- loocv(exp_trait, env_mean_trait)
head(loo_result)
#>   env_code line_code Prd_trait_mean Prd_trait_kPara Obs_trait Line_mean
#> 1     IA13       E10        109.455          98.139   89.7396  78.37150
#> 2     IA14       E10         89.676          99.649   77.3756  80.43217
#> 3     KS11       E10         84.764          90.275   95.5120  77.40943
#> 4     KS12       E10         90.948          87.028  107.9397  75.33815
#> 5     PR11       E10         65.257          57.860   53.4805  84.41468
#> 6     PR12       E10         65.317          59.200   53.1187  84.47498
# }
```
