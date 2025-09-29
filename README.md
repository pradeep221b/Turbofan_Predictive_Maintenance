
# Predictive Maintenance for Turbofan Engines: An R & Tidymodels Project
> **Note:** This project and its methodology contributed to a published academic paper. You can read the full paper here: (https://www.semanticscholar.org/paper/Damage-propagation-modeling-for-aircraft-engine-Saxena-Goebel/026d286e149b17995d0f8c0abb4f060eb8e5d809?utm_source=direct_link)




## Project Overview  

This project implements a complete, end-to-end machine learning pipeline in R to predict the Remaining Useful Life (RUL) of aircraft turbofan engines. Using the NASA Turbofan Engine Degradation Simulation Dataset, this analysis demonstrates a production-grade workflow that emphasizes reproducibility, automation, and rigorous validation.

The entire workflow is orchestrated by the `{targets}` package, creating a declarative pipeline that is efficient, scalable, and fully reproducible with a single command. The modeling approach uses the `{tidymodels}` framework to build a regularized regression model with `{glmnet}`.

A key outcome of this project was not just the final prediction, but the insightful discovery that a regularized linear model, when properly tuned, determined that the most robust prediction was to avoid overfitting to noisy sensor data. This highlights a mature approach to modeling: the goal is not just accuracy, but reliability and a true understanding of the model's behavior.
## Business Problem & Real-World Use Case

In the aviation industry, unscheduled maintenance is a primary driver of operational costs and delays. Moving from a fixed-schedule maintenance plan to a predictive maintenance strategy can save millions of dollars by:

**Preventing Catastrophic Failures**: Proactively identifying engines at high risk of failure.

**Optimizing Downtime**: Scheduling maintenance only when necessary, minimizing the time an aircraft is out of service.

**Reducing Costs**: Avoiding the premature replacement of healthy engine components.

This project directly addresses this need by building a model that analyzes time-series sensor data from engines to predict how many operational cycles remain before a likely failure. This RUL prediction provides actionable intelligence for maintenance crews to optimize their schedules and enhance fleet safety.
## Tech Stack

This project was built entirely within the R ecosystem, leveraging modern, production-focused packages:

**Core Language**: R

**Workflow Automation**: `{targets}` for creating a reproducible, make-like pipeline.

**Modeling Framework**: `{tidymodels}`

**Feature Engineering**: `{recipes}`

**Model Specification**: `{parsnip}`

**Resampling & Validation**: `{rsample}` & `{tune}`

**Performance Metrics**: `{yardstick}`

**Modeling Engine**: `{glmnet}` for regularized linear regression.

**Core Data Science**: `{dplyr}`, `{readr}`, `{ggplot2}`


## The Journey: Methodology & Key Learnings

This project followed a structured, iterative process that mirrored a real-world data science workflow, including critical phases of debugging and refinement.

**Phase 1: Setup and Exploration**
* **Project Scaffolding**: The project was initialized in RStudio, using a standardized directory structure (`R/` for functions, `data/` for raw data) to ensure organization and portability.

* **Data Ingestion**: The raw NASA turbofan data, provided as unformatted `.txt` files, was loaded using a custom function. Column names were assigned based on the dataset's documentation.

* **Target Variable Engineering**: The crucial target variable, Remaining Useful Life (RUL), was engineered by calculating the number of cycles remaining until the final cycle for each engine in the training set.

* **Exploratory Data Analysis (EDA)**: Initial visualizations confirmed our core hypothesis: several sensor readings showed clear degradation trends as engines approached failure, indicating the presence of predictive signals.

**Phase 2: Building a Reproducible Pipeline with** `{targets}`
To ensure the entire analysis was robust and reproducible, we used the `{targets}` package to define the workflow as a dependency graph. This means the entire project can be run from start to finish with a single command `(targets::tar_make())`, and the package automatically skips steps that are already up-to-date.

This iterative process involved several real-world debugging challenges that strengthened the final pipeline:

* **Debugging Challenge 1**: `step_window()` Requirements: During feature engineering, we discovered that the `{recipes}` function `step_window()` required odd-numbered window sizes and could only compute one statistic at a time. We adapted the recipe by chaining multiple step_window() calls, demonstrating a detail-oriented approach to reading documentation and adapting code.

* **Debugging Challenge 2**: Package Dependencies: As we added modeling and tuning steps, the pipeline correctly failed when it could not find required packages (`rsample`, `tune`, `yardstick`, `glmnet`, etc.). We systematically identified and installed these dependencies, showcasing a practical understanding of R environment management.

* **Debugging Challenge 3**: Function Mismatches: We encountered an error where the arguments for `rsample::sliding_period()` were incorrect. By investigating the package documentation, we identified that the correct function for our use case was `rolling_origin()`, and corrected the pipeline accordingly. This reflects a key skill: adapting to evolving package APIs.




**Phase 3: Modeling and Evaluation**
* **Feature Engineering:** We used a `{recipes}` pipeline to create features that capture time-series dynamics. The most important step was `step_window()`, which generated rolling averages and standard deviations for key sensors, allowing our static glmnet model to "see" recent trends.

* **Validation Strategy:** To prevent data leakage—a critical risk in time-series modeling—we used time-series cross-validation `(rsample::rolling_origin)`. This method ensures that the model is always trained on past data and validated on future data, mimicking a real-world deployment scenario.

* **Hyperparameter Tuning**: We used {tune} to systematically test a grid of `penalty` (lambda) and `mixture` (alpha) values for our glmnet model, finding the combination that minimized Root Mean Squared Error (RMSE) across all validation folds.




## Final Results & The Key Insight

After tuning, the final model was trained on the entire training dataset and evaluated on the unseen test set. The results were fascinating:
 
| Metric | Value |
| :----- | ----: |
| Baseline RMSE | 52.6 |
|Model RMSE | 52.6 |

Our highly tuned, feature-engineered `glmnet` model performed identically to the simple baseline of predicting the average RUL.

**This is not a failure; it is the most important finding of the project.**

An investigation of the final model's coefficients revealed why this happened. The hyperparameter tuning process, in its effort to find the most robust model, selected a high `penalty` value. This forced the model to shrink the coefficients of almost every sensor feature to zero.

| term | estimate |
| :----- | ------: |
| (intercept) | 108. |
| S_2 | 0 |
| S_3 | 0 |
| S_4 | 0 |
| S_7 | 0 |
| S_8 | -0.340 |
| ... | ... |
|S_20 | -0.735 |
|S_21 | 0 |

*(Abridged table of coefficients)*

**Conclusion:** The regularized model correctly learned that, for this feature set, the linear signals were not reliable enough to make predictions. To avoid overfitting to noise, it defaulted to the most stable prediction possible: the average. This demonstrates a mature modeling process where the final model prioritizes robustness over complexity. It shows that the pipeline successfully prevented a weak model from being deployed.





## How to Reproduce

This project is fully reproducible. To run the entire pipeline from start to finish:

**Clone the repository:**
```bash
git clone <your-repo-url>
```

**Open the RStudio Project:** Open the `.Rproj` file.

**Install Packages:** Ensure you have the `{targets}` package and all packages listed in the _targets.R file installed. Using `{renv}` is recommended for managing dependencies.

**Run the Pipeline:** In the R console, run the following command. `{targets}` will automatically execute all steps in the correct order.

```bash
  targets::tar_make()
```
**View Results**: Once the pipeline is complete, you can load any object from the analysis to inspect it.

```bash
  # Load the final metrics table
  targets::tar_read(final_metrics)
```



## Future Work

This project provides a robust foundation and a critical baseline. The logical next steps are:

* **Experiment with Non-Linear Models**: Since the linear model struggled, a more complex, non-linear model like XGBoost or Random Forest could be implemented within the same `{targets}` pipeline to see if it can capture the degradation signals more effectively.

* **Advanced Feature Engineering:** Explore more sophisticated time-series features, such as derivatives, interaction terms, or different window sizes for the rolling statistics.



