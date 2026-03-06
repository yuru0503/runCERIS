#' Identify the Best Environmental Window from CERIS Results
#'
#' Finds the window and parameter with the maximum absolute correlation
#' from a CERIS search result.
#'
#' @param ceris_result Data.frame from \code{ceris_search}
#' @param params Character vector of parameter names
#' @param min_window Minimum window size in days (default 7)
#' @return A list with components:
#'   \item{param_name}{Name of the best environmental parameter}
#'   \item{dap_start}{Start day of the best window}
#'   \item{dap_end}{End day of the best window}
#'   \item{correlation}{Correlation value at the best window}
#'   \item{neg_log_p}{-log10(p-value) at the best window}
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' result <- ceris_search(env_mean_trait, d$env_params, params, max_days = 80)
#' best <- ceris_identify_best(result, params)
#' best$param_name
#' best$dap_start
#' best$dap_end
#' }
ceris_identify_best <- function(ceris_result, params, min_window = 7) {
  r_cols <- paste0("R_", params)
  p_cols <- paste0("P_", params)

  # Filter to minimum window size
  filtered <- ceris_result[ceris_result$window >= min_window, ]

  # Find max |R| across all parameters
  r_mat <- as.matrix(filtered[, r_cols, drop = FALSE])
  abs_r <- abs(r_mat)
  max_idx <- arrayInd(which.max(abs_r), .dim = dim(abs_r))

  best_row <- max_idx[1, 1]
  best_col <- max_idx[1, 2]

  list(
    param_name = params[best_col],
    dap_start = filtered$Day_x[best_row],
    dap_end = filtered$Day_y[best_row],
    correlation = r_mat[best_row, best_col],
    neg_log_p = filtered[best_row, p_cols[best_col]]
  )
}
