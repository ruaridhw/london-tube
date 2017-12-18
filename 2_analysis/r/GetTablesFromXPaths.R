

"/TransXChange/VehicleJourneys/VehicleJourney" %>%
  lapply(xml2::xml_find_all, x = doc) %>%
  purrr::map(xml_dig_df, dig = TRUE) %>%
  purrr::map(dplyr::bind_rows) %>%
  dplyr::bind_cols()


terminal_xpaths <- nodeset %>% ## get all xpaths to parents of parent node
  xml_get_paths(only_terminal_parent = TRUE) %>% ## collapse xpaths to unique only
  unlist() %>%
  unique()


terminal_xpaths[required_terminal_xpaths[[2]]] %>%
  lapply(xml2::xml_find_all, x = doc) %>%
  purrr::map(xml_dig_df, dig = TRUE) %>%
  purrr::map(dplyr::bind_rows) %>%
  dplyr::bind_cols()

required_terminal_xpaths <- list(
   NptgLocalities = 1
  ,StopPoints = 2:5
  ,RouteSections = 8:10
  ,Routes = 11
  ,JourneyPatternSections = 12:14
  ,StandardServices = 24
  ,VehicleJourneys = 26
)

# [1] "/TransXChange/NptgLocalities/AnnotatedNptgLocalityRef"
# [2] "/TransXChange/StopPoints/StopPoint"
# [3] "/TransXChange/StopPoints/StopPoint/Descriptor"
# [4] "/TransXChange/StopPoints/StopPoint/Place"
# [5] "/TransXChange/StopPoints/StopPoint/Place/Location"
# [8] "/TransXChange/RouteSections/RouteSection/RouteLink"
# [9] "/TransXChange/RouteSections/RouteSection/RouteLink/From"
# [10] "/TransXChange/RouteSections/RouteSection/RouteLink/To"
# [11] "/TransXChange/Routes/Route"
# [12] "/TransXChange/JourneyPatternSections/JourneyPatternSection/JourneyPatternTimingLink"
# [13] "/TransXChange/JourneyPatternSections/JourneyPatternSection/JourneyPatternTimingLink/From"
# [14] "/TransXChange/JourneyPatternSections/JourneyPatternSection/JourneyPatternTimingLink/To"
# [23] "/TransXChange/Services/Service/StandardService"
# [24] "/TransXChange/Services/Service/StandardService/JourneyPattern"
# [26] "/TransXChange/VehicleJourneys/VehicleJourney"

tables <- map(required_terminal_xpaths, function(xpath_idxs) {
  terminal_xpaths[xpath_idxs] %>%
    lapply(xml_find_all, x = doc) %>%
    map(xmltools::xml_dig_df) %>%
    map(bind_rows) %>%
    bind_cols
})

JourneyPatternSectionsNodeset <- "/TransXChange/JourneyPatternSections/JourneyPatternSection" %>%
  xml_find_all(x = doc)

tables$JourneyPatternSections <-
  map(JourneyPatternSectionsNodeset, function(Section) {
    TimingLinks <- Section %>%
      xml_find_all("JourneyPatternTimingLink")
    
    data.table(
      JourneyPatternSectionID = Section %>%
        xml_attr("id"),
      
      JourneyPatternTimingLinkID = TimingLinks %>%
        xml_attr("id"),
      
      FromSequenceNumber = TimingLinks %>%
        xml_find_all("From") %>%
        xml_attr("SequenceNumber") %>%
        as.integer,
      
      ToSequenceNumber = TimingLinks %>%
        xml_find_all("To") %>%
        xml_attr("SequenceNumber") %>%
        as.integer
    )
  }) %>%
  rbindlist %>%
  as_tibble %>%
  bind_cols(tables$JourneyPatternSections) %>%
  rename(FromActivity = Activity, FromStopPointRef = StopPointRef, FromTimingStatus = TimingStatus,
         ToActivity = Activity1, ToStopPointRef = StopPointRef1, ToTimingStatus = TimingStatus1)


tables$StandardServices <- tibble(JourneyPatternID =
         "/TransXChange/Services/Service/StandardService/JourneyPattern" %>%
         xml_find_all(x = doc) %>%
         xml_attr("id")
       ) %>%
  bind_cols(tables$StandardServices)
