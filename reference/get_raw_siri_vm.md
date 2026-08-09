# Get real-time vehicle locations from the BODS SIRI-VM API

Fetches live bus vehicle location data from the Bus Open Data Service in
SIRI-VM (XML) format.

## Usage

``` r
get_raw_siri_vm(
  api_key = Sys.getenv("BODS_KEY"),
  min_lat = NULL,
  min_lon = NULL,
  max_lat = NULL,
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

- min_lon:

  longitude of lower left corner of bounding box

- max_lat:

  latitude of upper right corner of bounding box

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

A named list with two elements:

- xml:

  An `xml_document` object containing the raw SIRI-VM response

- fetched_at:

  A `POSIXct` timestamp recording when the response was received

. Aborts if the request fails, if the API returns a non-2xx status, or
if the response body is not XML (for example, an HTML maintenance page).

## Examples

``` r
# All vehicles in a bounding box around South Derbyshire
xml <- get_raw_siri_vm(min_lat=52.70, min_lon=-1.75, max_lat=52.95, max_lon=-1.45)

# Filter to a specific operator
xml <- get_raw_siri_vm(
  min_lat=52.70, min_lon=-1.75, max_lat=52.95, max_lon=-1.45,
  operator_ref = "TBTN"
)
```
