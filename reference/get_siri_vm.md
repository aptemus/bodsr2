# Get real-time vehicle locations as a tidy data frame

Fetches and parses live bus vehicle location data from the Bus Open Data
Service (BODS) SIRI-VM API, returning a tidy tibble. This is the primary
interface for most users. For access to the raw XML response, see
[`get_raw_siri_vm()`](https://aptemus.github.io/bodsr2/reference/get_raw_siri_vm.md).
To parse a previously fetched response, see
[`parse_siri_vm()`](https://aptemus.github.io/bodsr2/reference/parse_siri_vm.md).

## Usage

``` r
get_siri_vm(
  api_key = Sys.getenv("BODS_KEY"),
  min_lat = NULL,
  max_lat = NULL,
  min_lon = NULL,
  max_lon = NULL,
  operator_ref = NULL,
  line_ref = NULL,
  vehicle_ref = NULL
)
```

## Arguments

- api_key:

  API key for the BODS dataset. Defaults to the value of the `BODS_KEY`
  environment variable.

- min_lat:

  latitude of lower left corner of bounding box Note that bounding box
  parameters are specified as latitude/longitude pairs (bottom left
  corner first, then top right), which follows the human geographic
  convention. Internally these are converted to the longitude-first.
  ordering required by the BODS API (following the GeoJSON convention).
  For large bounding boxes covering dense urban areas, consider also
  supplying `operator_ref` to reduce response size. The BODS API
  currently returns all matching vehicles in a single response with no
  pagination; the minimum poll interval is 5 seconds.

- max_lat:

  latitude of upper right corner of bounding box

- min_lon:

  longitude of lower left corner of bounding box

- max_lon:

  longitude of upper right corner of bounding box

- operator_ref:

  A string. National Operator Code (NOC) to filter results to a specific
  operator. Defaults to `NULL`.

- line_ref:

  A string. Line reference to filter results to a specific service.
  Defaults to `NULL`.

- vehicle_ref:

  A string. Vehicle reference to filter to a specific vehicle. Defaults
  to `NULL`.

## Value

A tibble with one row per vehicle activity record. See
[`parse_siri_vm()`](https://aptemus.github.io/bodsr2/reference/parse_siri_vm.md)
for a full description of columns.

## Examples

``` r
# All vehicles in a bounding box around South Derbyshire
vehicles <- get_siri_vm(
  min_lat = 52.70,
  max_lat = 52.95,
  min_lon = -1.75,
  max_lon = -1.45
)

# Filter to a specific operator
vehicles <- get_siri_vm(
  min_lat      = 52.70,
  max_lat      = 52.95,
  min_lon      = -1.75,
  max_lon      = -1.45,
  operator_ref = "TBTN"
)
```
