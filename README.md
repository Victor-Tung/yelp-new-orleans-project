# New Orleans Yelp Project

This repository currently contains the start of the Yelp New Orleans restaurant project

## Completed

1. Filtered the data to restaurants located in New Orleans, Louisiana.
2. Saved the filtered business and review data as compressed RDS files.

## Data files

The original Yelp JSON files are stored locally in `data/raw/` but are excluded from GitHub because they are very large

Note that the filtered RDS files are included in the repo but cannot be previewed directly on GitHub because they are binary R data files

The filtered files are:
- `data/new_orleans/business_new_orleans.rds`
- `data/new_orleans/reviews_new_orleans.rds`

## R code

- `R/import.R` imports the Yelp business and review data.
- `R/clean.R` filters the data to New Orleans restaurants and saves the RDS files.
