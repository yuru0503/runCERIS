#' Genomic Prediction using rrBLUP
#'
#' Predicts phenotypic values for a validation set using ridge regression BLUP.
#'
#' @param Y_matrix Data.frame with ID_code as first column and trait columns
#' @param X_matrix Genotype matrix with line codes as rownames
#' @param prd_idx Integer vector of row indices for the validation set
#' @param n Iteration number (for tracking)
#' @return Data.frame with observed and predicted values for each trait
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' lm_ab <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
#' SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
#' ab_df <- lm_ab[, c("line_code", "Intcp_para", "Slope_para")]
#' prd_result <- pred_rrblup(ab_df, SNPs, prd_idx = 1:5, n = 1)
#' head(prd_result)
#' }
pred_rrblup <- function(Y_matrix, X_matrix, prd_idx, n) {
  if (any(is.na(X_matrix))) {
    A_imp <- rrBLUP::A.mat(X_matrix, return.imputed = TRUE)
    X_matrix <- A_imp$imputed
  }

  names(Y_matrix)[1] <- "ID_code"

  y_trn <- Y_matrix[-prd_idx, ]
  A_trn <- X_matrix[match(y_trn$ID_code, rownames(X_matrix), nomatch = 0), ]
  y_trn <- y_trn[match(y_trn$ID_code, rownames(A_trn), nomatch = 0), ]

  y_prd <- Y_matrix[prd_idx, ]
  A_prd <- X_matrix[match(y_prd$ID_code, rownames(X_matrix), nomatch = 0), ]

  prd_result <- y_prd
  names(prd_result)[-1] <- paste0(names(prd_result)[-1], "_obs")

  for (t_i in 2:ncol(y_trn)) {
    M1k <- rrBLUP::mixed.solve(y_trn[, t_i], Z = A_trn)
    U <- as.matrix(M1k$u)
    y_prd_vals <- A_prd %*% U + as.numeric(M1k$beta)
    df1 <- data.frame(ID_code = rownames(A_prd),
                       prd = as.numeric(y_prd_vals),
                       stringsAsFactors = FALSE)
    names(df1)[2] <- paste0(names(y_trn)[t_i], "_prd")
    prd_result <- merge(prd_result, df1, by = "ID_code", all.x = TRUE)
  }

  prd_result$Rep <- n
  prd_result
}
