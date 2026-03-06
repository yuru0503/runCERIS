# K-Fold Genotype Cross-Validation (1-to-3)

Performs K-fold cross-validation on genotypes using GBLUP (rrBLUP) or
BayesB (BGLR) to predict slope and intercept, then predicts phenotypes
across environments.

## Usage

``` r
cv_genotype(
  gFold,
  gIteration,
  SNPs,
  lm_ab_matrix,
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

- lm_ab_matrix:

  Data.frame from `slope_intercept` with line_code, Intcp_para,
  Slope_para

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
lm_ab <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
cv_result <- cv_genotype(gFold = 5, gIteration = 2, SNPs = SNPs,
                         lm_ab_matrix = lm_ab, env_mean_trait = env_mean_trait,
                         exp_trait = exp_trait)
head(cv_result)
#>   line_code env_code   Yprd    Yobs Rep
#> 1      E103     PR12 55.738 53.8861   1
#> 2      E104     PR12 56.118 56.5722   1
#> 3      E110     PR12 58.155 60.0257   1
#> 4      E111     PR12 53.306 55.0373   1
#> 5       E12     PR12 58.620 56.1885   1
#> 6      E121     PR12 54.783 55.0373   1
# }
```
