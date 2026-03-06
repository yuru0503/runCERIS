test_that("prepare_trait_data works with sorghum data", {
  data(sorghum_traits, package = "runCERIS")
  result <- prepare_trait_data(sorghum_traits, "FTgdd")
  expect_s3_class(result, "data.frame")
  expect_true(all(c("line_code", "env_code", "Yobs") %in% names(result)))
  expect_true(nrow(result) > 0)
  expect_true(all(!is.na(result$Yobs)))
})

test_that("compute_env_means works", {
  data(sorghum_traits, package = "runCERIS")
  data(sorghum_env_meta, package = "runCERIS")
  exp_trait <- prepare_trait_data(sorghum_traits, "FTgdd")
  result <- compute_env_means(exp_trait, sorghum_env_meta)
  expect_s3_class(result, "data.frame")
  expect_true("meanY" %in% names(result))
  expect_true(all(diff(result$meanY) >= 0)) # ordered by meanY
})

test_that("prepare_line_by_env creates wide format", {
  data(sorghum_traits, package = "runCERIS")
  data(sorghum_env_meta, package = "runCERIS")
  exp_trait <- prepare_trait_data(sorghum_traits, "FTgdd")
  env_means <- compute_env_means(exp_trait, sorghum_env_meta)
  result <- prepare_line_by_env(exp_trait, env_means)
  expect_true("line_code" %in% names(result))
  expect_equal(ncol(result), nrow(env_means) + 1) # line_code + n_envs
})

test_that("prepare_trait_data errors on missing trait", {
  data(sorghum_traits, package = "runCERIS")
  expect_error(prepare_trait_data(sorghum_traits, "nonexistent"))
})
