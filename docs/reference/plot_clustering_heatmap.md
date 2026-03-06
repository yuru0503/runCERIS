# Clustering Heatmap of Environmental Parameters

Creates a heatmap with hierarchical clustering of environments based on
environmental parameters using pheatmap.

## Usage

``` r
plot_clustering_heatmap(env_params, params, scale_data = TRUE)
```

## Arguments

- env_params:

  Data.frame with env_code, DAP, and parameter columns

- params:

  Character vector of parameter names to include

- scale_data:

  Logical; whether to scale parameters (default TRUE)

## Value

A pheatmap object (also plots)

## Examples

``` r
d <- load_crop_data("sorghum")
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
plot_clustering_heatmap(d$env_params, params)
```
