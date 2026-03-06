#' Compile Daily Environmental Data into a Single Matrix
#'
#' Reads daily environmental files from a directory and combines them into a
#' single data.frame with a DAP (Days After Planting) column.
#'
#' @param env_dir Path to directory containing daily environment files
#'   named \code{<env_code>_daily.txt}
#' @param env_codes Character vector of environment codes
#' @return Data.frame with columns: env_code, DAP, and environmental parameters
#' @export
#' @examples
#' \dontrun{
#' env_params <- compile_envirome("path/to/env_files",
#'                                c("ENV01", "ENV02", "ENV03"))
#' head(env_params)
#' }
compile_envirome <- function(env_dir, env_codes) {
  dfs <- list()

  for (i in seq_along(env_codes)) {
    f <- file.path(env_dir, paste0(env_codes[i], "_daily.txt"))
    df <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
    param_cols <- setdiff(names(df), "env_code")
    df$DAP <- seq_len(nrow(df))
    dfs[[i]] <- df[, c("env_code", "DAP", param_cols)]
  }

  result <- do.call(rbind, dfs)
  rownames(result) <- NULL
  result
}
