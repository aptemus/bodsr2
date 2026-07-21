utils::globalVariables(c(
  "age_at_fetch_seconds",
  "bearing",
  "destination_aimed_arrival_time",
  "latitude",
  "longitude",
  "origin_aimed_departure_time",
  "recorded_at",
  "valid_until_time"
))

gtfs_valid_regions <- c(
  "east_midlands", "east_anglia", "london", "north_east", "north_west",
  "scotland", "south_east", "south_west", "wales", "west_midlands",
  "yorkshire"
)

gtfs_validate_region <- function(region) {
  if (!region %in% gtfs_valid_regions) {
    cli::cli_abort(c(
      "{.arg region} must be one of the known BODS region slugs.",
      "x" = "{.val {region}} is not recognised.",
      "i" = "Valid regions: {.val {gtfs_valid_regions}}"
    ))
  }

  invisible(region)
}
