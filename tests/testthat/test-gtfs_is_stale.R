test_that("gtfs_is_stale returns TRUE when feed_info.json does not exist", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      expect_true(gtfs_is_stale("east_midlands"))
    }
  )
})

test_that("gtfs_is_stale returns FALSE when feed is still valid", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

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
      expect_false(gtfs_is_stale("east_midlands"))
    }
  )
})

test_that("gtfs_is_stale returns TRUE when feed has expired", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

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

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      expect_true(gtfs_is_stale("east_midlands"))
    }
  )
})

test_that("gtfs_is_stale returns TRUE when feed_end_date is missing", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  feed_info <- data.frame(
    feed_publisher_name = "Test",
    feed_publisher_url  = "https://example.com",
    feed_lang           = "en"
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
      expect_true(gtfs_is_stale("east_midlands"))
    }
  )
})

test_that("gtfs_is_stale rejects invalid regions", {
  expect_error(gtfs_is_stale("narnia"), class = "rlang_error")
})
