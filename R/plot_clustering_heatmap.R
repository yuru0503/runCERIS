#' Clustering Heatmap of Environmental Parameters
#'
#' Creates a heatmap with hierarchical clustering of environments based on
#' environmental parameters using pheatmap.
#'
#' @param env_params Data.frame with env_code, DAP, and parameter columns
#' @param params Character vector of parameter names to include
#' @param scale_data Logical; whether to scale parameters (default TRUE)
#' @return A pheatmap object (also plots)
#' @export
#' @examples
#' d <- load_crop_data("sorghum")
#' params <- c("DL", "GDD", "PTT", "PTR", "PTS")
#' plot_clustering_heatmap(d$env_params, params)
plot_clustering_heatmap <- function(env_params, params, scale_data = TRUE) {
  # Aggregate per environment
  env_agg <- aggregate(env_params[, params], by = list(env_code = env_params$env_code),
                       FUN = mean, na.rm = TRUE)
  mat <- as.matrix(env_agg[, params])
  rownames(mat) <- env_agg$env_code

  if (scale_data) {
    mat <- scale(mat)
  }

  pheatmap::pheatmap(
    mat,
    clustering_distance_rows = "euclidean",
    clustering_distance_cols = "euclidean",
    clustering_method = "complete",
    color = colorspace::diverge_hcl(50, h = c(260, 0), c = 100, l = c(50, 90)),
    main = "Environment Clustering by Parameters",
    fontsize_row = 10,
    fontsize_col = 10
  )
}
