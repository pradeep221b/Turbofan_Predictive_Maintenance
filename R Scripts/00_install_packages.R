# ===================================================================
#
# Project Package Installation Script
#
# ===================================================================
#
# This script installs all the necessary R packages to run the
# Turbofan Predictive Maintenance project. It's recommended to
# run this script once before executing the pipeline for the
# first time.
#
# ===================================================================

# List of packages to install
packages_to_install <- c(
  "targets",      # The main package for orchestrating the reproducible pipeline.
  "tidymodels",   # A meta-package for modeling that includes most of what we need:
  # - recipes: for feature engineering
  # - rsample: for time-series data splitting and resampling
  # - parsnip: for defining the model specification
  # - workflows: for bundling recipes and models
  # - tune: for hyperparameter tuning
  # - dials: for creating tuning grids
  # - yardstick: for calculating performance metrics
  # - broom: for tidying model results
  "glmnet",       # The specific engine for our regularized regression model.
  "RcppRoll"      # A required dependency for the recipes::step_window() function
  # that performs fast rolling window calculations.
)

# Install the packages
install.packages(packages_to_install)

# Print a confirmation message
message("All required packages have been installed successfully.")

