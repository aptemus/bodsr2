test_that("gtfs_load returns a tidytransit object from zip when no RDS exists", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  file.copy(
    test_path("fixtures", "east_midlands.zip"),
    file.path(tmp, "east_midlands.zip")
  )

  # Write a valid feed_info.json so gtfs_is_stale returns FALSE
  feed_info <- data.frame(
    feed_publisher_name = "Test",
    feed_publisher_url  = "https://example.com",
    feed_lang           = "en",
    feed_start_date     = format(Sys.Date() - 30, "%Y-%m-%d"),
    feed_end_date       = format(Sys.Date() + 365, "%Y-%m-%d")
  )
  jsonlite::write_json(
    feed_info,
    file.path(tmp, "east_midlands_feed_info.json"),
    auto_unbox = TRUE
  )

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      result <- suppressMessages(gtfs_load("east_midlands"))
      expect_s3_class(result, "tidygtfs")
      expect_true(file.exists(file.path(tmp, "east_midlands.rds")))
    }
  )
})

test_that("gtfs_load returns RDS on second call without re-reading zip", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  file.copy(
    test_path("fixtures", "east_midlands.zip"),
    file.path(tmp, "east_midlands.zip")
  )

  feed_info <- data.frame(
    feed_publisher_name = "Test",
    feed_publisher_url  = "https://example.com",
    feed_lang           = "en",
    feed_start_date     = format(Sys.Date() - 30, "%Y-%m-%d"),
    feed_end_date       = format(Sys.Date() + 365, "%Y-%m-%d")
  )
  jsonlite::write_json(
    feed_info,
    file.path(tmp, "east_midlands_feed_info.json"),
    auto_unbox = TRUE
  )

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      suppressMessages(gtfs_load("east_midlands"))

      # Second call should load from RDS — no "Reading GTFS zip" message
      expect_no_message(
        gtfs_load("east_midlands"),
        message = "Reading GTFS zip"
      )
    }
  )
})

test_that("gtfs_load falls back to zip if RDS is corrupt", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  file.copy(
    test_path("fixtures", "east_midlands.zip"),
    file.path(tmp, "east_midlands.zip")
  )

  feed_info <- data.frame(
    feed_publisher_name = "Test",
    feed_publisher_url  = "https://example.com",
    feed_lang           = "en",
    feed_start_date     = format(Sys.Date() - 30, "%Y-%m-%d"),
    feed_end_date       = format(Sys.Date() + 365, "%Y-%m-%d")
  )
  jsonlite::write_json(
    feed_info,
    file.path(tmp, "east_midlands_feed_info.json"),
    auto_unbox = TRUE
  )

  # Write a corrupt RDS
  writeLines("this is not an RDS file", file.path(tmp, "east_midlands.rds"))

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      expect_warning(
        result <- suppressMessages(gtfs_load("east_midlands")),
        class = "rlang_warning"
      )
      expect_s3_class(result, "tidygtfs")
    }
  )
})

test_that("gtfs_load deletes RDS and re-downloads when stale", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Write an expired feed_info.json
  feed_info <- data.frame(
    feed_publisher_name = "Test",
    feed_publisher_url  = "https://example.com",
    feed_lang           = "en",
    feed_start_date     = format(Sys.Date() - 60, "%Y-%m-%d"),
    feed_end_date       = format(Sys.Date() - 1, "%Y-%m-%d")
  )
  jsonlite::write_json(
    feed_info,
    file.path(tmp, "east_midlands_feed_info.json"),
    auto_unbox = TRUE
  )

  # Write a dummy RDS to confirm it gets deleted
  saveRDS(list(), file.path(tmp, "east_midlands.rds"))

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
        result <- suppressMessages(gtfs_load("east_midlands"))
        expect_s3_class(result, "tidygtfs")
        # RDS should have been regenerated from fresh zip
        expect_true(file.exists(file.path(tmp, "east_midlands.rds")))
      }
    )
  )
})

test_that("gtfs_load rejects invalid regions", {
  expect_error(gtfs_load("narnia"), class = "rlang_error")
})

test_that("gtfs_load re-downloads when download = TRUE even if cache is valid", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Write a valid feed_info.json — cache appears fresh
  feed_info <- data.frame(
    feed_publisher_name = "Test",
    feed_publisher_url  = "https://example.com",
    feed_lang           = "en",
    feed_start_date     = format(Sys.Date() - 30, "%Y-%m-%d"),
    feed_end_date       = format(Sys.Date() + 365, "%Y-%m-%d")
  )
  jsonlite::write_json(
    feed_info,
    file.path(tmp, "east_midlands_feed_info.json"),
    auto_unbox = TRUE
  )

  # Write a dummy RDS to confirm it gets deleted and regenerated
  saveRDS(list(), file.path(tmp, "east_midlands.rds"))

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
        result <- suppressMessages(gtfs_load("east_midlands", download = TRUE))
        expect_s3_class(result, "tidygtfs")
        # RDS should have been regenerated
        expect_true(file.exists(file.path(tmp, "east_midlands.rds")))
      }
    )
  )
})

test_that("gtfs_load downloads zip if it does not exist", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # No zip, no feed_info.json, no RDS — empty cache
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
        result <- suppressMessages(gtfs_load("east_midlands"))
        expect_s3_class(result, "tidygtfs")
        expect_true(file.exists(file.path(tmp, "east_midlands.zip")))
        expect_true(file.exists(file.path(tmp, "east_midlands.rds")))
      }
    )
  )
})
