# Yelp New Orleans Restaurant Analysis

This project analyzes Yelp restaurant data in New Orleans, Louisiana. It examines restaurant categories, restaurant locations, geographic systems, Yelp ratings, and reviewer-adjusted ratings.

## Final report

The complete analysis is available as a standalone webpage:

[Open the final analysis website](https://victor-tung.github.io/yelp-new-orleans-project/)

The report contains the project question, data description, category analysis, maps, geographic comparison, reviewer-adjusted ratings, top-ten ranking, limitations, conclusion, and AI assistance documentation.

## Main findings

The project compares three geographic systems:

- ZIP Code Tabulation Areas (ZCTAs)
- Census tracts
- Census block groups

ZCTAs were selected for the main analysis because they assigned all 1,057 selected restaurants, produced no unmatched restaurants, and were easier for a general audience to understand.

The analysis includes:

- 1,057 selected New Orleans restaurants
- 299,924 reviews
- Six restaurant categories
- Category counts and category co-occurrence
- Restaurant counts by geographic area
- Average and median business ratings
- Reviewer-adjusted ratings
- Geographic comparison maps
- A sorted top-ten restaurant ranking
- A final map focused on New Orleans

## Repository structure

```text
.
├── index.html
├── README.md
├── .gitignore
├── yelp_new_orleans_final_report.qmd
├── new_orleans_restaurant_geography_analysis.qmd
├── new_orleans_restaurant_geography_analysis.html
├── R/
│   ├── import.R
│   ├── clean.R
│   ├── new_orleans_restaurant_geography_analysis.R
│   └── top_ten_analysis.R
├── figures/
├── tables/
└── data/
    └── new_orleans/
```

## Important files

- `index.html` is the final standalone report published through GitHub Pages.
- `yelp_new_orleans_final_report.qmd` is the source Quarto document for the final report.
- `README.md` describes the project and explains how to access the report.
- `.gitignore` excludes large local data files from GitHub.

## R scripts

- `R/import.R` imports the Yelp business and review JSON files.
- `R/clean.R` filters the data to New Orleans restaurants and saves the filtered RDS files.
- `R/new_orleans_restaurant_geography_analysis.R` compares geographic systems and completes the Step 6 analysis.
- `R/post_step6_final_analysis.R` performs the category analysis, reviewer-adjusted rating analysis, ranking, and final visualizations.

## Data management

The original Yelp JSON files are very large and are not included in the repository.

The filtered RDS files contain the New Orleans restaurant and review data used in the analysis. The final HTML report is standalone, so its maps, charts, tables, styles, and other report content are embedded directly in `index.html`.

## Reproducing the analysis

Run the R scripts in this order:

```r
source("R/import.R")
source("R/clean.R")
source("R/new_orleans_restaurant_geography_analysis.R")
source("R/post_step6_final_analysis.R")
```

To render the final report again, run:

```bash
quarto render yelp_new_orleans_final_report.qmd
```

After rendering, save the resulting HTML file as:

```text
index.html
```

The `index.html` file must be located in the repository root for GitHub Pages to use it as the homepage.

## Geographic comparison

The project compares ZCTAs, Census tracts, and Census block groups using spatial joins.

Each geographic system was evaluated using:

- Number of geographic areas
- Number of restaurants assigned
- Number of unmatched restaurants
- Smallest area restaurant count
- Largest area restaurant count
- Average business rating
- Median business rating
- Geographic maps

The comparison found:

- ZCTAs assigned all 1,057 selected restaurants.
- ZCTAs had no unmatched restaurants.
- Census tracts left 27 restaurants unmatched.
- Census block groups left 27 restaurants unmatched.
- ZCTAs were easier to understand and provided complete coverage.

## Restaurant categories

The analysis selected six restaurant-related categories:

- Cajun/Creole
- Seafood
- Southern
- Sandwiches
- Fast Food
- Food Trucks

These categories were selected to include both New Orleans-associated foods and common quick-service or casual dining categories. Category counts and category co-occurrence results are included in the final report.

## Reviewer-adjusted ratings

The project calculates reviewer-adjusted scores by comparing each review with the reviewer’s usual rating behavior.

The calculation is:

```text
reviewer-adjusted score =
individual review rating - reviewer average rating
```

A positive adjusted score means that the reviewer rated the restaurant higher than usual. A negative adjusted score means that the reviewer rated the restaurant lower than usual.

The report compares ordinary average ratings with reviewer-adjusted ratings and uses the adjusted results to create the top-ten ranking.

Reviewer-adjusted scores provide an additional perspective, but they should not be interpreted as a perfect measure of restaurant quality.

## Limitations

The Yelp data represents a historical snapshot and may not reflect current restaurant ownership, locations, ratings, or operations.

Different geographic systems use different boundary definitions, so restaurant counts and visual patterns may change depending on the selected geography.

Smaller areas may contain very few restaurants, making comparisons less stable. Areas with only one or two restaurants should be interpreted cautiously.

Reviewer-adjusted ratings also depend on the number of reviews available for each reviewer and restaurant.

## GitHub Pages

The final report is published using GitHub Pages from the `main` branch and repository root.

The live report is available at:

[https://victor-tung.github.io/yelp-new-orleans-project/](https://victor-tung.github.io/yelp-new-orleans-project/)

## AI assistance

AI assistance was used as a coding and troubleshooting resource throughout the project. I ran the code in RStudio, checked the outputs, investigated errors, and adjusted the scripts when needed.

AI assistance helped with:

- Organizing the repository
- Creating import and cleaning scripts
- Processing large Yelp JSON files
- Creating spatial joins and geographic comparisons
- Calculating reviewer-adjusted ratings
- Debugging R errors
- Creating the Quarto report
- Checking that tables and maps were included in the final HTML file
- Preparing the report for GitHub Pages
