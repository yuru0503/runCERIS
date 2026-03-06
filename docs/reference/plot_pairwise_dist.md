# Plot Pairwise Trait Distributions

Four-panel visualization: (A) geo-ordered reaction norms, (B)
env-mean-ordered with boxplots, (C) JRA regression lines, (D) MSE by
environment.

## Usage

``` r
plot_pairwise_dist(
  exp_trait,
  env_mean_trait,
  trait = "Trait",
  env_colors = NULL
)
```

## Arguments

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame with env_code, meanY, lat, lon, PlantingDate

- trait:

  Character; trait name

- env_colors:

  Optional named character vector of colors per env_code

## Value

A patchwork object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
plot_pairwise_dist(exp_trait, env_mean_trait, trait = "FTdap")
```
