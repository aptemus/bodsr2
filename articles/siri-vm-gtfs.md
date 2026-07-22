# Combining real-time location data with timetable data using bodsr2

``` r

library(bodsr2)
```

## Introduction

This vignette demonstrates how to combine a live SIRI-VM position from
[`get_siri_vm()`](https://aptemus.github.io/bodsr2/reference/get_siri_vm.md)
with GTFS timetable data loaded via
[`gtfs_load()`](https://aptemus.github.io/bodsr2/reference/gtfs_load.md)
to place a bus precisely on its route — identifying which stop it is
nearest to, what the next stop is, and whether it is running on time.

This kind of analysis requires both data sources. SIRI-VM gives us the
live position and the timetabled departure time from the origin stop.
GTFS gives us the full stop sequence and scheduled times for every trip.
Neither is sufficient alone.

If you are unfamiliar with the GTFS data model, the [tidytransit
introduction
vignette](https://r-transit.github.io/tidytransit/articles/introduction.html)
covers it well. This vignette assumes that background.

Note that the approach shown here involves multiple table joins and a
distance calculation for each vehicle on every poll. This is fine for
tracking a small number of vehicles on known routes, but scales poorly
to hundreds of vehicles — which is one reason bodsr2 is not suited to
city-wide real-time tracking.

## A live SIRI-VM ping

We start by fetching live positions for the V1 Villager service (Trent
Barton, Burton upon Trent to Derby):

``` r

library(bodsr2)
library(dplyr)
library(lubridate)

buses <- get_siri_vm(
  operator_ref = "TBTN",
  line_ref     = "vil"
) |>
  filter_fresh(max_age_seconds = 600)
```

Each row in the result represents one vehicle. The fields we need for
GTFS resolution are:

``` r

bus <- buses[1, ]

bus |> select(origin_ref, origin_aimed_departure_time,
              latitude, longitude, direction)
#> # A tibble: 1 × 5
#>   origin_ref origin_aimed_departure_time latitude longitude direction
#>   <chr>      <dttm>                         <dbl>     <dbl> <chr>
#> 1 1090BSTN04 2026-07-21 13:05:00            52.874    -1.679 outbound
```

- `origin_ref` is the ATCO stop code for the departure stop — Derby Bus
  Station Bay 4 in this case, which is also a `stop_id` in GTFS
- `origin_aimed_departure_time` is the timetabled departure time in UTC
- `latitude` and `longitude` are the vehicle’s current position

## Loading GTFS data

``` r

gtfs <- gtfs_load("east_midlands")
```

See the [BODS GTFS caching
vignette](https://aptemus.github.io/bodsr2/articles/bods-gtfs-caching.md)
for details on how the caching layer works.

## Resolving the ping to a GTFS trip

SIRI-VM’s `dated_vehicle_journey_ref` field does not map directly to any
GTFS identifier. Instead, we resolve the trip by joining on origin stop
and departure time, then narrowing to the service running on today’s
date.

First, convert the UTC departure time to local time, since GTFS stores
departure times in local clock time:

``` r

dep_local <- hms::as_hms(format(
  with_tz(bus$origin_aimed_departure_time, "Europe/London"),
  "%H:%M:%S"
))

dep_date <- as.Date(with_tz(bus$origin_aimed_departure_time, "Europe/London"))
day_col  <- tolower(as.character(wday(dep_date, label = TRUE, abbr = FALSE)))

dep_local
#> 14:05:00
dep_date
#> [1] "2026-07-21"
day_col
#> [1] "monday"
```

Find candidate trips departing from the origin stop at this time:

``` r

candidates <- gtfs$stop_times |>
  filter(
    stop_id        == bus$origin_ref,
    departure_time == dep_local
  ) |>
  group_by(trip_id) |>
  filter(stop_sequence == min(stop_sequence)) |>
  ungroup()

nrow(candidates)
#> [1] 3
```

Three candidates — one per service pattern (weekday, Saturday, Sunday).
Narrow to the trip running on today’s date using the calendar tables:

``` r

active_services <- gtfs$calendar |>
  filter(
    .data[[day_col]] == 1,
    as.Date(start_date) <= dep_date,
    as.Date(end_date)   >= dep_date
  ) |>
  pull(service_id)

# Apply calendar_dates exceptions
cancelled <- gtfs$calendar_dates |>
  filter(as.Date(date) == dep_date, exception_type == 2) |>
  pull(service_id)

added <- gtfs$calendar_dates |>
  filter(as.Date(date) == dep_date, exception_type == 1) |>
  pull(service_id)

active_services <- union(setdiff(active_services, cancelled), added)

trip <- gtfs$trips |>
  filter(
    trip_id    %in% candidates$trip_id,
    service_id %in% active_services
  )

trip |> select(trip_id, trip_headsign, direction_id)
#> # A tibble: 1 × 3
#>   trip_id                                  trip_headsign direction_id
#>   <chr>                                    <chr>                <int>
#> 1 VJa02d83251371dbf1e4278cd05269c635c25416 Burton                   0
```

One trip resolved. In a production application you would pre-compute all
active trips at startup rather than performing these joins on every
poll.

## Building the stop sequence

Retrieve all stops for this trip with their coordinates and timetabled
departure times:

``` r

trip_stops <- gtfs$stop_times |>
  filter(trip_id == trip$trip_id) |>
  arrange(stop_sequence) |>
  select(stop_sequence, stop_id, departure_time) |>
  left_join(
    gtfs$stops |> select(stop_id, stop_name, stop_lat, stop_lon),
    by = "stop_id"
  )

nrow(trip_stops)
#> [1] 77
```

77 stops from Derby Bus Station to Burton Market Place.

## Finding the nearest stop

A simple haversine distance calculation finds the nearest stop to the
vehicle’s current position:

``` r

haversine <- function(lat1, lon1, lat2, lon2) {
  r <- 6371000
  p <- pi / 180
  a <- sin((lat2 - lat1) * p / 2)^2 +
       cos(lat1 * p) * cos(lat2 * p) * sin((lon2 - lon1) * p / 2)^2
  2 * r * asin(sqrt(a))
}

trip_stops <- trip_stops |>
  mutate(dist_m = haversine(bus$latitude, bus$longitude, stop_lat, stop_lon))

nearest <- trip_stops |> slice_min(dist_m, n = 1)

nearest |> select(stop_sequence, stop_name, dist_m)
#> # A tibble: 1 × 3
#>   stop_sequence stop_name    dist_m
#>           <int> <chr>         <dbl>
#> 1            40 Balmoral Way   32.8
```

The bus is at stop 40 of 77, near Balmoral Way in Hatton, 33 metres from
the stop.

## What is the next stop?

``` r

next_stop <- trip_stops |>
  filter(stop_sequence == nearest$stop_sequence + 1)

next_stop |> select(stop_sequence, stop_name, departure_time)
#> # A tibble: 1 × 3
#>   stop_sequence stop_name  departure_time
#>           <int> <chr>      <time>
#> 1            41 Lime Grove 14:42:00
```

The next stop is Lime Grove, timetabled at 14:42.

## Is the bus on time?

The timetabled departure from the origin stop is in `trip_stops`.
Comparing it to `origin_aimed_departure_time` from the SIRI-VM ping
gives us the delay:

``` r

origin_timetabled <- trip_stops |>
  filter(stop_sequence == min(stop_sequence)) |>
  pull(departure_time)

actual_departure <- hms::as_hms(format(
  with_tz(bus$origin_aimed_departure_time, "Europe/London"),
  "%H:%M:%S"
))

delay_mins <- as.numeric(actual_departure - origin_timetabled, units = "mins")

cat("Delay:", delay_mins, "minutes\n")
#> Delay: 0 minutes
```

This bus departed on time. A positive value indicates the bus left late;
a negative value indicates it left early — which does happen on some
services, particularly on later evening departures.
