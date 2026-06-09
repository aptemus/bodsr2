#' Get real-time vehicle locations from the BODS SIRI-VM API
#'
#' Fetches live bus vehicle location data from the Bus Open Data Service
#' in SIRI-VM (XML) format.
#'
#' @param api_key API key for the BODS dataset. Defaults to the value of
#'   the `BODS_KEY` environment variable.
#' @param min_lat latitude of lower left corner of bounding box
#'   Note that bounding box parameters are specified as latitude/longitude pairs
#'   (bottom left corner first, then top right), which follows the human
#'   geographic convention. Internally these are converted to the longitude-first.
#'   ordering required by the BODS API (following the GeoJSON convention).
#'   For large bounding boxes covering dense urban areas, consider also
#'   supplying \code{operator_ref} to reduce response size. The BODS API
#'   currently returns all matching vehicles in a single response with no
#'   pagination; the minimum poll interval is 5 seconds.
#' @param min_lon longitude of lower left corner of bounding box
#' @param max_lat latitude of upper right corner of bounding box
#' @param max_lon longitude of upper right corner of bounding box
#' @param operator_ref A string. National Operator Code (NOC) to filter results
#'   to a specific operator. Defaults to `NULL`.
#' @param line_ref A string. Line reference to filter results to a specific
#'   service. Defaults to `NULL`.
#' @param vehicle_ref A string. Vehicle reference to filter to a specific
#'   vehicle. Defaults to `NULL`.
#'
#' @return A named list with two elements:
#'   \describe{
#'     \item{xml}{An `xml_document` object containing the raw SIRI-VM response}
#'     \item{fetched_at}{A `POSIXct` timestamp recording when the response was received}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' # All vehicles in a bounding box around South Derbyshire
#' xml <- get_raw_siri_vm(min_lat=52.70, min_lon=-1.75, max_lat=52.95, max_lon=-1.45)
#'
#' # Filter to a specific operator
#' xml <- get_raw_siri_vm(
#'   min_lat=52.70, min_lon=-1.75, max_lat=52.95, max_lon=-1.45,
#'   operator_ref = "TBTN"
#' )
#' }
get_raw_siri_vm <- function(
    api_key      = Sys.getenv("BODS_KEY"),
    min_lat      = NULL,
    min_lon      = NULL,
    max_lat      = NULL,
    max_lon      = NULL,
    operator_ref = NULL,
    line_ref     = NULL,
    vehicle_ref  = NULL
) {

  if (api_key == "") {
    cli::cli_abort(
      "No API key found. Set the {.envvar BODS_KEY} environment variable or pass {.arg api_key} directly."
    )
  }



  req <- httr2::request("https://data.bus-data.dft.gov.uk/api/v1/datafeed/") |>
    httr2::req_url_query(api_key = api_key) |>
    httr2::req_timeout(15) |>
    httr2::req_user_agent("bodsr2 (https://github.com/aptemus/bodsr2)")

  if (!is.null(min_lat) && !is.null(max_lat) &&
      !is.null(min_lon) && !is.null(max_lon)) {
    bounding_box <- paste(min_lon, min_lat, max_lon, max_lat, sep = ",")
    req <- req |> httr2::req_url_query(boundingBox = bounding_box)
  }

  resp <- req |>
    httr2::req_error(is_error = \(resp) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_is_error(resp)) {
    # Try to extract BODS error description from XML response
    error_msg <- tryCatch({
      body <- httr2::resp_body_string(resp)
      desc <- regmatches(body, regexpr("(?<=<error_description>)[^<]+", body, perl = TRUE))
      if (length(desc) > 0) desc else "Unknown error"
    }, error = function(e) "Unknown error")

    cli::cli_abort(
      "BODS API request failed with status {httr2::resp_status(resp)}: {error_msg}"
    )
  }

  list(
    xml        = resp |> httr2::resp_body_xml(),
    fetched_at = as.POSIXct(Sys.time(), tz = "UTC")
  )
}
