test_that("jra_model returns correct structure", {
  data(sorghum_traits, package = "runCERIS")
  data(sorghum_env_meta, package = "runCERIS")

  exp_trait <- prepare_trait_data(sorghum_traits, "FTgdd")
  env_means <- compute_env_means(exp_trait, sorghum_env_meta)
  line_by_env <- prepare_line_by_env(exp_trait, env_means)

  result <- jra_model(line_by_env, env_means)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("line_code", "Intcp", "Intcp_mean",
                     "Slope_mean", "R2_mean") %in% names(result)))
  expect_true(nrow(result) > 0)
  expect_true(all(as.numeric(result$R2_mean) >= 0))
  expect_true(all(as.numeric(result$R2_mean) <= 1))
})
