# Leave-One-Environment-Out Cross-Validation (1-to-2)

For each environment, drops it from training, recalculates reaction norm
parameters, and predicts phenotypes for the dropped environment.

## Usage

``` r
cv_env(env_mean_trait, exp_trait)
```

## Arguments

- env_mean_trait:

  Data.frame from `compute_env_means` with kPara

- exp_trait:

  Data.frame from `prepare_trait_data`

## Value

Data.frame with columns: line_code, env_code, Yprd, Yobs, Rep

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
cv_result <- cv_env(env_mean_trait, exp_trait)
head(cv_result)
#>   line_code env_code   Yprd    Yobs Rep
#> 1       E10     PR12 59.200 53.1187   1
#> 2      E100     PR12 63.292 60.0257   1
#> 3      E101     PR12 57.671 56.9559   1
#> 4      E102     PR12 53.058 56.5722   1
#> 5      E103     PR12 58.087 53.8861   1
#> 6      E104     PR12 53.060 56.5722   1
# }
```
