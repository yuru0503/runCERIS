# Genomic Prediction using BayesB (BGLR)

Predicts phenotypic values for a validation set using BayesB from the
BGLR package. This is an alternative to [`pred_rrblup`](pred_rrblup.md)
that uses Bayesian variable selection via MCMC, allowing marker-specific
shrinkage.

## Usage

``` r
pred_bayesb(Y_matrix, X_matrix, prd_idx, n, nIter = 5000, burnIn = 1000)
```

## Arguments

- Y_matrix:

  Data.frame with ID_code as first column and trait columns (e.g.,
  Intcp_para, Slope_para).

- X_matrix:

  Genotype matrix with line codes as rownames.

- prd_idx:

  Integer vector of row indices for the validation set.

- n:

  Iteration number (for tracking via the Rep column).

- nIter:

  Integer. Number of MCMC iterations (default 5000).

- burnIn:

  Integer. Number of burn-in iterations (default 1000).

## Value

Data.frame with observed and predicted values for each trait, plus an
ID_code and Rep column.

## Examples

``` r
if (FALSE) { # \dontrun{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params,
                                        20, 60, params)
lm_ab <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
ab_df <- lm_ab[, c("line_code", "Intcp_para", "Slope_para")]
prd_result <- pred_bayesb(ab_df, SNPs, prd_idx = 1:5, n = 1,
                          nIter = 1000, burnIn = 200)
head(prd_result)
} # }
```
