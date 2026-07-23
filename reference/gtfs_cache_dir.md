# Get the bodsr2 cache directory

Returns the path to the bodsr2 user cache directory, creating it if it
does not already exist. The location is determined by
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) and will
be platform-appropriate (e.g.
`~/Library/Caches/org.R-project.R/R/bodsr2` on macOS).

## Usage

``` r
gtfs_cache_dir()
```

## Value

A string giving the path to the cache directory.

## Examples

``` r
gtfs_cache_dir()
#> [1] "/home/runner/.cache/R/bodsr2"
```
