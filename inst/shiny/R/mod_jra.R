mod_jra_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(12),
    card(
      card_header("Joint Regression Analysis"),
      plotOutput(ns("jra_plot"), height = "450px")
    ),
    card(
      card_header("JRA Results"),
      DTOutput(ns("jra_table"))
    )
  )
}

mod_jra_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    observe({
      req(shared$line_by_env, shared$env_mean_trait)
      shared$jra_result <- jra_model(shared$line_by_env, shared$env_mean_trait)
    })

    output$jra_plot <- renderPlot({
      req(shared$jra_result, shared$exp_trait, shared$env_mean_trait)
      plot_jra(shared$exp_trait, shared$env_mean_trait,
               shared$jra_result, shared$trait_name)
    })

    output$jra_table <- renderDT({
      req(shared$jra_result)
      datatable(shared$jra_result,
                options = list(pageLength = 10, scrollX = TRUE))
    })
  })
}
