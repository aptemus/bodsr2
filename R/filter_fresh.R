#' Filter vehicle data by data age
#'
#' Filters a tibble of vehicle activity records returned by [get_siri_vm()] or
#' [parse_siri_vm()] to remove stale records. This is important because the
#' BODS feed can contain vehicles whose position data is many hours old — these
#' are ghost buses that have finished their service but not been purged from
#' the feed.
#'
#' @param vehicles A tibble as returned by [get_siri_vm()] or [parse_siri_vm()].
#' @param max_age_seconds Maximum age in seconds of the `age_at_fetch_seconds`
#'   column. Records older than this will be removed. Defaults to 300 seconds
#'   (5 minutes). The BODS feed can be polled no more than every 5 seconds, so
#'   values below 5 are unlikely to be useful.
#'
#' @return A tibble with the same columns as the input, with stale records
#'   removed.
#' @export
#'
#' @examples
#' vehicles <- get_siri_vm(
#'   min_lat      = 52.70,
#'   max_lat      = 52.95,
#'   min_lon      = -1.75,
#'   max_lon      = -1.45,
#'   operator_ref = "TBTN"
#' )
#'
#' # Keep only vehicles updated within the last 5 minutes (default)
#' fresh <- filter_fresh(vehicles)
#'
#' # Keep only vehicles updated within the last 2 minutes
#' very_fresh <- filter_fresh(vehicles, max_age_seconds = 120)
filter_fresh <- function(vehicles, max_age_seconds = 300) {

  if (!is.numeric(max_age_seconds) || max_age_seconds <= 0) {
    cli::cli_abort(
      "{.arg max_age_seconds} must be a positive number. Got {.val {max_age_seconds}}."
    )
  }

  if (max_age_seconds < 5) {
    cli::cli_warn(
      c(
        "!" = "{.arg max_age_seconds} is set to {.val {max_age_seconds}} seconds.",
        "i" = "The BODS feed can be polled no more than every 5 seconds, so values below 5 are unlikely to be useful."
      )
    )
  }

  if (!"age_at_fetch_seconds" %in% names(vehicles)) {
    cli::cli_abort(
      "Input does not contain an {.col age_at_fetch_seconds} column. Did you pass a tibble from {.fn get_siri_vm} or {.fn parse_siri_vm}?"
    )
  }

  dplyr::filter(vehicles, age_at_fetch_seconds <= max_age_seconds)
}
