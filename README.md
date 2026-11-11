# yelp-new-orleans-project

This repository contains the Yelp New Orleans restaurant project.

## Completed

1. Filtered the data to restaurants located in New Orleans, Louisiana.
2. Saved the filtered business and review data as compressed RDS files.
3. Examined restaurant categories and selected categories related to New Orleans dining.
4. Compared three geographic systems: ZCTAs, census tracts, and census block groups.
5. Created tables and maps showing restaurant locations across these geographic systems.
6. Selected ZCTAs as the preferred geographic system because they assigned all restaurants and produced the clearest comparison.

## Data files

The original Yelp JSON files are stored locally in `data/raw/` but are excluded from GitHub because they are very large.

The filtered files are:

- `data/new_orleans/business_new_orleans.rds`
- `data/new_orleans/reviews_new_orleans.rds`

## Analysis files

- `R/import.R` imports the Yelp business and review data.
- `R/clean.R` filters the data to New Orleans restaurants and saves the RDS files.
- `R/new_orleans_restaurant_geography_analysis.R` performs the category and geographic analysis.
- `new_orleans_restaurant_geography_analysis.qmd` contains the written analysis.
- `new_orleans_restaurant_geography_analysis.html` is the rendered report with embedded tables and maps.

## Geographic comparison

The analysis compared ZCTAs, census tracts, and census block groups. ZCTAs were selected because they assigned all 1,057 selected restaurants and had no unmatched restaurants. Census tracts and block groups provided more detailed boundaries, but each left 27 restaurants unmatched and created more complicated maps.

## Figures

The analysis includes maps showing:

- Selected New Orleans restaurant locations
- Restaurants by ZCTA
- Restaurants by census tract
- Restaurants by census block group

## Tables

The analysis includes tables showing:

- Restaurant category counts
- Geographic system comparison
- Selected restaurant data summary

The large raw Yelp files are not included in the repository. The RDS files and analysis outputs were created from those local files.