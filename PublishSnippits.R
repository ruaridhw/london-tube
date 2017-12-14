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

### Using XPaths to extract the Operating Period of every file ----

namespace <- c(txc = "http://www.transxchange.org.uk/")
xpath <- ".//txc:Services/txc:Service/txc:OperatingPeriod/*"

rootdir <- "0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017"
files <- list.files(rootdir, pattern = "tfl_1-[^.]+\\.xml")

dates <- sapply(files, function(x) {
  xmlParse(file.path(rootdir, x)) %>%
    xmlRoot %>%
    xpathApply(xpath, namespaces = namespace, fun = function(y) xmlValue(y) %>% as.Date)
}, simplify = FALSE) %>%
{data.table(names(.), rbindlist(.))}
names(dates) <- c("File", "StartDate", "EndDate")
#str(dates)

library(lubridate)
relevant_dates <- dates %$%
  interval(StartDate, EndDate) %>%
  {today() %within% .} %>%
  dates[.]


### Retreive Vehicle Journeys that relate to a given day of the week ----

get_weekday_category <- function(timetable_date = lubridate::today()){
  day_of_week <- weekdays(timetable_date)
  day_category <- ifelse(day_of_week %in% c("Saturday", "Sunday"), "Weekend", "MondayToFriday")
  c(day_of_week, day_category)
}


daysofweek <- sapply(files, function(x) {
  xmlParse(file.path(rootdir, x)) %>%
    xmlRoot %>%
    xpathApply(".//txc:VehicleJourneys/txc:VehicleJourney/txc:OperatingProfile/txc:RegularDayType/txc:DaysOfWeek/*", namespaces = namespace, fun = xmlName)
}, simplify = FALSE) %>%
  unlist %>%
  unique
# [1] "Sunday"         "Wednesday"      "Friday"         "Thursday"       "Monday"        
# [6] "Saturday"       "MondayToFriday" "Tuesday"        "Weekend"  

weekday_vec <- get_weekday_category(today())
xpath_required_days <- sprintf(".//txc:VehicleJourneys/txc:VehicleJourney[descendant::txc:DaysOfWeek/txc:%s or descendant::txc:DaysOfWeek/txc:%s]", weekday_vec[1], weekday_vec[2])

xmlParse(file.path(rootdir, "tfl_1-BAK-_-y05-430200.xml")) %>%
  xmlRoot %>%
  xpathApply(xpath_required_days, namespaces = namespace)


terminal_nodesets <- lapply(paste0("/TransXChange/VehicleJourneys/VehicleJourney", "[descendant::DaysOfWeek/", weekday_vec[1], " or descendant::DaysOfWeek/", weekday_vec[2], "]"), xml2::xml_find_all, x = doc)

library(xmltools)
library(purrr)
library(dplyr)
df_VehicleJourneys <- terminal_nodesets %>%
  map(xml_dig_df) %>%
  map(bind_rows) %>%
  bind_cols %>%
  select(VehicleJourneyCode, ServiceRef, JourneyPatternRef, DepartureTime)


df2 %>%
  filter(JourneyPatternRef == "JP_1-BAK-_-y05-430200-2-O-1") %>%
  arrange(DepartureTime)
