# Use devtools for sourcing R scripts online
# Load necessary libraries
library(devtools)
library(jsonlite)
library(tidyverse)
library(sf)
library(gfwr)
library(janitor)

# Paths to the R scripts inside the container
calculate_surface_path <- "/app/R/calculate_surface.R"
download_GFW_data_path <- "/app/R/download_GFW_data.R"

# Source the R scripts
source(calculate_surface_path)
source(download_GFW_data_path)
Sys.setenv(GFW_TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImtpZEtleSJ9.eyJkYXRhIjp7Im5hbWUiOiJ0cmF3bF93YXRjaCIsInVzZXJJZCI6MTk3NTYsImFwcGxpY2F0aW9uTmFtZSI6InRyYXdsX3dhdGNoIiwiaWQiOjIxNzIsInR5cGUiOiJ1c2VyLWFwcGxpY2F0aW9uIn0sImlhdCI6MTczNjg3MTQ2OCwiZXhwIjoyMDUyMjMxNDY4LCJhdWQiOiJnZnciLCJpc3MiOiJnZncifQ.kcwlppP-MkoxG8l9wK-Gf5nVD4I3uMQ1JyoQ7x9b3V3iqVy0IpEGaZ4kqJlkgx2VrpEFjc5uuplRyH5GGJ69znElqucoXeOIxvXMOLtpuwlObwUYUNrzB7pCxgpfwbu79XL0xiGnPkGIFd7ti7MbJSeQxjpImf2J9QPrY1Wmr0wn2teqQlAiwehKPe1Se6itXM6PGtIIVYRk5gqiuSttet5_AO6naHYzWF8r1vYqJVsLXYo5Dksp3w8X9iy-uEKUEJtTXI40Nl379e1WQkYHU62HGWc393ruYSNg7PAs1LKbHG7zmCk0A3MXQdqWAi4UujbRiTmpQ1MCJqi7dppALgZNE76sqeP1PtCSBwnOh3jrAI79UGggVqZWJpIdpEIK_C4WMUAEfwa3KvZ8q2KsJg6ZnEeNKmJCNEP07hGAQgdItGKtP9j1fCZVw2l4OMhhcEhsNNT5YV5VFivUh-FHpfl5mM8aemLgd6PgEFdpkRsyI-WnMtnyE2i5ihbDwW_r")


  # Use dedicated GFW API key
  key <- gfw_auth()
  

  
  # Load datasets directly from GitHub
  options(timeout = 300)  # Set timeout to 5 minutes
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
  total_surface <- round(sum(surface_data$swept_area_km2), 0)


  # Define updated equivalences (areas in km²)
  equivalences <- c(
    "du Parc naturel régional des Caps et Marais d'Opale" = 4300,
    "de 10 fois le parc national des Calanques" = 5200,
    "du Lot" = 5217,
    "du Lot-et-Garonne" = 5361,
    "du Vaucluse" = 5600,
    "de Bali" = 5700,
    "de la Vendée" = 6000,
    "de Shanghai" = 6300,
    "du Morbihan" = 6800,
    "de 10 fois la ville de New York" = 7000,
    "de Maine-et-Loire" = 7100,
    "de 10 fois Singapour" = 7200,
    "de 10 fois le parc national du Kilimandjaro" = 7500,
    "de Mayotte, La Réunion, Martinique et Guadeloupe" = 7800,
    "des Îles Galápagos" = 8000,
    "de la Corse" = 8680,
    "du Parc de Yellowstone" = 8900,
    "de Chypre" = 9250,
    "de Maine-et-Loire et du Rhône" = 10300,
    "du Liban" = 10400,
    "du Lot-et-Garonne et du Lot" = 10500,
    "de la Gironde" = 10700,
    "de l'Île-de-France" = 12000,
    "de 50 fois Marseille" = 12030,
    "du Vanuatu" = 12100,
    "du Nord et des Pyrénées-Atlantiques" = 13300,
    "du Parc national du Serengeti" = 14700,
    "de 50 fois la ville de Dunkerque" = 14995,
    "de 10 fois la ville de Londres" = 15000,
    "des Landes et des Pyrénées-Atlantiques" = 16888,
    "des Îles Fidji" = 18270,
    "de la Charente-Maritime, de la Vienne et des Deux-Sèvres" = 19864,
    "de la Corse et de l'Île-de-France" = 20000,
    "de la Vendée, de la Loire-Atlantique et de Maine-et-Loire" = 20700,
    "du Salvador" = 21041,
    "de la Vendée, de la Loire-Atlantique, de Maine-et-Loire et de l'Essonne" = 22500,
    "de la Vendée, de la Loire-Atlantique, de Maine-et-Loire et du Rhône" = 23950,
    "de la Sardaigne" = 24000,
    "de la Guadeloupe, de la Martinique, de La Réunion, de Mayotte et de la Nouvelle-Calédonie" = 24217,
    "de la Sicile" = 25700,
    "de la Vendée, de la Loire-Atlantique, de Maine-et-Loire et de la Mayenne" = 25876,
    "du Rwanda" = 26300,
    "de la Bretagne" = 27724,
    "de la Normandie" = 29906,
    "de 10 fois le parc national du Yosemite aux USA" = 30000,
    "de la Belgique" = 30689,
    "de Provence-Alpes-Côte-d'Azur" = 31400,
    "des Hauts-de-France" = 31806,
    "du Pays de la Loire" = 32082,
    "de Taïwan" = 36197,
    "du Pays de la Loire et des Alpes-Maritimes" = 36380,
    "du Centre-Val de Loire" = 38151,
    "du Bhoutan" = 38300,
    "des Pays-Bas" = 38300,
    "du Pays de la Loire et de la Somme" = 38352,
    "de la Suisse" = 41200,
    "du Centre-Val de Loire et du Tarn-et-Garonne" = 41800,
    "du Parc National du Wood Buffalo (Canada)" = 44700,
    "de 1/10 de la France métropolitaine" = 54400,
    "du Sri Lanka" = 65000,
    "de la Tasmanie" = 68000,
    "de l'Islande" = 103000,
    "de Cuba" = 109000
  )

   # Define updated picto
  equivalences_picto <- c(
    "Parc National" = 4300,
    "Parc National" = 5200,
    "Département" = 5217,
    "Département" = 5361,
    "Département" = 5600,
    "Région" = 5700,
    "Région" = 6000,
    "Ville" = 6300,
    "Région" = 6800,
    "Ville" = 7000,
    "Département" = 7100,
    "Pays" = 7200,
    "Parc National" = 7500,
    "Région" = 7800,
    "Parc National" = 8000,
    "Région" = 8680,
    "Parc National" = 8900,
    "Pays" = 9250,
    "Département" = 10300,
    "Pays" = 10400,
    "Département" = 10500,
    "Département" = 10700,
    "Région" = 12000,
    "Ville" = 12030,
    "Pays" = 12100,
    "Département" = 13300,
    "Parc National" = 14700,
    "Ville" = 14995,
    "Ville" = 15000,
    "Département" = 16888,
    "Pays" = 18270,
    "Département" = 19864,
    "Région" = 20000,
    "Département" = 20700,
    "Pays" = 21041,
    "Département" = 22500,
    "Département" = 23950,
    "Région" = 24000,
    "Région" = 24217,
    "Région" = 25700,
    "Département" = 25876,
    "Pays" = 26300,
    "Région" = 27724,
    "Région" = 29906,
    "Parc National" = 30000,
    "Pays" = 30689,
    "Région" = 31400,
    "Région" = 31806,
    "Région" = 32082,
    "Pays" = 36197,
    "Région" = 36380,
    "Région" = 38151,
    "Pays" = 38300,
    "Pays" = 38300,
    "Région" = 38352,
    "Pays" = 41200,
    "Région" = 41800,
    "Parc National" = 44700,
    "Pays" = 54400,
    "Pays" = 65000,
    "Pays" = 68000,
    "Pays" = 103000,
    "Pays" = 109000
  )
  
  # Find the closest equivalence
  closest_equivalence <- names(equivalences)[which.min(abs(equivalences - total_surface))]
  
  # Create equivalence string
  equivalence_text <-  paste("Soit l'équivalent de la surface", closest_equivalence)

  # Find the picto corresponding to closest equivalence
  picto <- names(equivalences_picto)[which.min(abs(equivalences - total_surface))]  

data <- list(
  surface_f = total_surface,
  equivalence_text_f = equivalence_text,
  picto_f = picto
)

# Save output as JSON file
write(toJSON(data, pretty = TRUE), "/app/output/toplumb.json")
  