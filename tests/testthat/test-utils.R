test_that("gtfs_validate_region accepts valid regions", {
  expect_invisible(gtfs_validate_region("east_midlands"))
  expect_equal(gtfs_validate_region("east_midlands"), "east_midlands")
  expect_invisible(gtfs_validate_region("yorkshire"))
  expect_invisible(gtfs_validate_region("london"))
})

test_that("gtfs_validate_region rejects invalid regions", {
  expect_error(gtfs_validate_region("midlands"), class = "rlang_error")
  expect_error(gtfs_validate_region("East_Midlands"), class = "rlang_error")
  expect_error(gtfs_validate_region(""), class = "rlang_error")
  expect_error(gtfs_validate_region("east midlands"), class = "rlang_error")
})
