# runCERIS

R package implementing the **C**ritical **E**nvironmental **R**egressor through **I**nformed **S**earch (CERIS) framework for dissecting genotype-by-environment (G×E) interaction in multi-environment trials (MET). Provides an exhaustive window-scanning algorithm to identify critical developmental periods where environmental covariates maximally explain G×E variance, coupled with Joint Regression Analysis (JRA), reaction norm–based genomic prediction (JGRA), and three cross-validation schemes.

## Stack

- **Language**: R (>= 4.1.0), base R only (no tidyverse)
- **Visualization**: `ggplot2` + `patchwork` (composite figures), `pheatmap` (dendrogram heatmaps), `colorspace` (perceptually uniform HCL palettes)
- **Genomic prediction**: `rrBLUP` (G-BLUP via ridge regression), optional `BGLR` (BayesB variable selection)
- **Interactive**: Shiny GUI (`inst/shiny/`) with modular architecture
- **Documentation**: `roxygen2` inline docs, `pkgdown` site (`docs/`), 10 vignettes
- **Testing**: `testthat` (edition 3)

## Architecture

```
R/                          # Package source
├── prepare_data.R          # Phenotype extraction, replicate averaging, line×env matrix,
│                           #   window-aggregated env covariates, genotype matrix orientation
├── data.R                  # Roxygen documentation for 4 crop datasets (sorghum/maize/rice/oat)
├── compile_envirome.R      # Compile per-environment daily climate files into unified data.frame
├── fetch_nasa_power.R      # Retrieve daily meteorological records via NASA POWER API
├── run_CERIS.R          # Core CERIS: exhaustive pairwise DAP window scan, Pearson r + -log10(P)
├── ceris_identify_best.R   # Extract optimal window and parameter from CERIS output
├── ceris_loo_cor.R         # Leave-one-environment-out correlation for CERIS (median/mean summary)
├── jra_model.R             # Finlay–Wilkinson Joint Regression (per-genotype slope & intercept on env mean)
├── slope_intercept.R       # Reaction norm regression on arbitrary env covariate (kPara)
├── jgra.R                  # Joint Genomic Regression Analysis — predict reaction norm
│                           #   intercept + slope from SNP markers (RM.E / RM.G / RM.GE)
├── jgra_marker.R           # Extract per-marker effects from JGRA for downstream QTL mapping
├── loocv.R                 # Per-genotype leave-one-env-out CV (envMean vs kPara predictors)
├── forecast.R              # Temporal forecasting: train on year t, predict year t+1
├── cv_env.R                # CV-1: leave-one-environment-out prediction accuracy
├── cv_genotype.R           # CV-2: k-fold genotype cross-validation
├── cv_combined.R           # CV-3: simultaneous leave-env + leave-genotype-out
├── pred_rrblup.R           # G-BLUP via rrBLUP::mixed.solve() with mean imputation
├── pred_bayesb.R           # BayesB via BGLR::BGLR() with MCMC sampling
├── solve_gp.R              # Unified genomic prediction dispatcher (rrBLUP / BayesB)
├── plot_*.R                # 12 publication-quality plot functions (scatter, heatmap, biplot, etc.)
├── utils_colors.R          # Palettes: ceris_diverge_palette(), ceris_env_palette(), grey/violet alpha
├── utils_data.R            # load_crop_data(), validate_input_data()
├── run_app.R               # Shiny app launcher
└── ceris-package.R         # Package-level @import / @importFrom declarations

inst/shiny/                 # Interactive Shiny application
├── app.R                   # UI + server bootstrap
├── global.R                # Shared configuration
└── R/                      # Modular UI/server pairs
    ├── mod_data_upload.R   # File upload & bundled dataset selection
    ├── mod_data_explore.R  # Exploratory data summary & distribution plots
    ├── mod_reaction_norm.R # Reaction norm visualization (4-panel)
    ├── mod_ceris.R         # CERIS search with real-time progress
    ├── mod_jra.R           # Joint Regression Analysis interface
    ├── mod_jgra.R          # Genomic reaction norm prediction
    ├── mod_cv.R            # Cross-validation scenario comparison
    └── mod_visualization.R # General-purpose plotting interface

data/                       # Bundled .rda datasets (LazyData, xz-compressed)
vignettes/                  # 10 Rmd vignettes covering full analytical workflow
tests/testthat/             # Unit tests for core algorithms
docs/                       # pkgdown site (GitHub Pages deployment)
```

