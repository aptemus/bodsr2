#' Parse a SIRI-VM XML response into a tidy data frame
#'
#' Takes the raw `xml_document` returned by [get_raw_siri_vm()] and extracts
#' vehicle activity records into a tidy tibble. One row per vehicle.
#'
#' Note that field availability varies by operator. Fields such as
#' `bearing`, `occupancy`, and `destination_aimed_arrival_time` are optional
#' in the SIRI-VM standard and will be `NA` where not published. Wales is not
#' covered by the BODS statutory requirement and Welsh operators are unlikely
#' to appear in results.
#'
#' @param result A named list as returned by [get_raw_siri_vm()], containing
#'   elements `xml` (the raw SIRI-VM response) and `fetched_at` (the fetch
#'   timestamp).
#'
#' @return A tibble with one row per vehicle activity record, containing
#'   the following columns:
#'   \describe{
#'     \item{operator_ref}{National Operator Code (NOC)}
#'     \item{line_ref}{Line reference as published in the feed}
#'     \item{published_line_name}{Human-readable line name}
#'     \item{direction}{Direction of travel: `"inbound"` or `"outbound"`}
#'     \item{origin_ref}{ATCO code of the origin stop}
#'     \item{origin_name}{Name of the origin stop}
#'     \item{destination_ref}{ATCO code of the destination stop}
#'     \item{destination_name}{Name of the destination stop}
#'     \item{origin_aimed_departure_time}{Scheduled departure time from origin as `POSIXct`, `NA` if not published}
#'     \item{destination_aimed_arrival_time}{Scheduled arrival time at destination as `POSIXct`, `NA` if not published}
#'     \item{dated_vehicle_journey_ref}{Journey identifier, useful for tracking a specific journey across multiple calls}
#'     \item{latitude}{Vehicle latitude as numeric}
#'     \item{longitude}{Vehicle longitude as numeric}
#'     \item{bearing}{Vehicle bearing in degrees as numeric, `NA` if not published}
#'     \item{occupancy}{Passenger occupancy level as reported by the operator, `NA` if not published}
#'     \item{vehicle_ref}{Vehicle reference - format varies by operator}
#'     \item{recorded_at}{Time the vehicle position was recorded as `POSIXct`}
#'     \item{valid_until_time}{Time until which this record is considered valid, as `POSIXct`}
#'     \item{age_at_fetch_seconds}{Seconds elapsed between `recorded_at` and the time the feed was fetched.
#'       Reflects the freshness of the operator's AVL feed at the point of retrieval.}
#'     \item{age_seconds}{Seconds elapsed between `recorded_at` and the time `parse_siri_vm()` was called.
#'       Use this for application logic such as deciding whether to display or dim a vehicle marker.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' xml <- get_raw_siri_vm(
#'   api_key      = Sys.getenv("BODS_KEY"),
#'   min_lat      = 52.70,
#'   min_lon      = -1.75,
#'   max_lat      = 52.95,
#'   max_lon      = -1.45,
#'   operator_ref = "TBTN"
#' )
#' vehicles <- parse_siri_vm(xml)
#' }
parse_siri_vm <- function(result) {

  xml        <- result$xml
  fetched_at <- result$fetched_at

  activities <- xml2::xml_find_all(xml, "//*[local-name()='VehicleActivity']")

  if (length(activities) == 0) {
    cli::cli_inform("No VehicleActivity nodes found in response - returning empty tibble.")
    return(tibble::tibble())
  }

  get_val <- function(node, field) {
    result <- xml2::xml_find_first(
      node,
      paste0(".//*[local-name()='", field, "']")
    )
    if (inherits(result, "xml_missing")) NA_character_ else xml2::xml_text(result)
  }

  parse_datetime <- function(x) {
    as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  }

  activities |>
    purrr::map(\(a) tibble::tibble(
      operator_ref                  = get_val(a, "OperatorRef"),
      line_ref                      = get_val(a, "LineRef"),
      published_line_name           = get_val(a, "PublishedLineName"),
      direction                     = get_val(a, "DirectionRef"),
      origin_ref                    = get_val(a, "OriginRef"),
      origin_name                   = get_val(a, "OriginName"),
      destination_ref               = get_val(a, "DestinationRef"),
      destination_name              = get_val(a, "DestinationName"),
      origin_aimed_departure_time   = get_val(a, "OriginAimedDepartureTime"),
      destination_aimed_arrival_time = get_val(a, "DestinationAimedArrivalTime"),
      dated_vehicle_journey_ref     = get_val(a, "DatedVehicleJourneyRef"),
      latitude                      = get_val(a, "Latitude"),
      longitude                     = get_val(a, "Longitude"),
      bearing                       = get_val(a, "Bearing"),
      occupancy                     = get_val(a, "Occupancy"),
      vehicle_ref                   = get_val(a, "VehicleRef"),
      recorded_at                   = get_val(a, "RecordedAtTime"),
      valid_until_time              = get_val(a, "ValidUntilTime")
    )) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      latitude                       = as.numeric(latitude),
      longitude                      = as.numeric(longitude),
      bearing                        = as.numeric(bearing),
      origin_aimed_departure_time    = parse_datetime(origin_aimed_departure_time),
      destination_aimed_arrival_time = parse_datetime(destination_aimed_arrival_time),
      recorded_at                    = parse_datetime(recorded_at),
      valid_until_time               = parse_datetime(valid_until_time),
      age_at_fetch_seconds = as.numeric(
        difftime(fetched_at, recorded_at, units = "secs")
      ),
      age_seconds = as.numeric(
        difftime(as.POSIXct(Sys.time(), tz = "UTC"), recorded_at, units = "secs")
      )
    )
}
