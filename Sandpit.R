library(rio)

timetable_path <- "0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017"
list.files(timetable_path, pattern = "xml")

x <- import("0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017/tfl_1-BAK-_-y05-1462422.xml")


library(xml2)

x <- read_xml(file)

devtools::install_github('dantonnoriega/xmltools')
library(xmltools)
library(magrittr)


file <- "0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017/tfl_1-BAK-_-y05-1462422.xml"
doc <- file %>%
  xml2::read_xml()
nodeset <- doc %>%
  xml2::xml_children() # get top level nodeset
