#' Load GTFS data for a region
#'
#' Returns a tidytransit object for the specified region. Downloads the GTFS
#' zip from BODS if no valid cache exists, then loads and caches the result
#' as an RDS file for fast subsequent access. On repeated calls, the cached
#' RDS is returned directly without re-reading the zip.
#'
#' @param region A string. Defaults to `"east_midlands"`.
#' @param download Logical. If `TRUE`, forces a fresh download of the zip
#'   regardless of cache state. Defaults to `FALSE`.
#'
#' @return A tidytransit object (list of tibbles).
#' @export
#'
#' @examples
#' \dontrun{
#' gtfs <- gtfs_load("east_midlands")
#' }
gtfs_load <- function(region = "east_midlands", download = FALSE) {

  gtfs_validate_region(region)

  zip_path <- file.path(gtfs_cache_dir(), paste0(region, ".zip"))
  rds_path <- file.path(gtfs_cache_dir(), paste0(region, ".rds"))

  # Step 1: download if forced, missing, or stale
  if (download || !file.exists(zip_path) || gtfs_is_stale(region)) {
    gtfs_download(region)
    # Remove stale RDS so it is regenerated from the fresh zip
    if (file.exists(rds_path)) {
      file.remove(rds_path)
      cli::cli_inform(c("i" = "Removed stale RDS cache for {.val {region}}."))
    }
  }

  # Step 2: return RDS if it exists and loads cleanly
  if (file.exists(rds_path)) {
    gtfs <- tryCatch(
      readRDS(rds_path),
      error = function(e) {
        cli::cli_warn(c(
          "!" = "Cached RDS for {.val {region}} could not be read: {e$message}",
          "i" = "Falling back to reading the GTFS zip."
        ))
        NULL
      }
    )
    if (!is.null(gtfs)) {
      return(gtfs)
    }
  }

  # Step 3: read zip, save RDS, return
  cli::cli_inform(c("i" = "Reading GTFS zip for {.val {region}}. This may take a moment."))
  gtfs <- tidytransit::read_gtfs(zip_path)
  saveRDS(gtfs, rds_path)
  cli::cli_inform(c("v" = "GTFS data cached to {.path {rds_path}}."))

  gtfs
}
