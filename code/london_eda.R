library(tidyverse)
library(ggplot2)
library(readr)
library(readxl)
library(mapview)

london_census <- str_subset(list.files(), "^2021")
london_2021 <- vector("list", length(london_census))
london_2011 <- vector("list", length(london_census))
prototype <- read_xlsx('/Users/jonghyunoh/Documents/SNU/4-1/데이터마이닝 방법 및 실습/London Housing/Data/2021 census lsoa housing/accommodation type.xlsx', sheet = 3)

# Counting the number of sheets in each excel file.
sheet_count <- vector("list", length(london_census))
for (i in 1:length(london_census)) {
  census_folder <- london_census[i]
  folder_files <- list.files(census_folder)
  sheet_count[[i]] <- rep(0, length(folder_files))
  for (j in 1:length(folder_files)) {
    sheet_count[[i]][j] <- length(excel_sheets(paste0(census_folder, "/", folder_files[j])))
  }
}
sheet_count

# Read & Merge the Census data
for (i in 1:length(london_census)) {
  census_folder <- london_census[i]
  folder_files <- list.files(census_folder)
  london_2011[[i]] <- prototype[1]
  london_2021[[i]] <- prototype[1]
  for (j in 1:length(folder_files)) {
    if (sheet_count[[i]][j] >= 4) {
      data_2011 <- read_xlsx(paste0(census_folder, "/", folder_files[j]), sheet = 3)
      data_2011 <- data_2011 |> rename_with(
        ~paste0(folder_files[j], "_", colnames(data_2011)[-str_which(colnames(data_2011), "LSOA|local authority")]), colnames(data_2011)[-str_which(colnames(data_2011), "LSOA|local authority")]
      )
      data_2021 <- read_xlsx(paste0(census_folder, "/", folder_files[j]), sheet = 4)
      data_2021 <- data_2021 |> rename_with(
        ~paste0(folder_files[j], "_", colnames(data_2021)[-str_which(colnames(data_2021), "LSOA|local authority")]), colnames(data_2021)[-str_which(colnames(data_2021), "LSOA|local authority")]
      )
    }
    else if (sheet_count[[i]][j] == 3) {
      data_2021 <- read_xlsx(paste0(census_folder, "/", folder_files[j]), sheet = 3)
      data_2021 <- data_2021 |> rename_with(
        ~paste0(folder_files[j], "_", colnames(data_2021)[-str_which(colnames(data_2021), "LSOA|local authority")]), colnames(data_2021)[-str_which(colnames(data_2021), "LSOA|local authority")]
      )
    }
    if (j == 1) {
      london_2011[[i]] <- full_join(london_2011[[i]], data_2011, by = c("LSOA code"))
      london_2021[[i]] <- full_join(london_2021[[i]], data_2021, by = c("LSOA code"))
    }
    else if (j > 1) {
      london_2011[[i]] <- full_join(london_2011[[i]], data_2011, by = c("LSOA code", "local authority code", "local authority name"))
      london_2021[[i]] <- full_join(london_2021[[i]], data_2021, by = c("LSOA code", "local authority code", "local authority name"))
    }
  }
}

names(london_2011) <- london_census; names(london_2021) <- london_census

house_prices <- read_csv("london_house_price.csv")
head(house_prices)
postal_codes <- read_csv("london_postcodes.csv")
head(postal_codes) #useful columns = postcode, population, national park, london zone, lsoa code, rural/urban, nearest station, distance to station, quality, average income, police force, water company, travel to work area, distance to sea, property type

# Create a super data frame that has all the census information.
for (i in 1:length(london_2011)) {
  colnames(london_2011[[i]]) <- str_remove(colnames(london_2011[[i]]), "\\.xlsx")
}
london_2011_supra <- london_2011[[1]]
for (i in 2:length(london_2011)) {
  london_2011_supra <- full_join(london_2011_supra, london_2011[[i]], by = c('LSOA code', 'local authority code', 'local authority name'))
}
london_2011_supra <- house_prices |> left_join(postal_codes, by = c("postcode" = "Postcode")) |>
  left_join(london_2011_supra, by = c("LSOA Code" = "LSOA code"))

for (i in 1:length(london_2021)) {
  colnames(london_2021[[i]]) <- str_remove(colnames(london_2021[[i]]), "\\.xlsx")
}
london_2021_supra <- london_2021[[1]]
for (i in 2:length(london_2021)) {
  london_2021_supra <- full_join(london_2021_supra, london_2021[[i]], by = c('LSOA code', 'local authority code', 'local authority name'))
}
london_2021_supra <- house_prices |> left_join(postal_codes, by = c("postcode" = "Postcode")) |>
  left_join(london_2021_supra, by = c("LSOA Code" = "LSOA code"))

