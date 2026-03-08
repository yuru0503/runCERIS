#' Plot CERIS Correlation Heatmap
#'
#' Creates a multi-panel visualization of CERIS search results showing
#' correlation heatmaps for each environmental parameter, plus trace plots
#' of p-values and correlations.
#'
#' @param ceris_result Data.frame from \code{run_CERIS}
#' @param params Character vector of parameter names
#' @param max_days Maximum DAP searched
#' @return A patchwork object with heatmap + trace plots
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' result <- run_CERIS(env_mean_trait, d$env_params, params, max_days = 80)
#' plot_ceris_heatmap(result, params, max_days = 80)
#' }
plot_ceris_heatmap <- function(ceris_result, params, max_days) {
  r_cols <- paste0("R_", params)
  p_cols <- paste0("P_", params)

  # --- Heatmap panel ---
  # Reshape to long format for ggplot
  heatmap_data <- do.call(rbind, lapply(seq_along(params), function(k) {
    data.frame(
      Day_x = ceris_result$Day_x,
      Day_y = ceris_result$Day_y,
      R = ceris_result[[r_cols[k]]],
      parameter = params[k],
      stringsAsFactors = FALSE
    )
  }))
  heatmap_data$parameter <- factor(heatmap_data$parameter, levels = params)

  # Find best window per parameter
  best_windows <- do.call(rbind, lapply(seq_along(params), function(k) {
    sub <- ceris_result[ceris_result$window >= 7, ]
    idx <- which.max(abs(sub[[r_cols[k]]]))
    data.frame(
      Day_x = sub$Day_x[idx], Day_y = sub$Day_y[idx],
      R = sub[[r_cols[k]]][idx],
      parameter = params[k],
      label = paste0(sub$Day_x[idx], "-", sub$Day_y[idx],
                     " DAP\nr = ", sprintf("%.3f", sub[[r_cols[k]]][idx])),
      stringsAsFactors = FALSE
    )
  }))
  best_windows$parameter <- factor(best_windows$parameter, levels = params)

  p_heat <- ggplot2::ggplot(heatmap_data,
                            ggplot2::aes(x = .data$Day_x, y = .data$Day_y,
                                         fill = .data$R)) +
    ggplot2::geom_tile(width = 1, height = 1) +
    ggplot2::scale_fill_gradient2(
      low = "#3B4CC0", mid = "white", high = "#B40426",
      midpoint = 0, limits = c(-1, 1), name = "r"
    ) +
    ggplot2::geom_segment(
      data = best_windows,
      ggplot2::aes(x = .data$Day_x + 10, y = .data$Day_y - 10,
                   xend = .data$Day_x + 1, yend = .data$Day_y - 1),
      arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm")),
      inherit.aes = FALSE, color = "black"
    ) +
    ggplot2::geom_text(
      data = best_windows,
      ggplot2::aes(x = .data$Day_x + 15, y = .data$Day_y - 15,
                   label = .data$label),
      inherit.aes = FALSE, size = 2.5, hjust = 0
    ) +
    ggplot2::facet_wrap(~ parameter, nrow = 1) +
    ggplot2::labs(x = "DAP (start)", y = "DAP (end)") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold")
    )

  # --- Trace plots ---
  # Aggregate: for each parameter and midpoint, find the window with max |P|
  trace_data <- do.call(rbind, lapply(seq_along(params), function(k) {
    sub <- ceris_result[, c("midXY", r_cols[k], p_cols[k])]
    names(sub) <- c("midXY", "R", "P")
    agg <- stats::aggregate(cbind(R, P) ~ midXY, data = sub,
                            FUN = function(x) x[which.max(abs(x))])
    agg$parameter <- params[k]
    agg
  }))
  trace_data$parameter <- factor(trace_data$parameter, levels = params)

  p_logp <- ggplot2::ggplot(trace_data,
                            ggplot2::aes(x = .data$midXY, y = .data$P)) +
    ggplot2::geom_line(color = "cornflowerblue") +
    ggplot2::facet_wrap(~ parameter, nrow = 1, scales = "free_y") +
    ggplot2::labs(x = NULL, y = expression(-log[10](P))) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())

  p_r <- ggplot2::ggplot(trace_data,
                         ggplot2::aes(x = .data$midXY, y = .data$R)) +
    ggplot2::geom_line(color = "cornflowerblue") +
    ggplot2::geom_hline(yintercept = 0, color = "black", linewidth = 0.3) +
    ggplot2::facet_wrap(~ parameter, nrow = 1) +
    ggplot2::labs(x = "Window midpoint (DAP)", y = expression(italic(r))) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())

  # Combine
  p_heat / p_logp / p_r + patchwork::plot_layout(heights = c(3, 1, 1))
}
