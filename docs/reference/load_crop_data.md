# Load a crop dataset

Convenience function to load all components of a crop dataset.

## Usage

``` r
load_crop_data(crop)
```

## Arguments

- crop:

  One of "sorghum", "maize", "rice", "oat"

## Value

A list with components: traits, env_meta, env_params, genotype (NULL if
unavailable)

## Examples

``` r
data_list <- load_crop_data("sorghum")
str(data_list$traits)
#> 'data.frame':    1659 obs. of  6 variables:
#>  $ env_code : chr  "PR12" "PR12" "PR12" "PR12" ...
#>  $ pop_code : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ line_code: chr  "E5" "E6" "E7" "E8" ...
#>  $ FTdap    : num  58.1 59.3 56.2 56.2 63.1 ...
#>  $ FTgdd    : num  1544 1575 1492 1492 1671 ...
#>  $ env_note : int  2 2 2 2 2 2 2 2 2 2 ...
```
