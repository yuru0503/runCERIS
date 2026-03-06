#' @keywords internal
"_PACKAGE"

#' @import patchwork
#' @importFrom stats cor cor.test lm predict aggregate median coef prcomp residuals
#' @importFrom utils read.table write.table
#' @importFrom grDevices rgb
NULL

# Global variables used in ggplot2 aes() via .data pronoun
utils::globalVariables(".data")
