download_GFW_data <- function(France_MPA_dissolved, GFW_registry, trawlers, input_start_date, input_end_date){
  library(gfwr)
 # Use dedicated GFW API key
  key <- gfw_auth()
  #Download fishing effort in French EEZ
  fishing_effort <- gfwr::get_raster(spatial_resolution = 'HIGH',
             temporal_resolution = 'DAILY',
             group_by = 'VESSEL_ID',
             start_date = input_start_date,
             end_date = input_end_date,
             region = 5677,
             region_source = 'EEZ',
             key = key)

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
  
  save(fishing_effort_clean, file = "output/fishing_effort_clean.Rdata")
  
  return(fishing_effort_clean)
  
}