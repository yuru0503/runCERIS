mod_data_explore_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(6, 6, 12),
    card(
      card_header("Geographic Order"),
      plotOutput(ns("geo_order"), height = "400px")
    ),
    card(
      card_header("Environmental Means"),
      plotOutput(ns("env_means"), height = "400px")
    ),
    card(
      card_header("Reaction Norms"),
      plotOutput(ns("reaction_norm"), height = "600px")
    )
  )
}

mod_data_explore_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    output$geo_order <- renderPlot({
      req(shared$exp_trait, shared$env_mean_trait)
      if (!("lat" %in% names(shared$env_mean_trait))) return(NULL)
      plot_geo_order(shared$exp_trait, shared$env_mean_trait, shared$trait_name)
    })

    output$env_means <- renderPlot({
      req(shared$exp_trait, shared$env_mean_trait)
      plot_env_means(shared$exp_trait, shared$env_mean_trait, shared$trait_name)
    })

    output$reaction_norm <- renderPlot({
      req(shared$exp_trait, shared$env_mean_trait)
      plot_reaction_norm(shared$exp_trait, shared$env_mean_trait, shared$trait_name)
    })
  })
}
