# Internal: Impute Missing Marker Values

Uses [`rrBLUP::A.mat`](https://rdrr.io/pkg/rrBLUP/man/A.mat.html) when
`gp_method = "rrBLUP"`, otherwise falls back to column-mean imputation
so that BayesB does not require rrBLUP.

## Usage

``` r
impute_markers(geno_matrix, gp_method = "rrBLUP")
```

## Arguments

- geno_matrix:

  Numeric genotype matrix.

- gp_method:

  Character, `"rrBLUP"` or `"BayesB"`.

## Value

Imputed numeric genotype matrix.
