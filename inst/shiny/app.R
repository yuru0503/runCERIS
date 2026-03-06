library(runCERIS)
library(shiny)
library(bslib)
library(ggplot2)
library(patchwork)
library(DT)

# Source modules
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  source(f, local = TRUE)
}

ui <- page_navbar(
  title = "CERIS",
  theme = bs_theme(bootswatch = "flatly", version = 5),
  nav_panel("Data", mod_data_upload_ui("data")),
  nav_panel("Explore", mod_data_explore_ui("explore")),
  nav_panel("CERIS Search", mod_ceris_ui("ceris")),
  nav_panel("Reaction Norm", mod_reaction_norm_ui("rn")),
  nav_panel("JRA", mod_jra_ui("jra")),
  nav_panel("Cross-Validation", mod_cv_ui("cv")),
  nav_panel("JGRA", mod_jgra_ui("jgra")),
  nav_panel("Visualization", mod_visualization_ui("viz"))
)

server <- function(input, output, session) {
  shared <- reactiveValues(
    traits = NULL, env_meta = NULL, env_params = NULL, genotype = NULL,
    trait_name = NULL, exp_trait = NULL, env_mean_trait = NULL,
    line_by_env = NULL, line_codes = NULL, all_env_codes = NULL,
    params = NULL, ceris_result = NULL, best_window = NULL,
    slope_intercept_result = NULL, jra_result = NULL
  )

  mod_data_upload_server("data", shared)
  mod_data_explore_server("explore", shared)
  mod_ceris_server("ceris", shared)
  mod_reaction_norm_server("rn", shared)
  mod_jra_server("jra", shared)
  mod_cv_server("cv", shared)
  mod_jgra_server("jgra", shared)
  mod_visualization_server("viz", shared)
}

shinyApp(ui, server)
