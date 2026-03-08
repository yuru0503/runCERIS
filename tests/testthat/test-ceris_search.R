test_that("run_CERIS runs and returns correct structure", {
  data(sorghum_traits, package = "runCERIS")
  data(sorghum_env_meta, package = "runCERIS")
  data(sorghum_env_params, package = "runCERIS")

  exp_trait <- prepare_trait_data(sorghum_traits, "FTgdd")
  env_means <- compute_env_means(exp_trait, sorghum_env_meta)
  params <- setdiff(names(sorghum_env_params), c("env_code", "DAP"))

  # Use a small max_days for speed
  result <- run_CERIS(env_means, sorghum_env_params, params, max_days = 20)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("Day_x", "Day_y", "window", "midXY") %in% names(result)))

  # Check R and P columns exist for each param
  for (p in params) {
    expect_true(paste0("R_", p) %in% names(result))
    expect_true(paste0("P_", p) %in% names(result))
  }

  expect_true(all(result$window >= 6))
  expect_true(all(result$Day_y > result$Day_x))
})

test_that("ceris_identify_best finds a valid window", {
  data(sorghum_traits, package = "runCERIS")
  data(sorghum_env_meta, package = "runCERIS")
  data(sorghum_env_params, package = "runCERIS")

  exp_trait <- prepare_trait_data(sorghum_traits, "FTgdd")
  env_means <- compute_env_means(exp_trait, sorghum_env_meta)
  params <- setdiff(names(sorghum_env_params), c("env_code", "DAP"))

  result <- run_CERIS(env_means, sorghum_env_params, params, max_days = 20)
  best <- ceris_identify_best(result, params)

  expect_true(best$param_name %in% params)
  expect_true(best$dap_start < best$dap_end)
  expect_true(abs(best$correlation) <= 1)
})
