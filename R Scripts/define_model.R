# R/define_model.R

# Load necessary library
library(parsnip)

# Define a function that creates the glmnet model specification
create_glmnet_spec <- function() {
  
  # Specify a linear regression model
  linear_reg(
    # 'penalty' is the regularization amount. We will tune this.
    penalty = tune(),
    # 'mixture' controls the L1/L2 balance. We will tune this.
    mixture = tune()
  ) %>%
    # Set the engine to "glmnet"
    set_engine("glmnet")
}


