# 01_initial_exploration.R

# Load libraries
library(dplyr)
library(ggplot2)

# Source our custom data loading function
source("R/load_data.R")

# --- DATA LOADING ---
# Specify the path to the training data
train_file_path <- "data/train_FD001.txt"

# Load the training data using our function
train_raw <- load_turbofan_data(train_file_path)

# --- TARGET VARIABLE ENGINEERING ---
# Calculate the Remaining Useful Life (RUL) for each engine
train_data <- train_raw %>%
  group_by(unit) %>%
  mutate(rul = max(cycle) - cycle) %>%
  ungroup()

# Display the first few rows with the new 'rul' column
print(head(train_data))

# Display the last few rows for a single engine to see RUL count down to 0
print(tail(filter(train_data, unit == 1)))


# --- EXPLORATORY DATA ANALYSIS (EDA) ---

# Select a few engines to visualize to keep the plots clean
units_to_plot <- c(1, 15, 30, 45, 60, 75, 90, 100)

# Filter the data for these units
eda_data <- train_data %>%
  filter(unit %in% units_to_plot)

# Plot sensor s_4 (HPC outlet temperature) over time for each engine
ggplot(eda_data, aes(x = cycle, y = s_4)) +
  geom_line(aes(color = factor(unit)), show.legend = FALSE) +
  facet_wrap(~unit) +
  labs(
    title = "Sensor s_4 (HPC Outlet Temperature) vs. Cycle",
    subtitle = "Clear degradation trend visible across multiple engines",
    x = "Operational Cycle",
    y = "Sensor Reading"
  ) +
  theme_minimal()

# Plot sensor s_11 (HPC outlet Static pressure) over time for each engine
ggplot(eda_data, aes(x = cycle, y = s_11)) +
  geom_line(aes(color = factor(unit)), show.legend = FALSE) +
  facet_wrap(~unit) +
  labs(
    title = "Sensor s_11 (HPC Outlet Static Pressure) vs. Cycle",
    subtitle = "Another sensor showing a clear trend towards failure",
    x = "Operational Cycle",
    y = "Sensor Reading"
  ) +
  theme_minimal()

