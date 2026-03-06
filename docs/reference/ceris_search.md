# CERIS Exhaustive Search for Critical Environmental Windows

Searches all possible date windows for correlations between
environmental parameters and trait means across environments.

## Usage

``` r
ceris_search(
  env_mean_trait,
  env_params,
  params,
  max_days = NULL,
  loo = FALSE,
  loo_summary = median,
  progress = NULL
)
```

## Arguments

- env_mean_trait:

  Data.frame with env_code and meanY columns

- env_params:

  Data.frame with env_code, DAP, and parameter columns

- params:

  Character vector of environmental parameter column names

- max_days:

  Maximum number of days after planting to search (default: max DAP)

- loo:

  Logical; if TRUE, perform leave-one-environment-out cross-validation
  (default FALSE)

- loo_summary:

  Function used to summarize LOO correlations across environments.
  Default is `median` (robust to outlier environments, as in the
  original CERIS implementation). Use `mean` to compare.

- progress:

  Optional callback function receiving a fraction (0–1) for progress
  reporting. Called every 100 windows.

## Value

Data.frame with columns: Day_x, Day_y, window, midXY, R\_\<param\>,
P\_\<param\> for each parameter

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
result <- ceris_search(env_mean_trait, d$env_params, params, max_days = 80)
head(result)
#>   Day_x Day_y window midXY   R_DL   R_GDD   R_PTT   R_PTR  R_PTS   P_DL  P_GDD
#> 1     1     7      6   4.0 0.9273 -0.6057 -0.1714 -0.8528 0.6876 2.5804 0.8254
#> 2     1     8      7   4.5 0.9275 -0.5840 -0.1299 -0.8479 0.6937 2.5823 0.7731
#> 3     1     9      8   5.0 0.9276 -0.5819 -0.0799 -0.8568 0.7298 2.5848 0.7682
#> 4     1    10      9   5.5 0.9277 -0.5835 -0.0200 -0.8713 0.7415 2.5853 0.7719
#> 5     1    11     10   6.0 0.9278 -0.5951  0.0064 -0.8795 0.7790 2.5877 0.7995
#> 6     1    12     11   6.5 0.9279 -0.5821  0.0352 -0.8784 0.7893 2.5889 0.7687
#>    P_PTT  P_PTR  P_PTS
#> 1 0.1468 1.8321 1.0568
#> 2 0.1071 1.7975 1.0765
#> 3 0.0631 1.8608 1.2034
#> 4 0.0150 1.9732 1.2483
#> 5 0.0047 2.0429 1.4088
#> 6 0.0268 2.0328 1.4581
# }
```
