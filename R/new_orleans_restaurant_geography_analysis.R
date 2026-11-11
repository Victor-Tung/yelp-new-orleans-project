# 1. Load packages
library(tidyverse)
library(sf)
library(tigris)
library(viridis)

options(tigris_use_cache = TRUE)

# 2. Load the filtered RDS files
new_orleans_restaurants <- readRDS(
  "data/new_orleans/business_new_orleans.rds"
)

new_orleans_reviews <- readRDS(
  "data/new_orleans/reviews_new_orleans.rds"
)

# Confirm dimensions without printing the full objects
restaurant_dimensions <- dim(new_orleans_restaurants)
review_dimensions <- dim(new_orleans_reviews)

# 3. Create output folders
dir.create("tables", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ============================================================
# Restaurant category analysis
# ============================================================

# Selected New Orleans-related restaurant categories
selected_categories <- c(
  "cajun/creole",
  "seafood",
  "southern",
  "sandwiches",
  "fast food",
  "food trucks"
)

# Separate comma-separated categories into individual rows
restaurant_categories <- new_orleans_restaurants |>
  dplyr::select(
    business_id,
    business_name,
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
  dplyr::distinct(
    business_id,
    category
  )

# Count every category
all_category_counts <- restaurant_categories |>
  dplyr::count(
    category,
    name = "number_of_businesses",
    sort = TRUE
  )

# Save all category counts without printing the tibble
write.csv(
  as.data.frame(all_category_counts),
  "tables/all_restaurant_category_counts.csv",
  row.names = FALSE
)

# Filter to the selected category group
selected_restaurants <- restaurant_categories |>
  dplyr::filter(
    category %in% selected_categories
  ) |>
  dplyr::distinct(business_id) |>
  dplyr::left_join(
    new_orleans_restaurants,
    by = "business_id"
  )

# Save a table describing the selected restaurants
write.csv(
  as.data.frame(selected_restaurants),
  "tables/selected_restaurants.csv",
  row.names = FALSE
)

# Filter reviews to the selected restaurants
selected_reviews <- new_orleans_reviews |>
  dplyr::semi_join(
    selected_restaurants,
    by = "business_id"
  )

# Save a small summary of the selected data
selected_data_summary <- data.frame(
  measure = c(
    "Number of selected restaurants",
    "Number of selected reviews",
    "Number of selected categories",
    "Number of postal codes"
  ),
  value = c(
    nrow(selected_restaurants),
    nrow(selected_reviews),
    length(selected_categories),
    dplyr::n_distinct(
      selected_restaurants$postal_code,
      na.rm = TRUE
    )
  )
)

write.csv(
  selected_data_summary,
  "tables/selected_data_summary.csv",
  row.names = FALSE
)

# ============================================================
# Convert restaurants to spatial points
# ============================================================

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

# ============================================================
# Basic restaurant-location map
# ============================================================

restaurant_location_map <- ggplot() +
  geom_sf(
    data = restaurant_points,
    aes(color = stars),
    size = 2,
    alpha = 0.8
  ) +
  scale_color_viridis_c(
    option = "C",
    limits = c(1, 5)
  ) +
  labs(
    title = "Selected New Orleans Restaurants",
    color = "Business stars"
  ) +
  theme_minimal()

ggplot2::ggsave(
  "figures/new_orleans_restaurant_locations.png",
  restaurant_location_map,
  width = 9,
  height = 7,
  dpi = 300
)

# ============================================================
# ZCTA analysis
# ============================================================

# Download ZCTA boundaries
zcta_boundaries <- tigris::zctas(
  cb = TRUE,
  year = 2020,
  class = "sf"
)

# Transform ZCTAs to the restaurant point CRS
zcta_boundaries <- sf::st_transform(
  zcta_boundaries,
  sf::st_crs(restaurant_points)
)

# Create a bounding box with an explicitly assigned CRS
restaurant_bbox <- sf::st_as_sfc(
  sf::st_bbox(restaurant_points)
)

sf::st_crs(restaurant_bbox) <- sf::st_crs(
  restaurant_points
)

# Keep only ZCTAs intersecting the restaurant area
zcta_boundaries <- zcta_boundaries[
  sf::st_intersects(
    zcta_boundaries,
    restaurant_bbox,
    sparse = FALSE
  )[, 1],
]

# Find the ZCTA identifier column
zcta_id_column <- grep(
  "^ZCTA5CE",
  names(zcta_boundaries),
  value = TRUE
)[1]

# Join restaurants to ZCTAs
restaurants_zcta <- restaurant_points |>
  sf::st_join(
    zcta_boundaries |>
      dplyr::select(
        zcta = dplyr::all_of(zcta_id_column)
      ),
    join = sf::st_within,
    left = TRUE
  )

# Summarize restaurants by ZCTA
zcta_summary <- restaurants_zcta |>
  sf::st_drop_geometry() |>
  dplyr::filter(!is.na(zcta)) |>
  dplyr::group_by(zcta) |>
  dplyr::summarise(
    number_of_restaurants = dplyr::n(),
    average_business_stars = mean(stars, na.rm = TRUE),
    median_business_stars = median(stars, na.rm = TRUE),
    total_reviews = sum(review_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(
    dplyr::desc(number_of_restaurants)
  )

write.csv(
  as.data.frame(zcta_summary),
  "tables/zcta_restaurant_summary.csv",
  row.names = FALSE
)

# Create ZCTA map
zcta_map <- ggplot() +
  geom_sf(
    data = zcta_boundaries,
    fill = "grey95",
    color = "grey60"
  ) +
  geom_sf(
    data = restaurants_zcta,
    aes(color = stars),
    size = 2,
    alpha = 0.8
  ) +
  scale_color_viridis_c(
    option = "C",
    limits = c(1, 5)
  ) +
  labs(
    title = "Selected Restaurants by ZCTA",
    color = "Business stars"
  ) +
  theme_minimal()

ggplot2::ggsave(
  "figures/restaurants_by_zcta.png",
  zcta_map,
  width = 9,
  height = 7,
  dpi = 300
)

# ============================================================
# Census tract analysis
# ============================================================

# Download Census tract boundaries
tract_boundaries <- tigris::tracts(
  state = "LA",
  county = "Orleans",
  cb = TRUE,
  year = 2020,
  class = "sf"
)

# Transform tracts to the restaurant point CRS
tract_boundaries <- sf::st_transform(
  tract_boundaries,
  sf::st_crs(restaurant_points)
)

# Join restaurants to Census tracts
restaurants_tract <- restaurant_points |>
  sf::st_join(
    tract_boundaries |>
      dplyr::select(
        tract = GEOID
      ),
    join = sf::st_within,
    left = TRUE
  )

# Summarize restaurants by Census tract
tract_summary <- restaurants_tract |>
  sf::st_drop_geometry() |>
  dplyr::filter(!is.na(tract)) |>
  dplyr::group_by(tract) |>
  dplyr::summarise(
    number_of_restaurants = dplyr::n(),
    average_business_stars = mean(stars, na.rm = TRUE),
    median_business_stars = median(stars, na.rm = TRUE),
    total_reviews = sum(review_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(
    dplyr::desc(number_of_restaurants)
  )

write.csv(
  as.data.frame(tract_summary),
  "tables/census_tract_restaurant_summary.csv",
  row.names = FALSE
)

# Create Census tract map
tract_map <- ggplot() +
  geom_sf(
    data = tract_boundaries,
    fill = "grey95",
    color = "grey60"
  ) +
  geom_sf(
    data = restaurants_tract,
    aes(color = stars),
    size = 2,
    alpha = 0.8
  ) +
  scale_color_viridis_c(
    option = "C",
    limits = c(1, 5)
  ) +
  labs(
    title = "Selected Restaurants by Census Tract",
    color = "Business stars"
  ) +
  theme_minimal()

ggplot2::ggsave(
  "figures/restaurants_by_census_tract.png",
  tract_map,
  width = 9,
  height = 7,
  dpi = 300
)

# ============================================================
# Census block group analysis
# ============================================================

# Download Census block group boundaries
block_group_boundaries <- tigris::block_groups(
  state = "LA",
  county = "Orleans",
  cb = TRUE,
  year = 2020,
  class = "sf"
)

# Transform block groups to the restaurant point CRS
block_group_boundaries <- sf::st_transform(
  block_group_boundaries,
  sf::st_crs(restaurant_points)
)

# Join restaurants to block groups
restaurants_block_group <- restaurant_points |>
  sf::st_join(
    block_group_boundaries |>
      dplyr::select(
        block_group = GEOID
      ),
    join = sf::st_within,
    left = TRUE
  )

# Summarize restaurants by block group
block_group_summary <- restaurants_block_group |>
  sf::st_drop_geometry() |>
  dplyr::filter(!is.na(block_group)) |>
  dplyr::group_by(block_group) |>
  dplyr::summarise(
    number_of_restaurants = dplyr::n(),
    average_business_stars = mean(stars, na.rm = TRUE),
    median_business_stars = median(stars, na.rm = TRUE),
    total_reviews = sum(review_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(
    dplyr::desc(number_of_restaurants)
  )

write.csv(
  as.data.frame(block_group_summary),
  "tables/block_group_restaurant_summary.csv",
  row.names = FALSE
)

# Create Census block group map
block_group_map <- ggplot() +
  geom_sf(
    data = block_group_boundaries,
    fill = "grey95",
    color = "grey60"
  ) +
  geom_sf(
    data = restaurants_block_group,
    aes(color = stars),
    size = 2,
    alpha = 0.8
  ) +
  scale_color_viridis_c(
    option = "C",
    limits = c(1, 5)
  ) +
  labs(
    title = "Selected Restaurants by Census Block Group",
    color = "Business stars"
  ) +
  theme_minimal()

ggplot2::ggsave(
  "figures/restaurants_by_block_group.png",
  block_group_map,
  width = 9,
  height = 7,
  dpi = 300
)

# ============================================================
# Geographic comparison table
# ============================================================

zcta_counts <- restaurants_zcta |>
  sf::st_drop_geometry() |>
  dplyr::count(
    zcta,
    name = "restaurant_count"
  ) |>
  dplyr::filter(!is.na(zcta))

tract_counts <- restaurants_tract |>
  sf::st_drop_geometry() |>
  dplyr::count(
    tract,
    name = "restaurant_count"
  ) |>
  dplyr::filter(!is.na(tract))

block_group_counts <- restaurants_block_group |>
  sf::st_drop_geometry() |>
  dplyr::count(
    block_group,
    name = "restaurant_count"
  ) |>
  dplyr::filter(!is.na(block_group))

geographic_system_comparison <- data.frame(
  geographic_system = c(
    "ZCTA",
    "Census tract",
    "Census block group"
  ),
  number_of_areas = c(
    nrow(zcta_counts),
    nrow(tract_counts),
    nrow(block_group_counts)
  ),
  restaurants_assigned = c(
    sum(!is.na(restaurants_zcta$zcta)),
    sum(!is.na(restaurants_tract$tract)),
    sum(!is.na(restaurants_block_group$block_group))
  ),
  unmatched_restaurants = c(
    sum(is.na(restaurants_zcta$zcta)),
    sum(is.na(restaurants_tract$tract)),
    sum(is.na(restaurants_block_group$block_group))
  ),
  smallest_area_count = c(
    min(zcta_counts$restaurant_count),
    min(tract_counts$restaurant_count),
    min(block_group_counts$restaurant_count)
  ),
  largest_area_count = c(
    max(zcta_counts$restaurant_count),
    max(tract_counts$restaurant_count),
    max(block_group_counts$restaurant_count)
  )
)

write.csv(
  geographic_system_comparison,
  "tables/geographic_system_comparison.csv",
  row.names = FALSE
)

# ============================================================
# End of analysis
# ============================================================