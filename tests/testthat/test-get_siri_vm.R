library(httptest2)

test_that("get_siri_vm returns a tibble", {
  with_mock_api({
    vehicles <- get_siri_vm(
      api_key      = "REDACTED",
      min_lat      = 52.70,
      max_lat      = 52.95,
      min_lon      = -1.75,
      max_lon      = -1.45,
      operator_ref = "TBTN"
    )
    expect_s3_class(vehicles, "tbl_df")
    expect_gt(nrow(vehicles), 0)
  })
})

test_that("get_siri_vm returns empty tibble for empty feed", {
  with_mock_api({
    vehicles <- get_siri_vm(
      api_key = "REDACTED",
      min_lat = 52.80,
      max_lat = 52.90,
      min_lon = 1.60,
      max_lon = 1.70
    )
    expect_s3_class(vehicles, "tbl_df")
    expect_equal(nrow(vehicles), 0)
  })
})

test_that("get_siri_vm errors on impossible latitude", {
  expect_error(
    get_siri_vm(
      api_key = "REDACTED",
      min_lat = -91,
      max_lat = 52.95,
      min_lon = -1.75,
      max_lon = -1.45
    ),
    "Latitude"
  )
})

test_that("get_siri_vm errors on impossible longitude", {
  expect_error(
    get_siri_vm(
      api_key = "REDACTED",
      min_lat = 52.70,
      max_lat = 52.95,
      min_lon = -181,
      max_lon = -1.45
    ),
    "Longitude"
  )
})

test_that("get_siri_vm errors when min_lat >= max_lat", {
  expect_error(
    get_siri_vm(
      api_key = "REDACTED",
      min_lat = 52.95,
      max_lat = 52.70,
      min_lon = -1.75,
      max_lon = -1.45
    ),
    "min_lat"
  )
})

test_that("get_siri_vm errors when min_lon >= max_lon", {
  expect_error(
    get_siri_vm(
      api_key = "REDACTED",
      min_lat = 52.70,
      max_lat = 52.95,
      min_lon = -1.45,
      max_lon = -1.75
    ),
    "min_lon"
  )
})

test_that("get_siri_vm errors when only some bounding box params provided", {
  expect_error(
    get_siri_vm(
      api_key = "REDACTED",
      min_lat = 52.70,
      max_lat = 52.95
    ),
    "All four"
  )
})

test_that("get_siri_vm warns when operator_ref not found in results", {
  with_mock_api({
    expect_warning(
      get_siri_vm(
        api_key      = "REDACTED",
        min_lat      = 52.70,
        max_lat      = 52.95,
        min_lon      = -1.75,
        max_lon      = -1.45,
        operator_ref = "XXXX"
      ),
      "No vehicles found"
    )
  })
})
