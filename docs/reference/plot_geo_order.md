# Plot Environments in Geographic Order

Plots individual line phenotypes with environments ordered by latitude,
longitude, and planting date.

## Usage

``` r
plot_geo_order(exp_trait, env_mean_trait, trait = "Trait", env_colors = NULL)
```

## Arguments

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- env_mean_trait:

  Data.frame with env_code, meanY, lat, lon, PlantingDate

- trait:

  Character; trait name for axis labels

- env_colors:

  Optional named character vector of colors per env_code

## Value

A ggplot object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
plot_geo_order(exp_trait, env_mean_trait, trait = "FTdap")
```
