# bodsr2

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/aptemus/bodsr2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/aptemus/bodsr2/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

An R package for accessing the [Bus Open Data Service (BODS)](https://data.bus-data.dft.gov.uk/) API, built on [httr2](https://httr2.r-lib.org/). It provides functions to retrieve real-time vehicle location data in SIRI-VM format and returns tidy data frames suitable for use with the tidyverse.

`bodsr2` was inspired by [bodsr](https://cran.r-project.org/package=bodsr) by Francesca Bryden (Department for Transport). It extends that work with an httr2-based implementation, tidy tibble output, and improved parameter handling.

> **Note:** This package was developed with AI assistance (Claude by Anthropic).

## Status

This is a personal hobby project, developed primarily for my own use and released in case others find it useful. It is not under active maintenance — issues and PRs are welcome but I cannot commit to addressing them promptly. If you're building something that depends on this package, please fork it.

## Installation

You can install the development version of bodsr2 from GitHub:

```r
# install.packages("remotes")
remotes::install_github("aptemus/bodsr2")
```

## Getting started

You will need a free API key from the [Bus Open Data Service](https://data.bus-data.dft.gov.uk/account/signup/). Once registered, add your key to your `.Renviron` file:

```r
BODS_KEY=your-api-key-here
```

Then restart R. `bodsr2` will use this key by default.

## Example

```r
library(bodsr2)
library(dplyr)
library(mapview)
library(sf)

# Fetch live vehicle locations for a bounding box around South Derbyshire
# and filter to Trent Barton vehicles updated within the last 10 minutes
vehicles <- get_siri_vm(
  min_lat      = 52.70,
  max_lat      = 52.95,
  min_lon      = -1.75,
  max_lon      = -1.45,
  operator_ref = "TBTN"
) |>
  filter_fresh(max_age_seconds = 600)

# Filter to Burton-bound services and visualise
vehicles |>
  filter(grepl("Burton", destination_name)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |>
  mapview(zcol = "published_line_name")
```

## Key functions

**Primary interface**

| Function | Description |
|---|---|
| `get_siri_vm()` | Fetch and parse live vehicle locations into a tidy tibble |
| `filter_fresh()` | Remove stale records from the BODS feed |

**Utility functions**

| Function | Description |
|---|---|
| `get_raw_siri_vm()` | Fetch the raw SIRI-VM XML response |
| `parse_siri_vm()` | Parse a raw SIRI-VM response into a tidy tibble |

## Notes on the BODS feed

- The BODS API covers bus services in **England only**. Welsh and Scottish operators are not included.
- The feed may contain **ghost buses** — vehicles whose position data is many hours old. Use `filter_fresh()` to remove these.
- An unknown `operator_ref` is silently ignored by the API, which returns all vehicles in the bounding box instead. `get_siri_vm()` will warn if the supplied operator code does not appear in the results.
- The BODS consumer rate limit is one request per 5 seconds.
- Field availability varies by operator. `bearing`, `occupancy`, and `destination_aimed_arrival_time` are optional in the SIRI-VM standard and will be `NA` where not published.

## Acknowledgements

Thanks to the [Department for Transport](https://www.gov.uk/government/organisations/department-for-transport) 
and the [Bus Open Data Service](https://data.bus-data.dft.gov.uk/) team for building and maintaining 
a genuinely useful open API, and to Francesca Bryden for the original 
[bodsr](https://cran.r-project.org/package=bodsr) package which inspired this one.

## Getting help

- [File an issue](https://github.com/aptemus/bodsr2/issues)
- Contact: dev@antonberry.dev
