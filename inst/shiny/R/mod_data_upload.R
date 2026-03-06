mod_data_upload_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      title = "Data Source",
      radioButtons(ns("source"), "Data source:",
                   choices = c("Example dataset" = "example", "Upload files" = "upload")),
      conditionalPanel(
        condition = paste0("input['", ns("source"), "'] == 'example'"),
        selectInput(ns("crop"), "Crop:", choices = c("Sorghum" = "sorghum",
                     "Maize" = "maize", "Rice" = "rice", "Oat" = "oat")),
        uiOutput(ns("trait_ui"))
      ),
      conditionalPanel(
        condition = paste0("input['", ns("source"), "'] == 'upload'"),
        fileInput(ns("traits_file"), "Traits file (.txt)", accept = ".txt"),
        fileInput(ns("env_meta_file"), "Env metadata file (.txt)", accept = ".txt"),
        fileInput(ns("env_params_file"), "Env parameters file (.txt)", accept = ".txt"),
        fileInput(ns("geno_file"), "Genotype file (.txt, optional)", accept = ".txt"),
        textInput(ns("upload_trait"), "Trait column name:", value = "FTdap")
      ),
      actionButton(ns("load"), "Load Data", class = "btn-primary w-100")
    ),
    card(
      card_header("Data Preview"),
      navset_tab(
        nav_panel("Traits", DTOutput(ns("traits_table"))),
        nav_panel("Env Metadata", DTOutput(ns("env_meta_table"))),
        nav_panel("Env Parameters", DTOutput(ns("env_params_table"))),
        nav_panel("Summary", verbatimTextOutput(ns("summary")))
      )
    )
  )
}

mod_data_upload_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$trait_ui <- renderUI({
      req(input$crop)
      data("crop_info", package = "runCERIS", envir = environment())
      info <- crop_info[crop_info$crop == input$crop, ]
      traits <- strsplit(info$traits, ",")[[1]]
      selectInput(ns("trait"), "Trait:", choices = traits,
                  selected = info$default_trait)
    })

    observeEvent(input$load, {
      withProgress(message = "Loading data...", {
        if (input$source == "example") {
          req(input$crop, input$trait)
          crop_data <- load_crop_data(input$crop)
          shared$traits <- crop_data$traits
          shared$env_meta <- crop_data$env_meta
          shared$env_params <- crop_data$env_params
          shared$genotype <- crop_data$genotype
          shared$trait_name <- input$trait
        } else {
          req(input$traits_file, input$env_meta_file, input$env_params_file)
          shared$traits <- read.table(input$traits_file$datapath, header = TRUE,
                                       sep = "\t", stringsAsFactors = FALSE)
          shared$env_meta <- read.table(input$env_meta_file$datapath, header = TRUE,
                                         sep = "\t", stringsAsFactors = FALSE)
          shared$env_params <- read.table(input$env_params_file$datapath, header = TRUE,
                                           sep = "\t", stringsAsFactors = FALSE)
          if (!is.null(input$geno_file)) {
            gdf <- read.table(input$geno_file$datapath, header = TRUE,
                               sep = "\t", stringsAsFactors = FALSE)
            rn <- gdf[[1]]
            shared$genotype <- as.matrix(gdf[, -1])
            rownames(shared$genotype) <- rn
          }
          shared$trait_name <- input$upload_trait
        }

        # Process data
        shared$exp_trait <- prepare_trait_data(shared$traits, shared$trait_name)
        shared$env_mean_trait <- compute_env_means(shared$exp_trait, shared$env_meta)
        shared$line_by_env <- prepare_line_by_env(shared$exp_trait, shared$env_mean_trait)
        shared$line_codes <- unique(shared$exp_trait$line_code)
        shared$all_env_codes <- unique(shared$exp_trait$env_code)
        param_exclude <- c("env_code", "DAP", "date")
        shared$params <- setdiff(names(shared$env_params), param_exclude)
      })

      showNotification("Data loaded successfully!", type = "message")
    })

    output$traits_table <- renderDT({
      req(shared$traits)
      datatable(head(shared$traits, 100), options = list(pageLength = 10, scrollX = TRUE))
    })

    output$env_meta_table <- renderDT({
      req(shared$env_meta)
      datatable(shared$env_meta, options = list(pageLength = 20, scrollX = TRUE))
    })

    output$env_params_table <- renderDT({
      req(shared$env_params)
      datatable(head(shared$env_params, 100), options = list(pageLength = 10, scrollX = TRUE))
    })

    output$summary <- renderPrint({
      req(shared$exp_trait)
      cat("Trait:", shared$trait_name, "\n")
      cat("Environments:", length(shared$all_env_codes), "\n")
      cat("Lines:", length(shared$line_codes), "\n")
      cat("Observations:", nrow(shared$exp_trait), "\n")
      cat("Env parameters:", paste(shared$params, collapse = ", "), "\n")
      cat("Max DAP:", max(shared$env_params$DAP), "\n")
      cat("Genotype data:", ifelse(is.null(shared$genotype), "No", "Yes"), "\n")
    })
  })
}
