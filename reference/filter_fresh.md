# Filter vehicle data by data age

Filters a tibble of vehicle activity records returned by
[`get_siri_vm()`](https://aptemus.github.io/bodsr2/reference/get_siri_vm.md)
or
[`parse_siri_vm()`](https://aptemus.github.io/bodsr2/reference/parse_siri_vm.md)
to remove stale records. This is important because the BODS feed can
contain vehicles whose position data is many hours old — these are ghost
buses that have finished their service but not been purged from the
feed.

## Usage

``` r
filter_fresh(vehicles, max_age_seconds = 300)
```

## Arguments

- vehicles:

  A tibble as returned by
  [`get_siri_vm()`](https://aptemus.github.io/bodsr2/reference/get_siri_vm.md)
  or
  [`parse_siri_vm()`](https://aptemus.github.io/bodsr2/reference/parse_siri_vm.md).

- max_age_seconds:

  Maximum age in seconds of the `age_at_fetch_seconds` column. Records
  older than this will be removed. Defaults to 300 seconds (5 minutes).
  The BODS feed can be polled no more than every 5 seconds, so values
  below 5 are unlikely to be useful.

## Value

A tibble with the same columns as the input, with stale records removed.

## Examples

``` r
# \donttest{
vehicles <- get_siri_vm(
  min_lat      = 52.70,
  max_lat      = 52.95,
  min_lon      = -1.75,
  max_lon      = -1.45,
  operator_ref = "TBTN"
)
#> Error in get_raw_siri_vm(api_key = api_key, min_lat = min_lat, max_lat = max_lat,     min_lon = min_lon, max_lon = max_lon, operator_ref = operator_ref,     line_ref = line_ref, vehicle_ref = vehicle_ref): No API key found. Set the `BODS_KEY` environment variable or pass
#> `api_key` directly.

# Keep only vehicles updated within the last 5 minutes (default)
fresh <- filter_fresh(vehicles)
#> Error: object 'vehicles' not found

# Keep only vehicles updated within the last 2 minutes
very_fresh <- filter_fresh(vehicles, max_age_seconds = 120)
#> Error: object 'vehicles' not found
# }
```
