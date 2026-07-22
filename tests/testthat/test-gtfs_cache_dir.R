test_that("gtfs_cache_dir returns a string", {
  expect_type(gtfs_cache_dir(), "character")
})

test_that("gtfs_cache_dir creates the directory if it doesn't exist", {
  expect_true(dir.exists(gtfs_cache_dir()))
})

test_that("gtfs_cache_dir returns the same path on repeated calls", {
  expect_equal(gtfs_cache_dir(), gtfs_cache_dir())
})
