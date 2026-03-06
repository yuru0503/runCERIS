#' Plot JRA Results
#'
#' Two-panel plot: (A) JRA regression lines overlaid on data, (B) histogram
#' of R-squared values.
#'
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame with meanY
#' @param jra_result Data.frame from \code{jra_model} with Intcp, Slope_mean, R2_mean
#' @param trait Character; trait name for axis labels
#' @return A patchwork object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' line_by_env <- prepare_line_by_env(exp_trait, env_mean_trait)
#' jra_result <- jra_model(line_by_env, env_mean_trait)
#' plot_jra(exp_trait, env_mean_trait, jra_result, trait = "FTdap")
plot_jra <- function(exp_trait, env_mean_trait, jra_result, trait = "Trait") {
  plot_df <- merge(exp_trait, env_mean_trait[, c("env_code", "meanY")],
                   by = "env_code")

  # Panel A: Regression lines
  p_a <- ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$meanY, y = .data$Yobs)) +
    ggplot2::geom_point(alpha = 0.1, color = "grey50", size = 0.5) +
    ggplot2::geom_abline(
      data = jra_result,
      ggplot2::aes(intercept = as.numeric(.data$Intcp),
                   slope = as.numeric(.data$Slope_mean)),
      alpha = 0.1, color = "grey50"
    ) +
    ggplot2::labs(x = "Environmental mean", y = trait, subtitle = "A") +
    ggplot2::theme_minimal(base_size = 12)

  # Panel B: R^2 histogram
  p_b <- ggplot2::ggplot(jra_result,
                         ggplot2::aes(x = as.numeric(.data$R2_mean))) +
    ggplot2::geom_histogram(bins = 15, fill = "grey70", color = "white") +
    ggplot2::labs(x = expression(paste("JRA ", R^2)),
                  y = "Count", subtitle = "B") +
    ggplot2::theme_minimal(base_size = 12)

  p_a + p_b
}
