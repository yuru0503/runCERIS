# Validate input data for CERIS analysis

Checks that the required columns and data types are present. Stops with
an informative error if a hard requirement is not met, and issues
warnings for recommended columns that are missing (e.g., `lat`, `lon`,
`PlantingDate` in `env_meta`).

## Usage

``` r
validate_input_data(
  traits,
  env_meta,
  env_params,
  genotype = NULL,
  verbose = FALSE
)
```

## Arguments

- traits:

  Data frame with at least `line_code`, `env_code`, and one numeric
  trait column. Optional columns: `pop_code`, `env_note`.

- env_meta:

  Data frame with at least `env_code`. Recommended: `lat`, `lon`,
  `PlantingDate`, `TrialYear`, `Location`.

- env_params:

  Data frame with at least `env_code`, `DAP` (days after planting), and
  one or more numeric environmental parameter columns (e.g., `DL`,
  `GDD`, `PTT`).

- genotype:

  Optional numeric matrix with `line_code` values as rownames and marker
  names as column names. Typically coded 0/1/2.

- verbose:

  Logical. If `TRUE`, print a summary of the validated data. Default is
  `FALSE`.

## Value

`TRUE` invisibly if all checks pass.

## Details

When `verbose = TRUE`, prints a summary of the data dimensions, detected
trait and parameter columns, and the result of each check.

## Examples

``` r
d <- load_crop_data("sorghum")
validate_input_data(d$traits, d$env_meta, d$env_params, d$genotype)
#> Warning: no genotype rownames match line_code values in traits

# Print a data summary
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
