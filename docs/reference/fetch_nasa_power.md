# Fetch Environmental Data from NASA POWER and Compute CERIS Parameters

Downloads daily weather data (temperature, precipitation) from the NASA
POWER API for each environment in `env_meta`, then computes all derived
CERIS environmental parameters: day length (DL), growing degree days
(GDD), photothermal time (PTT), photothermal ratio (PTR), photothermal
day variants (PTD1, PTD2), and photothermal sum (PTS).

## Usage

``` r
fetch_nasa_power(env_meta, max_dap = 150, base_temp = 10, progress = TRUE)
```

## Arguments

- env_meta:

  Data frame with at least `env_code`, `lat`, `lon`, and `PlantingDate`
  columns. `PlantingDate` should be in a format parseable by `as.Date`
  (e.g., "2014-05-15").

- max_dap:

  Integer. Maximum number of days after planting to fetch. Default is
  150.

- base_temp:

  Numeric. Base temperature (Celsius) for GDD calculation. Default is
  10.

- progress:

  Logical. If `TRUE`, print progress messages for each environment.
  Default is `TRUE`.

## Value

A data frame with columns: `env_code`, `DAP`, `TMAX`, `TMIN`, `DL`,
`GDD`, `PTT`, `PTR`, `PTD1`, `PTD2`, `PTS`.

## Details

The returned data frame has the same structure as `env_params` and can
be used directly in [`ceris_search`](ceris_search.md).

The function calls the NASA POWER daily API
(<https://power.larc.nasa.gov>) to retrieve `T2M_MAX` (daily maximum
temperature) and `T2M_MIN` (daily minimum temperature) for the
agroclimatology community. Day length is computed astronomically from
latitude and day of year using the CBM model. No API key is required.

Derived parameters follow the definitions in Tibbs-Cortes et al. (2024):

- DL:

  Astronomical day length in hours

- GDD:

  max(0, (TMAX + TMIN) / 2 - base_temp)

- PTT:

  GDD \* DL

- PTR:

  GDD / DL

- PTD1:

  (TMAX - TMIN) \* DL

- PTD2:

  (TMAX - TMIN) / DL

- PTS:

  (TMAX^2 - TMIN^2) \* DL^2

## Examples

``` r
if (FALSE) { # \dontrun{
d <- load_crop_data("sorghum")
env_params <- fetch_nasa_power(d$env_meta, max_dap = 80)
head(env_params)

# Use in CERIS search
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
ceris_result <- ceris_search(
  env_mean_trait, env_params,
  params = c("DL", "GDD", "PTT", "PTR", "PTS"),
  max_days = 80
)
} # }
```
