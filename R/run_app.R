#' Launch the CERIS Shiny Application
#'
#' @param ... Arguments passed to \code{shiny::runApp}
#' @export
#' @examples
#' \dontrun{
#' run_app()
#' }
run_app <- function(...) {
  app_dir <- system.file("shiny", package = "runCERIS")
  if (app_dir == "") {
    stop("Could not find Shiny app directory. Try reinstalling `runCERIS`.")
  }
  shiny::runApp(app_dir, ...)
}
