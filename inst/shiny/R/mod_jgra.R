mod_jgra_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      title = "JGRA Settings",
      selectInput(ns("approach"), "Approach:",
                  choices = c("Reaction Norm" = "rn", "Marker Effects" = "marker")),
      selectInput(ns("method"), "Method:",
                  choices = c("RM.E (Env LOO)" = "RM.E",
                              "RM.G (Genotype CV)" = "RM.G",
                              "RM.GE (Combined)" = "RM.GE")),
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
      numericInput(ns("fold"), "Folds:", value = 5, min = 2, max = 20),
      numericInput(ns("reshuffle"), "Reshuffles:", value = 5, min = 1, max = 50),
      numericInput(ns("seed"), "Seed (optional):", value = NA, min = 1),
      helpText("Higher reshuffles = more accurate but slower"),
      actionButton(ns("run"), "Run JGRA", class = "btn-primary w-100")
    ),
    card(
      card_header("JGRA Prediction Results"),
      plotOutput(ns("pred_plot"), height = "400px")
    ),
    card(
      card_header("Correlation Summary"),
      layout_columns(
        col_widths = c(6, 6),
        card(card_header("Within-Environment"), DTOutput(ns("within_table"))),
        card(card_header("Across-Environment"), verbatimTextOutput(ns("across_text")))
      )
    )
  )
}

mod_jgra_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    jgra_result <- reactiveVal(NULL)

    observe({
      has_geno <- !is.null(shared$genotype)
      if (!has_geno) {
        updateSelectInput(session, "method",
                          choices = c("RM.E (Env LOO)" = "RM.E"))
      }
      has_bglr <- requireNamespace("BGLR", quietly = TRUE)
      if (!has_bglr) {
        updateSelectInput(session, "gp_method",
                          choices = c("rrBLUP (GBLUP)" = "rrBLUP"))
      }
    })

    observeEvent(input$run, {
      req(shared$line_by_env, shared$env_mean_trait, shared$env_params)
      req(!is.null(shared$genotype) || input$method == "RM.E")
      req("kPara" %in% names(shared$env_mean_trait))

      # Prepare envir data.frame
      envir_df <- shared$env_mean_trait[, c("env_code", "kPara")]

      withProgress(message = "Running JGRA...", value = 0, {
        fn <- if (input$approach == "rn") jgra else jgra_marker

        # Prepare pheno with env columns header
        pheno <- shared$line_by_env

        # Prepare geno
        geno <- NULL
        if (!is.null(shared$genotype)) {
          geno <- data.frame(line_code = rownames(shared$genotype),
                              shared$genotype, check.names = FALSE,
                              stringsAsFactors = FALSE)
        }

        seed_val <- if (!is.na(input$seed)) input$seed else NULL
        nIter_val <- if (!is.null(input$nIter)) input$nIter else 5000
        burnIn_val <- if (!is.null(input$burnIn)) input$burnIn else 1000

        result <- tryCatch(
          fn(pheno = pheno, geno = geno, envir = envir_df,
             enp = "kPara", env_meta = shared$env_mean_trait,
             method = input$method,
             gp_method = input$gp_method,
             nIter = nIter_val, burnIn = burnIn_val, seed = seed_val,
             fold = input$fold, reshuffle = input$reshuffle,
             progress = function(frac) setProgress(frac)),
          error = function(e) {
            showNotification(paste("Error:", e$message), type = "error")
            NULL
          }
        )

        jgra_result(result)
      })

      if (!is.null(jgra_result())) {
        showNotification("JGRA complete!", type = "message")
      }
    })

    output$pred_plot <- renderPlot({
      req(jgra_result())
      res <- jgra_result()
      df <- res$predictions
      df <- df[!is.na(df$obs) & !is.na(df$pre), ]
      r_val <- round(cor(df$obs, df$pre, use = "complete.obs"), 3)
      xy_lim <- range(c(df$obs, df$pre), na.rm = TRUE)

      ggplot(df, aes(x = pre, y = obs, color = envir)) +
        geom_point(alpha = 0.5, size = 1) +
        geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
        coord_cartesian(xlim = xy_lim, ylim = xy_lim) +
        annotate("text", x = mean(xy_lim), y = xy_lim[1],
                 label = paste0("r = ", r_val), size = 5) +
        labs(x = "Predicted", y = "Observed", color = "Environment")
    })

    output$within_table <- renderDT({
      req(jgra_result())
      res <- jgra_result()
      rw <- res$r_within
      if (is.matrix(rw)) {
        df <- data.frame(Environment = colnames(rw),
                          Mean_r = round(colMeans(rw, na.rm = TRUE), 3))
      } else {
        df <- rw
      }
      datatable(df, options = list(dom = "t"))
    })

    output$across_text <- renderPrint({
      req(jgra_result())
      res <- jgra_result()
      ra <- res$r_across
      if (length(ra) > 1) {
        cat("Mean r:", round(mean(ra, na.rm = TRUE), 3), "\n")
        cat("SD:", round(sd(ra, na.rm = TRUE), 3), "\n")
      } else {
        cat("r:", round(ra, 3), "\n")
      }
    })
  })
}
