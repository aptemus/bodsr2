# Delete cached GTFS data for a region

Deletes all cached GTFS files for the specified region, including the
zip file, feed info JSON, and the cached RDS file. Use this to force a
fresh download or to clean up files downloaded for testing.

## Usage

``` r
gtfs_delete_cache(region = "east_midlands", confirm = TRUE)
```

## Arguments

- region:

  A string. The region whose cache files should be deleted. Defaults to
  `"east_midlands"`.

- confirm:

  Logical. If `TRUE` (the default), prompts for confirmation before
  deleting. Set to `FALSE` to delete without prompting.

## Value

Invisibly returns the paths of the deleted files.

## Examples

``` r
gtfs_delete_cache("east_midlands")
```
