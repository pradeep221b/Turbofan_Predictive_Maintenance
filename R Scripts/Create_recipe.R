# R/create_recipe.R

# Load necessary libraries
library(recipes)
library(dplyr)

# Define the function to create our feature engineering recipe
create_turbofan_recipe <- function(data) {
  
  # Define which sensors we will create window features for
  sensors_for_windows <- c(
    "s_2", "s_3", "s_4", "s_7", "s_8", "s_9", "s_11", "s_12", 
    "s_13", "s_14", "s_15", "s_17", "s_20", "s_21"
  )
  
  recipe(rul ~., data = data) %>%
    # Step 1: Assign roles. 'unit' and 'cycle' are IDs, not predictors.
    update_role(unit, cycle, new_role = "ID") %>%
    
    # Step 2: Remove operational settings and sensors with no variance.
    step_rm(setting_1, setting_2, setting_3) %>%
    step_nzv(all_predictors()) %>%
    
    # Step 3: Create time-based features (rolling statistics).
    # We now chain multiple calls to step_window to create all our features.
    step_window(
      all_of(sensors_for_windows),
      size = 5, # 5-cycle window
      statistic = "mean"
    ) %>%
    step_window(
      all_of(sensors_for_windows),
      size = 5, # 5-cycle window
      statistic = "sd"
    ) %>%
    step_window(
      all_of(sensors_for_windows),
      size = 9, # Using 9 instead of 10, as size must be odd
      statistic = "mean"
    ) %>%
    step_window(
      all_of(sensors_for_windows),
      size = 9, # Using 9 instead of 10, as size must be odd
      statistic = "sd"
    ) %>%
    
    # Step 4: Normalize all numeric predictors.
    step_normalize(all_predictors())
}

