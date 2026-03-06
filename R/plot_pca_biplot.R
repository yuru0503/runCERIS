#' PCA Biplot of Environmental Parameters
#'
#' Performs PCA on environmental parameters aggregated per environment and
#' creates a biplot with optional ellipses.
#'
#' @param env_params Data.frame with env_code, DAP, and parameter columns
#' @param env_mean_trait Data.frame with env_code (for labeling)
#' @param params Character vector of parameter names to include
#' @param group_col Optional column name in env_mean_trait for grouping ellipses
#' @return A ggplot object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' plot_pca_biplot(d$env_params, env_mean_trait, params)
plot_pca_biplot <- function(env_params, env_mean_trait, params,
                             group_col = NULL) {
  # Aggregate parameters per environment
  env_agg <- aggregate(env_params[, params], by = list(env_code = env_params$env_code),
                       FUN = mean, na.rm = TRUE)

  # PCA
  pca_data <- env_agg[, params]
  pca_result <- prcomp(pca_data, scale. = TRUE)
  scores <- as.data.frame(pca_result$x[, 1:2])
  scores$env_code <- env_agg$env_code

  var_explained <- round(100 * summary(pca_result)$importance[2, 1:2], 1)

  # Add grouping if provided
  if (!is.null(group_col) && group_col %in% names(env_mean_trait)) {
    scores <- merge(scores, env_mean_trait[, c("env_code", group_col)],
                    by = "env_code")
  }

  p <- ggplot2::ggplot(scores, ggplot2::aes(x = .data$PC1, y = .data$PC2)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_text(ggplot2::aes(label = .data$env_code),
                       vjust = -0.8, size = 3) +
    ggplot2::labs(
      x = paste0("PC1 (", var_explained[1], "%)"),
      y = paste0("PC2 (", var_explained[2], "%)")
    ) +
    ggplot2::theme_minimal(base_size = 12)

  # Add ellipses if grouping exists
  if (!is.null(group_col) && group_col %in% names(scores)) {
    p <- p + ggplot2::stat_ellipse(
      ggplot2::aes(color = .data[[group_col]]),
      type = "norm", level = 0.68
    )
  }

  # Add loadings as arrows
  loadings <- as.data.frame(pca_result$rotation[, 1:2])
  loadings$variable <- rownames(loadings)
  scale_factor <- max(abs(scores$PC1)) / max(abs(loadings$PC1)) * 0.8

  p + ggplot2::geom_segment(
    data = loadings,
    ggplot2::aes(x = 0, y = 0,
                 xend = .data$PC1 * scale_factor,
                 yend = .data$PC2 * scale_factor),
    arrow = ggplot2::arrow(length = ggplot2::unit(0.2, "cm")),
    color = "red", inherit.aes = FALSE
  ) +
    ggplot2::geom_text(
      data = loadings,
      ggplot2::aes(x = .data$PC1 * scale_factor * 1.1,
                   y = .data$PC2 * scale_factor * 1.1,
                   label = .data$variable),
      color = "red", size = 3, inherit.aes = FALSE
    )
}
