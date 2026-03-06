#' Joint Genomic Regression Analysis (Marker Effects)
#'
#' Performs genomic prediction through estimation of environment-specific marker
#' effects and predicting their values in new environments using GBLUP (rrBLUP)
#' or BayesB (BGLR).
#'
#' @param pheno Wide-format phenotype data.frame (line_code + environment columns)
#' @param geno Genotype data.frame or matrix with line_code identifier
#' @param envir Data.frame with env_code and environmental parameter columns
#' @param enp Name or index of the environmental parameter column to use
#' @param env_meta Data.frame with env_code (used for filtering)
#' @param tt_line Minimum non-NA lines per environment
#' @param tt_env Minimum non-NA environments per line
#' @param method One of "RM.E" (env LOO), "RM.G" (genotype CV), "RM.GE" (combined)
#' @param gp_method Genomic prediction method: \code{"rrBLUP"} (default, ridge
#'   regression BLUP) or \code{"BayesB"} (Bayesian variable selection via BGLR).
#' @param nIter Integer. MCMC iterations for BayesB (default 5000). Ignored
#'   when \code{gp_method = "rrBLUP"}.
#' @param burnIn Integer. Burn-in iterations for BayesB (default 1000). Ignored
#'   when \code{gp_method = "rrBLUP"}.
#' @param seed Integer or \code{NULL}. Random seed for reproducible results.
#' @param fold Number of CV folds (default 10)
#' @param reshuffle Number of iterations (default 5)
#' @param progress Optional callback function(fraction)
#' @return A list with:
#'   \item{predictions}{Data.frame with obs, pre, envir columns}
#'   \item{r_within}{Within-environment correlations}
#'   \item{r_across}{Across-environment correlation(s)}
#' @export
#' @examples
#' \dontrun{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' pheno <- prepare_line_by_env(exp_trait, env_mean_trait)
#' SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
#' geno_df <- data.frame(line_code = rownames(SNPs), SNPs, check.names = FALSE)
#' envir <- env_mean_trait[, c("env_code", "kPara")]
#' result <- jgra_marker(pheno, geno_df, envir, "kPara", d$env_meta,
#'                       method = "RM.E", fold = 5, reshuffle = 2)
#' result$r_across
#' }
jgra_marker <- function(pheno, geno, envir, enp, env_meta,
                        tt_line = NULL, tt_env = NULL,
                        method = c("RM.E", "RM.G", "RM.GE"),
                        gp_method = c("rrBLUP", "BayesB"),
                        nIter = 5000, burnIn = 1000, seed = NULL,
                        fold = 10, reshuffle = 5, progress = NULL) {
  method <- match.arg(method)
  gp_method <- match.arg(gp_method)
  if (!is.null(seed)) set.seed(seed)

  envir_names <- setdiff(names(pheno), "line_code")
  envir <- envir[envir$env_code %in% envir_names, ]
  env_meta <- env_meta[env_meta$env_code %in% envir_names, ]

  if (!is.null(tt_line)) {
    na_counts <- colSums(is.na(pheno[, envir_names, drop = FALSE]))
    rm_env <- names(na_counts[na_counts >= tt_line])
    envir <- envir[!(envir$env_code %in% rm_env), ]
    pheno <- pheno[, !(names(pheno) %in% rm_env)]
    envir_names <- setdiff(names(pheno), "line_code")
  }

  if (!is.null(tt_env)) {
    keep <- (ncol(pheno) - 1) - rowSums(is.na(pheno[, -1, drop = FALSE]))
    pheno <- pheno[keep >= tt_env, ]
  }

  n_line <- nrow(pheno)
  n_envir <- length(envir_names)

  # Prepare genotype
  geno_match <- match(pheno$line_code, geno[, 1])
  geno_sub <- geno[geno_match, ]
  Marker <- impute_markers(as.matrix(geno_sub[, -1]), gp_method)
  n_marker <- ncol(Marker)

  # Set up BGLR temp directory if needed
  bglr_dir <- NULL
  if (gp_method == "BayesB") {
    bglr_dir <- tempfile("bglr_jgra_m_")
    dir.create(bglr_dir, recursive = TRUE)
    on.exit(unlink(bglr_dir, recursive = TRUE), add = TRUE)
  }

  if (method == "RM.E") {
    # Estimate marker effects per environment
    effect <- matrix(NA_real_, n_marker, n_envir)
    intercept <- numeric(n_envir)
    for (i in seq_len(n_envir)) {
      fit <- solve_gp(as.numeric(pheno[, envir_names[i]]), Marker,
                      gp_method, nIter, burnIn, bglr_dir)
      effect[, i] <- fit$u
      intercept[i] <- fit$beta
    }

    pheno_hat <- matrix(NA_real_, n_line, n_envir)
    cor_whole <- numeric(n_envir)

    for (k in seq_len(n_envir)) {
      # Predict marker effects for env k from other envs
      effect_hat <- numeric(n_marker)
      for (j in seq_len(n_marker)) {
        fit <- lm(y ~ x, data = data.frame(x = envir[[enp]][-k], y = effect[j, -k]))
        effect_hat[j] <- coef(fit)[1] + coef(fit)[2] * envir[[enp]][k]
      }

      # Predict intercept
      fit_int <- lm(y ~ x, data = data.frame(
        x = as.numeric(envir[[enp]][-k]), y = intercept[-k]))
      y_int <- coef(fit_int)[1] + coef(fit_int)[2] * as.numeric(envir[[enp]][k])

      pheno_hat[, k] <- y_int + as.numeric(Marker %*% effect_hat)
      cor_whole[k] <- cor(pheno_hat[, k], as.numeric(pheno[, envir_names[k]]),
                          use = "complete.obs")
    }

    observe <- as.vector(as.matrix(pheno[, envir_names]))
    predicted <- as.vector(pheno_hat)
    r_within <- data.frame(cor_within = cor_whole, envir = envir_names)
    r_across <- cor(observe, predicted, use = "complete.obs")
    out <- data.frame(obs = observe, pre = predicted,
                      envir = rep(envir_names, each = n_line),
                      stringsAsFactors = FALSE)
  }

  if (method == "RM.G") {
    cor_within <- matrix(NA_real_, reshuffle, n_envir)
    cor_all <- numeric(reshuffle)

    for (i in seq_len(reshuffle)) {
      cross <- sample(rep(seq_len(fold), length.out = n_line))
      yhat_all <- yobs_all <- matrix(NA_real_, 0, n_envir)

      for (f in seq_len(fold)) {
        id_T <- which(cross != f)
        id_V <- which(cross == f)

        # Estimate marker effects from training
        effect <- matrix(NA_real_, n_marker, n_envir)
        intercept <- numeric(n_envir)
        for (k in seq_len(n_envir)) {
          fit <- solve_gp(as.numeric(pheno[id_T, envir_names[k]]),
                          Marker[id_T, ], gp_method, nIter, burnIn, bglr_dir)
          effect[, k] <- fit$u
          intercept[k] <- fit$beta
        }

        # Predict marker effects across envs
        effect_hat <- matrix(NA_real_, n_marker, n_envir)
        for (j in seq_len(n_marker)) {
          fit <- lm(y ~ x, data = data.frame(x = envir[[enp]], y = effect[j, ]))
          effect_hat[j, ] <- coef(fit)[1] + coef(fit)[2] * envir[[enp]]
        }

        fit_int <- lm(y ~ x, data = data.frame(
          x = as.numeric(envir[[enp]]), y = intercept))
        y_int <- coef(fit_int)[1] + coef(fit_int)[2] * as.numeric(envir[[enp]])

        yhat_env <- yobs_env <- matrix(NA_real_, length(id_V), n_envir)
        for (j in seq_len(n_envir)) {
          yhat_env[, j] <- y_int[j] +
            as.numeric(Marker[id_V, ] %*% effect_hat[, j])
          yobs_env[, j] <- as.numeric(pheno[id_V, envir_names[j]])
        }
        yhat_all <- rbind(yhat_all, yhat_env)
        yobs_all <- rbind(yobs_all, yobs_env)
      }

      for (j in seq_len(n_envir)) {
        cor_within[i, j] <- cor(yhat_all[, j], yobs_all[, j], use = "complete.obs")
      }
      cor_all[i] <- cor(as.vector(yhat_all), as.vector(yobs_all), use = "complete.obs")
      if (!is.null(progress)) progress(i / reshuffle)
    }

    colnames(cor_within) <- envir_names
    r_within <- cor_within
    r_across <- cor_all
    out <- data.frame(obs = as.vector(yobs_all), pre = as.vector(yhat_all),
                      envir = rep(envir_names, each = nrow(yhat_all)),
                      stringsAsFactors = FALSE)
  }

  if (method == "RM.GE") {
    cor_within <- matrix(NA_real_, reshuffle, n_envir)
    cor_all <- numeric(reshuffle)

    for (i in seq_len(reshuffle)) {
      cross <- sample(rep(seq_len(fold), length.out = n_line))
      obs_mat <- pre_mat <- matrix(NA_real_, 0, n_envir)

      for (f in seq_len(fold)) {
        id_T <- which(cross != f)
        id_V <- which(cross == f)

        # Estimate marker effects from training
        effect <- matrix(NA_real_, n_marker, n_envir)
        intercept <- numeric(n_envir)
        for (k in seq_len(n_envir)) {
          fit <- solve_gp(as.numeric(pheno[id_T, envir_names[k]]),
                          Marker[id_T, ], gp_method, nIter, burnIn, bglr_dir)
          effect[, k] <- fit$u
          intercept[k] <- fit$beta
        }

        obs_env <- pre_env <- matrix(NA_real_, length(id_V), n_envir)
        for (kk in seq_len(n_envir)) {
          # Predict marker effects for env kk from other envs
          effect_hat <- numeric(n_marker)
          for (j in seq_len(n_marker)) {
            fit <- lm(y ~ x, data = data.frame(
              x = envir[[enp]][-kk], y = effect[j, -kk]))
            effect_hat[j] <- coef(fit)[1] + coef(fit)[2] * envir[[enp]][kk]
          }
          fit_int <- lm(y ~ x, data = data.frame(
            x = as.numeric(envir[[enp]][-kk]), y = intercept[-kk]))
          y_int <- coef(fit_int)[1] + coef(fit_int)[2] * as.numeric(envir[[enp]][kk])

          pre_env[, kk] <- y_int + as.numeric(Marker[id_V, ] %*% effect_hat)
          obs_env[, kk] <- as.numeric(pheno[id_V, envir_names[kk]])
        }
        obs_mat <- rbind(obs_mat, obs_env)
        pre_mat <- rbind(pre_mat, pre_env)
      }

      for (j in seq_len(n_envir)) {
        cor_within[i, j] <- cor(pre_mat[, j], obs_mat[, j], use = "complete.obs")
      }
      cor_all[i] <- cor(as.vector(obs_mat), as.vector(pre_mat), use = "complete.obs")
      if (!is.null(progress)) progress(i / reshuffle)
    }

    colnames(cor_within) <- envir_names
    r_within <- cor_within
    r_across <- cor_all
    out <- data.frame(obs = as.vector(obs_mat), pre = as.vector(pre_mat),
                      envir = rep(envir_names, each = nrow(obs_mat)),
                      stringsAsFactors = FALSE)
  }

  list(predictions = out, r_within = r_within, r_across = r_across)
}
