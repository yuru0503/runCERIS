# Compute environmental means

Calculates mean phenotype per environment, merges with metadata, and
orders by the environmental mean.

## Usage

``` r
compute_env_means(exp_trait, env_meta)
```

## Arguments

- exp_trait:

  Data.frame from `prepare_trait_data`

- env_meta:

  Data.frame with env_code and metadata columns

## Value

Data.frame with env_code, meanY, plus env_meta columns, ordered by meanY

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
head(env_mean_trait)
#>   env_code    meanY env_notes     lat      lon PlantingDate TrialYear Location
#> 1     PR12 56.77317         2 18.0373 -66.7963   2011-12-12      2011       PR
#> 2     PR11 56.85371         1 18.0373 -66.7963   2010-12-04      2010       PR
#> 3    PR14S 60.45186         7 18.0373 -66.7963   2014-06-05      2014       PR
#> 4     KS11 73.81378         3 39.1836 -96.5717   2011-06-08      2011       KS
#> 5     IA14 74.44027         6 42.0308 -93.6319   2014-06-10      2014       IA
#> 6     KS12 80.02100         4 39.1836 -96.5717   2012-06-07      2012       KS
```
