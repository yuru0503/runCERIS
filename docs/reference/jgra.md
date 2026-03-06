# Joint Genomic Regression Analysis (Reaction Norm Parameters)

Performs genomic prediction through estimation and prediction of
reaction norm parameters (intercept and slope) using GBLUP (rrBLUP) or
BayesB (BGLR).

## Usage

``` r
jgra(
  pheno,
  geno,
  envir,
  enp,
  env_meta,
  tt_line = NULL,
  tt_env = NULL,
  method = c("RM.E", "RM.G", "RM.GE"),
  gp_method = c("rrBLUP", "BayesB"),
  nIter = 5000,
  burnIn = 1000,
  seed = NULL,
  fold = 10,
  reshuffle = 5,
  progress = NULL
)
```

## Arguments

- pheno:

  Wide-format phenotype data.frame (line_code + environment columns)

- geno:

  Genotype data.frame or matrix with line_code identifier

- envir:

  Data.frame with env_code and environmental parameter columns

- enp:

  Name or index of the environmental parameter column to use

- env_meta:

  Data.frame with env_code (used for filtering)

- tt_line:

  Minimum non-NA lines per environment; environments with fewer are
  dropped

- tt_env:

  Minimum non-NA environments per line; lines with fewer are dropped

- method:

  One of "RM.E" (env LOO), "RM.G" (genotype CV), "RM.GE" (combined)

- gp_method:

  Genomic prediction method: `"rrBLUP"` (default, ridge regression BLUP)
  or `"BayesB"` (Bayesian variable selection via BGLR). Only used for
  methods `"RM.G"` and `"RM.GE"`.

- nIter:

  Integer. MCMC iterations for BayesB (default 5000). Ignored when
  `gp_method = "rrBLUP"`.

- burnIn:

  Integer. Burn-in iterations for BayesB (default 1000). Ignored when
  `gp_method = "rrBLUP"`.

- seed:

  Integer or `NULL`. Random seed for reproducible results.

- fold:

  Number of CV folds (default 10)

- reshuffle:

  Number of iterations (default 5)

- progress:

  Optional callback function(fraction)

## Value

A list with:

- predictions:

  Data.frame with obs, pre, envir columns

- r_within:

  Within-environment correlations

- r_across:

  Across-environment correlation(s)

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
pheno <- prepare_line_by_env(exp_trait, env_mean_trait)
SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
geno_df <- data.frame(line_code = rownames(SNPs), SNPs, check.names = FALSE)
envir <- env_mean_trait[, c("env_code", "kPara")]
result <- jgra(pheno, geno_df, envir, "kPara", d$env_meta,
               method = "RM.E", fold = 5, reshuffle = 2)
result$r_across
#> [1] 0.449978
# }
```
