#' Leave-One-Out Cross-Validated Correlation
#'
#' Computes leave-one-environment-out (LOO) correlations between a trait vector
#' and one or more environmental parameter vectors. For each environment left
#' out, the Pearson correlation and \eqn{-\log_{10}(p)} are computed from the
#' remaining environments. The per-fold values are then summarised across folds
#' using a user-chosen function (default: \code{median}).
#'
#' This function is used internally by \code{\link{run_CERIS}} when
#' \code{loo = TRUE}, but can also be called directly to evaluate a specific
#' trait--parameter combination without running the full exhaustive search.
#'
#' @param trait Numeric vector of trait means (one value per environment).
#' @param params_matrix Numeric matrix of environmental parameter values with
#'   rows corresponding to environments and columns to parameters.
#' @param summary_fn Function used to summarise LOO correlations across
#'   environments. Default is \code{median} (robust to outlier environments,
#'   as in the original CERIS implementation). Use \code{mean} to compare.
#' @return A list with components:
#'   \item{r}{Summarised correlation for each parameter (length = \code{ncol(params_matrix)}).}
#'   \item{p}{Summarised \eqn{-\log_{10}(p)} for each parameter.}
#'   \item{r_matrix}{Matrix of per-fold correlations (environments x parameters).}
#'   \item{p_matrix}{Matrix of per-fold \eqn{-\log_{10}(p)} values.}
#' @export
#' @examples
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT")
#'
#' # Compute parameter means for a specific window (DAP 20-60)
#' param_mat <- matrix(nrow = nrow(env_mean_trait), ncol = length(params))
#' for (i in seq_len(nrow(env_mean_trait))) {
#'   e <- env_mean_trait$env_code[i]
#'   e_data <- d$env_params[d$env_params$env_code == e, ]
#'   rows <- e_data$DAP >= 20 & e_data$DAP <= 60
#'   param_mat[i, ] <- colMeans(e_data[rows, params, drop = FALSE], na.rm = TRUE)
#' }
#'
#' loo <- ceris_loo_cor(env_mean_trait$meanY, param_mat)
#' loo$r
#' loo$p
#'
#' # Use mean instead of median
#' loo_mean <- ceris_loo_cor(env_mean_trait$meanY, param_mat, summary_fn = mean)
#' loo_mean$r
#' }
ceris_loo_cor <- function(trait, params_matrix, summary_fn = median) {
  if (!is.matrix(params_matrix)) {
    params_matrix <- as.matrix(params_matrix)
  }
  n_env <- length(trait)
  n_params <- ncol(params_matrix)

  loo_rs <- matrix(nrow = n_env, ncol = n_params)
  loo_ps <- matrix(nrow = n_env, ncol = n_params)

  for (k in seq_len(n_params)) {
    for (e_x in seq_len(n_env)) {
      c_test <- cor.test(trait[-e_x], params_matrix[-e_x, k],
                         use = "complete.obs")
      loo_rs[e_x, k] <- c_test$estimate
      loo_ps[e_x, k] <- -log10(c_test$p.value)
    }
  }

  list(
    r = round(apply(loo_rs, 2, summary_fn), digits = 4),
    p = round(apply(loo_ps, 2, summary_fn), digits = 4),
    r_matrix = loo_rs,
    p_matrix = loo_ps
  )
}
