#' Delete cached GTFS data for a region
#'
#' Deletes all cached GTFS files for the specified region, including the zip
#' file, feed info JSON, and the cached RDS file. Use this to force a
#' fresh download or to clean up files downloaded for testing.
#'
#' @param region A string. The region whose cache files should be deleted.
#'   Defaults to `"east_midlands"`.
#' @param confirm Logical. If `TRUE` (the default), prompts for confirmation
#'   before deleting. Set to `FALSE` to delete without prompting.
#'
#' @return Invisibly returns the paths of the deleted files.
#' @export
#'
#' @examples
#' \dontrun{
#' gtfs_delete_cache("east_midlands")
#' }
gtfs_delete_cache <- function(region = "east_midlands", confirm = TRUE) {

  gtfs_validate_region(region)

  cache_dir <- gtfs_cache_dir()
  files <- list.files(cache_dir, pattern = paste0("^", region), full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform(c("i" = "No cached files found for {.val {region}}."))
    return(invisible(character(0)))
  }

  cli::cli_inform(c("i" = "The following files will be deleted:"))
  cli::cli_bullets(stats::setNames(basename(files), rep("*", length(files))))

  if (confirm) {
    response <- readline("Delete these files? (y/n): ")
    if (!tolower(trimws(response)) %in% c("y", "yes")) {
      cli::cli_inform(c("i" = "Deletion cancelled."))
      return(invisible(character(0)))
    }
  }

  file.remove(files)
  cli::cli_inform(c("v" = "Deleted {length(files)} file{?s} for {.val {region}}."))

  invisible(files)
}
