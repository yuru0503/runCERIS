# Getting Started with CERIS

## What is CERIS?

**CERIS** (Critical Environmental Regressor through Informed Search) is
an R package for dissecting genotype-by-environment (GxE) interactions
through exhaustive environmental window analysis. In multi-environment
trials, crop performance varies across locations and years. CERIS helps
answer a fundamental question: *which environmental factor, during which
developmental window, best explains the observed variation in a trait
across environments?*

The core idea is straightforward. For every possible contiguous window
of days after planting (defined by a start day and an end day), CERIS
computes a summary of each environmental parameter (e.g., cumulative
growing degree days, mean photoperiod) and correlates that summary with
the trait’s environmental mean. By exhaustively searching over all
windows and all parameters, the package identifies the critical
developmental period and the environmental driver most strongly
associated with GxE variation.

## Background and Motivation

The CERIS and JGRA (Joint Genomic Regression Analysis) methods were
originally developed by **Dr. Jianming Yu’s lab** at Iowa State
University, with key contributions from Xianran Li, Tingting Guo, and
collaborators. The foundational work demonstrated how environmental
indices identified through exhaustive search can be used to model
phenotypic plasticity and enable genomic prediction across environments
in major crops including sorghum, maize, wheat, oat, and rice (Li et
al. 2018; Li et al. 2021; Guo et al. 2024; Wei et al. 2025).

