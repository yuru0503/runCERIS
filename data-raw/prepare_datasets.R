## Script to prepare all crop datasets for the CERIS package
## Run this from the package root: source("data-raw/prepare_datasets.R")

pag_dir <- normalizePath("../CERIS_PAG", mustWork = TRUE)

#' Read and standardize trait data for a crop
read_traits <- function(crop_dir) {
  f <- file.path(crop_dir, "Traits_record.txt")
  df <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                   na.strings = "NA")
  # Ensure line_code and env_code columns exist
  stopifnot("line_code" %in% names(df), "env_code" %in% names(df))
  df
}

#' Read environment metadata
read_env_meta <- function(crop_dir) {
  f <- file.path(crop_dir, "Env_meta_table.txt")
  df <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                   strip.white = TRUE)
  # Standardize: ensure env_code exists
  stopifnot("env_code" %in% names(df))
  # Trim whitespace from all character columns
  for (col in names(df)) {
    if (is.character(df[[col]])) df[[col]] <- trimws(df[[col]])
  }
  df
}

#' Read environmental parameters (pre-compiled or from dailyEnv/)
read_env_params <- function(crop_dir, crop_name) {
  # Check for dailyEnv directory first (Sorghum)
  daily_dir <- file.path(crop_dir, "dailyEnv")
  if (dir.exists(daily_dir)) {
    files <- list.files(daily_dir, pattern = "_daily\\.txt$", full.names = TRUE)
    dfs <- lapply(files, function(f) {
      read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
    })
    df <- do.call(rbind, dfs)
    # Add DAP column per environment
    df <- do.call(rbind, lapply(split(df, df$env_code), function(env_df) {
      env_df$DAP <- seq_len(nrow(env_df))
      env_df
    }))
    rownames(df) <- NULL
    return(df)
  }

  # Fallback: pre-compiled file
  pattern <- "Envs_envParas"
  files <- list.files(crop_dir, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) stop("No env params file found for ", crop_name)
  df <- read.table(files[1], header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                   na.strings = "NA")
  # Add DAP column if missing
  if (!("DAP" %in% names(df))) {
    params <- setdiff(names(df), c("env_code", "date"))
    df <- do.call(rbind, lapply(split(df, df$env_code), function(env_df) {
      env_df$DAP <- seq_len(nrow(env_df))
      env_df[, c("env_code", "DAP", params)]
    }))
    rownames(df) <- NULL
  }
  # Remove date column if present
  df$date <- NULL
  df
}

#' Read genotype data
read_genotype <- function(crop_dir) {
  f <- file.path(crop_dir, "Genotype.txt")
  if (!file.exists(f)) return(NULL)
  df <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                   check.names = FALSE)
  # Convert to matrix with line_code as rownames
  line_codes <- df[[1]]
  mat <- as.matrix(df[, -1, drop = FALSE])
  rownames(mat) <- line_codes
  storage.mode(mat) <- "integer"
  mat
}

## Process each crop
crops <- c("Sorghum", "Maize", "Rice", "Oat")
crop_info_list <- list()

for (crop in crops) {
  crop_dir <- file.path(pag_dir, crop)
  crop_lower <- tolower(crop)
  cat("Processing", crop, "...\n")

  # Traits
  traits <- read_traits(crop_dir)
  assign(paste0(crop_lower, "_traits"), traits)

  # Env meta
  env_meta <- read_env_meta(crop_dir)
  assign(paste0(crop_lower, "_env_meta"), env_meta)

  # Env params
  env_params <- read_env_params(crop_dir, crop)
  assign(paste0(crop_lower, "_env_params"), env_params)

  # Genotype (may be NULL)
  geno <- read_genotype(crop_dir)
  if (!is.null(geno)) {
    assign(paste0(crop_lower, "_genotype"), geno)
  }

  # Collect info
  trait_cols <- setdiff(names(traits), c("env_code", "pop_code", "line_code", "env_note"))
  param_cols <- setdiff(names(env_params), c("env_code", "DAP", "date"))
  n_envs <- length(unique(traits$env_code))

  crop_info_list[[crop_lower]] <- data.frame(
    crop = crop_lower,
    n_envs = n_envs,
    traits = paste(trait_cols, collapse = ","),
    default_trait = trait_cols[1],
    has_genotype = !is.null(geno),
    env_params = paste(param_cols, collapse = ","),
    stringsAsFactors = FALSE
  )
}

crop_info <- do.call(rbind, crop_info_list)
rownames(crop_info) <- NULL

## Save all datasets
data_dir <- "data"
if (!dir.exists(data_dir)) dir.create(data_dir)

save_data <- function(obj_name, compress = "xz") {
  save(list = obj_name, file = file.path(data_dir, paste0(obj_name, ".rda")),
       compress = compress)
}

for (crop in tolower(crops)) {
  save_data(paste0(crop, "_traits"), compress = "gzip")
  save_data(paste0(crop, "_env_meta"), compress = "gzip")
  save_data(paste0(crop, "_env_params"), compress = "gzip")
  geno_name <- paste0(crop, "_genotype")
  if (exists(geno_name)) save_data(geno_name, compress = "xz")
}

save_data("crop_info", compress = "gzip")

cat("Done! Datasets saved to", data_dir, "\n")
