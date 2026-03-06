# Data Format Reference

## Overview

CERIS requires four input data frames that describe the phenotypic
observations, trial environments, daily environmental covariates, and
(optionally) genotype marker data. All data frames are linked through
two key identifiers:

- **`env_code`**: A unique identifier for each trial environment (e.g.,
  location-year combination). Present in `traits`, `env_meta`, and
  `env_params`.
- **`line_code`**: A unique identifier for each genotype. Present in
  `traits` and as rownames in `genotype`.

This vignette documents the required and recommended columns for each
data frame, the derived data frames produced by the CERIS pipeline, and
practical tips for preparing custom data.

``` r

library(runCERIS)
d <- load_crop_data("sorghum")
```

------------------------------------------------------------------------

## 1. traits

The `traits` data frame contains phenotypic observations at the plot
level. Each row represents one genotype observed in one environment (or
one replicate of that combination).

### Required columns

| Column            | Type      | Description                                  |
|-------------------|-----------|----------------------------------------------|
| `line_code`       | character | Genotype identifier                          |
| `env_code`        | character | Environment identifier                       |
| *(trait columns)* | numeric   | One or more columns of measured trait values |

### Optional columns

| Column     | Type      | Description                          |
|------------|-----------|--------------------------------------|
| `pop_code` | character | Population or group identifier       |
| `env_note` | character | Short description of the environment |

Any column that is not `line_code`, `env_code`, `pop_code`, or
`env_note` is treated as a trait column and must be numeric. Multiple
trait columns are allowed — select the trait of interest when calling
[`prepare_trait_data()`](../reference/prepare_trait_data.md).

### Example

``` r

str(d$traits)
#> 'data.frame':    1659 obs. of  6 variables:
#>  $ env_code : chr  "PR12" "PR12" "PR12" "PR12" ...
#>  $ pop_code : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ line_code: chr  "E5" "E6" "E7" "E8" ...
#>  $ FTdap    : num  58.1 59.3 56.2 56.2 63.1 ...
#>  $ FTgdd    : num  1544 1575 1492 1492 1671 ...
#>  $ env_note : int  2 2 2 2 2 2 2 2 2 2 ...
head(d$traits)
#>   env_code pop_code line_code   FTdap    FTgdd env_note
#> 1     PR12        1        E5 58.1071 1544.069        2
#> 2     PR12        1        E6 59.2582 1575.221        2
#> 3     PR12        1        E7 56.1885 1492.151        2
#> 4     PR12        1        E8 56.1885 1492.151        2
#> 5     PR12        1        E9 63.0955 1671.440        2
#> 6     PR12        1       E10 53.1187 1409.773        2
```

The sorghum dataset has two trait columns: `FTdap` (flowering time in
days after planting) and `FTgdd` (flowering time in growing degree
days).

------------------------------------------------------------------------

## 2. env_meta

The `env_meta` data frame describes each trial environment. There is one
row per environment.

### Required columns

| Column | Type | Description |
|----|----|----|
| `env_code` | character | Environment identifier (must match `traits` and `env_params`) |

### Recommended columns

These columns are used by plotting functions and are strongly
recommended:

| Column         | Type           | Description                        |
|----------------|----------------|------------------------------------|
| `lat`          | numeric        | Latitude of the trial site         |
| `lon`          | numeric        | Longitude of the trial site        |
| `PlantingDate` | character/Date | Planting date (e.g., “2014-05-15”) |
| `TrialYear`    | integer        | Year of the trial                  |
| `Location`     | character      | Name of the trial location         |

If `lat`, `lon`, or `PlantingDate` are missing, some visualization
functions (e.g., [`plot_geo_order()`](../reference/plot_geo_order.md))
will not work.

### Example

``` r

str(d$env_meta)
#> 'data.frame':    7 obs. of  7 variables:
#>  $ env_notes   : int  1 2 3 4 5 6 7
#>  $ env_code    : chr  "PR11" "PR12" "KS11" "KS12" ...
#>  $ lat         : num  18 18 39.2 39.2 42 ...
#>  $ lon         : num  -66.8 -66.8 -96.6 -96.6 -93.6 ...
#>  $ PlantingDate: chr  "2010-12-04" "2011-12-12" "2011-06-08" "2012-06-07" ...
#>  $ TrialYear   : int  2010 2011 2011 2012 2013 2014 2014
#>  $ Location    : chr  "PR" "PR" "KS" "KS" ...
d$env_meta
#>   env_notes env_code     lat      lon PlantingDate TrialYear Location
#> 1         1     PR11 18.0373 -66.7963   2010-12-04      2010       PR
#> 2         2     PR12 18.0373 -66.7963   2011-12-12      2011       PR
#> 3         3     KS11 39.1836 -96.5717   2011-06-08      2011       KS
#> 4         4     KS12 39.1836 -96.5717   2012-06-07      2012       KS
#> 5         5     IA13 42.0308 -93.6319   2013-06-05      2013       IA
#> 6         6     IA14 42.0308 -93.6319   2014-06-10      2014       IA
#> 7         7    PR14S 18.0373 -66.7963   2014-06-05      2014       PR
```

