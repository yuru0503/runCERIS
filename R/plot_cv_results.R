#' Plot Cross-Validation Results
#'
#' Multi-panel predicted vs observed scatter plots for different CV scenarios.
#'
#' @param cv_results List of data.frames, each with Yprd, Yobs, env_code, Rep columns.
#'   Typically: list(cv_env_result, cv_genotype_result, cv_combined_result)
#' @param labels Character vector of labels for each CV scenario
#'   (default: "1-to-2", "1-to-3", "1-to-4")
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
#' cv_e <- cv_env(env_mean_trait, exp_trait)
#' plot_cv_results(list(cv_e), labels = c("1-to-2 (Env)"))
#' }
plot_cv_results <- function(cv_results,
                            labels = paste0("1-to-", seq_along(cv_results) + 1),
                            env_colors = NULL) {
  plots <- lapply(seq_along(cv_results), function(i) {
    df <- cv_results[[i]]
    # Use only first replicate if multiple
    if (max(df$Rep, na.rm = TRUE) > 1) df <- df[df$Rep == 1, ]

    r_val <- round(cor(df$Yprd, df$Yobs, use = "complete.obs"), 2)
    xy_lim <- range(c(df$Yprd, df$Yobs), na.rm = TRUE)

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$Yprd, y = .data$Yobs,
                                           color = .data$env_code)) +
      ggplot2::geom_point(size = 1, alpha = 0.6) +
      ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
      ggplot2::coord_cartesian(xlim = xy_lim, ylim = xy_lim) +
      ggplot2::annotate("text",
                        x = xy_lim[1] + diff(xy_lim) * 0.5,
                        y = xy_lim[1] + diff(xy_lim) * 0.05,
                        label = paste0("r = ", r_val), size = 4) +
      ggplot2::labs(x = "Predicted", y = "Observed",
                    subtitle = paste(labels[i], "prediction"),
                    color = "Environment") +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = if (i == length(cv_results)) "right" else "none")

    if (!is.null(env_colors)) {
      p <- p + ggplot2::scale_color_manual(values = env_colors)
    }
    p
  })

  patchwork::wrap_plots(plots, nrow = 1)
}
