library(httptest2)

test_that("get_raw_siri_vm returns a list with xml and fetched_at", {
  with_mock_api({
    result <- get_raw_siri_vm(
      api_key      = "REDACTED",
      min_lat      = 52.70,
      max_lat      = 52.95,
      min_lon      = -1.75,
      max_lon      = -1.45,
      operator_ref = "TBTN"
    )
    expect_type(result, "list")
    expect_named(result, c("xml", "fetched_at"))
    expect_s3_class(result$xml, "xml_document")
    expect_s3_class(result$fetched_at, "POSIXct")
  })
})

test_that("get_raw_siri_vm gives informative error for invalid bounding box", {
  with_mock_api({
    expect_error(
      get_raw_siri_vm(
        api_key      = "REDACTED",
        min_lat      = 52.70,
        max_lat      = 52.95,
        min_lon      = -999,
        max_lon      = -1.45,
        operator_ref = "TBTN"
      ),
      "400"
    )
  })
})

test_that("get_raw_siri_vm gives informative error for invalid api key", {
  with_mock_api({
    expect_error(
      get_raw_siri_vm(
        api_key      = "INVALID",
        min_lat      = 52.70,
        max_lat      = 52.95,
        min_lon      = -1.75,
        max_lon      = -1.45,
        operator_ref = "TBTN"
      ),
      "401"
    )
  })
})


test_that("get_raw_siri_vm returns valid result with no vehicles", {
  with_mock_api({
    result <- get_raw_siri_vm(
      api_key = "REDACTED",
      min_lat = 52.80,
      max_lat = 52.90,
      min_lon = 1.60,
      max_lon = 1.70
    )
    expect_type(result, "list")
    expect_named(result, c("xml", "fetched_at"))
  })
})

test_that("get_raw_siri_vm includes operator_ref in request URL", {
  with_mock_api({
    result <- get_raw_siri_vm(
      api_key      = "REDACTED",
      min_lat      = 52.70,
      max_lat      = 52.95,
      min_lon      = -1.75,
      max_lon      = -1.45,
      operator_ref = "TBTN"
    )
    # The fixture for this request must have operatorRef in its URL
    # If the parameter wasn't being sent, it would match a different fixture
    expect_s3_class(result$xml, "xml_document")
  })
})

test_that("get_raw_siri_vm() errors informatively on HTML response", {
  html_body <- charToRaw(
    "<html><body><h1>Service Unavailable</h1><p>Try again later.</p></body></html>"
  )

  mock_resp <- httr2::response(
    status_code = 200,
    headers = list("Content-Type" = "text/html; charset=utf-8"),
    body = html_body
  )

  with_mocked_bindings(
    req_perform = function(...) mock_resp,
    .package = "httr2",
    {
      expect_error(
        get_raw_siri_vm(api_key = "test_key"),
        class = "rlang_error"
      )
      expect_error(
        get_raw_siri_vm(api_key = "test_key"),
        regexp = "text/html"
      )
      expect_error(
        get_raw_siri_vm(api_key = "test_key"),
        regexp = "Service Unavailable"
      )
    }
  )
})