------------------------------------------------------------------------

## 3. env_params

The `env_params` data frame contains daily environmental covariates for
each environment. Each row represents one environment on one day after
planting (DAP). This is the data CERIS searches over to identify
critical environmental windows.

### Required columns

| Column                | Type      | Description                                |
|-----------------------|-----------|--------------------------------------------|
| `env_code`            | character | Environment identifier                     |
| `DAP`                 | integer   | Day after planting (1, 2, 3, …)            |
| *(parameter columns)* | numeric   | One or more daily environmental parameters |

### Available environmental parameters

The parameters used across CERIS studies are derived from three
fundamental domains — temperature, day length, and moisture — and their
interactions (Tibbs-Cortes et al. 2024):

| Parameter   | Formula                           | Domain                   |
|-------------|-----------------------------------|--------------------------|
| DL          | Day length (hours)                | Day Length               |
| GDD         | (Tmax + Tmin) / 2 - base          | Temperature              |
| TMAX        | Daily maximum temperature         | Temperature              |
| TMIN        | Daily minimum temperature         | Temperature              |
| DTR         | Tmax - Tmin                       | Temperature              |
| PTT         | GDD x DL                          | Temperature x Day Length |
| PTR         | GDD / DL                          | Temperature x Day Length |
| PTD1        | (Tmax - Tmin) x DL                | Temperature x Day Length |
| PTD2        | (Tmax - Tmin) / DL                | Temperature x Day Length |
| PTS         | (Tmax^2 - Tmin^2) x (DL)^2        | Temperature x Day Length |
| PET         | Potential evapotranspiration (mm) | Temperature x Moisture   |
| PRECIP      | Precipitation (mm)                | Moisture                 |
| H2O.balance | PET - PRECIP                      | Temperature x Moisture   |

Not all parameters need to be present. You choose which parameters to
search over when calling
[`ceris_search()`](../reference/ceris_search.md). The built-in datasets
include:

| Crop    | Parameters                                     |
|---------|------------------------------------------------|
| Sorghum | DL, GDD, PTT, PTR, PTS                         |
| Maize   | TMAX, TMIN, DL, GDD, PTT, PTR, PTS             |
| Rice    | TMAX, TMIN, DL, GDD, PTT, PTR, PTS             |
| Oat     | TMAX, TMIN, DL, GDD, PTT, PTR, PTD1, PTD2, PTS |

### Example

``` r

str(d$env_params)
#> 'data.frame':    854 obs. of  7 variables:
#>  $ env_code: chr  "IA13" "IA13" "IA13" "IA13" ...
#>  $ DL      : num  16.2 16.2 16.2 16.3 16.3 ...
#>  $ GDD     : num  10 12 11 10.5 9 10 15 14.5 24 28.5 ...
#>  $ PTT     : num  162 195 179 171 147 ...
#>  $ PTR     : num  0.617 0.739 0.677 0.645 0.553 ...
#>  $ PTS     : num  631412 522611 257725 480454 500392 ...
#>  $ DAP     : int  1 2 3 4 5 6 7 8 9 10 ...
head(d$env_params)
#>   env_code    DL  GDD     PTT       PTR      PTS DAP
#> 1     IA13 16.22 10.0 162.200 0.6165228 631412.2   1
#> 2     IA13 16.23 12.0 194.760 0.7393715 522611.2   2
#> 3     IA13 16.25 11.0 178.750 0.6769231 257725.0   3
#> 4     IA13 16.27 10.5 170.835 0.6453596 480453.9   4
#> 5     IA13 16.28  9.0 146.520 0.5528256 500392.5   5
#> 6     IA13 16.30 10.0 163.000 0.6134969 510124.8   6

# DAP range per environment
tapply(d$env_params$DAP, d$env_params$env_code, range)
#> $IA13
#> [1]   1 122
#> 
#> $IA14
#> [1]   1 122
#> 
#> $KS11
#> [1]   1 122
#> 
#> $KS12
#> [1]   1 122
#> 
#> $PR11
#> [1]   1 122
#> 
#> $PR12
#> [1]   1 122
#> 
#> $PR14S
#> [1]   1 122
```

------------------------------------------------------------------------

## 4. genotype (optional)

The `genotype` matrix contains marker scores for genomic prediction. It
is optional — CERIS search, JRA, and phenotypic cross-validation work
without it. Genomic prediction functions
([`jgra()`](../reference/jgra.md),
[`jgra_marker()`](../reference/jgra_marker.md),
[`cv_genotype()`](../reference/cv_genotype.md),
[`cv_combined()`](../reference/cv_combined.md)) require it.

