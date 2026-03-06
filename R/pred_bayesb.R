#' Genomic Prediction using BayesB (BGLR)
#'
#' Predicts phenotypic values for a validation set using BayesB from the BGLR
#' package. This is an alternative to \code{\link{pred_rrblup}} that uses
#' Bayesian variable selection via MCMC, allowing marker-specific shrinkage.
#'
#' @param Y_matrix Data.frame with ID_code as first column and trait columns
#'   (e.g., Intcp_para, Slope_para).
#' @param X_matrix Genotype matrix with line codes as rownames.
#' @param prd_idx Integer vector of row indices for the validation set.
#' @param n Iteration number (for tracking via the Rep column).
#' @param nIter Integer. Number of MCMC iterations (default 5000).
#' @param burnIn Integer. Number of burn-in iterations (default 1000).
#' @return Data.frame with observed and predicted values for each trait,
#'   plus an ID_code and Rep column.
#' @export
#' @examples
#' \dontrun{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params,
#'                                         20, 60, params)
#' lm_ab <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
#' SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
#' ab_df <- lm_ab[, c("line_code", "Intcp_para", "Slope_para")]
#' prd_result <- pred_bayesb(ab_df, SNPs, prd_idx = 1:5, n = 1,
#'                           nIter = 1000, burnIn = 200)
#' head(prd_result)
#' }
pred_bayesb <- function(Y_matrix, X_matrix, prd_idx, n,
                        nIter = 5000, burnIn = 1000) {
  if (!requireNamespace("BGLR", quietly = TRUE)) {
    stop("Package 'BGLR' is required for BayesB. ",
         "Install with: install.packages('BGLR')")
  }

  # Column-mean imputation (no rrBLUP dependency)
  if (any(is.na(X_matrix))) {
    for (j in seq_len(ncol(X_matrix))) {
      na_idx <- is.na(X_matrix[, j])
      if (any(na_idx)) {
        X_matrix[na_idx, j] <- mean(X_matrix[, j], na.rm = TRUE)
      }
    }
  }

  names(Y_matrix)[1] <- "ID_code"

  y_trn <- Y_matrix[-prd_idx, ]
  A_trn <- X_matrix[match(y_trn$ID_code, rownames(X_matrix), nomatch = 0), ]
  y_trn <- y_trn[match(y_trn$ID_code, rownames(A_trn), nomatch = 0), ]

  y_prd <- Y_matrix[prd_idx, ]
  A_prd <- X_matrix[match(y_prd$ID_code, rownames(X_matrix), nomatch = 0), ]

  prd_result <- y_prd
  names(prd_result)[-1] <- paste0(names(prd_result)[-1], "_obs")

  # BGLR writes temp files; use a dedicated directory and clean up
  bglr_dir <- tempfile("bglr_pred_")
  dir.create(bglr_dir, recursive = TRUE)
  on.exit(unlink(bglr_dir, recursive = TRUE), add = TRUE)

  for (t_i in 2:ncol(y_trn)) {
    ETA <- list(list(X = A_trn, model = "BayesB"))
    fit <- BGLR::BGLR(
      y       = y_trn[, t_i],
      ETA     = ETA,
      nIter   = nIter,
      burnIn  = burnIn,
      verbose = FALSE,
      saveAt  = file.path(bglr_dir, paste0("pred_", t_i, "_"))
    )
    y_prd_vals <- A_prd %*% fit$ETA[[1]]$b + fit$mu
    df1 <- data.frame(
      ID_code = rownames(A_prd),
      prd     = as.numeric(y_prd_vals),
      stringsAsFactors = FALSE
    )
    names(df1)[2] <- paste0(names(y_trn)[t_i], "_prd")
    prd_result <- merge(prd_result, df1, by = "ID_code", all.x = TRUE)
  }

  prd_result$Rep <- n
  prd_result
}
