#' CERIS diverging color palette for correlation heatmaps
#'
#' @param n Number of colors (default 26)
#' @return Character vector of hex colors
#' @export
#' @examples
#' pal <- ceris_diverge_palette(11)
#' length(pal)
ceris_diverge_palette <- function(n = 26L) {
  colorspace::diverge_hcl(n, h = c(260, 0), c = 100, l = c(50, 90), power = 1)
}

#' Environment color palette
#'
#' @param n_envs Number of environments
#' @return Character vector of hex colors with alpha
#' @export
#' @examples
#' colors <- ceris_env_palette(7)
#' length(colors)
ceris_env_palette <- function(n_envs) {
  colorspace::rainbow_hcl(n_envs, c = 80, l = 60, start = 0, end = 300,
                          fixup = TRUE, alpha = 0.75)
}

#' Semi-transparent grey for background data
#'
#' @return A single color string
#' @keywords internal
ceris_grey_alpha <- function() {
  rgb(128, 128, 128, alpha = 35, maxColorValue = 255)
}

#' Semi-transparent violet for IQR polygons
#'
#' @return A single color string
#' @keywords internal
ceris_poly_alpha <- function() {
  rgb(238, 130, 238, alpha = 55.5, maxColorValue = 255)
}