## Key Patterns

- **Analytical pipeline**: `load_crop_data()` → `prepare_trait_data()` → `compute_env_means()` → `compute_window_params()` → analysis (`run_CERIS`, `jra_model`, `jgra`, `loocv`, `cv_*`) → `plot_*()` visualization
- **Canonical column names**: `line_code` (genotype ID), `env_code` (environment ID), `Yobs` (observed phenotype), `meanY` (environment mean ȳ_j), `kPara` (best environmental covariate), `DAP` (days after planting)
- **CERIS algorithm**: O(n²) exhaustive scan over all (DAP_start, DAP_end) pairs where window ≥ 7 days; computes Pearson *r* and −log₁₀(*P*) between window-aggregated covariate and ȳ_j for each environmental parameter
- **Reaction norm model**: y_ij = α_i + β_i × h_j + ε_ij, where h_j is the environmental covariate (either ȳ_j for JRA or kPara for CERIS-informed regression)
- **JGRA**: predicts α̂_i and β̂_i from SNP markers via G-BLUP or BayesB; three validation schemes — `RM.E` (environment LOO), `RM.G` (genotype k-fold), `RM.GE` (combined)
- **Genomic prediction**: `solve_gp()` dispatches to `rrBLUP::mixed.solve()` (closed-form) or `BGLR::BGLR()` (MCMC); missing markers imputed to column mean
- **Progress callbacks**: computationally intensive functions accept `progress = function(fraction)` for Shiny progress bar integration
- **Composite figures**: multi-panel plots use `patchwork` operators (`+` horizontal, `/` vertical, `wrap_plots()`)

## Coding Rules

- All `ggplot2` calls use explicit namespace (`ggplot2::ggplot`, `ggplot2::geom_*`) — no `@import ggplot2`
- Tidy evaluation: `.data$col` pronoun in `aes()`; `utils::globalVariables(".data")` declared in `ceris-package.R`
- `patchwork` is the sole `@import`; all other dependencies use `@importFrom`
- Plot theme: `theme_minimal()` base with `base_size` 10–12
- Color palettes centralized in `utils_colors.R`: `ceris_diverge_palette()` (blue–white–red), `ceris_env_palette()` (rainbow HCL)
- Pure base R data manipulation throughout (`merge`, `aggregate`, `for`, `matrix`); no dplyr/tidyr
- Bundled datasets: `.rda` format, `LazyData: true`, xz compression, 4 crops × {traits, env_meta, env_params, genotype}
- Shiny modules: `mod_<name>_ui(id)` / `mod_<name>_server(id, ...)` convention
- Roxygen examples: `\donttest{}` for computationally expensive, `\dontrun{}` for interactive-only

## Commands

```bash
# Build & check
R CMD build .                    # Build source tarball
R CMD check runCERIS_*.tar.gz    # Full R CMD check (CRAN-style)
devtools::test()                 # Run testthat suite
devtools::document()             # Regenerate NAMESPACE + man/ from roxygen2
pkgdown::build_site()            # Rebuild documentation website

# Interactive usage
library(runCERIS)
d <- load_crop_data("sorghum")   # Available: sorghum, maize, rice, oat
run_app()                        # Launch Shiny GUI

# Typical scripted workflow
exp_trait <- prepare_trait_data(d$traits, "FTdap")
env_mean  <- compute_env_means(exp_trait, d$env_meta)
result    <- run_CERIS(env_mean, d$env_params, c("DL","GDD","PTT","PTR","PTS"))
best      <- ceris_identify_best(result)
```
