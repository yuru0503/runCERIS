# Plot Reaction Norm Slopes and Intercepts

Two-panel plot: (A) Reaction norm regression lines using the
environmental parameter, (B) histogram of R-squared values.

## Usage

``` r
plot_slope_intercept(
  exp_trait_merged,
  res_para,
  trait = "Trait",
  kpara_name = "kPara"
)
```

## Arguments

- exp_trait_merged:

  Data.frame with Yobs and kPara columns (merge of exp_trait and
  env_mean_trait)

- res_para:

  Data.frame from `slope_intercept` with Intcp_para, Slope_para, R2_para

- trait:

  Character; trait name for axis labels

- kpara_name:

  Character; name of the environmental parameter

## Value

A patchwork object

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
si <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
merged <- merge(exp_trait, env_mean_trait[, c("env_code", "kPara")], by = "env_code")
plot_slope_intercept(merged, si, trait = "FTdap")
```
