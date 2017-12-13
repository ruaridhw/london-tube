library(rio)

timetable_path <- "0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017"
list.files(timetable_path, pattern = "xml")

x <- import("0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017/tfl_1-BAK-_-y05-1462422.xml")


library(xml2)
library(magrittr)
library(xmltools)

file <- "0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017/tfl_1-BAK-_-y05-1462422.xml"

doc <- file %>%
  xml2::read_xml()
nodeset <- doc %>%
  xml2::xml_children() # get top level nodeset

# `xml_view_tree` structure
# we can get a tree for each node of the doc
doc %>% 
  xml_view_tree()
doc %>% # we can also vary the depth
  xml_view_tree(depth = 2)

nodeset[1] %>%
  xml_view_trees()
