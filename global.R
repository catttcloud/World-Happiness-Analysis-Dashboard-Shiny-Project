library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinycssloaders)
library(shinyWidgets)

library(rnaturalearth)  
library(sf)

library(ggplot2)
library(forecast)
library(leaflet)
library(dplyr)
library(tidyr)
library(readr)
library(plotly)
library(RColorBrewer)
library(reshape2)
library(DT)

# load the dataset
dataset_by_country <- read.csv('dataset/Data_by_Country.csv')
dataset_by_year <- read.csv('dataset/Data_by_Year.csv')

## Data Process
# Merge your data with world map data in 2024
world <- ne_countries(scale = "medium", returnclass = "sf")
world_data <- world %>%
  left_join(dataset_by_country, by = c("name" = "Country.name"))

# average score in 2024
global_avg_score <- mean(world_data$Ladder.score, na.rm = TRUE)
global_median_score <- median(world_data$Ladder.score, na.rm = TRUE)
# min and max score in 2024
global_min_score <- min(world_data$Ladder.score, na.rm = TRUE)
global_max_score <- max(world_data$Ladder.score, na.rm = TRUE)
# the happiest and least happiness countries
median_happy_country_data <- world_data %>%
  filter(Ladder.score == global_median_score) %>%
  select(name, Ladder.score)
median_happy_country <- median_happy_country_data$name[1]
most_happy_country <- world_data %>%
  filter(Ladder.score == global_max_score) %>%
  select(name, Ladder.score)
least_happy_country <- world_data %>%
  filter(Ladder.score == global_min_score) %>%
  select(name, Ladder.score)





