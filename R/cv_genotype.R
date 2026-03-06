#' K-Fold Genotype Cross-Validation (1-to-3)
#'
#' Performs K-fold cross-validation on genotypes using GBLUP (rrBLUP) or
#' BayesB (BGLR) to predict slope and intercept, then predicts phenotypes
#' across environments.
#'
#' @param gFold Number of CV folds
#' @param gIteration Number of iterations (reshuffles)
#' @param SNPs Genotype matrix (line_code as rownames)
#' @param lm_ab_matrix Data.frame from \code{slope_intercept} with line_code,
#'   Intcp_para, Slope_para
#' @param env_mean_trait Data.frame with env_code, meanY, kPara
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param gp_method Genomic prediction method: \code{"rrBLUP"} (default) or
#'   \code{"BayesB"}.
#' @param nIter Integer. MCMC iterations for BayesB (default 5000).
#' @param burnIn Integer. Burn-in iterations for BayesB (default 1000).
#' @param seed Integer or \code{NULL}. Random seed for reproducible results.
#' @param progress Optional callback function(fraction)
#' @return Data.frame with columns: line_code, env_code, Yprd, Yobs, Rep
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
#' cv_result <- cv_genotype(gFold = 5, gIteration = 2, SNPs = SNPs,
#'                          lm_ab_matrix = lm_ab, env_mean_trait = env_mean_trait,
#'                          exp_trait = exp_trait)
#' head(cv_result)
#' }
cv_genotype <- function(gFold, gIteration, SNPs, lm_ab_matrix,
                        env_mean_trait, exp_trait,
                        gp_method = c("rrBLUP", "BayesB"),
                        nIter = 5000, burnIn = 1000, seed = NULL,
                        progress = NULL) {
  gp_method <- match.arg(gp_method)
  if (!is.null(seed)) set.seed(seed)
  line_codes <- lm_ab_matrix$line_code
  total_s <- length(line_codes)

  block_idx <- floor(seq(1, total_s, length = gFold + 1))
  if (block_idx[length(block_idx)] < total_s) {
    block_idx[length(block_idx)] <- total_s
  }

  # Prepare lm_ab as data.frame for pred_rrblup
  ab_df <- lm_ab_matrix[, c("line_code", "Intcp_para", "Slope_para")]
  ab_df$Intcp_para <- as.numeric(ab_df$Intcp_para)
  ab_df$Slope_para <- as.numeric(ab_df$Slope_para)

  total_steps <- gIteration * gFold
  step <- 0L
  results <- list()

  for (n in seq_len(gIteration)) {
    env_idx <- sample(seq_len(total_s), total_s)

    for (bi in seq_len(length(block_idx) - 1)) {
      step <- step + 1L
      block_s <- block_idx[bi]
      block_e <- if (bi == length(block_idx) - 1) block_idx[bi + 1] else block_idx[bi + 1] - 1
      prd_idx <- sort(env_idx[block_s:block_e])

      if (gp_method == "BayesB") {
        ab_prd <- pred_bayesb(ab_df, SNPs, prd_idx, n, nIter, burnIn)
      } else {
        ab_prd <- pred_rrblup(ab_df, SNPs, prd_idx, n)
      }

      for (e_i in seq_len(nrow(env_mean_trait))) {
        Y_prd <- round(ab_prd$Intcp_para_prd +
                         ab_prd$Slope_para_prd * env_mean_trait$kPara[e_i], 3)
        prd <- data.frame(
          line_code = ab_prd$ID_code,
          env_code = env_mean_trait$env_code[e_i],
          Yprd = Y_prd,
          stringsAsFactors = FALSE
        )
        prd <- merge(prd, exp_trait, by = c("line_code", "env_code"), all.x = TRUE)
        prd$Rep <- n
        results[[length(results) + 1L]] <- prd
      }

      if (!is.null(progress)) progress(step / total_steps)
    }
  }

  result <- do.call(rbind, results)
  result[!is.na(result$Yobs), ]
}
