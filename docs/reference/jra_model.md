# Joint Regression Analysis

Fits a linear regression of individual line phenotypes against the
environmental mean for each genotype. Extracts intercept, slope, and
R-squared.

## Usage

``` r
jra_model(line_by_env, env_mean_trait)
```

## Arguments

- line_by_env:

  Wide data.frame from `prepare_line_by_env` (line_code + environment
  columns)

- env_mean_trait:

  Data.frame from `compute_env_means` with meanY

## Value

Data.frame with columns: line_code, Intcp, Intcp_mean, Slope_mean,
R2_mean

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
line_by_env <- prepare_line_by_env(exp_trait, env_mean_trait)
jra_result <- jra_model(line_by_env, env_mean_trait)
head(jra_result)
#>              line_code    Intcp Intcp_mean Slope_mean R2_mean
#> (Intercept)        E10 -24.2110    79.9955     1.5008  0.6681
#> (Intercept)1      E100  29.0797    69.9480     0.5886  0.6418
#> (Intercept)2      E101  -0.7133    72.5409     1.0550  0.9373
#> (Intercept)3      E102   9.2963    66.4430     0.8231  0.9763
#> (Intercept)4      E103 -60.6675    87.9326     2.1402  0.5742
#> (Intercept)5      E104 -26.4641    77.3758     1.4956  0.6291
```
