download_GFW_data <- function(France_MPA_dissolved, GFW_registry, trawlers, input_start_date, input_end_date){

Sys.setenv(GFW_TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImtpZEtleSJ9.eyJkYXRhIjp7Im5hbWUiOiJ0cmF3bF93YXRjaCIsInVzZXJJZCI6MTk3NTYsImFwcGxpY2F0aW9uTmFtZSI6InRyYXdsX3dhdGNoIiwiaWQiOjIxNzIsInR5cGUiOiJ1c2VyLWFwcGxpY2F0aW9uIn0sImlhdCI6MTczNjg3MTQ2OCwiZXhwIjoyMDUyMjMxNDY4LCJhdWQiOiJnZnciLCJpc3MiOiJnZncifQ.kcwlppP-MkoxG8l9wK-Gf5nVD4I3uMQ1JyoQ7x9b3V3iqVy0IpEGaZ4kqJlkgx2VrpEFjc5uuplRyH5GGJ69znElqucoXeOIxvXMOLtpuwlObwUYUNrzB7pCxgpfwbu79XL0xiGnPkGIFd7ti7MbJSeQxjpImf2J9QPrY1Wmr0wn2teqQlAiwehKPe1Se6itXM6PGtIIVYRk5gqiuSttet5_AO6naHYzWF8r1vYqJVsLXYo5Dksp3w8X9iy-uEKUEJtTXI40Nl379e1WQkYHU62HGWc393ruYSNg7PAs1LKbHG7zmCk0A3MXQdqWAi4UujbRiTmpQ1MCJqi7dppALgZNE76sqeP1PtCSBwnOh3jrAI79UGggVqZWJpIdpEIK_C4WMUAEfwa3KvZ8q2KsJg6ZnEeNKmJCNEP07hGAQgdItGKtP9j1fCZVw2l4OMhhcEhsNNT5YV5VFivUh-FHpfl5mM8aemLgd6PgEFdpkRsyI-WnMtnyE2i5ihbDwW_r")

 # Use dedicated GFW API key
  key <- gfw_auth()
  #Download fishing effort in French EEZ
 fishing_effort <- withTimeout(
  gfwr::get_raster(
    spatial_resolution = 'HIGH',
    temporal_resolution = 'DAILY',
    group_by = 'VESSEL_ID',
    start_date = input_start_date,
    end_date = input_end_date,
    region = 5677,
    region_source = 'EEZ',
    key = key
  ),
  timeout = 900,  # Timeout in seconds
  onTimeout = "error"  # What to do if it times out
)

  #Clean GFW fishing fishing_effort
  fishing_effort_clean <- fishing_effort %>%
    clean_names() %>%
    mutate(mmsi = as.factor(mmsi)) %>%
    #As Sf object
    st_as_sf(coords = c("lon","lat"), crs = 4326) %>%
    #join with French mpas
    st_join(France_MPA_dissolved, join = st_intersects, left = F) %>%
    #Keep only trawler
    #Join with EU fleet registry
    left_join(trawlers, by = "mmsi") %>%
    #Join with GFW registry
    left_join(GFW_registry, by = "mmsi") %>%
    dplyr::filter(!is.na(main_gear) | vessel_class_gfw %in% c("trawlers","dredge_fishing")) %>%
    #Keep best info available for each important parameter
    dplyr::mutate(
      final_length = coalesce(length, length_m_registry, length_m_gfw, length_m_inferred),
      final_power = coalesce(power, engine_power_kw_registry, engine_power_kw_gfw, engine_power_kw_inferred),
      final_flag = coalesce(country, flag_registry, flag_gfw)
    ) %>%
    dplyr::select(time_range, country, mmsi, apparent_fishing_hours, main_gear, final_flag, vessel_class_gfw, final_length, final_power, geometry) %>%
    st_as_sf() 
  
  save(fishing_effort_clean, file = "/app/output/fishing_effort_clean.Rdata")
  
  return(fishing_effort_clean)
  
}