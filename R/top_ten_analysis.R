###############################################################################
#
# Steps 1-6 were completed in the import, cleaning, and geographic-analysis
# files. This file begins with the existing filtered RDS files and focuses on
# the remaining final analysis:
#
# 1. Analyze the selected category group using all reviewers.
# 2. Select active reviewers and calculate reviewer baselines.
# 3. Create reviewer-adjusted scores using mean and median baselines.
# 4. Compare ordinary and reviewer-adjusted restaurant results.
# 5. Produce a final top-ten restaurant table.
# 6. Create a final map showing the top ten with geographic boundaries.
# 7. Create final tables and figures for the final QMD/HTML report.
#
###############################################################################

library(tidyverse)
library(lubridate)
library(sf)
library(tigris)
library(viridis)

options(tigris_use_cache = TRUE)

dir.create("tables", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Load the completed Step 1-6 data
# -----------------------------------------------------------------------------

businesses <- readRDS(
  "data/new_orleans/business_new_orleans.rds"
)

reviews <- readRDS(
  "data/new_orleans/reviews_new_orleans.rds"
)

# These are the categories selected for the current project theme.
# A business is included when its Yelp category list contains at least one.
selected_categories <- c(
  "cajun/creole",
  "seafood",
  "southern",
  "sandwiches",
  "fast food",
  "food trucks"
)

# Keep the category evidence required for the final report.
restaurant_categories <- businesses |>
  dplyr::select(
    business_id,
    categories
  ) |>
  tidyr::separate_rows(
    categories,
    sep = ","
  ) |>
  dplyr::mutate(
    category = stringr::str_to_lower(
      stringr::str_squish(categories)
    )
  ) |>
  dplyr::filter(
    !is.na(category),
    category != ""
  ) |>
  dplyr::distinct(business_id, category)

final_category_counts <- restaurant_categories |>
  dplyr::count(
    category,
    name = "number_of_businesses",
    sort = TRUE
  )

category_cooccurrence <- restaurant_categories |>
  dplyr::inner_join(
    restaurant_categories,
    by = "business_id",
    suffix = c("_one", "_two"),
    relationship = "many-to-many"
  ) |>
  dplyr::filter(
    category_one < category_two
  ) |>
  dplyr::count(
    category_one,
    category_two,
    name = "number_of_shared_businesses",
    sort = TRUE
  )

write.csv(
  final_category_counts,
  "tables/final_category_counts.csv",
  row.names = FALSE
)

write.csv(
  category_cooccurrence,
  "tables/category_cooccurrence.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 2. Recreate the selected category group and join its reviews
# -----------------------------------------------------------------------------

selected_restaurants <- businesses |>
  dplyr::filter(
    stringr::str_detect(
      stringr::str_to_lower(categories),
      stringr::regex(
        paste(selected_categories, collapse = "|"),
        ignore_case = TRUE
      )
    )
  ) |>
  dplyr::distinct(business_id, .keep_all = TRUE)

selected_reviews <- reviews |>
  dplyr::semi_join(
    selected_restaurants,
    by = "business_id"
  ) |>
  dplyr::mutate(
    review_date = lubridate::ymd_hms(date),
    review_year = lubridate::year(review_date)
  )

selected_data_summary <- tibble(
  number_of_selected_restaurants = nrow(selected_restaurants),
  number_of_selected_reviews = nrow(selected_reviews),
  number_of_selected_categories = length(selected_categories)
)

write.csv(
  selected_data_summary,
  "tables/final_selected_data_summary.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 3. All-reviewer restaurant results
# -----------------------------------------------------------------------------

all_reviewer_summary <- selected_reviews |>
  dplyr::group_by(business_id) |>
  dplyr::summarise(
    number_of_reviews_all_reviewers = dplyr::n(),
    average_stars_all_reviewers = round(
      mean(stars, na.rm = TRUE),
      1
    ),
    median_stars_all_reviewers = round(
      median(stars, na.rm = TRUE),
      1
    ),
    .groups = "drop"
  )

# -----------------------------------------------------------------------------
# 4. Reviewer activity and eligibility
# -----------------------------------------------------------------------------

# Reviewers with only one review provide limited evidence about their usual
# scoring habits. Five reviews is used as the activity threshold and is stated
# in the final report.
reviewer_activity <- selected_reviews |>
  dplyr::count(
    user_id,
    name = "reviews_in_selected_categories"
  ) |>
  dplyr::arrange(
    dplyr::desc(reviews_in_selected_categories)
  )

eligible_reviewers <- reviewer_activity |>
  dplyr::filter(
    reviews_in_selected_categories >= 5
  )

eligible_reviewer_count <- nrow(eligible_reviewers)

eligible_selected_review_count <- selected_reviews |>
  dplyr::semi_join(
    eligible_reviewers,
    by = "user_id"
  ) |>
  nrow()

eligible_review_summary <- tibble(
  total_reviewers = nrow(reviewer_activity),
  eligible_reviewers = eligible_reviewer_count,
  total_selected_reviews = nrow(selected_reviews),
  eligible_selected_reviews = eligible_selected_review_count
)

write.csv(
  reviewer_activity,
  "tables/reviewer_activity.csv",
  row.names = FALSE
)

write.csv(
  eligible_review_summary,
  "tables/eligible_reviewer_summary.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 5. Reviewer baselines and normalized reviews
# -----------------------------------------------------------------------------

reviewer_baselines <- selected_reviews |>
  dplyr::group_by(user_id) |>
  dplyr::summarise(
    reviewer_mean = mean(stars, na.rm = TRUE),
    reviewer_median = median(stars, na.rm = TRUE),
    reviewer_review_count = dplyr::n(),
    .groups = "drop"
  )

adjusted_reviews <- selected_reviews |>
  dplyr::left_join(
    reviewer_baselines,
    by = "user_id"
  ) |>
  dplyr::semi_join(
    eligible_reviewers,
    by = "user_id"
  ) |>
  dplyr::mutate(
    normalized_mean_score = stars - reviewer_mean,
    normalized_median_score = stars - reviewer_median
  )

reviewer_adjusted_summary <- adjusted_reviews |>
  dplyr::group_by(business_id) |>
  dplyr::summarise(
    number_of_reviews_eligible_reviewers = dplyr::n(),
    average_stars_eligible_reviewers = round(
      mean(stars, na.rm = TRUE),
      1
    ),
    average_normalized_mean_score = mean(
      normalized_mean_score,
      na.rm = TRUE
    ),
    median_normalized_mean_score = median(
      normalized_mean_score,
      na.rm = TRUE
    ),
    average_normalized_median_score = mean(
      normalized_median_score,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

write.csv(
  reviewer_baselines,
  "tables/reviewer_baselines.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 6. Compare ordinary and reviewer-adjusted restaurant results
# -----------------------------------------------------------------------------

restaurant_summary <- selected_restaurants |>
  dplyr::select(
    business_id,
    business_name,
    review_count,
    latitude,
    longitude
  ) |>
  dplyr::left_join(
    all_reviewer_summary,
    by = "business_id"
  ) |>
  dplyr::left_join(
    reviewer_adjusted_summary,
    by = "business_id"
  ) |>
  dplyr::arrange(
    dplyr::desc(average_normalized_mean_score)
  )

write.csv(
  restaurant_summary,
  "tables/reviewer_adjusted_restaurant_ratings.csv",
  row.names = FALSE
)

# This table identifies restaurants whose ranking changes between the ordinary
# all-reviewer average and the reviewer-adjusted score.
ranking_comparison <- restaurant_summary |>
  dplyr::filter(
    !is.na(average_stars_all_reviewers),
    !is.na(average_normalized_mean_score)
  ) |>
  dplyr::mutate(
    raw_rating_rank = dplyr::min_rank(
      dplyr::desc(average_stars_all_reviewers)
    ),
    adjusted_rating_rank = dplyr::min_rank(
      dplyr::desc(average_normalized_mean_score)
    ),
    rank_change = raw_rating_rank - adjusted_rating_rank
  ) |>
  dplyr::arrange(
    dplyr::desc(abs(rank_change))
  )

write.csv(
  ranking_comparison,
  "tables/raw_vs_adjusted_ranking_comparison.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 7. Final top-ten table
# -----------------------------------------------------------------------------

# The minimum of five eligible-reviewer reviews prevents a restaurant from
# ranking highly because of only one or two adjusted reviews.
top_ten_restaurants <- restaurant_summary |>
  dplyr::filter(
    !is.na(average_normalized_mean_score),
    number_of_reviews_eligible_reviewers >= 5
  ) |>
  dplyr::arrange(
    dplyr::desc(average_normalized_mean_score),
    dplyr::desc(number_of_reviews_eligible_reviewers)
  ) |>
  dplyr::slice_head(n = 10)

write.csv(
  top_ten_restaurants,
  "tables/top_ten_restaurants.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 8. Recreate only the boundary needed for the final top-ten map
# -----------------------------------------------------------------------------

restaurant_points <- selected_restaurants |>
  dplyr::filter(
    !is.na(longitude),
    !is.na(latitude)
  ) |>
  sf::st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )

zcta_boundaries <- tigris::zctas(
  cb = TRUE,
  year = 2020,
  class = "sf"
) |>
  dplyr::select(
    zcta = ZCTA5CE20
  ) |>
  sf::st_transform(
    sf::st_crs(restaurant_points)
  )

# Limit the final map to Louisiana. Without this filter, zctas() returns
# nationwide ZCTA boundaries, which causes the map to include places such as
# Alaska even though the restaurants are in New Orleans.
louisiana_boundary <- tigris::states(
  cb = TRUE,
  year = 2020,
  class = "sf"
) |>
  dplyr::filter(STUSPS == "LA") |>
  sf::st_transform(sf::st_crs(restaurant_points))

zcta_louisiana <- zcta_boundaries[
  lengths(
    sf::st_intersects(zcta_boundaries, louisiana_boundary)
  ) > 0,
]

# Confirm the Step 3 requirement that the selected category group contains
# restaurants in at least seven geographic areas.
restaurants_with_zcta <- restaurant_points |>
  sf::st_join(
    zcta_boundaries,
    join = sf::st_within,
    left = TRUE
  )

category_area_coverage <- restaurants_with_zcta |>
  sf::st_drop_geometry() |>
  dplyr::filter(!is.na(zcta)) |>
  dplyr::group_by(zcta) |>
  dplyr::summarise(
    number_of_restaurants = dplyr::n(),
    average_business_stars = mean(stars, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(number_of_restaurants))

category_area_coverage_check <- tibble(
  selected_restaurants = nrow(selected_restaurants),
  geographic_areas_with_selected_restaurants = nrow(category_area_coverage),
  meets_minimum_restaurant_requirement = nrow(selected_restaurants) >= 10,
  meets_minimum_area_requirement = nrow(category_area_coverage) >= 7
)

write.csv(
  category_area_coverage,
  "tables/selected_category_area_coverage.csv",
  row.names = FALSE
)

write.csv(
  category_area_coverage_check,
  "tables/selected_category_area_coverage_check.csv",
  row.names = FALSE
)

top_ten_points <- top_ten_restaurants |>
  sf::st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  ) |>
  sf::st_join(
    zcta_boundaries,
    join = sf::st_within,
    left = TRUE
  )

write.csv(
  sf::st_drop_geometry(top_ten_points),
  "tables/top_ten_restaurants_with_zcta.csv",
  row.names = FALSE
)

top_ten_map <- ggplot() +
  geom_sf(
    data = louisiana_boundary,
    fill = "grey92",
    color = "grey70",
    linewidth = 0.35
  ) +
  geom_sf(
    data = zcta_louisiana,
    fill = NA,
    color = "grey65",
    linewidth = 0.25
  ) +
  geom_sf(
    data = top_ten_points,
    aes(color = average_normalized_mean_score),
    size = 3,
    alpha = 0.90
  ) +
  scale_color_viridis_c(
    option = "C"
  ) +
  labs(
    title = "Top Ten Selected Restaurants by ZCTA",
    color = "Reviewer-adjusted score"
  ) +
  coord_sf(
    xlim = c(-90.25, -89.85),
    ylim = c(29.86, 30.15),
    expand = FALSE
  ) +
  theme_minimal()

ggsave(
  "figures/top_ten_restaurants_map.png",
  top_ten_map,
  width = 10,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------------------------------
# 9. Final comparison plot
# -----------------------------------------------------------------------------

rating_comparison_plot <- restaurant_summary |>
  dplyr::filter(
    !is.na(average_stars_all_reviewers),
    !is.na(average_normalized_mean_score)
  ) |>
  ggplot(
    aes(
      x = average_stars_all_reviewers,
      y = average_normalized_mean_score
    )
  ) +
  geom_hline(
    yintercept = 0,
    color = "grey70"
  ) +
  geom_point(
    aes(size = number_of_reviews_all_reviewers),
    alpha = 0.60
  ) +
  labs(
    title = "Raw Ratings Compared with Reviewer-adjusted Scores",
    x = "Average stars from all reviewers",
    y = "Average normalized score",
    size = "Reviews"
  ) +
  theme_minimal()

ggsave(
  "figures/raw_vs_adjusted_ratings.png",
  rating_comparison_plot,
  width = 10,
  height = 7,
  dpi = 300
)

# A short text file records the choices used by this analysis.
writeLines(
  c(
    "Selected categories:",
    paste(selected_categories, collapse = ", "),
    "",
    "Reviewer eligibility threshold:",
    "At least 5 reviews within the selected category group.",
    "",
    "Primary reviewer-adjusted score:",
    "Mean-normalized score: individual stars minus reviewer mean."
  ),
  "tables/post_step6_analysis_notes.txt"
)
