#' Download GTFS data for a region from BODS
#'
#' Downloads the GTFS zip file for the specified region from the Bus Open Data
#' Service and stores it in the bodsr2 cache directory. Also extracts
#' `feed_info.txt` and writes it as `{region}_feed_info.json` to the cache.
#'
#' @param region A string. One of `"east_midlands"`, `"east_anglia"`,
#'   `"london"`, `"north_east"`, `"north_west"`, `"scotland"`,
#'   `"south_east"`, `"south_west"`, `"wales"`, `"west_midlands"`,
#'   `"yorkshire"`.
#'
#' @return The path to the downloaded zip file, invisibly.
#'
#' @keywords internal
gtfs_download <- function(region = "east_midlands") {

  gtfs_validate_region(region)

  url      <- paste0("https://data.bus-data.dft.gov.uk/timetable/download/gtfs-file/", region, "/")
  zip_path <- file.path(gtfs_cache_dir(), paste0(region, ".zip"))
  fi_path  <- file.path(gtfs_cache_dir(), paste0(region, "_feed_info.json"))

  cli::cli_inform(c(
    "i" = "Downloading GTFS data for {.val {region}} from BODS.",
    "i" = "This file is large and may take a moment."
  ))

  resp <- httr2::request(url) |>
    httr2::req_timeout(300) |>
    httr2::req_user_agent("bodsr2 (https://github.com/aptemus/bodsr2)") |>
    httr2::req_perform()

  if (httr2::resp_is_error(resp)) {
    cli::cli_abort(c(
      "BODS GTFS download failed.",
      "x" = "Status {httr2::resp_status(resp)} returned for {.url {url}}."
    ))
  }

  writeBin(httr2::resp_body_raw(resp), zip_path)
  cli::cli_inform(c("v" = "Zip saved to {.path {zip_path}}."))

  # Check feed_info.txt is present in the zip
  zip_contents <- unzip(zip_path, list = TRUE)$Name
  if (!"feed_info.txt" %in% zip_contents) {
    cli::cli_abort(c(
      "x" = "Downloaded zip does not contain {.file feed_info.txt}.",
      "i" = "This does not appear to be a valid GTFS file."
    ))
  }

  # Extract feed_info.txt to a temp location and parse it
  tmp_dir <- tempdir()
  unzip(zip_path, files = "feed_info.txt", exdir = tmp_dir, overwrite = TRUE)
  feed_info <- utils::read.csv(file.path(tmp_dir, "feed_info.txt"),
                               stringsAsFactors = FALSE)

  # Convert dates to ISO 8601
  feed_info$feed_start_date <- format(
    as.Date(as.character(feed_info$feed_start_date), format = "%Y%m%d"),
    "%Y-%m-%d"
  )
  feed_info$feed_end_date <- format(
    as.Date(as.character(feed_info$feed_end_date), format = "%Y%m%d"),
    "%Y-%m-%d"
  )

  # Warn if feed has already expired
  if ("feed_end_date" %in% names(feed_info)) {
    end_date <- as.Date(feed_info$feed_end_date)
    if (!is.na(end_date) && end_date < Sys.Date()) {
      cli::cli_warn(c(
        "!" = "The downloaded GTFS feed for {.val {region}} expired on {.val {end_date}}.",
        "i" = "Data may be outdated. Check BODS for an updated feed."
      ))
    }
  }

  # Write feed_info to cache as JSON
  jsonlite::write_json(feed_info, fi_path, auto_unbox = TRUE)
  cli::cli_inform(c("v" = "Feed info written to {.path {fi_path}}."))

  invisible(zip_path)
}
