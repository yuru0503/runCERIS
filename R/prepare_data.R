#' Prepare trait data for analysis
#'
#' Extracts a single trait column, renames it to Yobs, and averages across
#' replicates within environments.
#'
#' @param traits Raw data.frame with line_code, env_code, and trait columns
#' @param trait Character name of the trait column to analyze
#' @return Data.frame with columns: line_code, env_code, Yobs
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' head(exp_trait)
prepare_trait_data <- function(traits, trait) {
  if (!(trait %in% names(traits))) {
    stop("Trait '", trait, "' not found in data. Available: ",
         paste(setdiff(names(traits),
                       c("line_code", "env_code", "pop_code", "env_note")),
               collapse = ", "))
  }

  exp_trait <- traits[, c("line_code", "env_code", trait)]
  names(exp_trait)[3] <- "Yobs"

  # Average across replicates
  exp_trait <- aggregate(Yobs ~ line_code + env_code, exp_trait, mean, na.rm = TRUE)
  exp_trait <- exp_trait[!is.na(exp_trait$Yobs), ]
  exp_trait
}

#' Compute environmental means
#'
#' Calculates mean phenotype per environment, merges with metadata, and orders
#' by the environmental mean.
#'
#' @param exp_trait Data.frame from \code{prepare_trait_data}
#' @param env_meta Data.frame with env_code and metadata columns
#' @return Data.frame with env_code, meanY, plus env_meta columns, ordered by meanY
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' head(env_mean_trait)
compute_env_means <- function(exp_trait, env_meta) {
  env_mean_trait <- aggregate(Yobs ~ env_code, exp_trait, mean, na.rm = TRUE)
  names(env_mean_trait)[2] <- "meanY"
  env_mean_trait <- merge(env_mean_trait, env_meta, by = "env_code")
  env_mean_trait <- env_mean_trait[order(env_mean_trait$meanY), ]
  rownames(env_mean_trait) <- NULL
  env_mean_trait
}

#' Prepare line-by-environment matrix
#'
#' Creates a wide-format data.frame with line_code as first column and
#' environments as subsequent columns, ordered by environmental mean.
#'
#' @param exp_trait Data.frame from \code{prepare_trait_data}
#' @param env_mean_trait Data.frame from \code{compute_env_means}
#' @return Wide data.frame with line_code + environment columns
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' line_by_env <- prepare_line_by_env(exp_trait, env_mean_trait)
#' head(line_by_env[, 1:4])
prepare_line_by_env <- function(exp_trait, env_mean_trait) {
  line_codes <- unique(exp_trait$line_code)
  env_codes <- env_mean_trait$env_code

  line_by_env <- data.frame(line_code = line_codes, stringsAsFactors = FALSE)
  for (e in env_codes) {
    e_trait <- exp_trait[exp_trait$env_code == e, c("line_code", "Yobs")]
    names(e_trait)[2] <- e
    line_by_env <- merge(line_by_env, e_trait, by = "line_code", all.x = TRUE)
  }
  line_by_env
}

#' Compute environmental covariate values for a window
#'
#' For each environment, calculates the mean of each environmental parameter
#' over a specified DAP window.
#'
#' @param env_mean_trait Data.frame with env_code column
#' @param env_params Data.frame with env_code, DAP, and parameter columns
#' @param dap_start Start day of window
#' @param dap_end End day of window
#' @param params Character vector of parameter column names
#' @return Data.frame env_mean_trait with added kPara column (first param) and
#'   a \code{window_params} attribute containing all parameter averages
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' env_mean_trait <- compute_window_params(env_mean_trait, d$env_params, 20, 60, params)
#' head(env_mean_trait[, c("env_code", "meanY", "kPara")])
compute_window_params <- function(env_mean_trait, env_params, dap_start, dap_end, params) {
  param_vals <- matrix(nrow = nrow(env_mean_trait), ncol = length(params))
  colnames(param_vals) <- params

  for (i in seq_len(nrow(env_mean_trait))) {
    e <- env_mean_trait$env_code[i]
    e_params <- env_params[env_params$env_code == e, ]
    rows <- e_params$DAP >= dap_start & e_params$DAP <= dap_end
    param_vals[i, ] <- colMeans(e_params[rows, params, drop = FALSE], na.rm = TRUE)
  }

  result <- env_mean_trait
  result$kPara <- param_vals[, 1]
  attr(result, "window_params") <- as.data.frame(param_vals)
  result
}

#' Prepare genotype matrix for genomic prediction
#'
#' Ensures genotype matrix is properly oriented (lines as rows) and filters
#' to lines present in the trait data.
#'
#' @param genotype Matrix with line_code as rownames or first column
#' @param line_codes Character vector of line codes from trait data
#' @return Numeric matrix with matching line_codes as rownames
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' SNPs <- prepare_genotype(d$genotype, unique(exp_trait$line_code))
#' dim(SNPs)
prepare_genotype <- function(genotype, line_codes) {
  if (is.data.frame(genotype)) {
    rn <- genotype[[1]]
    genotype <- as.matrix(genotype[, -1])
    rownames(genotype) <- rn
  }

  # Check orientation: if line_codes match column names, transpose
  if (!any(line_codes %in% rownames(genotype)) &&
      any(line_codes %in% colnames(genotype))) {
    genotype <- t(genotype)
  }

  # Filter to matching lines
  common <- intersect(line_codes, rownames(genotype))
  if (length(common) == 0) stop("No matching line_codes between genotype and trait data")

  genotype[common, , drop = FALSE]
}
