# Prepare line-by-environment matrix

Creates a wide-format data.frame with line_code as first column and
environments as subsequent columns, ordered by environmental mean.

## Usage

``` r
prepare_line_by_env(exp_trait, env_mean_trait)
```

## Arguments

- exp_trait:

  Data.frame from `prepare_trait_data`

- env_mean_trait:

  Data.frame from `compute_env_means`

## Value

Wide data.frame with line_code + environment columns

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
line_by_env <- prepare_line_by_env(exp_trait, env_mean_trait)
head(line_by_env[, 1:4])
#>   line_code    PR12    PR11   PR14S
#> 1       E10 53.1187 53.4805 82.8025
#> 2      E100 60.0257 66.6417 64.0564
#> 3      E101 56.9559 58.7449 65.3437
#> 4      E102 56.5722 54.3579 60.0090
#> 5      E103 53.8861 54.7966 77.9528
#> 6      E104 56.5722 53.4805 64.8587
```