The original code is available at
[github.com/jmyu/CERIS_JGRA](https://github.com/jmyu/CERIS_JGRA). This R
package was developed by **Yu-Ru Chen**, who adapted and restructured
the original functions into a documented, tested, and user-friendly R
package. As a researcher who frequently applies these methods, Yu-Ru
Chen recognized that packaging the code would make it far more
accessible for the plant breeding community. Beyond providing a
convenient interface, the package aims to help users understand the
deeper quantitative genetics concepts behind GxE analysis — from
reaction norms and Finlay-Wilkinson regression to genomic prediction
with environmental covariates.

## Installation

Install runCERIS from GitHub:

``` r

# install.packages("remotes")
remotes::install_github("yuru0503/runCERIS")
```

Once installed, load the package:

``` r

library(runCERIS)
```

## Package Overview

CERIS provides functions organized into four categories:

| Category | Functions | Purpose |
|----|----|----|
| **Data Loading** | [`load_crop_data()`](../reference/load_crop_data.md), [`validate_input_data()`](../reference/validate_input_data.md) | Load built-in datasets and validate custom data |
| **Data Preparation** | [`prepare_trait_data()`](../reference/prepare_trait_data.md), [`compute_env_means()`](../reference/compute_env_means.md), [`prepare_line_by_env()`](../reference/prepare_line_by_env.md) | Transform raw trial data into analysis-ready formats |
| **CERIS Search** | [`run_CERIS()`](../reference/run_CERIS.md), [`ceris_identify_best()`](../reference/ceris_identify_best.md), [`compute_window_params()`](../reference/compute_window_params.md) | Run the exhaustive window search and extract results |
| **Visualization** | [`plot_ceris_heatmap()`](../reference/plot_ceris_heatmap.md), [`plot_trait_env_param()`](../reference/plot_trait_env_param.md), [`plot_geo_order()`](../reference/plot_geo_order.md), [`plot_env_means()`](../reference/plot_env_means.md), [`plot_env_factors()`](../reference/plot_env_factors.md), [`plot_pca_biplot()`](../reference/plot_pca_biplot.md), [`plot_clustering_heatmap()`](../reference/plot_clustering_heatmap.md) | Explore data and interpret search results |

## Built-in Datasets

CERIS ships with multi-environment trial data for four crops. The
`crop_info` dataset provides a quick summary:

``` r

crop_info
#>      crop n_envs      traits default_trait has_genotype
#> 1 sorghum      7 FTdap,FTgdd         FTdap         TRUE
#> 2   maize     10       FT,PH            FT         TRUE
#> 3    rice      9 FTdap,FTgdd         FTdap         TRUE
#> 4     oat     13 FTdap,PH,GY         FTdap        FALSE
#>                               env_params
#> 1                     DL,GDD,PTT,PTR,PTS
#> 2           TMAX,TMIN,DL,GDD,PTT,PTR,PTS
#> 3           TMAX,TMIN,DL,GDD,PTT,PTR,PTS
#> 4 TMAX,TMIN,DL,GDD,PTT,PTR,PTD1,PTD2,PTS
```

Each crop includes between 7 and 13 environments, a set of measured
traits, and daily environmental parameters. Three crops (sorghum, maize,
rice) include genotype marker data; oat does not.

## Loading Data

Use [`load_crop_data()`](../reference/load_crop_data.md) to load the
full dataset for a crop. The function returns a named list with four
components: `traits`, `env_meta`, `env_params`, and `genotype`.

``` r

sorghum <- load_crop_data("sorghum")
names(sorghum)
#> [1] "traits"     "env_meta"   "env_params" "genotype"
```

### Traits

The `traits` data frame contains phenotypic observations at the plot
level. Each row is one genotype in one environment:

``` r

str(sorghum$traits)
#> 'data.frame':    1659 obs. of  6 variables:
#>  $ env_code : chr  "PR12" "PR12" "PR12" "PR12" ...
#>  $ pop_code : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ line_code: chr  "E5" "E6" "E7" "E8" ...
#>  $ FTdap    : num  58.1 59.3 56.2 56.2 63.1 ...
#>  $ FTgdd    : num  1544 1575 1492 1492 1671 ...
#>  $ env_note : int  2 2 2 2 2 2 2 2 2 2 ...
head(sorghum$traits)
#>   env_code pop_code line_code   FTdap    FTgdd env_note
#> 1     PR12        1        E5 58.1071 1544.069        2
#> 2     PR12        1        E6 59.2582 1575.221        2
#> 3     PR12        1        E7 56.1885 1492.151        2
#> 4     PR12        1        E8 56.1885 1492.151        2
#> 5     PR12        1        E9 63.0955 1671.440        2
#> 6     PR12        1       E10 53.1187 1409.773        2
```

For sorghum, the measured traits are flowering time in days after
planting (`FTdap`) and in growing degree days (`FTgdd`). The `env_note`
column provides a short description of each environment.

### Environment Metadata

The `env_meta` data frame describes each trial environment:

``` r

str(sorghum$env_meta)
#> 'data.frame':    7 obs. of  7 variables:
#>  $ env_notes   : int  1 2 3 4 5 6 7
#>  $ env_code    : chr  "PR11" "PR12" "KS11" "KS12" ...
#>  $ lat         : num  18 18 39.2 39.2 42 ...
#>  $ lon         : num  -66.8 -66.8 -96.6 -96.6 -93.6 ...
#>  $ PlantingDate: chr  "2010-12-04" "2011-12-12" "2011-06-08" "2012-06-07" ...
#>  $ TrialYear   : int  2010 2011 2011 2012 2013 2014 2014
#>  $ Location    : chr  "PR" "PR" "KS" "KS" ...
sorghum$env_meta
#>   env_notes env_code     lat      lon PlantingDate TrialYear Location
#> 1         1     PR11 18.0373 -66.7963   2010-12-04      2010       PR
#> 2         2     PR12 18.0373 -66.7963   2011-12-12      2011       PR
#> 3         3     KS11 39.1836 -96.5717   2011-06-08      2011       KS
#> 4         4     KS12 39.1836 -96.5717   2012-06-07      2012       KS
#> 5         5     IA13 42.0308 -93.6319   2013-06-05      2013       IA
#> 6         6     IA14 42.0308 -93.6319   2014-06-10      2014       IA
#> 7         7    PR14S 18.0373 -66.7963   2014-06-05      2014       PR
```

This includes geographic coordinates (`lat`, `lon`), planting date,
trial year, and location name — information used for geographic ordering
and mapping.

### Environmental Parameters

The `env_params` data frame contains daily environmental covariates for
each environment. Each row is one environment on one day after planting
(DAP):

``` r

str(sorghum$env_params)
#> 'data.frame':    854 obs. of  7 variables:
#>  $ env_code: chr  "IA13" "IA13" "IA13" "IA13" ...
#>  $ DL      : num  16.2 16.2 16.2 16.3 16.3 ...
#>  $ GDD     : num  10 12 11 10.5 9 10 15 14.5 24 28.5 ...
#>  $ PTT     : num  162 195 179 171 147 ...
#>  $ PTR     : num  0.617 0.739 0.677 0.645 0.553 ...
#>  $ PTS     : num  631412 522611 257725 480454 500392 ...
#>  $ DAP     : int  1 2 3 4 5 6 7 8 9 10 ...
head(sorghum$env_params)
#>   env_code    DL  GDD     PTT       PTR      PTS DAP
#> 1     IA13 16.22 10.0 162.200 0.6165228 631412.2   1
#> 2     IA13 16.23 12.0 194.760 0.7393715 522611.2   2
#> 3     IA13 16.25 11.0 178.750 0.6769231 257725.0   3
#> 4     IA13 16.27 10.5 170.835 0.6453596 480453.9   4
#> 5     IA13 16.28  9.0 146.520 0.5528256 500392.5   5
#> 6     IA13 16.30 10.0 163.000 0.6134969 510124.8   6
```

For sorghum, the daily parameters are day length (`DL`), growing degree
days (`GDD`), photothermal time (`PTT`), photothermal ratio (`PTR`), and
photothermal sum (`PTS`). These are the candidate regressors that CERIS
will evaluate.

The environmental parameters used across all crops in CERIS are derived
from three fundamental domains — temperature, day length, and moisture —
and their interactions (Tibbs-Cortes et al. 2024):

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

Not all parameters are available for every crop. The sorghum dataset
includes DL, GDD, PTT, PTR, and PTS; maize and rice add TMAX and TMIN;
oat further adds PTD1 and PTD2. See
[`vignette("multi-crop-examples")`](../articles/multi-crop-examples.md)
for details.

### Genotype Data

The `genotype` component is a matrix of marker scores (lines in rows,
markers in columns):

``` r

str(sorghum$genotype)
#>  int [1:1462, 1:237] 1 1 1 1 1 1 -1 -1 -1 -1 ...
#>  - attr(*, "dimnames")=List of 2
#>   ..$ : chr [1:1462] "S1_1857181" "S1_1857180" "S1_1857182" "S1_1857183" ...
#>   ..$ : chr [1:237] "E5" "E6" "E7" "E8" ...
sorghum$genotype[1:5, 1:5]
#>            E5 E6 E7 E8 E9
#> S1_1857181  1  1 -1  1  1
#> S1_1857180  1  1 -1  1  1
#> S1_1857182  1  1 -1  1  1
#> S1_1857183  1  1 -1  1  1
#> S1_1857184  1  1 -1  1  1
```

## Data Structure Requirements

If you bring your own data, it must follow the same structure as the
built-in datasets. The key requirements are:

- **traits**: Must contain `env_code`, `line_code`, and one or more
  numeric trait columns.
- **env_meta**: Must contain `env_code` plus location metadata. Columns
  `lat`, `lon`, and `PlantingDate` are expected by several plotting
  functions.
- **env_params**: Must contain `env_code`, `DAP` (days after planting),
  and one or more numeric parameter columns.
- **genotype** (optional): A numeric matrix with row names matching
  `line_code` values in `traits`.

All `env_code` values in `traits` must appear in both `env_meta` and
`env_params`.

## Validating Input Data

Use [`validate_input_data()`](../reference/validate_input_data.md) to
check that your data meets all requirements before analysis. The
function returns `TRUE` silently on success or stops with an informative
error message:

``` r

validate_input_data(
  traits    = sorghum$traits,
  env_meta  = sorghum$env_meta,
  env_params = sorghum$env_params,
  genotype  = sorghum$genotype
)
#> Warning: no genotype rownames match line_code values in traits
```

The `genotype` argument is optional. If you do not have marker data,
simply omit it:

``` r

validate_input_data(
  traits    = sorghum$traits,
  env_meta  = sorghum$env_meta,
  env_params = sorghum$env_params
)
```

## Workflow Roadmap

A typical CERIS analysis proceeds in three stages:

1.  **Data Exploration** — Prepare trait and environment data, visualize
    geographic patterns, trait distributions, and environmental
    covariate profiles. See
    [`vignette("data-exploration")`](../articles/data-exploration.md).

2.  **CERIS Search** — Run the exhaustive window search to identify the
    critical environmental parameter and developmental window, then
    visualize and interpret the results. See
    [`vignette("ceris-search")`](../articles/ceris-search.md).

3.  **Advanced Analysis** — Use leave-one-out cross-validation for
    robustness, compare across crops, and integrate genotype data for
    genomic prediction (covered in the CERIS Search vignette and future
    extensions).

The next vignette walks through data exploration step by step.
