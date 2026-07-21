#' Get the bodsr2 cache directory
#'
#' Returns the path to the bodsr2 user cache directory, creating it if it
#' does not already exist. The location is determined by
#' [tools::R_user_dir()] and will be platform-appropriate (e.g.
#' `~/Library/Caches/org.R-project.R/R/bodsr2` on macOS).
#'
#' @return A string giving the path to the cache directory.
#' @export
#'
#' @examples
#' gtfs_cache_dir()
gtfs_cache_dir <- function() {
  path <- tools::R_user_dir("bodsr2", which = "cache")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}
