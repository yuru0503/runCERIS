#' Plot Environmental Factors Over Time
#'
#' Line plots of daily environmental parameters (e.g., day length, cumulative GDD)
#' across environments.
#'
#' @param env_params Data.frame with env_code, DAP, and parameter columns
#' @param params Character vector of parameter names to plot (default: c("DL", "GDD"))
#' @param env_colors Optional named character vector of colors per env_code
#' @return A patchwork object with one panel per parameter
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' plot_env_factors(d$env_params, params = c("DL", "GDD"))
plot_env_factors <- function(env_params, params = c("DL", "GDD"),
                              env_colors = NULL) {
  available <- intersect(params, names(env_params))
  if (length(available) == 0) stop("None of the requested params found in env_params")

  plots <- lapply(available, function(param) {
    p <- ggplot2::ggplot(env_params,
                         ggplot2::aes(x = .data$DAP, y = .data[[param]],
                                      color = .data$env_code)) +
      ggplot2::geom_line(linewidth = 0.6) +
      ggplot2::labs(x = "Days After Planting", y = param, color = "Environment") +
      ggplot2::theme_minimal(base_size = 11)
    if (!is.null(env_colors)) {
      p <- p + ggplot2::scale_color_manual(values = env_colors)
    }
    p
  })

  patchwork::wrap_plots(plots, ncol = 1) +
    patchwork::plot_layout(guides = "collect")
}
