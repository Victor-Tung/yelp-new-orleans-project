library(tidyverse)
<<<<<<< HEAD

# Filter to New Orleans restaurants
new_orleans_restaurants <- business |>
  filter(
    state == "LA",
    city == "New Orleans",
    !is.na(categories),
    str_detect(
      categories,
      regex("Restaurants", ignore_case = TRUE)
    )
  ) |>
  mutate(
    postal_code = na_if(postal_code, ""),
    categories = str_squish(categories),
    business_name = str_squish(name)
  ) |>
  distinct(business_id, .keep_all = TRUE)

# Filter reviews to New Orleans restaurants
new_orleans_reviews <- reviews |>
  semi_join(
    new_orleans_restaurants,
    by = "business_id"
  )

# Display results
new_orleans_restaurants |>
  summarise(
    number_of_restaurants = n(),
    missing_latitude = sum(is.na(latitude)),
    missing_longitude = sum(is.na(longitude)),
    missing_categories = sum(is.na(categories))
  )

dim(new_orleans_reviews)

# Create the output folder
dir.create(
  "data/new_orleans",
  recursive = TRUE,
  showWarnings = FALSE
)

# Save the filtered business data
saveRDS(
  new_orleans_restaurants,
  "data/new_orleans/business_new_orleans.rds",
  compress = "xz"
)

# Save the filtered review data
saveRDS(
  new_orleans_reviews,
  "data/new_orleans/reviews_new_orleans.rds",
  compress = "xz"
)
=======
library(jsonlite)

business_file <- "data/raw/yelp_academic_dataset_business.json"
review_file <- "data/raw/yelp_academic_dataset_review.json"

business_raw <- jsonlite::stream_in(
  file(business_file),
  verbose = FALSE
)

business <- business_raw |>
  select(
    business_id,
    name,
    address,
    city,
    state,
    postal_code,
    latitude,
    longitude,
    stars,
    review_count,
    categories
  )

review_raw <- jsonlite::stream_in(
  file(review_file),
  verbose = FALSE
)

reviews <- review_raw |>
  select(
    business_id,
    user_id,
    stars,
    date,
    text,
    useful,
    funny,
    cool
  )

dim(business)
dim(reviews)

dplyr::glimpse(business)
dplyr::glimpse(reviews)
>>>>>>> origin/main
