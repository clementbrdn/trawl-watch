 # Load necessary libraries
install.packages(c('plumber', 'devtools', 'systemfonts', 'ragg', 'textshaping', 'pkgdown'))
install.packages("gfwr", 
                 repos = c("https://globalfishingwatch.r-universe.dev",
                           "https://cran.r-project.org"))
install.packages('tidyverse')
install.packages('janitor')
install.packages('sf')
# Use devtools for sourcing R scripts online
library(devtools)
source_url("https://raw.githubusercontent.com/RaphSeguin/trawl_watch/main/R/download_GFW_data.R")
source_url("https://raw.githubusercontent.com/RaphSeguin/trawl_watch/main/R/calculate_surface.R")


# Load necessary libraries
library(tidyverse)
library(sf)
library(gfwr)
library(janitor)

  # Use dedicated GFW API key
  key <- gfw_auth()
  

  
  # Load datasets directly from GitHub
  url <- "https://raw.githubusercontent.com/RaphSeguin/trawl_watch/main/output/France_MPA_dissolved.Rdata"
  con <- url(url)
  load(con)
  close(con)
  
  url <- "https://raw.githubusercontent.com/RaphSeguin/trawl_watch/main/output/gear_widths.Rdata"
  con <- url(url)
  load(con)
  close(con)
  
  GFW_registry <- read.csv("https://raw.githubusercontent.com/RaphSeguin/trawl_watch/main/data/fishing-vessels-v2.csv") %>%
    dplyr::select(mmsi, vessel_class_gfw, flag_registry, flag_gfw, length_m_registry, length_m_gfw, length_m_inferred,
                  engine_power_kw_registry, engine_power_kw_gfw, engine_power_kw_inferred,
                  tonnage_gt_registry, tonnage_gt_inferred) %>%
    mutate(mmsi = as.factor(mmsi))
  
  trawlers <- readRDS(url("https://raw.githubusercontent.com/RaphSeguin/trawl_watch/main/data/clean_fleet_register_20240618xl.rds")) %>%
    clean_names() %>%
    mutate(mmsi = as.factor(mmsi), main_gear_cat = as.factor(main_gear_cat)) %>%
    filter(main_gear_cat == "Bottom trawls & dredges") %>%
    group_by(mmsi) %>%
    arrange(desc(event_end_date)) %>%
    slice(1) %>%  # Keep only the most recent record for each mmsi
    ungroup() %>%
    dplyr::select(country, mmsi, length, power, main_gear, tonnage_gt)
  
  # Execute your functions
  fishing_effort_clean <- download_GFW_data(
    France_MPA_dissolved, 
    GFW_registry, 
    trawlers, 
    "2025-01-01",  # Current date for daily execution
    Sys.Date()   # Same day (daily estimate)
  )
  
  surface_data <- calculate_surface(fishing_effort_clean, gear_widths)
  
  # Calculate the total trawled surface area
  total_surface <- round(sum(surface_data$swept_area_km2), 2)
  
