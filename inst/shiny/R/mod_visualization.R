mod_visualization_ui <- function(id) {
  ns <- NS(id)
  navset_card_tab(
    title = "Advanced Visualization",
    nav_panel("Environmental Factors",
      layout_sidebar(
        sidebar = sidebar(
          checkboxGroupInput(ns("env_params"), "Parameters to plot:",
                              choices = NULL, selected = NULL),
          width = 200
        ),
        plotOutput(ns("env_factors"), height = "500px")
      )
    ),
    nav_panel("PCA",
      plotOutput(ns("pca"), height = "500px")
    ),
    nav_panel("Clustering",
      plotOutput(ns("cluster"), height = "500px")
    )
  )
}

mod_visualization_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observe({
      req(shared$params)
      updateCheckboxGroupInput(session, "env_params",
                                choices = shared$params,
                                selected = shared$params[1:min(2, length(shared$params))])
    })

    output$env_factors <- renderPlot({
      req(shared$env_params, input$env_params)
      plot_env_factors(shared$env_params, input$env_params)
    })

    output$pca <- renderPlot({
      req(shared$env_params, shared$env_mean_trait, shared$params)
      plot_pca_biplot(shared$env_params, shared$env_mean_trait, shared$params)
    })

    output$cluster <- renderPlot({
      req(shared$env_params, shared$params)
      plot_clustering_heatmap(shared$env_params, shared$params)
    })
  })
}