### Format

| Property | Requirement                                          |
|----------|------------------------------------------------------|
| Type     | Numeric matrix                                       |
| Rows     | Genotype lines (rownames must be `line_code` values) |
| Columns  | Markers/SNPs (column names are marker identifiers)   |
| Values   | Typically coded as 0, 1, 2 (allele dosage)           |

Rownames in the genotype matrix must match `line_code` values in
`traits`. Not all lines need to be present in both — functions will use
the intersection.

### Example

``` r

str(d$genotype)
#>  int [1:1462, 1:237] 1 1 1 1 1 1 -1 -1 -1 -1 ...
#>  - attr(*, "dimnames")=List of 2
#>   ..$ : chr [1:1462] "S1_1857181" "S1_1857180" "S1_1857182" "S1_1857183" ...
#>   ..$ : chr [1:237] "E5" "E6" "E7" "E8" ...
d$genotype[1:5, 1:5]
#>            E5 E6 E7 E8 E9
#> S1_1857181  1  1 -1  1  1
#> S1_1857180  1  1 -1  1  1
#> S1_1857182  1  1 -1  1  1
#> S1_1857183  1  1 -1  1  1
#> S1_1857184  1  1 -1  1  1
```

------------------------------------------------------------------------

## 5. Derived Data Frames

The CERIS pipeline produces several intermediate data frames.
Understanding their structure helps when using downstream functions.

### exp_trait (from `prepare_trait_data()`)

Averages replicates within each line-environment combination for a
single selected trait:

``` r

exp_trait <- prepare_trait_data(d$traits, "FTdap")
str(exp_trait)
#> 'data.frame':    1659 obs. of  3 variables:
#>  $ line_code: chr  "E10" "E100" "E101" "E102" ...
#>  $ env_code : chr  "IA13" "IA13" "IA13" "IA13" ...
#>  $ Yobs     : num  89.7 84.3 83.5 78.7 92.4 ...
head(exp_trait)
#>   line_code env_code     Yobs
#> 1       E10     IA13 89.73960
#> 2      E100     IA13 84.28180
#> 3      E101     IA13 83.53581
#> 4      E102     IA13 78.66140
#> 5      E103     IA13 92.39830
#> 6      E104     IA13 87.26640
```

| Column | Type | Description |
|----|----|----|
| `line_code` | character | Genotype identifier |
| `env_code` | character | Environment identifier |
| `Yobs` | numeric | Mean observed trait value (averaged across replicates) |

### env_mean_trait (from `compute_env_means()`)

Environmental means merged with environment metadata:

``` r

env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
str(env_mean_trait)
#> 'data.frame':    7 obs. of  8 variables:
#>  $ env_code    : chr  "PR12" "PR11" "PR14S" "KS11" ...
#>  $ meanY       : num  56.8 56.9 60.5 73.8 74.4 ...
#>  $ env_notes   : int  2 1 7 3 6 4 5
#>  $ lat         : num  18 18 18 39.2 42 ...
#>  $ lon         : num  -66.8 -66.8 -66.8 -96.6 -93.6 ...
#>  $ PlantingDate: chr  "2011-12-12" "2010-12-04" "2014-06-05" "2011-06-08" ...
#>  $ TrialYear   : int  2011 2010 2014 2011 2014 2012 2013
#>  $ Location    : chr  "PR" "PR" "PR" "KS" ...
```

| Column | Type | Description |
|----|----|----|
| `env_code` | character | Environment identifier |
| `meanY` | numeric | Mean trait value across all lines in this environment |
| *(env_meta columns)* | various | All columns from `env_meta` |

After calling
[`compute_window_params()`](../reference/compute_window_params.md), a
`kPara` column is added:

| Column | Type | Description |
|----|----|----|
| `kPara` | numeric | CERIS-derived environmental parameter summarized over the best window |

### line_by_env (from `prepare_line_by_env()`)

Wide-format matrix with one row per genotype and one column per
environment:

``` r

line_by_env <- prepare_line_by_env(exp_trait, env_mean_trait)
line_by_env[1:5, 1:4]
#>   line_code    PR12    PR11   PR14S
#> 1       E10 53.1187 53.4805 82.8025
#> 2      E100 60.0257 66.6417 64.0564
#> 3      E101 56.9559 58.7449 65.3437
#> 4      E102 56.5722 54.3579 60.0090
#> 5      E103 53.8861 54.7966 77.9528
```

| Column               | Type      | Description                      |
|----------------------|-----------|----------------------------------|
| `line_code`          | character | Genotype identifier              |
| *(env_code columns)* | numeric   | Trait value for each environment |

------------------------------------------------------------------------

## 6. Validating Your Data

