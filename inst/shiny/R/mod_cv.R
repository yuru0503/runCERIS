mod_cv_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      title = "Cross-Validation Settings",
      numericInput(ns("gFold"), "Number of folds:", value = 5, min = 2, max = 20),
      numericInput(ns("gIteration"), "Iterations:", value = 1, min = 1, max = 10),
      checkboxGroupInput(ns("cv_types"), "CV Scenarios:",
                          choices = c("1-to-2 (Env LOO)" = "1to2",
                                      "1-to-3 (Genotype CV)" = "1to3",
                                      "1-to-4 (Combined)" = "1to4"),
                          selected = "1to2"),
      selectInput(ns("gp_method"), "GP Method:",
                  choices = c("rrBLUP (GBLUP)" = "rrBLUP",
                              "BayesB (BGLR)" = "BayesB")),
      conditionalPanel(
        condition = paste0("input['", ns("gp_method"), "'] == 'BayesB'"),
        numericInput(ns("nIter"), "MCMC Iterations:",
                     value = 5000, min = 1000, max = 50000),
        numericInput(ns("burnIn"), "Burn-in:",
                     value = 1000, min = 100, max = 10000)
      ),
      numericInput(ns("seed"), "Seed (optional):", value = NA, min = 1),
      helpText("GP method applies to 1-to-3 and 1-to-4 scenarios"),
      helpText("1-to-3 and 1-to-4 require genotype data"),
      actionButton(ns("run"), "Run Cross-Validation", class = "btn-primary w-100")
    ),
    card(
      card_header("CV Results"),
      plotOutput(ns("cv_plot"), height = "400px")
    ),
    card(
      card_header("Correlation Summary"),
      DTOutput(ns("cor_table"))
    )
  )
}

mod_cv_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    cv_results <- reactiveVal(NULL)

    observe({
      has_bglr <- requireNamespace("BGLR", quietly = TRUE)
      if (!has_bglr) {
        updateSelectInput(session, "gp_method",
                          choices = c("rrBLUP (GBLUP)" = "rrBLUP"))
      }
    })

    observeEvent(input$run, {
      req(shared$exp_trait, shared$env_mean_trait, shared$slope_intercept_result)
      req("kPara" %in% names(shared$env_mean_trait))

      seed_val <- if (!is.na(input$seed)) input$seed else NULL
      nIter_val <- if (!is.null(input$nIter)) input$nIter else 5000
      burnIn_val <- if (!is.null(input$burnIn)) input$burnIn else 1000

      results <- list()
      labels <- character(0)

      withProgress(message = "Running cross-validation...", value = 0, {
        if ("1to2" %in% input$cv_types) {
          incProgress(0.1, detail = "Running 1-to-2 CV...")
          results[[length(results) + 1]] <- cv_env(shared$env_mean_trait,
                                                    shared$exp_trait)
          labels <- c(labels, "1-to-2")
        }

        if ("1to3" %in% input$cv_types && !is.null(shared$genotype)) {
          incProgress(0.3, detail = "Running 1-to-3 CV...")
          results[[length(results) + 1]] <- cv_genotype(
            input$gFold, input$gIteration,
            shared$genotype, shared$slope_intercept_result,
            shared$env_mean_trait, shared$exp_trait,
            gp_method = input$gp_method,
            nIter = nIter_val, burnIn = burnIn_val, seed = seed_val
          )
          labels <- c(labels, "1-to-3")
        }

        if ("1to4" %in% input$cv_types && !is.null(shared$genotype)) {
          incProgress(0.5, detail = "Running 1-to-4 CV...")
          results[[length(results) + 1]] <- cv_combined(
            input$gFold, input$gIteration,
            shared$genotype, shared$env_mean_trait, shared$exp_trait,
            gp_method = input$gp_method,
            nIter = nIter_val, burnIn = burnIn_val, seed = seed_val
          )
          labels <- c(labels, "1-to-4")
        }
      })

      cv_results(list(results = results, labels = labels))
      showNotification("Cross-validation complete!", type = "message")
    })

    output$cv_plot <- renderPlot({
      req(cv_results())
      res <- cv_results()
      if (length(res$results) > 0) {
        plot_cv_results(res$results, res$labels)
      }
    })

    output$cor_table <- renderDT({
      req(cv_results())
      res <- cv_results()
      cors <- data.frame(
        Scenario = res$labels,
        Correlation = sapply(res$results, function(df) {
          d <- df[df$Rep == 1, ]
          round(cor(d$Yprd, d$Yobs, use = "complete.obs"), 3)
        }),
        N = sapply(res$results, function(df) {
          nrow(df[df$Rep == 1 & !is.na(df$Yobs), ])
        })
      )
      datatable(cors, options = list(dom = "t"))
    })
  })
}
