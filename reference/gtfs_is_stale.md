# Check whether the cached GTFS data for a region is stale

Returns `TRUE` if no cached feed info exists for the region, or if the
feed's `feed_end_date` has passed. Used internally to determine whether
a fresh download is needed.

## Usage

``` r
gtfs_is_stale(region = "east_midlands")
```

## Arguments

- region:

  A string. Defaults to `"east_midlands"`.

## Value

Logical. `TRUE` if the cache is missing or expired, `FALSE` otherwise.
