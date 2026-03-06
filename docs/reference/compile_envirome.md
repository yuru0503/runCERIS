# Compile Daily Environmental Data into a Single Matrix

Reads daily environmental files from a directory and combines them into
a single data.frame with a DAP (Days After Planting) column.

## Usage

``` r
compile_envirome(env_dir, env_codes)
```

## Arguments

- env_dir:

  Path to directory containing daily environment files named
  `<env_code>_daily.txt`

- env_codes:

  Character vector of environment codes

## Value

Data.frame with columns: env_code, DAP, and environmental parameters

## Examples

``` r
if (FALSE) { # \dontrun{
env_params <- compile_envirome("path/to/env_files",
                               c("ENV01", "ENV02", "ENV03"))
head(env_params)
} # }
```
