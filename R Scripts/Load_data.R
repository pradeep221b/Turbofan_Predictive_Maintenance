# R/load_data.R

# Load necessary library
library(readr)
library(dplyr)

# Define the column names for the dataset based on the documentation.
# There are 26 columns in total.
col_names <- c("unit", "cycle", "setting_1", "setting_2", "setting_3", 
               paste0("s_", 1:21))

# Create a function to load a single data file.
load_turbofan_data <- function(file_path) {
  
  # Check if the file exists before trying to read it
  if (!file.exists(file_path)) {
    stop("File not found at path: ", file_path)
  }
  
  # Read the space-delimited file without headers
  data <- read_delim(
    file_path,
    delim = " ",
    col_names = FALSE,
    trim_ws = TRUE # Handles potential extra spaces
  )
  
  # The raw files have two empty columns at the end, which we need to remove.
  # These are created because of trailing spaces in the text files.
  data <- data[, 1:26]
  
  # Assign the correct column names
  colnames(data) <- col_names
  
  return(data)
}

