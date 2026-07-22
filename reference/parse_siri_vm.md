# Parse a SIRI-VM XML response into a tidy data frame

Takes the raw `xml_document` returned by
[`get_raw_siri_vm()`](https://aptemus.github.io/bodsr2/reference/get_raw_siri_vm.md)
and extracts vehicle activity records into a tidy tibble. One row per
vehicle.

## Usage

``` r
parse_siri_vm(result)
```

## Arguments

- result:

  A named list as returned by
  [`get_raw_siri_vm()`](https://aptemus.github.io/bodsr2/reference/get_raw_siri_vm.md),
  containing elements `xml` (the raw SIRI-VM response) and `fetched_at`
  (the fetch timestamp).

## Value

A tibble with one row per vehicle activity record, containing the
following columns:

- operator_ref:

  National Operator Code (NOC)

- line_ref:

  Line reference as published in the feed

- published_line_name:

  Human-readable line name

- direction:

  Direction of travel: `"inbound"` or `"outbound"`

- origin_ref:

  ATCO code of the origin stop

- origin_name:

  Name of the origin stop

- destination_ref:

  ATCO code of the destination stop

- destination_name:

  Name of the destination stop

- origin_aimed_departure_time:

  Scheduled departure time from origin as `POSIXct`, `NA` if not
  published

- destination_aimed_arrival_time:

  Scheduled arrival time at destination as `POSIXct`, `NA` if not
  published

- dated_vehicle_journey_ref:

  Journey identifier, useful for tracking a specific journey across
  multiple calls

- latitude:

  Vehicle latitude as numeric

- longitude:

  Vehicle longitude as numeric

- bearing:

  Vehicle bearing in degrees as numeric, `NA` if not published

- occupancy:

  Passenger occupancy level as reported by the operator, `NA` if not
  published

- vehicle_ref:

  Vehicle reference - format varies by operator

- recorded_at:

  Time the vehicle position was recorded as `POSIXct`

- valid_until_time:

  Time until which this record is considered valid, as `POSIXct`

- age_at_fetch_seconds:

  Seconds elapsed between `recorded_at` and the time the feed was
  fetched. Reflects the freshness of the operator's AVL feed at the
  point of retrieval.

- age_seconds:

  Seconds elapsed between `recorded_at` and the time `parse_siri_vm()`
  was called. Use this for application logic such as deciding whether to
  display or dim a vehicle marker.

## Details

Note that field availability varies by operator. Fields such as
`bearing`, `occupancy`, and `destination_aimed_arrival_time` are
optional in the SIRI-VM standard and will be `NA` where not published.
Wales is not covered by the BODS statutory requirement and Welsh
operators are unlikely to appear in results.

## Examples

``` r
if (FALSE) { # \dontrun{
xml <- get_raw_siri_vm(
  api_key      = Sys.getenv("BODS_KEY"),
  min_lat      = 52.70,
  min_lon      = -1.75,
  max_lat      = 52.95,
  max_lon      = -1.45,
  operator_ref = "TBTN"
)
vehicles <- parse_siri_vm(xml)
} # }
```
