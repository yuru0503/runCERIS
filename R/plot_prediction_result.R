#' Plot LOOCV/Forecast Prediction Results
#'
#' Four-panel visualization: (A) predicted by envMean vs observed,
#' (B) predicted by kPara vs observed, (C) kPara vs population mean,
#' (D) predicted by BLUE vs observed.
#'
#' @param obs_prd Data.frame from \code{loocv} or \code{forecast_next_year}
#'   with columns Prd_trait_mean, Prd_trait_kPara, Obs_trait, Line_mean, env_code
#' @param env_mean_trait Data.frame with env_code, meanY, kPara
#' @param trait Character; trait name for labels
#' @param kpara_name Character; parameter name
#' @param env_colors Optional named character vector of colors per env_code
#' @return A patchwork object
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' loo_result <- loocv(exp_trait, env_mean_trait)
#' plot_prediction_result(loo_result, env_mean_trait, trait = "FTdap")
#' }
plot_prediction_result <- function(obs_prd, env_mean_trait,
                                    trait = "Trait", kpara_name = "kPara",
                                    env_colors = NULL) {
  obs_prd <- obs_prd[!is.na(obs_prd$Obs_trait), ]
  xy_lim <- range(c(obs_prd$Prd_trait_mean, obs_prd$Prd_trait_kPara,
                     obs_prd$Obs_trait, obs_prd$Line_mean), na.rm = TRUE)

  make_scatter <- function(x_col, y_col, xlab, ylab, subtitle) {
    df <- obs_prd
    df$.x <- df[[x_col]]
    df$.y <- df[[y_col]]
    r_val <- sprintf("%.2f", cor(df$.x, df$.y, use = "complete.obs"))

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$.x, y = .data$.y,
                                           color = .data$env_code)) +
      ggplot2::geom_point(size = 0.8, alpha = 0.6) +
      ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "solid",
                           color = "grey50") +
      ggplot2::coord_cartesian(xlim = xy_lim, ylim = xy_lim) +
      ggplot2::annotate("text", x = mean(xy_lim), y = xy_lim[2],
                        label = paste0("r = ", r_val), vjust = 1, size = 3.5) +
      ggplot2::labs(x = xlab, y = ylab, subtitle = subtitle) +
      ggplot2::theme_minimal(base_size = 10) +
      ggplot2::theme(legend.position = "none")
    if (!is.null(env_colors)) p <- p + ggplot2::scale_color_manual(values = env_colors)
    p
  }

  p_a <- make_scatter("Obs_trait", "Prd_trait_mean",
                       paste("Observed", trait),
                       paste("Predicted", trait, "by envMean"), "A")
  p_b <- make_scatter("Obs_trait", "Prd_trait_kPara",
                       paste("Observed", trait),
                       paste("Predicted", trait, "by", kpara_name), "B")

  # Panel C: kPara vs population mean
  r_c <- sprintf("%.2f", cor(env_mean_trait$meanY, env_mean_trait$kPara,
                             use = "complete.obs"))
  p_c <- ggplot2::ggplot(env_mean_trait,
                         ggplot2::aes(x = .data$kPara, y = .data$meanY,
                                      color = .data$env_code)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
                         color = "black", linewidth = 0.5) +
    ggplot2::geom_text(ggplot2::aes(label = .data$env_code),
                       vjust = -0.8, size = 2.5) +
    ggplot2::annotate("text", x = mean(env_mean_trait$kPara),
                      y = max(env_mean_trait$meanY),
                      label = paste0("r = ", r_c), vjust = 1, size = 3.5) +
    ggplot2::labs(x = kpara_name, y = "Observed population mean", subtitle = "C") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(legend.position = "none")
  if (!is.null(env_colors)) p_c <- p_c + ggplot2::scale_color_manual(values = env_colors)

  p_d <- make_scatter("Obs_trait", "Line_mean",
                       paste("Observed", trait),
                       paste("Predicted", trait, "by BLUE"), "D")

  (p_a + p_b) / (p_c + p_d)
}
