mod_ceris_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      title = "CERIS Search",
      numericInput(ns("max_days"), "Max DAP:", value = 120, min = 20, max = 300),
      checkboxInput(ns("loo"), "Leave-One-Out CV", value = FALSE),
      conditionalPanel(
        condition = paste0("input['", ns("loo"), "']"),
        selectInput(ns("loo_summary"), "LOO Summary:",
                    choices = c("median (robust)" = "median",
                                "mean" = "mean"))
      ),
      actionButton(ns("run"), "Run CERIS Search", class = "btn-primary w-100"),
      hr(),
      h5("Best Window"),
      selectInput(ns("best_param"), "Parameter:", choices = NULL),
      numericInput(ns("dap_start"), "Window Start (DAP):", value = NA),
      numericInput(ns("dap_end"), "Window End (DAP):", value = NA),
      textOutput(ns("best_r")),
      actionButton(ns("apply"), "Apply Window", class = "btn-success w-100")
    ),
    card(
      card_header("CERIS Heatmap"),
      plotOutput(ns("heatmap"), height = "700px")
    ),
    card(
      card_header("Best Window: Trait vs Parameter"),
      plotOutput(ns("trait_param"), height = "350px")
    )
  )
}

mod_ceris_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(input$run, {
      req(shared$env_mean_trait, shared$env_params, shared$params)

      max_dap <- min(input$max_days, max(shared$env_params$DAP))

      withProgress(message = "Running CERIS search...", value = 0, {
        loo_fn <- if (!is.null(input$loo_summary) && input$loo_summary == "mean") {
          mean
        } else {
          median
        }
        shared$ceris_result <- ceris_search(
          shared$env_mean_trait, shared$env_params, shared$params,
          max_days = max_dap, loo = input$loo, loo_summary = loo_fn,
          progress = function(frac) setProgress(frac)
        )
      })

      # Auto-identify best window
      best <- ceris_identify_best(shared$ceris_result, shared$params)
      shared$best_window <- best

      updateSelectInput(session, "best_param", choices = shared$params,
                        selected = best$param_name)
      updateNumericInput(session, "dap_start", value = best$dap_start)
      updateNumericInput(session, "dap_end", value = best$dap_end)

      showNotification("CERIS search complete!", type = "message")
    })

    output$best_r <- renderText({
      req(shared$best_window)
      paste0("r = ", round(shared$best_window$correlation, 3))
    })

    observeEvent(input$apply, {
      req(shared$env_mean_trait, shared$env_params, input$best_param,
          input$dap_start, input$dap_end)

      shared$env_mean_trait <- compute_window_params(
        shared$env_mean_trait, shared$env_params,
        input$dap_start, input$dap_end, input$best_param
      )

      shared$best_window <- list(
        param_name = input$best_param,
        dap_start = input$dap_start,
        dap_end = input$dap_end
      )

      showNotification("Window applied! Proceed to Reaction Norm tab.", type = "message")
    })

    output$heatmap <- renderPlot({
      req(shared$ceris_result)
      plot_ceris_heatmap(shared$ceris_result, shared$params,
                         max(shared$env_params$DAP))
    })

    output$trait_param <- renderPlot({
      req(shared$env_mean_trait, "kPara" %in% names(shared$env_mean_trait))
      plot_trait_env_param(shared$env_mean_trait, shared$trait_name,
                           shared$best_window$param_name,
                           shared$best_window$dap_start,
                           shared$best_window$dap_end)
    })
  })
}
