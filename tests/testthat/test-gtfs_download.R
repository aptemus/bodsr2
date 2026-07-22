library(httptest2)

# Helper to create a temporary cache directory and redirect gtfs_cache_dir to it
with_test_cache <- function(code) {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    code
  )
}

# Helper to copy the fixture zip into a temp cache dir
seed_cache <- function(cache_dir, region = "east_midlands") {
  fixture <- test_path("fixtures", paste0(region, ".zip"))
  file.copy(fixture, file.path(cache_dir, paste0(region, ".zip")))
}

# --- Validation -----------------------------------------------------------

test_that("gtfs_download rejects invalid regions", {
  expect_error(supressMessages(gtfs_download("narnia"), class = "rlang_error"))
  expect_error(supressMessages(gtfs_download("East_Midlands"), class = "rlang_error"))
})

# --- HTTP layer -----------------------------------------------------------

test_that("gtfs_download writes zip and feed_info json to cache", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  fixture_bytes <- readBin(
    test_path("fixtures", "east_midlands.zip"),
    what = "raw",
    n = file.size(test_path("fixtures", "east_midlands.zip"))
  )

  fake_response <- httr2::response(
    status_code = 200,
    headers = list("content-type" = "application/zip"),
    body = fixture_bytes
  )

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    with_mocked_bindings(
      req_perform = function(...) fake_response,
      .package = "httr2",
      {
        result <- suppressMessages(gtfs_download("east_midlands"))
        expect_true(file.exists(file.path(tmp, "east_midlands.zip")))
        expect_true(file.exists(file.path(tmp, "east_midlands_feed_info.json")))
        expect_equal(result, file.path(tmp, "east_midlands.zip"))
      }
    )
  )
})

# --- Processing layer -----------------------------------------------------

test_that("gtfs_download writes feed_info json with ISO 8601 dates", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  fixture_bytes <- readBin(
    test_path("fixtures", "east_midlands.zip"),
    what = "raw",
    n = file.size(test_path("fixtures", "east_midlands.zip"))
  )

  fake_response <- httr2::response(
    status_code = 200,
    headers = list("content-type" = "application/zip"),
    body = fixture_bytes
  )

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    with_mocked_bindings(
      req_perform = function(...) fake_response,
      .package = "httr2",
      {
        result <- suppressMessages(gtfs_download("east_midlands"))
        expect_true(file.exists(file.path(tmp, "east_midlands.zip")))
        expect_true(file.exists(file.path(tmp, "east_midlands_feed_info.json")))
        expect_equal(result, file.path(tmp, "east_midlands.zip"))
      }
    )
  )
})

test_that("gtfs_download warns when feed has already expired", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  expired_feed <- "feed_publisher_name,feed_publisher_url,feed_lang,feed_start_date,feed_end_date
Test Publisher,https://example.com,en,20250101,20250601"
  tmp2 <- tempdir()
  writeLines(expired_feed, file.path(tmp2, "feed_info.txt"))
  expired_zip <- tempfile(fileext = ".zip")
  zip(expired_zip, files = file.path(tmp2, "feed_info.txt"), flags = "-j")

  fixture_bytes <- readBin(expired_zip, what = "raw",
                           n = file.size(expired_zip))

  fake_response <- httr2::response(
    status_code = 200,
    headers = list("content-type" = "application/zip"),
    body = fixture_bytes
  )

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    with_mocked_bindings(
      req_perform = function(...) fake_response,
      .package = "httr2",
      {
        expect_warning(
          suppressMessages(gtfs_download("east_midlands")),
          class = "rlang_warning"
        )
      }
    )
  )
})
