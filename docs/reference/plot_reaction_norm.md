# Plot Reaction Norms

Four-panel reaction norm visualization: (A) raw data by arbitrary env
order, (B) by env mean order, (C) continuous env mean axis, (D) fitted
regression lines.

## Usage

``` r
plot_reaction_norm(exp_trait, env_mean_trait, trait = "Trait")
```

## Arguments

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame with env_code, meanY

- trait:

  Character; trait name

## Value

A patchwork object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
plot_reaction_norm(exp_trait, env_mean_trait, trait = "FTdap")
```
