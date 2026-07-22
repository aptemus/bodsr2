test_that("gtfs_delete_cache removes all cached files for a region", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Create dummy cached files
  file.create(file.path(tmp, "east_midlands.zip"))
  file.create(file.path(tmp, "east_midlands_feed_info.json"))
  file.create(file.path(tmp, "east_midlands.rds"))

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      suppressMessages(gtfs_delete_cache("east_midlands", confirm = FALSE))
      expect_false(file.exists(file.path(tmp, "east_midlands.zip")))
      expect_false(file.exists(file.path(tmp, "east_midlands_feed_info.json")))
      expect_false(file.exists(file.path(tmp, "east_midlands.rds")))
    }
  )
})

test_that("gtfs_delete_cache returns invisibly the deleted file paths", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  file.create(file.path(tmp, "east_midlands.zip"))
  file.create(file.path(tmp, "east_midlands_feed_info.json"))
  file.create(file.path(tmp, "east_midlands.rds"))

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      result <- suppressMessages(gtfs_delete_cache("east_midlands", confirm = FALSE))
      expect_type(result, "character")
      expect_length(result, 3)
    }
  )
})

test_that("gtfs_delete_cache reports no files found when cache is empty", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      result <- suppressMessages(gtfs_delete_cache("east_midlands", confirm = FALSE))
      expect_length(result, 0)
    }
  )
})

test_that("gtfs_delete_cache does not delete files for other regions", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  file.create(file.path(tmp, "east_midlands.zip"))
  file.create(file.path(tmp, "yorkshire.zip"))

  with_mocked_bindings(
    gtfs_cache_dir = function() tmp,
    .package = "bodsr2",
    {
      suppressMessages(gtfs_delete_cache("east_midlands", confirm = FALSE))
      expect_false(file.exists(file.path(tmp, "east_midlands.zip")))
      expect_true(file.exists(file.path(tmp, "yorkshire.zip")))
    }
  )
})

test_that("gtfs_delete_cache rejects invalid regions", {
  expect_error(gtfs_delete_cache("narnia"), class = "rlang_error")
})
