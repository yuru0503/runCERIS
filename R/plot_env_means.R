#' Plot Phenotypes vs Environmental Means
#'
#' Scatter plot showing individual line phenotypes against environmental means,
#' with connecting lines for each genotype and a 1:1 reference line.
#'
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame with env_code and meanY
#' @param trait Character; trait name for axis labels
#' @return A ggplot object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' plot_env_means(exp_trait, env_mean_trait, trait = "FTdap")
plot_env_means <- function(exp_trait, env_mean_trait, trait = "Trait") {
  plot_df <- merge(exp_trait, env_mean_trait[, c("env_code", "meanY")],
                   by = "env_code")

  ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$meanY, y = .data$Yobs)) +
    ggplot2::geom_line(ggplot2::aes(group = .data$line_code),
                       alpha = 0.1, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_point(alpha = 0.1, color = "grey50", size = 0.5) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "solid",
                         color = "grey") +
    ggplot2::geom_point(
      data = env_mean_trait,
      ggplot2::aes(x = .data$meanY, y = .data$meanY),
      color = "black", size = 2, inherit.aes = FALSE
    ) +
    ggplot2::labs(x = "Environmental mean", y = trait) +
    ggplot2::theme_minimal(base_size = 12)
}
