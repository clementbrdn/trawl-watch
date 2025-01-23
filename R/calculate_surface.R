calculate_surface <- function(fishing_effort_clean, gear_widths){

  #Gear widths from 
  # #https://academic.oup.com/icesjms/article/73/suppl_1/i27/2573989
  # gear_widths <- get_benthis_parameters() 
  # save(gear_widths, file = "output/gear_widths.Rdata")
  # 
  #Clean gear width and associate with fishing gear declarede in the registry
  gear_widths_clean <- gear_widths %>% 
    mutate(gear_group = as.factor(case_when(
      benthisMet %in% c("OT_SPF", "OT_DMF", "OT_MIX_DMF_BEN", "OT_MIX", "OT_MIX_DMF_PEL", "OT_MIX_CRU_DMF", "OT_MIX_CRU", "OT_CRU") ~ "OT", # Otter trawls
      benthisMet %in% c("SDN_DMF", "SSC_DMF") ~ "SDN", # Danish and Scottish seines as OT
      benthisMet %in% c("TBB_CRU", "TBB_DMF", "TBB_MOL") ~ "BT", # Beam trawls
      benthisMet %in% c("DRB_MOL") ~ "TD" # Towed dredges
    ))) %>%
    #Average fishing speed for each gear group
    group_by(gear_group) %>%
    reframe(avFspeed = mean(as.numeric(avFspeed))) %>%
    ungroup() %>%
    dplyr::select(gear_group, avFspeed) 
  
  #Get gear
  fishing_effort_width <- fishing_effort_clean %>% 
    #Rename fishing gears by registry names
    mutate(gear_group = as.factor(case_when(
      main_gear %in% c("Single boat bottom otter trawls", "Twin bottom otter trawls", "Bottom pair trawls", "Bottom trawls (nei)",
                       "Bottom trawls shrimp trawls") ~ "OT",
      main_gear %in% c("Towed dredges","Undet. dredges","Mechanized dredges") ~ "TD",
      main_gear %in% c("Beam trawls") ~ "BT",
      main_gear %in% c("Danish seines") ~ "SDN"))) %>%
   # If there is no gear group we assume they are otter trawls as they are the most common. 
    mutate(gear_group = as.factor(case_when(
      !is.na(gear_group) ~ gear_group,
      vessel_class_gfw == "trawlers" ~ "OT",
      vessel_class_gfw == "dredge_fishing" ~ "TD"
    ))) %>%
    #Remove seines
    filter(gear_group != "SDN") %>%
    # Using the estimates from [Eigaard et al](https://academic.oup.com/icesjms/article/73/suppl_1/i27/2573989#supplementary-data) we can estimate gear width as:
    #                                          
    #- Dredgers: operate at 2-2.5 kts, very shallow, and use 0.72-3m width dredges. 
    # $$W = 0.3142*LOA^{1.2454}$$
    #
    # - Otter trawl (OT): operate at 2-4 kts, 25-250 m between doors width, between 10-2500 m deep. Equation from OT_MIX group,  representative of most number of species 
    #$$W = 10.6608*KW^{0.2921}$$
    #
    # Beam trawl (BT): operate usually two beam with a total widht between 4-12m, speed between 2.5-7 knts,  and shallower than 100m. Equation from TBB_DMF group, representative of most number of species 
    #$$W = 0.6601*KW^{0.5078}$$
    mutate(gear_width = case_when(
      gear_group == "BT" ~ 0.6601*final_power^(0.5078),
      gear_group == "OT" ~ 10.6608*final_power^(0.2921),
      gear_group %in% c("TD", "HD") ~ 0.3142*final_length^(1.2454)
    )) %>%
    left_join(gear_widths_clean, by = "gear_group") %>%
    #Convert gear width
    mutate(gear_width = gear_width/1000) %>%
    # filter(!is.na(main_gear)) %>%
    #Calculate swept area 
    mutate(swept_area_km2 = gear_width*apparent_fishing_hours*avFspeed*1.852) 
  
  # coords <- st_coordinates(fishing_effort_width %>% st_transform(crs = 4326))
  # 
  # vec <- c("#ffc6c4", "#f4a3a8", "#e38191", "#cc607d", "#ad466c", "#8b3058", "#672044")
  # 
  # SAR_2024 <- fishing_effort_width %>%
  #   st_drop_geometry() %>%
  #   cbind(coords) %>%
  #   group_by(X,Y) %>%
  #   reframe(sum_sar = sum(swept_area_km2)) %>%
  #   ungroup() %>%
  #   filter(sum_sar > 0) %>%
  #   st_as_sf(coords = c("X","Y"), crs = 4326) %>%
  #   ggplot() + 
  #   geom_sf(data = france) +
  #   geom_sf(aes(color = log10(sum_sar + 1)), shape = ".") + 
  #   scale_color_gradientn(colors = vec, breaks = c(0,)) +
  #   xlim(-10,10) +
  #   ylim(40,52)
  # 
  # ggsave(SAR_2024, file = "SAR_2024.jpg")
  # 
  # # Filter main_gear with at least 10 unique MMSI
  # filtered_fishing_effort <- fishing_effort_width %>%
  #   st_drop_geometry() %>%
  #   group_by(main_gear) %>%
  #   filter(n_distinct(mmsi) >= 10) %>%
  #   ungroup() %>%
  #   na.omit() %>%
  #   mutate(main_gear = case_when(
  #     main_gear == "Beam trawls" ~ "Chaluts à perche",
  #     main_gear == "Danish seines" ~ "Sennes danoises",
  #     main_gear == "Mechanized dredges" ~ "Dragues mécanisées",
  #     main_gear == "Scottish seines" ~ "Sennes écossaises",
  #     main_gear == "Single boat bottom otter trawls" ~ "Chaluts à panneaux de fond",
  #     main_gear == "Towed dredges" ~ "Dragues remorquées",
  #     main_gear == "Twin bottom otter trawls" ~ "Chaluts à panneaux de fond jumelés",
  #     TRUE ~ main_gear  # Keeps the original value if no match is found
  #   ))
  # 
  # # Plot the filtered data
  # (taille_filet <- filtered_fishing_effort %>%
  #   ggplot(aes(reorder(gear_group,-gear_width), gear_width)) +
  #   geom_boxplot() + 
  #   theme_minimal() + 
  #   labs(x = " ",
  #        y = "Ouverture des filets (mètres)"))
  # 
  # ggsave(taille_filet, file = "taille_filet.jpg", width = 297, height = 210, units = "mm", dpi = 300)
  
  return(fishing_effort_width)

}

