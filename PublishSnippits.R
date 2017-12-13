### Reading the entirety of an XML file ----

library(magrittr)
library(XML)
file <- "0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017/tfl_1-BAK-_-y05-1462422.xml"
data <- xmlParse(file) %>%
  xmlToList

# List of 9
# $ NptgLocalities        :List of 25
# $ StopPoints            :List of 43
# $ RouteSections         :List of 13
# $ Routes                :List of 13
# $ JourneyPatternSections:List of 42
# $ Operators             :List of 1
# $ Services              :List of 1
# $ VehicleJourneys       :List of 501
# $ .attrs                :Formal class 'XMLAttributes' [package "XML"] with 1 slot

library(data.table)
NptgLocalities <- rbindlist(data[["NptgLocalities"]], fill = TRUE)

clean_xml <- function(x){
  x %>%
    lapply(unlist) %>%
    {do.call(rbind, .)} %>%
    as.data.table
}

x <- xmlParse("0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017/tfl_1-BAK-_-y05-430200.xml") %>%
  xmlToList %>% 
  {clean_xml(.[["VehicleJourneys"]])}
