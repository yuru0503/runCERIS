# Plot Trait Mean vs Environmental Parameter

Scatter plot of the best environmental covariate vs phenotype means with
regression line and correlation annotation.

## Usage

``` r
plot_trait_env_param(
  env_mean_trait,
  trait = "Trait",
  kpara_name = "kPara",
  dap_start = NULL,
  dap_end = NULL,
  env_colors = NULL
)
```

## Arguments

- env_mean_trait:

  Data.frame with env_code, meanY, kPara

- trait:

  Character; trait name for y-axis label

- kpara_name:

  Character; parameter name for x-axis label

- dap_start:

  Start day of the window

- dap_end:

  End day of the window

- env_colors:

  Optional named character vector of colors per env_code

## Value

A ggplot object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
plot_trait_env_param(env_mean_trait, trait = "FTdap", kpara_name = "DL",
                     dap_start = 20, dap_end = 60)
```
