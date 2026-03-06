#' Joint Genomic Regression Analysis (Reaction Norm Parameters)
#'
#' Performs genomic prediction through estimation and prediction of reaction
#' norm parameters (intercept and slope) using GBLUP (rrBLUP) or BayesB (BGLR).
#'
#' @param pheno Wide-format phenotype data.frame (line_code + environment columns)
#' @param geno Genotype data.frame or matrix with line_code identifier
#' @param envir Data.frame with env_code and environmental parameter columns
#' @param enp Name or index of the environmental parameter column to use
#' @param env_meta Data.frame with env_code (used for filtering)
#' @param tt_line Minimum non-NA lines per environment; environments with fewer are dropped
#' @param tt_env Minimum non-NA environments per line; lines with fewer are dropped
#' @param method One of "RM.E" (env LOO), "RM.G" (genotype CV), "RM.GE" (combined)
#' @param gp_method Genomic prediction method: \code{"rrBLUP"} (default, ridge
#'   regression BLUP) or \code{"BayesB"} (Bayesian variable selection via BGLR).
#'   Only used for methods \code{"RM.G"} and \code{"RM.GE"}.
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
#' \donttest{
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' pheno <- prepare_line_by_env(exp_trait, env_mean_trait)
#' SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
#' geno_df <- data.frame(line_code = rownames(SNPs), SNPs, check.names = FALSE)
#' envir <- env_mean_trait[, c("env_code", "kPara")]
#' result <- jgra(pheno, geno_df, envir, "kPara", d$env_meta,
#'                method = "RM.E", fold = 5, reshuffle = 2)
#' result$r_across
#' }
jgra <- function(pheno, geno, envir, enp, env_meta,
                 tt_line = NULL, tt_env = NULL,
                 method = c("RM.E", "RM.G", "RM.GE"),
                 gp_method = c("rrBLUP", "BayesB"),
                 nIter = 5000, burnIn = 1000, seed = NULL,
                 fold = 10, reshuffle = 5, progress = NULL) {
  method <- match.arg(method)
  gp_method <- match.arg(gp_method)
  if (!is.null(seed)) set.seed(seed)

  # Ensure pheno is properly formatted (line_code + env columns)
  envir_names <- setdiff(names(pheno), "line_code")
  envir <- envir[envir$env_code %in% envir_names, ]
  env_meta <- env_meta[env_meta$env_code %in% envir_names, ]

  # Order to match
  envir <- envir[match(envir$env_code, env_meta$env_code), ]

  # Filter environments with too many NAs
  if (!is.null(tt_line)) {
    na_counts <- colSums(is.na(pheno[, envir_names, drop = FALSE]))
    rm_env <- names(na_counts[na_counts >= tt_line])
    envir <- envir[!(envir$env_code %in% rm_env), ]
    pheno <- pheno[, !(names(pheno) %in% rm_env)]
    envir_names <- setdiff(names(pheno), "line_code")
  }

  # Filter lines with too few environments
  if (!is.null(tt_env)) {
    keep <- (ncol(pheno) - 1) - rowSums(is.na(pheno[, -1, drop = FALSE]))
    pheno <- pheno[keep >= tt_env, ]
  }

  n_line <- nrow(pheno)
  n_envir <- length(envir_names)
  env_colors <- grDevices::heat.colors(n_envir)

  # Environment LOO method
  if (method == "RM.E") {
    pheno_hat <- matrix(NA_real_, n_line, n_envir)
    cor_whole <- numeric(n_envir)

    for (k in seq_len(n_envir)) {
      for (j in seq_len(n_line)) {
        x1 <- envir[[enp]][-k]
        y1 <- as.numeric(pheno[j, envir_names[-k]])
        fit <- lm(y ~ x, data = data.frame(x = x1, y = y1))
        pheno_hat[j, k] <- coef(fit)[1] + coef(fit)[2] * envir[[enp]][k]
      }
      cor_whole[k] <- cor(pheno_hat[, k], pheno[, envir_names[k]],
                          use = "complete.obs")
    }

    observe <- as.vector(as.matrix(pheno[, envir_names]))
    predicted <- as.vector(pheno_hat)
    r_within <- data.frame(cor_within = cor_whole, envir = envir_names)
    r_across <- cor(observe, predicted, use = "complete.obs")
    out <- data.frame(
      obs = observe, pre = predicted,
      envir = rep(envir_names, each = n_line),
      stringsAsFactors = FALSE
    )
  }

  # Genotype CV method
  if (method == "RM.G") {
    # Compute slopes and intercepts
    intercepts <- slopes <- numeric(n_line)
    for (j in seq_len(n_line)) {
      fit <- lm(y ~ x, data = data.frame(
        x = envir[[enp]], y = as.numeric(pheno[j, envir_names])))
      intercepts[j] <- coef(fit)[1]
      slopes[j] <- coef(fit)[2]
    }

    # Prepare genotype matrix
    geno_match <- match(pheno$line_code, geno[, 1])
    geno_sub <- geno[geno_match, ]
    Marker <- impute_markers(as.matrix(geno_sub[, -1]), gp_method)

    # Set up BGLR temp directory if needed
    bglr_dir <- NULL
    if (gp_method == "BayesB") {
      bglr_dir <- tempfile("bglr_jgra_")
      dir.create(bglr_dir, recursive = TRUE)
      on.exit(unlink(bglr_dir, recursive = TRUE), add = TRUE)
    }

    cor_within <- matrix(NA_real_, reshuffle, n_envir)
    cor_all <- numeric(reshuffle)

    for (i in seq_len(reshuffle)) {
      cross <- sample(rep(seq_len(fold), length.out = n_line))
      yhat_all <- yobs_all <- matrix(NA_real_, 0, n_envir)

      for (f in seq_len(fold)) {
        id_T <- which(cross != f)
        id_V <- which(cross == f)

        # Predict intercepts
        ans_i <- solve_gp(intercepts[id_T], Marker[id_T, ], gp_method,
                          nIter, burnIn, bglr_dir)
        GEBV_inter <- as.numeric(Marker[id_V, ] %*% ans_i$u) + ans_i$beta

        # Predict slopes
        ans_s <- solve_gp(slopes[id_T], Marker[id_T, ], gp_method,
                          nIter, burnIn, bglr_dir)
        GEBV_slope <- as.numeric(Marker[id_V, ] %*% ans_s$u) + ans_s$beta

        yhat_env <- yobs_env <- matrix(NA_real_, length(id_V), n_envir)
        for (j in seq_len(n_envir)) {
          yhat_env[, j] <- GEBV_inter + GEBV_slope * envir[[enp]][j]
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
    out <- data.frame(
      obs = as.vector(yobs_all), pre = as.vector(yhat_all),
      envir = rep(envir_names, each = nrow(yhat_all)),
      stringsAsFactors = FALSE
    )
  }

  # Combined env LOO + genotype CV method
  if (method == "RM.GE") {
    geno_match <- match(pheno$line_code, geno[, 1])
    geno_sub <- geno[geno_match, ]
    Marker <- impute_markers(as.matrix(geno_sub[, -1]), gp_method)

    # Set up BGLR temp directory if needed
    bglr_dir <- NULL
    if (gp_method == "BayesB") {
      bglr_dir <- tempfile("bglr_jgra_ge_")
      dir.create(bglr_dir, recursive = TRUE)
      on.exit(unlink(bglr_dir, recursive = TRUE), add = TRUE)
    }

    cor_within <- matrix(NA_real_, reshuffle, n_envir)
    cor_all <- numeric(reshuffle)

    for (i in seq_len(reshuffle)) {
      obs_mat <- pre_mat <- matrix(NA_real_, n_line, n_envir)

      for (k in seq_len(n_envir)) {
        # LOO: compute slopes/intercepts without env k
        intercepts <- slopes <- numeric(n_line)
        for (j in seq_len(n_line)) {
          fit <- lm(y ~ x, data = data.frame(
            x = envir[[enp]][-k], y = as.numeric(pheno[j, envir_names[-k]])))
          intercepts[j] <- coef(fit)[1]
          slopes[j] <- coef(fit)[2]
        }

        cross <- sample(rep(seq_len(fold), length.out = n_line))
        yhat_whole <- yobs_whole <- numeric(0)

        for (f in seq_len(fold)) {
          id_T <- which(cross != f)
          id_V <- which(cross == f)

          ans_i <- solve_gp(intercepts[id_T], Marker[id_T, ], gp_method,
                            nIter, burnIn, bglr_dir)
          GEBV_inter <- as.numeric(Marker[id_V, ] %*% ans_i$u) + ans_i$beta

          ans_s <- solve_gp(slopes[id_T], Marker[id_T, ], gp_method,
                            nIter, burnIn, bglr_dir)
          GEBV_slope <- as.numeric(Marker[id_V, ] %*% ans_s$u) + ans_s$beta

          yhat <- GEBV_inter + GEBV_slope * envir[[enp]][k]
          yobs <- as.numeric(pheno[id_V, envir_names[k]])
          yhat_whole <- c(yhat_whole, yhat)
          yobs_whole <- c(yobs_whole, yobs)
        }

        cor_within[i, k] <- cor(yhat_whole, yobs_whole, use = "complete.obs")
        obs_mat[, k] <- yobs_whole
        pre_mat[, k] <- yhat_whole
      }

      cor_all[i] <- cor(as.vector(obs_mat), as.vector(pre_mat), use = "complete.obs")
      if (!is.null(progress)) progress(i / reshuffle)
    }

    colnames(cor_within) <- envir_names
    r_within <- cor_within
    r_across <- cor_all
    out <- data.frame(
      obs = as.vector(obs_mat), pre = as.vector(pre_mat),
      envir = rep(envir_names, each = n_line),
      stringsAsFactors = FALSE
    )
  }

  list(predictions = out, r_within = r_within, r_across = r_across)
}
