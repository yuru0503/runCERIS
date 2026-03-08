#' CERIS Exhaustive Search for Critical Environmental Windows
#'
#' Searches all possible date windows for correlations between environmental
#' parameters and trait means across environments.
#'
#' @param env_mean_trait Data.frame with env_code and meanY columns
#' @param env_params Data.frame with env_code, DAP, and parameter columns
#' @param params Character vector of environmental parameter column names
#' @param max_days Maximum number of days after planting to search (default: max DAP)
#' @param loo Logical; if TRUE, perform leave-one-environment-out cross-validation
#'   (default FALSE)
#' @param loo_summary Function used to summarize LOO correlations across
#'   environments. Default is \code{median} (robust to outlier environments,
#'   as in the original CERIS implementation). Use \code{mean} to compare.
#' @param progress Optional callback function receiving a fraction (0--1) for
#'   progress reporting. Called every 100 windows.
#' @return Data.frame with columns: Day_x, Day_y, window, midXY, R_<param>,
#'   P_<param> for each parameter
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' result <- run_CERIS(env_mean_trait, d$env_params, params, max_days = 80)
#' head(result)
#' }
run_CERIS <- function(env_mean_trait, env_params, params,
                         max_days = NULL, loo = FALSE,
                         loo_summary = median, progress = NULL) {
  if (is.null(max_days)) max_days <- max(env_params$DAP)
  dap_y <- max_days
  n_params <- length(params)

  # Calculate total number of windows (minimum window size of 7 days)
  dap_win <- sum(seq(length(1:(dap_y - 6)), 1, -1))

  # Pre-allocate results
  col_names <- c("Day_x", "Day_y", "window", "midXY",
                 paste0("R_", params), paste0("P_", params))
  results <- matrix(nrow = dap_win, ncol = length(col_names))

  n <- 0L

  for (d1 in 1:(dap_y - 6)) {
    for (d2 in (d1 + 6):dap_y) {
      n <- n + 1L

      # Compile average covariate values for this window
      env_facts <- matrix(nrow = nrow(env_mean_trait), ncol = n_params)
      for (e_i in seq_len(nrow(env_mean_trait))) {
        e <- env_mean_trait$env_code[e_i]
        e_data <- env_params[env_params$env_code == e, ]
        rows <- e_data$DAP >= d1 & e_data$DAP <= d2
        env_facts[e_i, ] <- colMeans(e_data[rows, params, drop = FALSE],
                                     na.rm = TRUE)
      }
      Ymean_envPara <- cbind(env_facts, env_mean_trait$meanY)

      rs <- ps <- numeric(n_params)

      if (!loo) {
        for (k in seq_len(n_params)) {
          c_test <- cor.test(Ymean_envPara[, n_params + 1], Ymean_envPara[, k],
                             use = "complete.obs")
          rs[k] <- round(c_test$estimate, digits = 4)
          ps[k] <- round(-log10(c_test$p.value), digits = 4)
        }
      } else {
        loo_result <- ceris_loo_cor(
          Ymean_envPara[, n_params + 1],
          Ymean_envPara[, seq_len(n_params), drop = FALSE],
          summary_fn = loo_summary
        )
        rs <- loo_result$r
        ps <- loo_result$p
      }

      results[n, ] <- c(d1, d2, d2 - d1, (d2 + d1) / 2, rs, ps)

      # Progress reporting
      if (!is.null(progress) && n %% 100 == 0) {
        progress(n / dap_win)
      }
    }
  }

  results <- results[seq_len(n), , drop = FALSE]
  results <- as.data.frame(results)
  names(results) <- col_names
  results
}
