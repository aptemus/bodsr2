# Load GTFS data for a region

Returns a tidytransit object for the specified region. Downloads the
GTFS zip from BODS if no valid cache exists, then loads and caches the
result as an RDS file for fast subsequent access. On repeated calls, the
cached RDS is returned directly without re-reading the zip.

## Usage

``` r
gtfs_load(region = "east_midlands", download = FALSE)
```

## Arguments

- region:

  A string. Defaults to `"east_midlands"`.

- download:

  Logical. If `TRUE`, forces a fresh download of the zip regardless of
  cache state. Defaults to `FALSE`.

## Value

A tidytransit object (list of tibbles).

## Examples

``` r
if (FALSE) { # \dontrun{
gtfs <- gtfs_load("east_midlands")
} # }
```
