# Plot Environmental Factors Over Time

Line plots of daily environmental parameters (e.g., day length,
cumulative GDD) across environments.

## Usage

``` r
plot_env_factors(env_params, params = c("DL", "GDD"), env_colors = NULL)
```

## Arguments

- env_params:

  Data.frame with env_code, DAP, and parameter columns

- params:

  Character vector of parameter names to plot (default: c("DL", "GDD"))

- env_colors:

  Optional named character vector of colors per env_code

## Value

A patchwork object with one panel per parameter

## Examples

``` r
d <- load_crop_data("sorghum")
plot_env_factors(d$env_params, params = c("DL", "GDD"))
```
