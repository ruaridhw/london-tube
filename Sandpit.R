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


doc %>%
  xml_view_trees(1)

nodeset[1] %>%
  xml_children() %>%
  #xml_children() %>%
  #xml_view_trees
  xml_get_paths()


xmldataframe <- xml_to_df(file, xpath = ".//*", is_xml = FALSE, dig = FALSE)

result <- xmlParse(file)
rootnode <- xmlRoot(result)
getDefaultNamespace(result)

rates <- xpathApply(rootnode, ".//txc:Services/txc:Service/txc:OperatingPeriod/*", namespaces = c(txc = getDefaultNamespace(rootnode)[[1]]$uri), fun = xmlValue)
unlist(rates)

getChildrenStrings(rates)

# Print the result.
print(rootnode[2])

xmldataframe <- xmlToDataFrame(rootnode[1]["NptgLocalities"])

terminal_paths <- nodeset[1] %>%
  xml_get_paths(only_terminal_parent = TRUE)



library(data.table)
data <- xmlParse(file)
xml_data <- xmlToList(data)
rbindlist(xml_data[["NptgLocalities"]], fill=TRUE)

library(xmltools)
file <- "0_raw_data/journey-planner-timetables/LULDLRTramRiverCable 05122017/tfl_1-BAK-_-y05-430200.xml"
doc <- file %>%
  xml2::read_xml()
xml2::xml_ns_strip(doc)
nodeset <- doc %>%
  xml2::xml_children()
nodeset[8] %>%
  xml_get_paths(mark_terminal = ">>") %>% ## collapse xpaths to unique only
  unlist() %>%
  unique()


terminal_parent <- nodeset[8] %>% ## get all xpaths to parents of parent node
  xml_get_paths(only_terminal_parent = TRUE)

terminal_xpaths <- terminal_parent %>% ## collapse xpaths to unique only
  unlist() %>%
  unique()


terminal_nodesets <- lapply(terminal_xpaths, xml2::xml_find_all, x = doc)
df2 <- terminal_nodesets[1] %>%
  purrr::map(xml_dig_df, dig = TRUE) %>% ## does not dig by default
  purrr::map(dplyr::bind_rows) %>%
  dplyr::bind_cols() %>%
  dplyr::mutate_all(empty_as_na)

df2 <- xml_dig_df(terminal_nodesets[[1]], dig = TRUE)

df0 <- lapply(terminal_xpaths, function(x) {
  doc_internal <- file %>% XML::xmlInternalTreeParse()
  nodeset <- XML::getNodeSet(doc, x)
  XML::xmlToDataFrame(nodeset, stringsAsFactors = FALSE) %>%
    dplyr::as_data_frame()
})



xmlParse(file.path(rootdir, "tfl_1-BAK-_-y05-430200.xml")) %>%
  xmlRoot %>%
  xpathApply(".//txc:VehicleJourneys/txc:VehicleJourney[descendant::txc:DaysOfWeek/txc:Thursday]", namespaces = namespace)


xml_find_first(doc, "/TransXChange/JourneyPatternSections/JourneyPatternSection/@id") %>%
  xml_attrs


"/TransXChange/JourneyPatternSections/JourneyPatternSection/@id" %>%
  lapply(xml2::xml_find_all, x = doc) %>%
  {.[[1]]} %>%
  map(xml_text())
map(xml2::xml_attr()) %>%
  t() %>%
  tibble::as_tibble()

"/TransXChange/JourneyPatternSections/JourneyPatternSection/JourneyPatternTimingLink/From"  %>%
  lapply(xml2::xml_find_all, x = doc) %>%
  map(xml_dig_df, dig = TRUE) %>%
  map(dplyr::bind_rows) %>%
  bind_cols()
# 4,743 rows
