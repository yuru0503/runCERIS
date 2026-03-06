# Combined Environment and Genotype Cross-Validation (1-to-4)

Combines leave-one-environment-out with K-fold genotype
cross-validation. For each dropped environment, recalculates reaction
norms and then performs genotype CV with GBLUP (rrBLUP) or BayesB
(BGLR).

## Usage

``` r
cv_combined(
  gFold,
  gIteration,
  SNPs,
  env_mean_trait,
  exp_trait,
  gp_method = c("rrBLUP", "BayesB"),
  nIter = 5000,
  burnIn = 1000,
  seed = NULL,
  progress = NULL
)
```

## Arguments

- gFold:

  Number of CV folds

- gIteration:

  Number of iterations (reshuffles)

- SNPs:

  Genotype matrix (line_code as rownames)

- env_mean_trait:

  Data.frame with env_code, meanY, kPara

- exp_trait:

  Data.frame with line_code, env_code, Yobs

- gp_method:

  Genomic prediction method: `"rrBLUP"` (default) or `"BayesB"`.

- nIter:

  Integer. MCMC iterations for BayesB (default 5000).

- burnIn:

  Integer. Burn-in iterations for BayesB (default 1000).

- seed:

  Integer or `NULL`. Random seed for reproducible results.

- progress:

  Optional callback function(fraction)

## Value

Data.frame with columns: line_code, env_code, Yprd, Yobs, Rep

## Examples

``` r
# \donttest{
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
cv_result <- cv_combined(gFold = 5, gIteration = 2, SNPs = SNPs,
                         env_mean_trait = env_mean_trait, exp_trait = exp_trait)
head(cv_result)
#>   line_code env_code   Yprd    Yobs Rep
#> 1      E102     PR12 58.611 56.5722   1
#> 2      E103     PR12 55.364 53.8861   1
#> 3      E106     PR12 53.217 57.3396   1
#> 4      E107     PR12 52.402 58.1071   1
#> 5      E108     PR12 55.731 60.0257   1
#> 6      E114     PR12 54.083 54.6536   1
# }
```
