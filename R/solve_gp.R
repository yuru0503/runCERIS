#' Internal: Solve Genomic Prediction for a Single Trait Vector
#'
#' Dispatches to \code{rrBLUP::mixed.solve} or \code{BGLR::BGLR} based on
#' \code{gp_method}. Returns a list with marker effects and intercept in a
#' consistent format regardless of the method used.
#'
#' @param y Numeric vector of training phenotypes.
#' @param Z Numeric marker matrix for the training set.
#' @param gp_method Character, one of \code{"rrBLUP"} or \code{"BayesB"}.
#' @param nIter Integer. MCMC iterations for BayesB (default 5000).
#' @param burnIn Integer. Burn-in iterations for BayesB (default 1000).
#' @param bglr_dir Character. Directory for BGLR temporary files. If
#'   \code{NULL}, a temporary directory is created and cleaned up automatically.
#' @return A list with components:
#'   \item{u}{Numeric vector of marker effects}
#'   \item{beta}{Numeric scalar intercept}
#' @keywords internal
solve_gp <- function(y, Z, gp_method = "rrBLUP",
                     nIter = 5000, burnIn = 1000, bglr_dir = NULL) {
  if (gp_method == "rrBLUP") {
    fit <- rrBLUP::mixed.solve(y, Z = Z)
    return(list(u = fit$u, beta = as.numeric(fit$beta)))
  }

  if (gp_method == "BayesB") {
    if (!requireNamespace("BGLR", quietly = TRUE)) {
      stop("Package 'BGLR' is required for BayesB. ",
           "Install with: install.packages('BGLR')")
    }

    own_dir <- FALSE
    if (is.null(bglr_dir)) {
      bglr_dir <- tempfile("bglr_")
      dir.create(bglr_dir, recursive = TRUE)
      own_dir <- TRUE
    }

    save_prefix <- file.path(bglr_dir,
                             paste0("gp_", sample.int(1e6, 1), "_"))
    ETA <- list(list(X = Z, model = "BayesB"))
    fit <- BGLR::BGLR(
      y       = y,
      ETA     = ETA,
      nIter   = nIter,
      burnIn  = burnIn,
      verbose = FALSE,
      saveAt  = save_prefix
    )

    if (own_dir) unlink(bglr_dir, recursive = TRUE)

    return(list(u = fit$ETA[[1]]$b, beta = fit$mu))
  }

  stop("Unknown gp_method: ", gp_method,
       ". Choose 'rrBLUP' or 'BayesB'.")
}


#' Internal: Impute Missing Marker Values
#'
#' Uses \code{rrBLUP::A.mat} when \code{gp_method = "rrBLUP"}, otherwise
#' falls back to column-mean imputation so that BayesB does not require rrBLUP.
#'
#' @param geno_matrix Numeric genotype matrix.
#' @param gp_method Character, \code{"rrBLUP"} or \code{"BayesB"}.
#' @return Imputed numeric genotype matrix.
#' @keywords internal
impute_markers <- function(geno_matrix, gp_method = "rrBLUP") {
  if (!any(is.na(geno_matrix))) return(geno_matrix)

  if (gp_method == "rrBLUP") {
    geno_imp <- rrBLUP::A.mat(geno_matrix, max.missing = 0.5,
                               impute.method = "mean", return.imputed = TRUE)
    return(matrix(suppressWarnings(as.numeric(geno_imp$imputed)),
                  nrow = nrow(geno_imp$imputed)))
  }

  # Column-mean imputation for BayesB
  result <- geno_matrix
  for (j in seq_len(ncol(result))) {
    na_idx <- is.na(result[, j])
    if (any(na_idx)) {
      result[na_idx, j] <- mean(result[, j], na.rm = TRUE)
    }
  }
  result
}
