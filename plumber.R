# Load plumber
library(plumber)
library(jsonlite)

#* @apiTitle Daily Fishing Data Script
#* @apiDescription API to calculate daily trawled surface area in French MPAs.


#* Run the script and return the daily trawled surface
#* @get /run
function() {
  file_path <- "/app/output/toplumb.json"
  
  if (!file.exists(file_path)) {
    return(list(error = "No data available yet"))
  }
  
  data <- fromJSON(file_path)
  return(data)
  
}