Use [`validate_input_data()`](../reference/validate_input_data.md) to
check that your data meets all requirements. The function stops with an
error if a hard requirement is not met, warns about missing recommended
columns, and optionally prints a summary:

``` r

# Quiet mode (default) --- returns TRUE or stops with error
validate_input_data(d$traits, d$env_meta, d$env_params, d$genotype)
#> Warning: no genotype rownames match line_code values in traits
```

``` r

# Verbose mode --- prints a data summary
validate_input_data(d$traits, d$env_meta, d$env_params, d$genotype,
                    verbose = TRUE)
#> Warning: no genotype rownames match line_code values in traits
#> -- CERIS Data Summary --
#> traits:     1659 obs x 6 cols | 2 trait(s): FTdap, FTgdd | 237 lines, 7 envs
#> env_meta:   7 envs x 7 cols | Columns: env_notes, env_code, lat, lon, PlantingDate, TrialYear, Location
#> env_params: 854 obs x 7 cols | 5 param(s): DL, GDD, PTT, PTR, PTS | DAP range: 1-122
#> genotype:   1462 lines x 237 markers | 0 lines overlap with traits
#> All checks passed.
```

The genotype argument is optional:

``` r

validate_input_data(d$traits, d$env_meta, d$env_params, verbose = TRUE)
#> -- CERIS Data Summary --
#> traits:     1659 obs x 6 cols | 2 trait(s): FTdap, FTgdd | 237 lines, 7 envs
#> env_meta:   7 envs x 7 cols | Columns: env_notes, env_code, lat, lon, PlantingDate, TrialYear, Location
#> env_params: 854 obs x 7 cols | 5 param(s): DL, GDD, PTT, PTR, PTS | DAP range: 1-122
#> genotype:   not provided
#> All checks passed.
```

------------------------------------------------------------------------

## 7. Preparing Custom Data

### Fetching weather data from NASA POWER

The easiest way to build `env_params` for your own trials is to use
[`fetch_nasa_power()`](../reference/fetch_nasa_power.md). This function
downloads daily temperature data from the [NASA POWER
API](https://power.larc.nasa.gov/) and automatically computes all
CERIS-derived parameters (DL, GDD, PTT, PTR, PTD1, PTD2, PTS). All you
need is the `env_meta` data frame with latitude, longitude, and planting
date for each environment:

``` r

# Your env_meta must have: env_code, lat, lon, PlantingDate
env_params <- fetch_nasa_power(d$env_meta, max_dap = 120, base_temp = 10)
head(env_params)

# The result is ready to use in ceris_search()
ceris_result <- ceris_search(
  env_mean_trait, env_params,
  params = c("DL", "GDD", "PTT", "PTR", "PTS"),
  max_days = 80
)
```

The function fetches `T2M_MAX` and `T2M_MIN` from NASA POWER, computes
day length astronomically from latitude and day of year, and derives all
photothermal parameters. No API key is required. See
[`?fetch_nasa_power`](../reference/fetch_nasa_power.md) for details.

### From raw weather data

If you already have daily weather records (temperature, day length), you
can compute the derived parameters and assemble the `env_params` data
frame manually. The
[`compile_envirome()`](../reference/compile_envirome.md) function can
help if your data is stored as tab-separated files on disk — see
[`?compile_envirome`](../reference/compile_envirome.md) for details.

A minimal workflow to construct `env_params` by hand:

``` r

# Suppose you have a data frame 'weather' with columns:
#   env_code, DAP, Tmax, Tmin, DL, PRECIP

weather$GDD <- pmax(0, (weather$Tmax + weather$Tmin) / 2 - 10)
weather$PTT <- weather$GDD * weather$DL
weather$PTR <- weather$GDD / weather$DL
weather$PTS <- (weather$Tmax^2 - weather$Tmin^2) * (weather$DL)^2

env_params <- weather[, c("env_code", "DAP", "DL", "GDD",
                           "PTT", "PTR", "PTS")]
```

### Common pitfalls

- **`env_code` mismatches**: Environment codes must be identical across
  `traits`, `env_meta`, and `env_params`. Check for trailing whitespace
  or inconsistent formatting (e.g., “Env1” vs “ENV1”).
- **Missing DAP values**: `env_params` should have continuous DAP
  sequences within each environment (1, 2, 3, …, N). Gaps will cause
  errors in the window search.
- **Non-numeric trait columns**: Trait columns must be numeric. If they
  contain text (e.g., “NA” as a string), convert them before analysis.
- **Genotype matrix orientation**: Rows must be lines and columns must
  be markers. If your matrix is transposed,
  [`prepare_genotype()`](../reference/prepare_genotype.md) will
  auto-detect and fix it.
- **Marker coding**: The genotype matrix should contain numeric values
  (typically 0, 1, 2 for biallelic markers). Factor or character columns
  will cause errors.
