# Plot JRA Results

Two-panel plot: (A) JRA regression lines overlaid on data, (B) histogram
of R-squared values.

## Usage

``` r
plot_jra(exp_trait, env_mean_trait, jra_result, trait = "Trait")
```

## Arguments

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame with meanY

- jra_result:

  Data.frame from `jra_model` with Intcp, Slope_mean, R2_mean

- trait:

  Character; trait name for axis labels

## Value

A patchwork object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
line_by_env <- prepare_line_by_env(exp_trait, env_mean_trait)
jra_result <- jra_model(line_by_env, env_mean_trait)
plot_jra(exp_trait, env_mean_trait, jra_result, trait = "FTdap")
```
