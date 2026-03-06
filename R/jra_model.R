#' Joint Regression Analysis
#'
#' Fits a linear regression of individual line phenotypes against the
#' environmental mean for each genotype. Extracts intercept, slope, and R-squared.
#'
#' @param line_by_env Wide data.frame from \code{prepare_line_by_env}
#'   (line_code + environment columns)
#' @param env_mean_trait Data.frame from \code{compute_env_means} with meanY
#' @return Data.frame with columns: line_code, Intcp, Intcp_mean, Slope_mean, R2_mean
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' line_by_env <- prepare_line_by_env(exp_trait, env_mean_trait)
#' jra_result <- jra_model(line_by_env, env_mean_trait)
#' head(jra_result)
jra_model <- function(line_by_env, env_mean_trait) {
  n_lines <- nrow(line_by_env)
  results <- vector("list", n_lines)

  for (i in seq_len(n_lines)) {
    df <- data.frame(
      meanY = env_mean_trait$meanY,
      Yobs = as.numeric(line_by_env[i, -1])
    )
    df <- df[!is.na(df$Yobs), ]

    if (nrow(df) >= 4) {
      fit <- lm(Yobs ~ meanY, data = df)
      a_mean <- round(predict(fit,
                               data.frame(meanY = mean(env_mean_trait$meanY))), 4)
      b_mean <- round(coef(fit)[2], 4)
      r2 <- round(summary(fit)$r.squared, 4)

      results[[i]] <- data.frame(
        line_code = line_by_env$line_code[i],
        Intcp = round(coef(fit)[1], 4),
        Intcp_mean = as.numeric(a_mean),
        Slope_mean = as.numeric(b_mean),
        R2_mean = r2,
        stringsAsFactors = FALSE
      )
    }
  }

  do.call(rbind, results)
}
