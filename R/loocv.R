#' Line-Level Leave-One-Out Cross-Validation
#'
#' For each line, leaves out one environment at a time and predicts the
#' phenotype using both environmental mean and environmental parameter regressions.
#'
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame with env_code, meanY, kPara
#' @return Data.frame with columns: env_code, line_code, Prd_trait_mean,
#'   Prd_trait_kPara, Obs_trait, Line_mean
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' loo_result <- loocv(exp_trait, env_mean_trait)
#' head(loo_result)
#' }
loocv <- function(exp_trait, env_mean_trait) {
  line_codes <- unique(exp_trait$line_code)
  results <- list()
  n <- 0L

  for (l in line_codes) {
    l_trait <- exp_trait[exp_trait$line_code == l, ]
    ril_data <- merge(env_mean_trait, l_trait, by = "env_code", all.x = TRUE)

    if (sum(!is.na(ril_data$Yobs)) > 4) {
      for (e in seq_len(nrow(ril_data))) {
        obs_trait <- ril_data$Yobs[e]
        if (!is.na(obs_trait)) {
          trn <- ril_data[-e, ]
          l_mean <- mean(trn$Yobs, na.rm = TRUE)
          prd_mean <- round(predict(lm(Yobs ~ meanY, data = trn),
                                    ril_data[e, ]), 3)
          prd_kpara <- round(predict(lm(Yobs ~ kPara, data = trn),
                                     ril_data[e, ]), 3)
          n <- n + 1L
          results[[n]] <- data.frame(
            env_code = ril_data$env_code[e],
            line_code = l,
            Prd_trait_mean = as.numeric(prd_mean),
            Prd_trait_kPara = as.numeric(prd_kpara),
            Obs_trait = obs_trait,
            Line_mean = l_mean,
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }

  do.call(rbind, results)
}
