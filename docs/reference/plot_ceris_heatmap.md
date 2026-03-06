# Plot CERIS Correlation Heatmap

Creates a multi-panel visualization of CERIS search results showing
correlation heatmaps for each environmental parameter, plus trace plots
of p-values and correlations.

## Usage

``` r
plot_ceris_heatmap(ceris_result, params, max_days)
```

## Arguments

- ceris_result:

  Data.frame from `ceris_search`

- params:

  Character vector of parameter names

- max_days:

  Maximum DAP searched

## Value

A patchwork object with heatmap + trace plots

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
result <- ceris_search(env_mean_trait, d$env_params, params, max_days = 80)
plot_ceris_heatmap(result, params, max_days = 80)

# }
```
