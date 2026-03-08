#' Plot Trait Mean vs Environmental Parameter
#'
#' Scatter plot of the best environmental covariate vs phenotype means
#' with regression line and correlation annotation.
#'
#' @param env_mean_trait Data.frame with env_code, meanY, kPara
#' @param trait Character; trait name for y-axis label
#' @param kpara_name Character; parameter name for x-axis label
#' @param dap_start Start day of the window
#' @param dap_end End day of the window
#' @param env_colors Optional named character vector of colors per env_code
#' @return A ggplot object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' plot_trait_env_param(env_mean_trait, trait = "FTdap", kpara_name = "DL",
#'                      dap_start = 20, dap_end = 60)
plot_trait_env_param <- function(env_mean_trait, trait = "Trait",
                                 kpara_name = "kPara",
                                 dap_start = NULL, dap_end = NULL,
                                 env_colors = NULL) {
  r_val <- round(cor(env_mean_trait$meanY, env_mean_trait$kPara,
                     use = "complete.obs"), 3)

  x_lab <- kpara_name
  if (!is.null(dap_start) && !is.null(dap_end)) {
    x_lab <- paste0(kpara_name, " (", dap_start, " to ", dap_end, " DAP)")
  }

  p <- ggplot2::ggplot(env_mean_trait,
                       ggplot2::aes(x = .data$kPara, y = .data$meanY)) +
    ggplot2::geom_point(ggplot2::aes(color = .data$env_code), size = 3) +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
                         linetype = "solid", color = "black", linewidth = 0.5) +
    ggplot2::annotate("text", x = mean(env_mean_trait$kPara),
                      y = min(env_mean_trait$meanY),
                      label = paste0("r = ", r_val), size = 4) +
    ggplot2::labs(x = x_lab, y = paste(trait, "mean"), color = "Environment") +
    ggplot2::theme_minimal(base_size = 12)

  if (!is.null(env_colors)) {
    p <- p + ggplot2::scale_color_manual(values = env_colors)
  }
  p
}
