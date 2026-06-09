library(httptest2)

# Helper to get result from main fixture
get_tbtn_result <- function() {
  get_raw_siri_vm(
    api_key      = "REDACTED",
    min_lat      = 52.70,
    max_lat      = 52.95,
    min_lon      = -1.75,
    max_lon      = -1.45,
    operator_ref = "TBTN"
  )
}

get_empty_result <- function() {
  get_raw_siri_vm(
    api_key = "REDACTED",
    min_lat = 52.80,
    max_lat = 52.90,
    min_lon = 1.60,
    max_lon = 1.70
  )
}

test_that("parse_siri_vm returns a tibble with correct columns", {
  with_mock_api({
    vehicles <- parse_siri_vm(get_tbtn_result())
    expect_s3_class(vehicles, "tbl_df")
    expect_named(vehicles, c(
      "operator_ref", "line_ref", "published_line_name", "direction",
      "origin_ref", "origin_name", "destination_ref", "destination_name",
      "origin_aimed_departure_time", "destination_aimed_arrival_time",
      "dated_vehicle_journey_ref", "latitude", "longitude", "bearing",
      "occupancy", "vehicle_ref", "recorded_at", "valid_until_time",
      "age_at_fetch_seconds", "age_seconds"
    ))
  })
})

test_that("parse_siri_vm returns correct column types", {
  with_mock_api({
    vehicles <- parse_siri_vm(get_tbtn_result())
    expect_type(vehicles$operator_ref,              "character")
    expect_type(vehicles$latitude,                  "double")
    expect_type(vehicles$longitude,                 "double")
    expect_type(vehicles$bearing,                   "double")
    expect_type(vehicles$age_at_fetch_seconds,      "double")
    expect_type(vehicles$age_seconds,               "double")
    expect_s3_class(vehicles$recorded_at,           "POSIXct")
    expect_s3_class(vehicles$valid_until_time,      "POSIXct")
    expect_s3_class(vehicles$origin_aimed_departure_time, "POSIXct")
  })
})

test_that("parse_siri_vm returns at least one row for non-empty feed", {
  with_mock_api({
    vehicles <- parse_siri_vm(get_tbtn_result())
    expect_gt(nrow(vehicles), 0)
  })
})

test_that("age_at_fetch_seconds is less than or equal to age_seconds", {
  with_mock_api({
    vehicles <- parse_siri_vm(get_tbtn_result())
    expect_true(all(
      vehicles$age_at_fetch_seconds <= vehicles$age_seconds,
      na.rm = TRUE
    ))
  })
})

test_that("parse_siri_vm returns empty tibble with correct columns when no vehicles", {
  with_mock_api({
    vehicles <- parse_siri_vm(get_empty_result())
    expect_s3_class(vehicles, "tbl_df")
    expect_equal(nrow(vehicles), 0)
  })
})

test_that("parse_siri_vm handles NA bearing and occupancy without error", {
  with_mock_api({
    vehicles <- parse_siri_vm(get_tbtn_result())
    expect_type(vehicles$bearing,   "double")
    expect_type(vehicles$occupancy, "character")
    # NA values are acceptable — just confirm no error thrown
  })
})
