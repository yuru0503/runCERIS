# Prepare trait data for analysis

Extracts a single trait column, renames it to Yobs, and averages across
replicates within environments.

## Usage

``` r
prepare_trait_data(traits, trait)
```

## Arguments

- traits:

  Raw data.frame with line_code, env_code, and trait columns

- trait:

  Character name of the trait column to analyze

## Value

Data.frame with columns: line_code, env_code, Yobs

## Examples

``` r
d <- load_crop_data("sorghum")
exp_trait <- prepare_trait_data(d$traits, "FTdap")
head(exp_trait)
#>   line_code env_code     Yobs
#> 1       E10     IA13 89.73960
#> 2      E100     IA13 84.28180
#> 3      E101     IA13 83.53581
#> 4      E102     IA13 78.66140
#> 5      E103     IA13 92.39830
#> 6      E104     IA13 87.26640
```
