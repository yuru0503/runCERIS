# Genomic Prediction using rrBLUP

Predicts phenotypic values for a validation set using ridge regression
BLUP.

## Usage

``` r
pred_rrblup(Y_matrix, X_matrix, prd_idx, n)
```

## Arguments

- Y_matrix:

  Data.frame with ID_code as first column and trait columns

- X_matrix:

  Genotype matrix with line codes as rownames

- prd_idx:

  Integer vector of row indices for the validation set

- n:

  Iteration number (for tracking)

## Value

Data.frame with observed and predicted values for each trait

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
ab_df <- lm_ab[, c("line_code", "Intcp_para", "Slope_para")]
prd_result <- pred_rrblup(ab_df, SNPs, prd_idx = 1:5, n = 1)
head(prd_result)
#>   ID_code Intcp_para_obs Slope_para_obs Intcp_para_prd Slope_para_prd Rep
#> 1     E10       -60.2250         9.7216     -31.448138       7.184643   1
#> 2    E100        21.6207         3.3506       8.136223       4.063566   1
#> 3    E101       -18.2309         6.2933     -11.396233       5.652542   1
#> 4    E102        -4.4025         4.9118      -4.834306       5.145758   1
#> 5    E103      -101.4857        13.1325     -39.868451       7.976796   1
# }
```
