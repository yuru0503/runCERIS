# Plot Phenotypes vs Environmental Means

Scatter plot showing individual line phenotypes against environmental
means, with connecting lines for each genotype and a 1:1 reference line.

## Usage

``` r
plot_env_means(exp_trait, env_mean_trait, trait = "Trait")
```

## Arguments

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame with env_code and meanY

- trait:

  Character; trait name for axis labels

## Value

A ggplot object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
plot_env_means(exp_trait, env_mean_trait, trait = "FTdap")
```
