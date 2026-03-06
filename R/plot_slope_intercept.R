#' Plot Reaction Norm Slopes and Intercepts
#'
#' Two-panel plot: (A) Reaction norm regression lines using the environmental
#' parameter, (B) histogram of R-squared values.
#'
#' @param exp_trait_merged Data.frame with Yobs and kPara columns
#'   (merge of exp_trait and env_mean_trait)
#' @param res_para Data.frame from \code{slope_intercept} with Intcp_para,
#'   Slope_para, R2_para
#' @param trait Character; trait name for axis labels
#' @param kpara_name Character; name of the environmental parameter
#' @return A patchwork object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' si <- slope_intercept(exp_trait, env_mean_trait, type = "kPara")
#' merged <- merge(exp_trait, env_mean_trait[, c("env_code", "kPara")], by = "env_code")
#' plot_slope_intercept(merged, si, trait = "FTdap")
plot_slope_intercept <- function(exp_trait_merged, res_para,
                                 trait = "Trait", kpara_name = "kPara") {
  # Panel A: Regression lines
  p_a <- ggplot2::ggplot(exp_trait_merged,
                         ggplot2::aes(x = .data$kPara, y = .data$Yobs)) +
    ggplot2::geom_point(alpha = 0.1, color = "grey50", size = 0.5) +
    ggplot2::geom_abline(
      data = res_para,
      ggplot2::aes(intercept = as.numeric(.data$Intcp_para),
                   slope = as.numeric(.data$Slope_para)),
      alpha = 0.1, color = "grey50"
    ) +
    ggplot2::labs(x = kpara_name, y = trait, subtitle = "A") +
    ggplot2::theme_minimal(base_size = 12)

  # Panel B: R^2 histogram
  p_b <- ggplot2::ggplot(res_para,
                         ggplot2::aes(x = as.numeric(.data$R2_para))) +
    ggplot2::geom_histogram(bins = 15, fill = "grey70", color = "white") +
    ggplot2::labs(x = expression(paste("Parameter ", R^2)),
                  y = "Count", subtitle = "B") +
    ggplot2::theme_minimal(base_size = 12)

  p_a + p_b
}
