#' Load a crop dataset
#'
#' Convenience function to load all components of a crop dataset.
#'
#' @param crop One of "sorghum", "maize", "rice", "oat"
#' @return A list with components: traits, env_meta, env_params, genotype (NULL if unavailable)
#' @export
#' @examples
#' data_list <- load_crop_data("sorghum")
#' str(data_list$traits)
load_crop_data <- function(crop) {
  crop <- match.arg(tolower(crop), c("sorghum", "maize", "rice", "oat"))

  traits_name <- paste0(crop, "_traits")
  meta_name <- paste0(crop, "_env_meta")
  params_name <- paste0(crop, "_env_params")
  geno_name <- paste0(crop, "_genotype")

  # Load datasets from package data
  env <- new.env(parent = emptyenv())
  utils::data(list = traits_name, package = "runCERIS", envir = env)
  utils::data(list = meta_name, package = "runCERIS", envir = env)
  utils::data(list = params_name, package = "runCERIS", envir = env)

  geno <- tryCatch({
    utils::data(list = geno_name, package = "runCERIS", envir = env)
    env[[geno_name]]
  }, error = function(e) NULL)

  list(
    traits = env[[traits_name]],
    env_meta = env[[meta_name]],
    env_params = env[[params_name]],
    genotype = geno
  )
}

#' Validate input data for CERIS analysis
#'
#' Checks that the required columns and data types are present. Stops with an
#' informative error if a hard requirement is not met, and issues warnings for
#' recommended columns that are missing (e.g., \code{lat}, \code{lon},
#' \code{PlantingDate} in \code{env_meta}).
#'
#' When \code{verbose = TRUE}, prints a summary of the data dimensions, detected
#' trait and parameter columns, and the result of each check.
#'
#' @param traits Data frame with at least \code{line_code}, \code{env_code},
#'   and one numeric trait column. Optional columns: \code{pop_code},
#'   \code{env_note}.
#' @param env_meta Data frame with at least \code{env_code}. Recommended:
#'   \code{lat}, \code{lon}, \code{PlantingDate}, \code{TrialYear},
#'   \code{Location}.
#' @param env_params Data frame with at least \code{env_code}, \code{DAP}
#'   (days after planting), and one or more numeric environmental parameter
#'   columns (e.g., \code{DL}, \code{GDD}, \code{PTT}).
#' @param genotype Optional numeric matrix with \code{line_code} values as
#'   rownames and marker names as column names. Typically coded 0/1/2.
#' @param verbose Logical. If \code{TRUE}, print a summary of the validated
#'   data. Default is \code{FALSE}.
#' @return \code{TRUE} invisibly if all checks pass.
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' validate_input_data(d$traits, d$env_meta, d$env_params, d$genotype)
#'
#' # Print a data summary
#' validate_input_data(d$traits, d$env_meta, d$env_params, d$genotype,
#'                     verbose = TRUE)
validate_input_data <- function(traits, env_meta, env_params, genotype = NULL,
                                verbose = FALSE) {
  # --- Traits ---
  if (!is.data.frame(traits)) stop("traits must be a data frame")
  required_trait_cols <- c("line_code", "env_code")
  missing <- setdiff(required_trait_cols, names(traits))
  if (length(missing) > 0) {
    stop("traits missing required columns: ", paste(missing, collapse = ", "))
  }
  non_trait <- c("line_code", "env_code", "pop_code", "env_note")
  trait_cols <- setdiff(names(traits), non_trait)
  if (length(trait_cols) == 0) {
    stop("traits must have at least one trait column besides: ",
         paste(non_trait, collapse = ", "))
  }
  non_numeric_traits <- trait_cols[!vapply(traits[trait_cols], is.numeric,
                                           logical(1))]
  if (length(non_numeric_traits) > 0) {
    stop("trait columns must be numeric; non-numeric: ",
         paste(non_numeric_traits, collapse = ", "))
  }
  n_lines <- length(unique(traits$line_code))
  trait_envs <- unique(traits$env_code)

  # --- Env meta ---
  if (!is.data.frame(env_meta)) stop("env_meta must be a data frame")
  if (!("env_code" %in% names(env_meta))) {
    stop("env_meta missing required column: env_code")
  }
  recommended_meta <- c("lat", "lon", "PlantingDate")
  missing_meta <- setdiff(recommended_meta, names(env_meta))
  if (length(missing_meta) > 0) {
    warning("env_meta is missing recommended columns (needed by some plot ",
            "functions): ", paste(missing_meta, collapse = ", "),
            call. = FALSE)
  }

  # --- Env params ---
  if (!is.data.frame(env_params)) stop("env_params must be a data frame")
  required_param_cols <- c("env_code", "DAP")
  missing <- setdiff(required_param_cols, names(env_params))
  if (length(missing) > 0) {
    stop("env_params missing required columns: ", paste(missing, collapse = ", "))
  }
  param_cols <- setdiff(names(env_params), c("env_code", "DAP"))
  numeric_params <- param_cols[vapply(env_params[param_cols], is.numeric,
                                      logical(1))]
  if (length(numeric_params) == 0) {
    stop("env_params must have at least one numeric parameter column ",
         "besides env_code and DAP")
  }

  # --- env_code consistency ---
  meta_envs <- unique(env_meta$env_code)
  param_envs <- unique(env_params$env_code)
  missing_in_meta <- setdiff(trait_envs, meta_envs)
  missing_in_params <- setdiff(trait_envs, param_envs)
  if (length(missing_in_meta) > 0) {
    warning("env_codes in traits not found in env_meta: ",
            paste(missing_in_meta, collapse = ", "), call. = FALSE)
  }
  if (length(missing_in_params) > 0) {
    warning("env_codes in traits not found in env_params: ",
            paste(missing_in_params, collapse = ", "), call. = FALSE)
  }

  # --- Genotype ---
  if (!is.null(genotype)) {
    if (!is.matrix(genotype)) stop("genotype must be a matrix")
    if (is.null(rownames(genotype))) {
      stop("genotype must have rownames matching line_code values in traits")
    }
    geno_lines <- rownames(genotype)
    overlap <- intersect(geno_lines, unique(traits$line_code))
    if (length(overlap) == 0) {
      warning("no genotype rownames match line_code values in traits",
              call. = FALSE)
    }
  }

  # --- Verbose summary ---
  if (verbose) {
    dap_range <- range(env_params$DAP, na.rm = TRUE)
    cat("-- CERIS Data Summary --\n")
    cat(sprintf("traits:     %d obs x %d cols | %d trait(s): %s | %d lines, %d envs\n",
                nrow(traits), ncol(traits), length(trait_cols),
                paste(trait_cols, collapse = ", "),
                n_lines, length(trait_envs)))
    cat(sprintf("env_meta:   %d envs x %d cols | Columns: %s\n",
                nrow(env_meta), ncol(env_meta),
                paste(names(env_meta), collapse = ", ")))
    cat(sprintf("env_params: %d obs x %d cols | %d param(s): %s | DAP range: %d-%d\n",
                nrow(env_params), ncol(env_params), length(numeric_params),
                paste(numeric_params, collapse = ", "),
                dap_range[1], dap_range[2]))
    if (!is.null(genotype)) {
      cat(sprintf("genotype:   %d lines x %d markers | %d lines overlap with traits\n",
                  nrow(genotype), ncol(genotype), length(overlap)))
    } else {
      cat("genotype:   not provided\n")
    }
    cat("All checks passed.\n")
  }

  invisible(TRUE)
}
