#' Leave-One-Environment-Out Cross-Validation (1-to-2)
#'
#' For each environment, drops it from training, recalculates reaction norm
#' parameters, and predicts phenotypes for the dropped environment.
#'
#' @param env_mean_trait Data.frame from \code{compute_env_means} with kPara
#' @param exp_trait Data.frame from \code{prepare_trait_data}
#' @return Data.frame with columns: line_code, env_code, Yprd, Yobs, Rep
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' cv_result <- cv_env(env_mean_trait, exp_trait)
#' head(cv_result)
#' }
cv_env <- function(env_mean_trait, exp_trait) {
  results <- vector("list", nrow(env_mean_trait))

  for (e_i in seq_len(nrow(env_mean_trait))) {
    # Drop one environment
    loo_env_mean <- env_mean_trait[-e_i, ]
    loo_trait <- exp_trait[exp_trait$env_code != env_mean_trait$env_code[e_i], ]

    # Recalculate slopes/intercepts
    lm_ab <- slope_intercept(loo_trait, loo_env_mean, type = "kPara")
    lm_ab$Intcp_para <- as.numeric(lm_ab$Intcp_para)
    lm_ab$Slope_para <- as.numeric(lm_ab$Slope_para)

    # Predict
    Y_prd <- round(lm_ab$Intcp_para +
                     lm_ab$Slope_para * env_mean_trait$kPara[e_i], 3)
    prd <- data.frame(
      line_code = lm_ab$line_code,
      env_code = env_mean_trait$env_code[e_i],
      Yprd = Y_prd,
      stringsAsFactors = FALSE
    )
    prd <- merge(prd, exp_trait, by = c("line_code", "env_code"))
    prd$Rep <- 1L
    results[[e_i]] <- prd
  }

  result <- do.call(rbind, results)
  result[!is.na(result$Yobs), ]
}