# Merge the three data sets focused on `house_prices`.
## Shouldn't left_join on the original `london_2011/2021` data frames because their values are not unique to each house data in `postal_codes` and `house_prices` data sets.
london_merged_2011 <- vector("list", length(london_2011))
london_merged_2021 <- vector("list", length(london_2021))
for (i in 1:length(london_merged_2011)) {
  london_merged_2011[[i]] <- house_prices |> left_join(postal_codes, by = c("postcode" = "Postcode")) |>
    left_join(london_2011[[i]], by = c("LSOA Code" = "LSOA code"))
}
for (i in 1:length(london_merged_2021)) {
  london_merged_2021[[i]] <- house_prices |> left_join(postal_codes, by = c("postcode" = "Postcode")) |>
    left_join(london_2021[[i]], by = c("LSOA Code" = "LSOA code"))
}
names(london_merged_2011) <- london_census; names(london_merged_2021) <- london_census

london_merged_2011$`2021 census lsoa housing` |>
  filter(!is.na(history_price)) |>
  select(c("local authority name", "District", "London zone", "Nearest station", "history_price")) |>
  reframe(x = unique(`local authority name`))

# Visualise the data with housing_prices.
london_2021_housing_map <- london_merged_2021$`2021 census lsoa housing` |>
  filter(!is.na(longitude) & !is.na(latitude))

## Identify the number of missing `rentEstimate_currentPrice` data
london_2021_housing_map |>
  mutate(price_exist = as.integer(!is.na(rentEstimate_currentPrice))) |>
  summarise(
  n_total = n(),
  n_filtered = sum(price_exist),
  n_missing = n_total - n_filtered
)

## 2021 Housing Data Map
london_2021_map <- london_2021_supra |>
  filter(year(as.Date(history_date)) == 2021) |>
  sf::st_as_sf(coords = c("longitude", "latitude")) |>
  sf::st_set_crs(4326)

## MAP: LONDON ZONE
ldn_zone_map <- london_2021_supra |>
  filter(year(as.Date(history_date)) == 2021) |>
  select(fullAddress, postcode, longitude, latitude, `London zone`, history_date, history_price) |>
  sf::st_as_sf(coords = c("longitude", "latitude")) |>
  sf::st_set_crs(4326) |>
  ggplot() +
  geom_sf(aes(colour = as.factor(`London zone`)))

## MAP: 2021 Prices
price_2021_map <- london_2021_map |>
  mutate(history_price = cut(london_2021_map$history_price, quantile(london_2021_map$history_price, probs = seq(0, 1, 0.2)))) |>
  ggplot() +
  geom_sf(aes(colour = history_price), alpha = 0.4)

## MAP: Representative NSSEC for each LSOA code.
NSSEC_2021 <- london_2021_supra |>
  filter(year(as.Date(history_date)) == 2021) |>
  select(c("fullAddress", "postcode", "latitude", "longitude", "LSOA Code", starts_with("NSSEC")[-1])) |>
  pivot_longer(cols = starts_with("NSSEC"), names_to = "NSSEC_type", values_to = "NSSEC_count") |>
  group_by(postcode) |>
  summarise(
    NSSEC_rep = NSSEC_type[which.max(NSSEC_count)]
  )
NSSEC_2021_map <- london_2021_map |> left_join(NSSEC_2021, by = "postcode") |>
  ggplot() +
  geom_sf(aes(colour = NSSEC_rep), alpha = 0.4)

## MAP: Representative Biggest Ethnic Minority for each LSOA code.
ethnicity_2021 <- london_2021_supra |>
  filter(year(as.Date(history_date)) == 2021) |>
  select(c("fullAddress", "postcode", "latitude", "longitude", "LSOA Code", starts_with("Ethnic group")[-c(1, 2)])) |>
  pivot_longer(cols = starts_with("Ethnic group"), names_to = "ethnicity", values_to = "ethnicity_count") |>
  group_by(postcode) |>
  summarise(
    ethnicity_rep = ethnicity[which.max(ethnicity_count)]
  )
ethnicity_2021_map <- london_2021_map |> left_join(ethnicity_2021, by = "postcode") |>
  ggplot() +
  geom_sf(aes(colour = ethnicity_rep), alpha = 0.4)


## When is the current date in `house_prices` data set?
### Kaggle website (https://www.kaggle.com/datasets/jakewright/house-price-data?resource=download) states that it is a data collected from 1995 up to Oct 2024.
colnames(house_prices)
london_2021_housing_map |>
  mutate(history_date = as.Date(history_date)) |>
  summarise(
    most_recent = max(history_date)
  )