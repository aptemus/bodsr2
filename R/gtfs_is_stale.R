#' Check whether the cached GTFS data for a region is stale
#'
#' Returns `TRUE` if no cached feed info exists for the region, or if the
#' feed's `feed_end_date` has passed. Used internally to determine whether
#' a fresh download is needed.
#'
#' @param region A string. Defaults to `"east_midlands"`.
#'
#' @return Logical. `TRUE` if the cache is missing or expired, `FALSE` otherwise.
#' @export
gtfs_is_stale <- function(region = "east_midlands") {

  gtfs_validate_region(region)

  fi_path <- file.path(gtfs_cache_dir(), paste0(region, "_feed_info.json"))

  if (!file.exists(fi_path)) {
    return(TRUE)
  }

  feed_info <- jsonlite::read_json(fi_path, simplifyVector = TRUE)

  if (!"feed_end_date" %in% names(feed_info)) {
    return(TRUE)
  }

  end_date <- as.Date(feed_info$feed_end_date)

  if (is.na(end_date)) {
    return(TRUE)
  }

  Sys.Date() > end_date
}

