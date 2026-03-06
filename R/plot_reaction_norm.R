#' Plot Reaction Norms
#'
#' Four-panel reaction norm visualization: (A) raw data by arbitrary env order,
#' (B) by env mean order, (C) continuous env mean axis, (D) fitted regression lines.
#'
#' @param exp_trait Data.frame with line_code, env_code, Yobs
#' @param env_mean_trait Data.frame with env_code, meanY
#' @param trait Character; trait name
#' @return A patchwork object
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' plot_reaction_norm(exp_trait, env_mean_trait, trait = "FTdap")
plot_reaction_norm <- function(exp_trait, env_mean_trait, trait = "Trait") {
  plot_df <- merge(exp_trait, env_mean_trait[, c("env_code", "meanY")],
                   by = "env_code")
  # Env order by mean
  env_order <- env_mean_trait[order(env_mean_trait$meanY), ]
  env_order$rank <- seq_len(nrow(env_order))
  plot_df <- merge(plot_df, env_order[, c("env_code", "rank")], by = "env_code")

  # Arbitrary order
  arb_order <- data.frame(env_code = unique(exp_trait$env_code),
                           arb_rank = seq_along(unique(exp_trait$env_code)),
                           stringsAsFactors = FALSE)
  plot_df <- merge(plot_df, arb_order, by = "env_code")

  # Panel A: Arbitrary order
  p_a <- ggplot2::ggplot(plot_df,
                         ggplot2::aes(x = .data$arb_rank, y = .data$Yobs,
                                      group = .data$line_code)) +
    ggplot2::geom_line(alpha = 0.15, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_point(alpha = 0.15, color = "grey50", size = 0.5) +
    ggplot2::scale_x_continuous(breaks = arb_order$arb_rank,
                                labels = arb_order$env_code) +
    ggplot2::labs(x = "Environment", y = trait, subtitle = "A") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1))

  # Panel B: Sorted by env mean
  p_b <- ggplot2::ggplot(plot_df,
                         ggplot2::aes(x = .data$rank, y = .data$Yobs,
                                      group = .data$line_code)) +
    ggplot2::geom_line(alpha = 0.15, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_point(alpha = 0.15, color = "grey50", size = 0.5) +
    ggplot2::scale_x_continuous(breaks = env_order$rank,
                                labels = env_order$env_code) +
    ggplot2::labs(x = "Environment (sorted by mean)", y = trait, subtitle = "B") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1))

  # Panel C: Continuous env mean axis
  p_c <- ggplot2::ggplot(plot_df,
                         ggplot2::aes(x = .data$meanY, y = .data$Yobs,
                                      group = .data$line_code)) +
    ggplot2::geom_line(alpha = 0.15, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_point(alpha = 0.15, color = "grey50", size = 0.5) +
    ggplot2::labs(x = "Environmental mean", y = trait, subtitle = "C") +
    ggplot2::theme_minimal(base_size = 10)

  # Panel D: Fitted regression lines
  p_d <- ggplot2::ggplot(plot_df,
                         ggplot2::aes(x = .data$meanY, y = .data$Yobs,
                                      group = .data$line_code)) +
    ggplot2::geom_point(alpha = 0.1, color = "grey50", size = 0.3) +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
                         alpha = 0.15, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                         color = "black") +
    ggplot2::labs(x = "Environmental mean", y = trait, subtitle = "D") +
    ggplot2::theme_minimal(base_size = 10)

  (p_a + p_b) / (p_c + p_d)
}
