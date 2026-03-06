mod_reaction_norm_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(12, 6, 6),
    card(
      card_header("Slope/Intercept Results"),
      DTOutput(ns("table"))
    ),
    card(
      card_header("Reaction Norm Lines"),
      plotOutput(ns("slope_plot"), height = "400px")
    ),
    card(
      card_header("R-squared Distribution"),
      plotOutput(ns("r2_hist"), height = "400px")
    )
  )
}

mod_reaction_norm_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    observe({
      req(shared$exp_trait, shared$env_mean_trait, shared$best_window)
      req("kPara" %in% names(shared$env_mean_trait))

      shared$slope_intercept_result <- slope_intercept(
        shared$exp_trait, shared$env_mean_trait, type = "both"
      )
    })

    output$table <- renderDT({
      req(shared$slope_intercept_result)
      datatable(shared$slope_intercept_result,
                options = list(pageLength = 10, scrollX = TRUE))
    })

    output$slope_plot <- renderPlot({
      req(shared$slope_intercept_result, shared$exp_trait, shared$env_mean_trait)
      exp_merged <- merge(shared$exp_trait,
                           shared$env_mean_trait[, c("env_code", "meanY", "kPara")],
                           by = "env_code")
      plot_slope_intercept(exp_merged, shared$slope_intercept_result,
                            shared$trait_name,
                            shared$best_window$param_name)
    })

    output$r2_hist <- renderPlot({
      req(shared$slope_intercept_result)
      if ("R2_para" %in% names(shared$slope_intercept_result)) {
        ggplot(shared$slope_intercept_result,
               aes(x = as.numeric(R2_para))) +
          geom_histogram(bins = 20, fill = "steelblue", color = "white") +
          labs(x = expression(R^2), y = "Count", title = "Parameter R-squared")
      }
    })
  })
}
