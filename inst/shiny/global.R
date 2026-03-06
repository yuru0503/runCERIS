library(runCERIS)
library(shiny)
library(bslib)
library(ggplot2)
library(patchwork)
library(DT)

# Source all module files
mod_dir <- file.path(dirname(sys.frame(1)$ofile %||% "."), "R")
if (dir.exists(mod_dir)) {
  for (f in list.files(mod_dir, pattern = "\\.R$", full.names = TRUE)) {
    source(f, local = TRUE)
  }
}

# CERIS theme for plots
ceris_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

theme_set(ceris_theme)
