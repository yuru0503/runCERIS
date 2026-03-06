# PCA Biplot of Environmental Parameters

Performs PCA on environmental parameters aggregated per environment and
creates a biplot with optional ellipses.

## Usage

``` r
plot_pca_biplot(env_params, env_mean_trait, params, group_col = NULL)
```

## Arguments

- env_params:

  Data.frame with env_code, DAP, and parameter columns

- env_mean_trait:

  Data.frame with env_code (for labeling)

- params:

  Character vector of parameter names to include

- group_col:

  Optional column name in env_mean_trait for grouping ellipses

## Value

A ggplot object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
plot_pca_biplot(d$env_params, env_mean_trait, params)
```
