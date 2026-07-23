#' Get real-time vehicle locations as a tidy data frame
#'
#' Fetches and parses live bus vehicle location data from the Bus Open Data
#' Service (BODS) SIRI-VM API, returning a tidy tibble. This is the primary
#' interface for most users. For access to the raw XML response, see
#' [get_raw_siri_vm()]. To parse a previously fetched response, see
#' [parse_siri_vm()].
#'
#' @inheritParams get_raw_siri_vm
#'
#' @return A tibble with one row per vehicle activity record. See
#'   [parse_siri_vm()] for a full description of columns.
#' @export
#'
#' @examplesIf nzchar(Sys.getenv("BODS_KEY")) || identical(Sys.getenv("IN_PKGDOWN"), "true")
#' # All vehicles in a bounding box around South Derbyshire
#' vehicles <- get_siri_vm(
#'   min_lat = 52.70,
#'   max_lat = 52.95,
#'   min_lon = -1.75,
#'   max_lon = -1.45
#' )
#'
#' # Filter to a specific operator
#' vehicles <- get_siri_vm(
#'   min_lat      = 52.70,
#'   max_lat      = 52.95,
#'   min_lon      = -1.75,
#'   max_lon      = -1.45,
#'   operator_ref = "TBTN"
#' )
get_siri_vm <- function(
    api_key      = Sys.getenv("BODS_KEY"),
    min_lat      = NULL,
    max_lat      = NULL,
    min_lon      = NULL,
    max_lon      = NULL,
    operator_ref = NULL,
    line_ref     = NULL,
    vehicle_ref  = NULL
) {

  # TODO: If BODS introduces bounding box size limits in future, add
  # validation here. Currently the API returns all vehicles in a single
  # response with no documented size restriction.

  # Validate bounding box values if provided
  if (!is.null(min_lat) || !is.null(max_lat) ||
      !is.null(min_lon) || !is.null(max_lon)) {

    if (is.null(min_lat) || is.null(max_lat) ||
        is.null(min_lon) || is.null(max_lon)) {
      cli::cli_abort(
        "All four bounding box parameters must be provided together: {.arg min_lat}, {.arg max_lat}, {.arg min_lon}, {.arg max_lon}."
      )
    }

    if (!is.numeric(min_lat) || !is.numeric(max_lat) ||
        !is.numeric(min_lon) || !is.numeric(max_lon)) {
      cli::cli_abort("Bounding box parameters must be numeric.")
    }

    if (min_lat < -90 || max_lat > 90) {
      cli::cli_abort(
        "Latitude values must be between -90 and 90. Got {.val {min_lat}} and {.val {max_lat}}."
      )
    }

    if (min_lon < -180 || max_lon > 180) {
      cli::cli_abort(
        "Longitude values must be between -180 and 180. Got {.val {min_lon}} and {.val {max_lon}}."
      )
    }

    if (min_lat >= max_lat) {
      cli::cli_abort(
        "{.arg min_lat} ({.val {min_lat}}) must be less than {.arg max_lat} ({.val {max_lat}})."
      )
    }

    if (min_lon >= max_lon) {
      cli::cli_abort(
        "{.arg min_lon} ({.val {min_lon}}) must be less than {.arg max_lon} ({.val {max_lon}})."
      )
    }
  }

  # Fetch and parse
  result <- get_raw_siri_vm(
    api_key      = api_key,
    min_lat      = min_lat,
    max_lat      = max_lat,
    min_lon      = min_lon,
    max_lon      = max_lon,
    operator_ref = operator_ref,
    line_ref     = line_ref,
    vehicle_ref  = vehicle_ref
  )

  vehicles <- parse_siri_vm(result)

  # Warn if operator_ref was supplied but no matching vehicles returned
  if (!is.null(operator_ref) && nrow(vehicles) > 0) {
    actual_operators <- unique(vehicles$operator_ref)
    if (!operator_ref %in% actual_operators) {
      cli::cli_warn(c(
        "!" = "No vehicles found for operator {.val {operator_ref}}.",
        "i" = "Operators present in this bounding box: {.val {actual_operators}}.",
        "i" = "Check the National Operator Code (NOC) is correct."
      ))
    }
  }

  vehicles
}
