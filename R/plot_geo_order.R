#' Plot Environments in Geographic Order
#'
#' Plots individual line phenotypes with environments ordered by latitude,
#' longitude, and planting date.
#'
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame with env_code, meanY, lat, lon, PlantingDate
#' @param trait Character; trait name for axis labels
#' @param env_colors Optional named character vector of colors per env_code
#' @return A ggplot object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' plot_geo_order(exp_trait, env_mean_trait, trait = "FTdap")
plot_geo_order <- function(exp_trait, env_mean_trait, trait = "Trait",
                           env_colors = NULL) {
  # Order by geography
  geo_order <- env_mean_trait[order(env_mean_trait$lat,
                                     env_mean_trait$lon,
                                     env_mean_trait$PlantingDate), ]
  geo_order$order <- seq_len(nrow(geo_order))

  plot_df <- merge(exp_trait, geo_order[, c("env_code", "order")],
                   by = "env_code")

  env_means <- geo_order[, c("env_code", "meanY", "order")]

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$order, y = .data$Yobs)) +
    ggplot2::geom_line(ggplot2::aes(group = .data$line_code),
                       alpha = 0.1, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_point(alpha = 0.1, color = "grey50", size = 0.5) +
    ggplot2::geom_line(data = env_means,
                       ggplot2::aes(x = .data$order, y = .data$meanY),
                       linewidth = 0.5, inherit.aes = FALSE) +
    ggplot2::geom_point(data = env_means,
                        ggplot2::aes(x = .data$order, y = .data$meanY,
                                     color = .data$env_code),
                        size = 2.5, inherit.aes = FALSE) +
    ggplot2::scale_x_continuous(breaks = env_means$order,
                                labels = env_means$env_code) +
    ggplot2::labs(x = NULL, y = trait, color = "Environment") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1))

  if (!is.null(env_colors)) {
    p <- p + ggplot2::scale_color_manual(values = env_colors)
  }
  p
}
