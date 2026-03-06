#' Fetch Environmental Data from NASA POWER and Compute CERIS Parameters
#'
#' Downloads daily weather data (temperature, precipitation) from the NASA
#' POWER API for each environment in \code{env_meta}, then computes all
#' derived CERIS environmental parameters: day length (DL), growing degree
#' days (GDD), photothermal time (PTT), photothermal ratio (PTR),
#' photothermal day variants (PTD1, PTD2), and photothermal sum (PTS).
#'
#' The returned data frame has the same structure as \code{env_params} and
#' can be used directly in \code{\link{ceris_search}}.
#'
#' @param env_meta Data frame with at least \code{env_code}, \code{lat},
#'   \code{lon}, and \code{PlantingDate} columns. \code{PlantingDate} should
#'   be in a format parseable by \code{as.Date} (e.g., "2014-05-15").
#' @param max_dap Integer. Maximum number of days after planting to fetch.
#'   Default is 150.
#' @param base_temp Numeric. Base temperature (Celsius) for GDD calculation.
#'   Default is 10.
#' @param progress Logical. If \code{TRUE}, print progress messages for each
#'   environment. Default is \code{TRUE}.
#'
#' @return A data frame with columns: \code{env_code}, \code{DAP},
#'   \code{TMAX}, \code{TMIN}, \code{DL}, \code{GDD}, \code{PTT},
#'   \code{PTR}, \code{PTD1}, \code{PTD2}, \code{PTS}.
#'
#' @details
#' The function calls the NASA POWER daily API
#' (\url{https://power.larc.nasa.gov}) to retrieve \code{T2M_MAX} (daily
#' maximum temperature) and \code{T2M_MIN} (daily minimum temperature) for
#' the agroclimatology community. Day length is computed astronomically from
#' latitude and day of year using the CBM model. No API key is required.
#'
#' Derived parameters follow the definitions in Tibbs-Cortes et al. (2024):
#' \describe{
#'   \item{DL}{Astronomical day length in hours}
#'   \item{GDD}{max(0, (TMAX + TMIN) / 2 - base_temp)}
#'   \item{PTT}{GDD * DL}
#'   \item{PTR}{GDD / DL}
#'   \item{PTD1}{(TMAX - TMIN) * DL}
#'   \item{PTD2}{(TMAX - TMIN) / DL}
#'   \item{PTS}{(TMAX^2 - TMIN^2) * DL^2}
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' d <- load_crop_data("sorghum")
#' env_params <- fetch_nasa_power(d$env_meta, max_dap = 80)
#' head(env_params)
#'
#' # Use in CERIS search
#' exp_trait <- prepare_trait_data(d$traits, "FTdap")
#' env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
#' ceris_result <- ceris_search(
#'   env_mean_trait, env_params,
#'   params = c("DL", "GDD", "PTT", "PTR", "PTS"),
#'   max_days = 80
#' )
#' }
fetch_nasa_power <- function(env_meta, max_dap = 150, base_temp = 10,
                             progress = TRUE) {
  required <- c("env_code", "lat", "lon", "PlantingDate")
  missing <- setdiff(required, names(env_meta))
  if (length(missing) > 0) {
    stop("env_meta missing required columns: ",
         paste(missing, collapse = ", "))
  }

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Install it with: ",
         "install.packages('jsonlite')")
  }

  env_meta$PlantingDate <- as.Date(env_meta$PlantingDate)

  results <- vector("list", nrow(env_meta))

  for (i in seq_len(nrow(env_meta))) {
    env <- env_meta$env_code[i]
    lat <- env_meta$lat[i]
    lon <- env_meta$lon[i]
    plant_date <- env_meta$PlantingDate[i]
    end_date <- plant_date + max_dap - 1

    if (progress) {
      message(sprintf("[%d/%d] Fetching NASA POWER data for %s (%.2f, %.2f)...",
                      i, nrow(env_meta), env, lat, lon))
    }

    raw <- .fetch_power_point(lat, lon, plant_date, end_date)

    if (is.null(raw) || nrow(raw) == 0) {
      warning("No data returned for environment: ", env, call. = FALSE)
      next
    }

    doy <- as.integer(format(raw$date, "%j"))
    dl <- .compute_day_length(lat, doy)

    tmax <- raw$T2M_MAX
    tmin <- raw$T2M_MIN
    gdd <- pmax(0, (tmax + tmin) / 2 - base_temp)
    dtr <- tmax - tmin

    results[[i]] <- data.frame(
      env_code = env,
      DAP      = seq_len(nrow(raw)),
      TMAX     = tmax,
      TMIN     = tmin,
      DL       = round(dl, 4),
      GDD      = round(gdd, 4),
      PTT      = round(gdd * dl, 4),
      PTR      = round(ifelse(dl > 0, gdd / dl, 0), 4),
      PTD1     = round(dtr * dl, 4),
      PTD2     = round(ifelse(dl > 0, dtr / dl, 0), 4),
      PTS      = round((tmax^2 - tmin^2) * dl^2, 4),
      stringsAsFactors = FALSE
    )

    if (i < nrow(env_meta)) Sys.sleep(0.5)
  }

  result <- do.call(rbind, results)
  rownames(result) <- NULL
  result
}


#' @noRd
.fetch_power_point <- function(lat, lon, start_date, end_date) {
  start_str <- format(start_date, "%Y%m%d")
  end_str <- format(end_date, "%Y%m%d")

  url <- sprintf(
    paste0("https://power.larc.nasa.gov/api/temporal/daily/point?",
           "parameters=T2M_MAX,T2M_MIN&",
           "community=ag&longitude=%.4f&latitude=%.4f&",
           "start=%s&end=%s&format=json"),
    lon, lat, start_str, end_str
  )

  response <- tryCatch(
    jsonlite::fromJSON(url),
    error = function(e) {
      warning("NASA POWER API request failed: ", e$message,
              call. = FALSE)
      return(NULL)
    }
  )

  if (is.null(response) ||
      is.null(response$properties) ||
      is.null(response$properties$parameter)) {
    return(NULL)
  }

  params <- response$properties$parameter
  dates <- names(params$T2M_MAX)

  tmax <- as.numeric(params$T2M_MAX)
  tmin <- as.numeric(params$T2M_MIN)

  tmax[tmax <= -999] <- NA
  tmin[tmin <= -999] <- NA

  data.frame(
    date    = as.Date(dates, format = "%Y%m%d"),
    T2M_MAX = tmax,
    T2M_MIN = tmin,
    stringsAsFactors = FALSE
  )
}


#' @noRd
.compute_day_length <- function(lat, doy) {
  # CBM model for astronomical day length
  # Returns day length in hours
  lat_rad <- lat * pi / 180

  P <- asin(0.39795 * cos(0.2163108 +
    2 * atan(0.9671396 * tan(0.00860 * (doy - 186)))))

  arg <- (sin(0.8333 * pi / 180) + sin(lat_rad) * sin(P)) /
    (cos(lat_rad) * cos(P))

  # Clamp to [-1, 1] for polar regions

  arg <- pmax(-1, pmin(1, arg))

  dl <- 24 - (24 / pi) * acos(arg)
  dl
}
