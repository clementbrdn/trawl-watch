# Load plumber

library(plumber)

#* @apiTitle Daily Fishing Data Script
#* @apiDescription API to calculate daily trawled surface area in French MPAs.

#* Run the script and return the daily trawled surface
#* @get /run
function() {  # Return the result as JSON
  list(
    trawled_surface_km2 = total_surface
  )
  
}