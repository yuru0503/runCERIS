# Plot Cross-Validation Results

Multi-panel predicted vs observed scatter plots for different CV
scenarios.

## Usage

``` r
plot_cv_results(
  cv_results,
  labels = paste0("1-to-", seq_along(cv_results) + 1),
  env_colors = NULL
)
```

## Arguments

- cv_results:

  List of data.frames, each with Yprd, Yobs, env_code, Rep columns.
  Typically: list(cv_env_result, cv_genotype_result, cv_combined_result)

- labels:

  Character vector of labels for each CV scenario (default: "1-to-2",
  "1-to-3", "1-to-4")

- env_colors:

  Optional named character vector of colors per env_code

## Value

A patchwork object

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
cv_e <- cv_env(env_mean_trait, exp_trait)
plot_cv_results(list(cv_e), labels = c("1-to-2 (Env)"))

# }
```
