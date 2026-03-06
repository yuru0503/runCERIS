#' Sorghum phenotypic trait records
#'
#' Phenotypic data from 7 sorghum multi-environment trials.
#'
#' @format Data frame with columns: env_code, pop_code, line_code, FTdap, FTgdd, env_note
#' @source Li & Guo CERIS_PAG repository
"sorghum_traits"

#' Sorghum environment metadata
#'
#' Location and planting information for sorghum trial environments.
#'
#' @format Data frame with columns: env_notes, env_code, lat, lon, PlantingDate, TrialYear, Location
"sorghum_env_meta"

#' Sorghum daily environmental parameters
#'
#' Daily environmental covariates for sorghum trial environments.
#'
#' @format Data frame with columns: env_code, DAP, DL, GDD, PTT, PTR, PTS
"sorghum_env_params"

#' Sorghum SNP genotype matrix
#'
#' SNP marker data for sorghum lines.
#'
#' @format Integer matrix with line_code as rownames and marker names as colnames
"sorghum_genotype"

#' Maize phenotypic trait records
#'
#' Phenotypic data from 10 maize multi-environment trials.
#'
#' @format Data frame with columns: line_code, env_code, FT, PH
"maize_traits"

#' Maize environment metadata
#'
#' @format Data frame with columns: env_code, lat, lon, PlantingDate, TrialYear, env_note
"maize_env_meta"

#' Maize daily environmental parameters
#'
#' @format Data frame with columns: env_code, DAP, TMAX, TMIN, DL, GDD, PTT, PTR, PTS
"maize_env_params"

#' Maize SNP genotype matrix
#'
#' @format Integer matrix with line_code as rownames
"maize_genotype"

#' Rice phenotypic trait records
#'
#' Phenotypic data from 9 rice multi-environment trials.
#'
#' @format Data frame with columns: line_code, env_code, FTdap, FTgdd
"rice_traits"

#' Rice environment metadata
#'
#' @format Data frame with columns: env_code, lat, lon, PlantingDate, TrialYear, Location, env_note
"rice_env_meta"

#' Rice daily environmental parameters
#'
#' @format Data frame with columns: env_code, DAP, TMAX, TMIN, DL, GDD, PTT, PTR, PTS
"rice_env_params"

#' Rice SNP genotype matrix
#'
#' @format Integer matrix with line_code as rownames
"rice_genotype"

#' Oat phenotypic trait records
#'
#' Phenotypic data from 13 oat multi-environment trials.
#'
#' @format Data frame with columns: line_code, env_code, FTdap, PH, GY
"oat_traits"

#' Oat environment metadata
#'
#' @format Data frame with columns: env_code, lat, lon, PlantingDate, TrialYear, Location, env_note
"oat_env_meta"

#' Oat daily environmental parameters
#'
#' @format Data frame with columns: env_code, DAP, TMAX, TMIN, DL, GDD, PTT, PTR, PTD1, PTD2, PTS
"oat_env_params"

#' Crop information summary
#'
#' Metadata about available crop datasets.
#'
#' @format Data frame with columns: crop, n_envs, traits, default_trait, has_genotype, env_params
"crop_info"
