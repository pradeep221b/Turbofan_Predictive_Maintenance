# _targets.R

# Load the targets package
library(targets)

# Load packages needed for the pipeline.
tar_option_set(
  packages = c("readr", "dplyr", "recipes", "parsnip", "rsample",
               "workflows", "tune", "dials", "yardstick") # Added "yardstick"
)

# Source our custom functions
source("R/load_data.R")
source("R/create_recipe.R")
source("R/define_model.R")

# Define the pipeline as a list of targets.
list(
  #... (targets 1-5 remain unchanged)...
  tar_target(name = train_file, command = "data/train_FD001.txt", format = "file"),
  tar_target(name = train_data_with_rul, command = {
    raw_data <- load_turbofan_data(train_file)
    raw_data %>% group_by(unit) %>% mutate(rul = max(cycle) - cycle) %>% ungroup()
  }),
  tar_target(name = turbofan_recipe, command = create_turbofan_recipe(train_data_with_rul)),
  tar_target(name = time_split, command = initial_time_split(train_data_with_rul, prop = 0.8)),
  tar_target(name = glmnet_spec, command = create_glmnet_spec()),
  
  # Target 6: Create time-series cross-validation folds from the training data.
  tar_target(
    name = cv_folds,
    command = {
      training_data <- training(time_split)
      rolling_origin(
        training_data,
        initial = 15000,
        assess = 1000,
        skip = 1000,
        cumulative = FALSE
      )
    }
  ),
  
  # Target 7: Define a grid of hyperparameters to tune.
  tar_target(
    name = tuning_grid,
    command = grid_regular(penalty(), mixture(), levels = 5)
  ),
  
  # Target 8: Tune the glmnet model.
  tar_target(
    name = glmnet_tune_results,
    command = {
      glmnet_wf <- workflow(turbofan_recipe, glmnet_spec)
      tune_grid(
        object = glmnet_wf,
        resamples = cv_folds,
        grid = tuning_grid,
        metrics = metric_set(rmse)
      )
    }
  )
)

# _targets.R

#... (previous setup and targets 1-8 remain unchanged)...

list(
  #... (targets 1-8)...
  tar_target(name = train_file, command = "data/train_FD001.txt", format = "file"),
  tar_target(name = train_data_with_rul, command = {
    raw_data <- load_turbofan_data(train_file)
    raw_data %>% group_by(unit) %>% mutate(rul = max(cycle) - cycle) %>% ungroup()
  }),
  tar_target(name = turbofan_recipe, command = create_turbofan_recipe(train_data_with_rul)),
  tar_target(name = time_split, command = initial_time_split(train_data_with_rul, prop = 0.8)),
  tar_target(name = glmnet_spec, command = create_glmnet_spec()),
  tar_target(name = cv_folds, command = {
    training_data <- training(time_split)
    rolling_origin(
      training_data,
      initial = 15000, assess = 1000, skip = 1000, cumulative = FALSE
    )
  }),
  tar_target(name = tuning_grid, command = grid_regular(penalty(), mixture(), levels = 5)),
  tar_target(name = glmnet_tune_results, command = {
    glmnet_wf <- workflow(turbofan_recipe, glmnet_spec)
    tune_grid(
      object = glmnet_wf, resamples = cv_folds, grid = tuning_grid,
      metrics = metric_set(rmse)
    )
  }),
  
  # --- NEW TARGETS FOR FINAL EVALUATION ---
  
  # Target 9: Select the best hyperparameters from the tuning results.
  tar_target(
    name = best_params,
    command = select_best(glmnet_tune_results, metric = "rmse")
  ),
  
  # Target 10: Finalize the workflow with the best parameters.
  tar_target(
    name = final_workflow,
    command = {
      glmnet_wf <- workflow(turbofan_recipe, glmnet_spec)
      finalize_workflow(glmnet_wf, best_params)
    }
  ),
  
  # Target 11: Fit the final model on the ENTIRE training dataset.
  tar_target(
    name = final_model_fit,
    command = fit(final_workflow, data = train_data_with_rul)
  ),
  
  # Target 12: Load and prepare the official test data for evaluation.
  tar_target(
    name = prepared_test_data,
    command = {
      test_raw <- load_turbofan_data("data/test_FD001.txt")
      true_rul <- read.table("data/RUL_FD001.txt")$V1
      
      # The evaluation is done on the LAST cycle of each engine in the test set.
      test_raw %>%
        group_by(unit) %>%
        filter(cycle == max(cycle)) %>%
        ungroup() %>%
        mutate(true_rul = true_rul)
    }
  ),
  
  # Target 13: Make predictions and calculate final metrics.
  tar_target(
    name = final_metrics,
    command = {
      predictions <- predict(final_model_fit, new_data = prepared_test_data) %>%
        bind_cols(prepared_test_data %>% select(true_rul))
      
      # Baseline: Predict the mean RUL from the full training set for every test engine.
      mean_rul_train <- mean(train_data_with_rul$rul)
      baseline_rmse <- sqrt(mean((prepared_test_data$true_rul - mean_rul_train)^2))
      
      # Calculate the model's RMSE on the test set
      model_rmse <- rmse(predictions, truth = true_rul, estimate =.pred)
      
      # Combine into a final results tibble
      tibble::tibble(
        metric = c("Baseline RMSE", "Model RMSE"),
        value = c(baseline_rmse, model_rmse$.estimate)
      )
    }
  )
)