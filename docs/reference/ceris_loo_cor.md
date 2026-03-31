# Leave-One-Out Cross-Validated Correlation

Computes leave-one-environment-out (LOO) correlations between a trait
vector and one or more environmental parameter vectors. For each
environment left out, the Pearson correlation and \\-\log\_{10}(p)\\ are
computed from the remaining environments. The per-fold values are then
summarised across folds using a user-chosen function (default:
`median`).

## Usage

``` r
ceris_loo_cor(trait, params_matrix, summary_fn = median)
```

## Arguments

- trait:

  Numeric vector of trait means (one value per environment).

- params_matrix:

  Numeric matrix of environmental parameter values with rows
  corresponding to environments and columns to parameters.

- summary_fn:

  Function used to summarise LOO correlations across environments.
  Default is `median` (robust to outlier environments, as in the
  original CERIS implementation). Use `mean` to compare.

## Value

A list with components:

- r:

  Summarised correlation for each parameter (length =
  `ncol(params_matrix)`).

- p:

  Summarised \\-\log\_{10}(p)\\ for each parameter.

- r_matrix:

  Matrix of per-fold correlations (environments x parameters).

- p_matrix:

  Matrix of per-fold \\-\log\_{10}(p)\\ values.

## Details

This function is used internally by [`run_CERIS`](run_CERIS.md) when
`loo = TRUE`, but can also be called directly to evaluate a specific
trait–parameter combination without running the full exhaustive search.

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT")

# Compute parameter means for a specific window (DAP 20-60)
param_mat <- matrix(nrow = nrow(env_mean_trait), ncol = length(params))
for (i in seq_len(nrow(env_mean_trait))) {
  e <- env_mean_trait$env_code[i]
  e_data <- d$env_params[d$env_params$env_code == e, ]
  rows <- e_data$DAP >= 20 & e_data$DAP <= 60
  param_mat[i, ] <- colMeans(e_data[rows, params, drop = FALSE], na.rm = TRUE)
}

loo <- ceris_loo_cor(env_mean_trait$meanY, param_mat)
loo$r
#> [1]  0.9389 -0.0867  0.4305
loo$p
#> [1] 2.2613 0.0862 0.4044

# Use mean instead of median
loo_mean <- ceris_loo_cor(env_mean_trait$meanY, param_mat, summary_fn = mean)
loo_mean$r
#> [1]  0.9368 -0.0182  0.4433
# }
```
