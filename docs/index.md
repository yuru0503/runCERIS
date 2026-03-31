# runCERIS

**Critical Environmental Regressor through Informed Search**

runCERIS identifies critical environmental windows and covariates
driving genotype-by-environment (GxE) interaction in multi-environment
trials. It performs an exhaustive search over all possible
day-after-planting (DAP) windows, correlating environmental parameters
with trait means to find the time period and covariate most predictive
of GxE variation.

This R package was developed by **Dr. Yu-Ru Chen** at Iowa State
University, adapting and restructuring the original CERIS-JGRA functions
created by [Dr. Jianming Yu’s
lab](https://www.agron.iastate.edu/people/yu-jianming/) at ISU. The
original code is available at
[github.com/jmyu/CERIS_JGRA](https://github.com/jmyu/CERIS_JGRA). By
packaging these methods into a documented, tested R package with a Shiny
interface, runCERIS aims to make GxE environmental window analysis
accessible to the broader plant breeding community and to help users
understand the quantitative genetics concepts underlying
genotype-by-environment interaction.

## Documentation

Full tutorials and vignettes: **<https://yuru0503.github.io/runCERIS/>**

## Installation

``` r

# install.packages("remotes")
remotes::install_github("yuru0503/runCERIS")
```

## Quick Start

``` r

library(runCERIS)

# Load sorghum dataset
d <- load_crop_data("sorghum")

# Prepare trait data (flowering time in DAP)
exp_trait <- prepare_trait_data(d$traits, "FTdap")

# Compute environmental means and order environments
env_mean_trait <- compute_env_means(exp_trait, d$env_meta)
head(env_mean_trait)
#>   env_code    meanY env_notes     lat      lon PlantingDate TrialYear Location
#> 1     PR12 56.77317         2 18.0373 -66.7963   2011-12-12      2011       PR
#> 2     PR11 56.85371         1 18.0373 -66.7963   2010-12-04      2010       PR
#> 3    PR14S 60.45186         7 18.0373 -66.7963   2014-06-05      2014       PR
#> 4     KS11 73.81378         3 39.1836 -96.5717   2011-06-08      2011       KS
#> 5     IA14 74.44027         6 42.0308 -93.6319   2014-06-10      2014       IA
#> 6     KS12 80.02100         4 39.1836 -96.5717   2012-06-07      2012       KS
```

``` r

# Run CERIS search (use max_days = 80 for speed)
params <- c("DL", "GDD", "PTT", "PTR", "PTS")
ceris_result <- run_CERIS(env_mean_trait, d$env_params, params, max_days = 80)

# Find the best environmental window
best <- ceris_identify_best(ceris_result, params)
cat(sprintf("Best parameter: %s (DAP %d-%d, r = %.3f)\n",
            best$param_name, best$dap_start, best$dap_end, best$correlation))
#> Best parameter: PTS (DAP 9-16, r = 0.959)
```

## Workflow Overview

| Step | Function | Description |
|----|----|----|
| 1 | [`load_crop_data()`](reference/load_crop_data.md) | Load built-in dataset |
| 2 | [`prepare_trait_data()`](reference/prepare_trait_data.md) | Average replicates |
| 3 | [`compute_env_means()`](reference/compute_env_means.md) | Environmental means |
| 4 | [`run_CERIS()`](reference/run_CERIS.md) | Exhaustive window search |
| 5 | [`ceris_identify_best()`](reference/ceris_identify_best.md) | Find best window |
| 6 | [`slope_intercept()`](reference/slope_intercept.md) | Reaction norm parameters |
| 7 | [`jra_model()`](reference/jra_model.md) | Joint regression |
| 8 | [`cv_env()`](reference/cv_env.md) / [`cv_genotype()`](reference/cv_genotype.md) | Cross-validation |
| 9 | [`jgra()`](reference/jgra.md) / [`jgra_marker()`](reference/jgra_marker.md) | Genomic prediction |

## Built-in Datasets

``` r

data(crop_info)
crop_info[, c("crop", "n_envs", "traits", "has_genotype")]
#>      crop n_envs      traits has_genotype
#> 1 sorghum      7 FTdap,FTgdd         TRUE
#> 2   maize     10       FT,PH         TRUE
#> 3    rice      9 FTdap,FTgdd         TRUE
#> 4     oat     13 FTdap,PH,GY        FALSE
```

## Shiny Application

Launch the interactive analysis interface:

``` r

run_app()
```

## Vignettes

Detailed tutorials are available as package vignettes:

- [Getting Started](articles/getting-started.md)
- [Data Exploration](articles/data-exploration.md)
- [CERIS Search](articles/ceris-search.md)
- [Reaction Norms](articles/reaction-norms.md)
- [Joint Regression Analysis](articles/jra.md)
- [Cross-Validation](articles/cross-validation.md)
- [Genomic Prediction](articles/genomic-prediction.md)
- [Multi-Crop Examples](articles/multi-crop-examples.md)
- [Shiny App Guide](articles/shiny-app.md)

## References

The CERIS-JGRA methodology was developed by the scientists in
[Dr. Jianming Yu’s
lab](https://www.agron.iastate.edu/people/yu-jianming/) at Iowa State
University. Key publications:

- Li, X., Guo, T., Mu, Q., Li, X., & Yu, J. (2018). Genomic and
  environmental determinants and their interplay underlying phenotypic
  plasticity. *PNAS*, 115(26), 6679–6684.
  [doi:10.1073/pnas.1718326115](https://doi.org/10.1073/pnas.1718326115)

- Li, X., Guo, T., Wang, J., Bekele, W. A., Sukumaran, S., …, & Yu, J.
  (2021). An integrated framework reinstating the environmental
  dimension for GWAS and genomic selection in crops. *Molecular Plant*,
  14(6), 874–887.
  [doi:10.1016/j.molp.2021.03.010](https://doi.org/10.1016/j.molp.2021.03.010)

- Mu, Q., Guo, T., Li, X., & Yu, J. (2022). Phenotypic plasticity in
  plant height shaped by interaction between genetic loci and diurnal
  temperature range. *New Phytologist*, 233(4), 1768–1779.
  [doi:10.1111/nph.17904](https://doi.org/10.1111/nph.17904)

- Guo, T., Wei, J., Li, X., & Yu, J. (2024). Environmental context of
  phenotypic plasticity in flowering time in sorghum and rice. *Journal
  of Experimental Botany*, 75(3), 1004–1015.
  [doi:10.1093/jxb/erad398](https://doi.org/10.1093/jxb/erad398)

- Tibbs-Cortes, L. E., Guo, T., Li, X., & Yu, J. (2024). Comprehensive
  identification of genomic and environmental determinants of phenotypic
  plasticity in maize. *Genome Research*, 34(8), 1253–1265.
  [doi:10.1101/gr.279131.124](https://doi.org/10.1101/gr.279131.124)

- Wei, J., Guo, T., Mu, Q., …, & Yu, J. (2025). Genetic and
  environmental patterns underlying phenotypic plasticity in flowering
  time and plant height in sorghum. *Plant, Cell & Environment*, 48(4),
  1994–2009. [doi:10.1111/pce.15213](https://doi.org/10.1111/pce.15213)

## License

GPL-3
