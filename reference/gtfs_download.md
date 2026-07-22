# Download GTFS data for a region from BODS

Downloads the GTFS zip file for the specified region from the Bus Open
Data Service and stores it in the bodsr2 cache directory. Also extracts
`feed_info.txt` and writes it as `{region}_feed_info.json` to the cache.

## Usage

``` r
gtfs_download(region = "east_midlands")
```

## Arguments

- region:

  A string. One of `"east_midlands"`, `"east_anglia"`, `"london"`,
  `"north_east"`, `"north_west"`, `"scotland"`, `"south_east"`,
  `"south_west"`, `"wales"`, `"west_midlands"`, `"yorkshire"`.

## Value

The path to the downloaded zip file, invisibly.
