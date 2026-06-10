# Helper - minimal vehicles tibble
make_vehicles <- function(ages) {
  tibble::tibble(
    vehicle_ref          = paste0("V", seq_along(ages)),
    age_at_fetch_seconds = ages,
    age_seconds          = ages + 5
  )
}

test_that("filter_fresh removes stale records", {
  vehicles <- make_vehicles(c(30, 150, 400, 700))
  result   <- filter_fresh(vehicles)
  expect_equal(nrow(result), 2)
  expect_true(all(result$age_at_fetch_seconds <= 300))
})

test_that("filter_fresh keeps all records when all are fresh", {
  vehicles <- make_vehicles(c(10, 20, 30))
  result   <- filter_fresh(vehicles)
  expect_equal(nrow(result), 3)
})

test_that("filter_fresh returns empty tibble when all are stale", {
  vehicles <- make_vehicles(c(600, 700, 800))
  result   <- filter_fresh(vehicles)
  expect_equal(nrow(result), 0)
})

test_that("filter_fresh respects custom max_age_seconds", {
  vehicles <- make_vehicles(c(30, 150, 400))
  result   <- filter_fresh(vehicles, max_age_seconds = 100)
  expect_equal(nrow(result), 1)
})

test_that("filter_fresh errors on non-positive max_age_seconds", {
  vehicles <- make_vehicles(c(30, 150))
  expect_error(filter_fresh(vehicles, max_age_seconds = -1), "positive")
  expect_error(filter_fresh(vehicles, max_age_seconds = 0),  "positive")
})

test_that("filter_fresh warns when max_age_seconds is below 5", {
  vehicles <- make_vehicles(c(1, 2, 3))
  expect_warning(filter_fresh(vehicles, max_age_seconds = 3), "5 seconds")
})

test_that("filter_fresh errors when age_at_fetch_seconds column is missing", {
  vehicles <- tibble::tibble(vehicle_ref = "V1", age_seconds = 30)
  expect_error(filter_fresh(vehicles), "age_at_fetch_seconds")
})
