#' Plot Pairwise Trait Distributions
#'
#' Four-panel visualization: (A) geo-ordered reaction norms, (B) env-mean-ordered
#' with boxplots, (C) JRA regression lines, (D) MSE by environment.
#'
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame with env_code, meanY, lat, lon, PlantingDate
#' @param trait Character; trait name
#' @param env_colors Optional named character vector of colors per env_code
#' @return A patchwork object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' plot_pairwise_dist(exp_trait, env_mean_trait, trait = "FTdap")
plot_pairwise_dist <- function(exp_trait, env_mean_trait, trait = "Trait",
                                env_colors = NULL) {
  # Panel A: Geo-ordered reaction norms
  p_a <- plot_geo_order(exp_trait, env_mean_trait, trait, env_colors)
  p_a <- p_a + ggplot2::labs(subtitle = "A")

  # Panel B: Env-mean-ordered with boxplots
  plot_df <- merge(exp_trait, env_mean_trait[, c("env_code", "meanY")],
                   by = "env_code")
  plot_df$env_code <- factor(plot_df$env_code,
                              levels = env_mean_trait$env_code)

  p_b <- ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$meanY, y = .data$Yobs)) +
    ggplot2::geom_line(ggplot2::aes(group = .data$line_code),
                       alpha = 0.1, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_point(alpha = 0.1, color = "grey50", size = 0.5) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                         color = "grey") +
    ggplot2::geom_boxplot(ggplot2::aes(group = .data$env_code),
                          width = diff(range(env_mean_trait$meanY)) / 20,
                          alpha = 0.4, outlier.shape = NA) +
    ggplot2::labs(x = "Population mean", y = trait, subtitle = "B") +
    ggplot2::theme_minimal(base_size = 10)

  # Panel C: JRA regression lines
  p_c <- ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$meanY, y = .data$Yobs)) +
    ggplot2::geom_point(alpha = 0.1, color = "grey50", size = 0.5) +
    ggplot2::geom_smooth(ggplot2::aes(group = .data$line_code),
                         method = "lm", formula = y ~ x, se = FALSE,
                         alpha = 0.1, color = "grey50", linewidth = 0.3) +
    ggplot2::labs(x = "Population mean", y = trait, subtitle = "C") +
    ggplot2::theme_minimal(base_size = 10)

  # Panel D: MSE by environment
  line_codes <- unique(exp_trait$line_code)
  mse_list <- lapply(line_codes, function(l) {
    ld <- merge(exp_trait[exp_trait$line_code == l, ],
                env_mean_trait[, c("env_code", "meanY")], by = "env_code")
    ld <- ld[!is.na(ld$Yobs), ]
    if (nrow(ld) < 3) return(NULL)
    fit <- lm(Yobs ~ meanY, data = ld)
    data.frame(env_code = ld$env_code, residual_sq = residuals(fit)^2)
  })
  mse_df <- do.call(rbind, mse_list)
  mse_env <- aggregate(residual_sq ~ env_code, mse_df, mean, na.rm = TRUE)
  mse_env <- merge(mse_env, env_mean_trait[, c("env_code", "meanY")])

  p_d <- ggplot2::ggplot(mse_env,
                         ggplot2::aes(x = .data$meanY, y = .data$residual_sq,
                                      color = .data$env_code)) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::geom_text(ggplot2::aes(label = .data$env_code),
                       vjust = -0.8, size = 2.5) +
    ggplot2::labs(x = "Population mean", y = "MSE", subtitle = "D") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(legend.position = "none")
  if (!is.null(env_colors)) {
    p_d <- p_d + ggplot2::scale_color_manual(values = env_colors)
  }

  (p_a + p_b) / (p_c + p_d)
}
