# Internal: Solve Genomic Prediction for a Single Trait Vector

Dispatches to
[`rrBLUP::mixed.solve`](https://rdrr.io/pkg/rrBLUP/man/mixed.solve.html)
or [`BGLR::BGLR`](https://rdrr.io/pkg/BGLR/man/BGLR.html) based on
`gp_method`. Returns a list with marker effects and intercept in a
consistent format regardless of the method used.

## Usage

``` r
solve_gp(
  y,
  Z,
  gp_method = "rrBLUP",
  nIter = 5000,
  burnIn = 1000,
  bglr_dir = NULL
)
```

## Arguments

- y:

  Numeric vector of training phenotypes.

- Z:

  Numeric marker matrix for the training set.

- gp_method:

  Character, one of `"rrBLUP"` or `"BayesB"`.

- nIter:

  Integer. MCMC iterations for BayesB (default 5000).

- burnIn:

  Integer. Burn-in iterations for BayesB (default 1000).

- bglr_dir:

  Character. Directory for BGLR temporary files. If `NULL`, a temporary
  directory is created and cleaned up automatically.

## Value

A list with components:

- u:

  Numeric vector of marker effects

- beta:

  Numeric scalar intercept
