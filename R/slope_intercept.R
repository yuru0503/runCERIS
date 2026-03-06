#' Calculate Reaction Norm Slopes and Intercepts
#'
#' Fits linear regressions of individual line phenotypes against an
#' environmental covariate (kPara) and/or the environmental mean.
#'
#' @param exp_trait Data.frame from \code{prepare_trait_data} with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame from \code{compute_env_means} with meanY and kPara columns
#' @param type Character; one of "kPara" (default), "mean", or "both"
#' @return Data.frame with line_code and slope/intercept columns depending on type:
#'   \itemize{
#'     \item "kPara": Intcp_para_adj, Intcp_para, Slope_para, R2_para
#'     \item "mean": Intcp_mean, Slope_mean
#'     \item "both": all columns above
#'   }
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' si <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
#' head(si)
slope_intercept <- function(exp_trait, env_mean_trait, type = "kPara") {
  type <- match.arg(type, c("kPara", "mean", "both"))
  line_codes <- unique(exp_trait$line_code)

  # Merge trait with env means
  merge_cols <- c("env_code", "meanY")
  if ("kPara" %in% names(env_mean_trait) && type %in% c("kPara", "both")) {
    merge_cols <- c(merge_cols, "kPara")
  }
  merged <- merge(exp_trait, env_mean_trait[, merge_cols, drop = FALSE],
                  by = "env_code")

  results <- vector("list", length(line_codes))

  for (l in seq_along(line_codes)) {
    l_trait <- merged[merged$line_code == line_codes[l], ]
    if (nrow(l_trait) < 3) next

    row <- list(line_code = line_codes[l])

    if (type %in% c("mean", "both")) {
      fit_mean <- lm(Yobs ~ meanY, data = l_trait)
      row$Intcp_mean <- round(
        as.numeric(predict(fit_mean,
                           data.frame(meanY = mean(env_mean_trait$meanY)))), 4)
      row$Slope_mean <- round(as.numeric(coef(fit_mean)[2]), 4)
    }

    if (type %in% c("kPara", "both") && "kPara" %in% names(l_trait)) {
      fit_para <- lm(Yobs ~ kPara, data = l_trait)
      row$Intcp_para_adj <- round(
        as.numeric(predict(fit_para,
                           data.frame(kPara = mean(env_mean_trait$kPara)))), 4)
      row$Intcp_para <- round(as.numeric(coef(fit_para)[1]), 4)
      row$Slope_para <- round(as.numeric(coef(fit_para)[2]), 4)
      row$R2_para <- round(summary(fit_para)$r.squared, 4)
    }

    results[[l]] <- as.data.frame(row, stringsAsFactors = FALSE)
  }

  do.call(rbind, results)
}
