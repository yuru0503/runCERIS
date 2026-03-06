#' Forecast Phenotypes for New Environments
#'
#' Predicts phenotypes for a set of environments using models trained on
#' a different set of environments (e.g., year-to-year prediction).
#'
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame with env_code, meanY, kPara
#' @param trn_env Character vector of training environment codes
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
#' trn_env <- env_mean_trait$env_code[1:5]
#' fc_result <- forecast_next_year(exp_trait, env_mean_trait, trn_env)
#' head(fc_result)
#' }
forecast_next_year <- function(exp_trait, env_mean_trait, trn_env) {
  line_codes <- unique(exp_trait$line_code)
  results <- list()
  n <- 0L

  for (l in line_codes) {
    l_trait <- exp_trait[exp_trait$line_code == l, ]
    ril_data <- merge(env_mean_trait, l_trait, by = "env_code", all.x = TRUE)
    trn <- ril_data[ril_data$env_code %in% trn_env, ]
    prd <- ril_data[!(ril_data$env_code %in% trn_env), ]

    if (sum(!is.na(trn$Yobs)) >= 4 && sum(!is.na(prd$Yobs)) >= 1) {
      prd_mean <- round(predict(lm(Yobs ~ meanY, data = trn), prd), 3)
      prd_kpara <- round(predict(lm(Yobs ~ kPara, data = trn), prd), 3)

      for (r in seq_len(nrow(prd))) {
        n <- n + 1L
        results[[n]] <- data.frame(
          env_code = prd$env_code[r],
          line_code = l,
          Prd_trait_mean = as.numeric(prd_mean[r]),
          Prd_trait_kPara = as.numeric(prd_kpara[r]),
          Obs_trait = prd$Yobs[r],
          Line_mean = mean(trn$Yobs, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  do.call(rbind, results)
}
