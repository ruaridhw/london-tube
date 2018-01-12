#' ---
#' title: "Get Tables from XPaths"
#' ---
#'
#' Read in the first XML timetable file for inspection and
#' setup extraction process.
#' 
#' Source code used in [ManagingData.Rmd](ManagingData.html).
#' For full documentation and commentary see that report instead.
#' 
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/r/GetTablesFromXPaths.R)
# ---- extraction_setup
# Get top level nodeset for first file
doc <- data.files[1] %>%
  xml2::read_xml() %>%
  xml2::xml_ns_strip()
nodeset <- doc %>%
  xml2::xml_children()

# Get the xpaths to parents of a terminal node
terminal_xpaths <- nodeset %>%
  xmltools::xml_get_paths(only_terminal_parent = TRUE) %>%
  # Filter to unique paths
  unlist() %>%
  unique()
# ---- 

#' Define subset of xpaths required.
# ---- required_xpaths
required_xpaths <- list(
   NptgLocalities = 1
  ,StopPoints = 2:5
  ,RouteLinks = 8:10
  ,Routes = 11
  ,JourneyPatternTimingLinks = 12:14
  ,Services = 16
  ,JourneyPatterns = 24
  ,VehicleJourneys = 26
)
# ---- 

#' Extract the tables by grouping the results from the sets of xpaths
# ---- build_tfl
build_tfl <- function(doc, terminal_xpaths, required_terminal_xpaths) {
  purrr::map(required_terminal_xpaths, function(xpath_idxs) {
    # Subset the needed paths
    terminal_xpaths[xpath_idxs] %>%
      # Find all matches of each path
      lapply(xml2::xml_find_all, x = doc) %>%
      # Extract underlying data
      purrr::map(xmltools::xml_dig_df) %>%
      # Combine extracted data into one dataframe
      purrr::map(dplyr::bind_rows) %>%
      dplyr::bind_cols()
  })
}
# ---- 

#' Get XML attributes and parent IDs
# ---- retrieve_additional_fields, warning=FALSE, message=FALSE
library(dplyr)
retrieve_additional_fields <- function(tfl, doc){
  RouteSectionsNodeset <-
    xml2::xml_find_all(doc, "/TransXChange/RouteSections/RouteSection")
  
  AdditionalRouteLinksData <-
    purrr::map(RouteSectionsNodeset, function(Section) {
      RouteLinks <- xml2::xml_find_all(Section, "RouteLink")
      data.table(
        RouteSectionID = xml2::xml_attr(Section, "id"),
        RouteLinkID = xml2::xml_attr(RouteLinks, "id")
      )
    }) %>%
    rbindlist %>%
    as_tibble
  
  tfl$RouteLinks <- AdditionalRouteLinksData %>%
    bind_cols(tfl$RouteLinks) %>%
    rename(FromStopPointRef = StopPointRef,
           ToStopPointRef = StopPointRef1)
  
  JourneyPatternSectionsNodeset <-
    xml2::xml_find_all(doc, "/TransXChange/JourneyPatternSections/JourneyPatternSection")
  
  AdditionalTimingLinksData <-
    purrr::map(JourneyPatternSectionsNodeset, function(Section) {
      TimingLinks <- xml2::xml_find_all(Section, "JourneyPatternTimingLink")
      
      data.table(
        JourneyPatternSectionID = xml2::xml_attr(Section, "id"),
        JourneyPatternTimingLinkID = xml2::xml_attr(TimingLinks, "id"),
        
        FromSequenceNumber = TimingLinks %>%
          xml2::xml_find_all("From") %>%
          xml2::xml_attr("SequenceNumber") %>%
          as.integer,
        
        ToSequenceNumber = TimingLinks %>%
          xml2::xml_find_all("To") %>%
          xml2::xml_attr("SequenceNumber") %>%
          as.integer
      )
    }) %>%
    rbindlist %>%
    as_tibble
  
  tfl$JourneyPatternTimingLinks <- AdditionalTimingLinksData %>%
    bind_cols(tfl$JourneyPatternTimingLinks) %>%
    rename(FromActivity = Activity,
           FromStopPointRef = StopPointRef,
           FromTimingStatus = TimingStatus,
           ToActivity = Activity1,
           ToStopPointRef = StopPointRef1,
           ToTimingStatus = TimingStatus1)
  
  tfl$JourneyPatterns <-
    tibble(JourneyPatternID =
             "/TransXChange/Services/Service/StandardService/JourneyPattern" %>%
             xml2::xml_find_all(x = doc) %>%
             xml2::xml_attr("id")
    ) %>%
    bind_cols(tfl$JourneyPatterns)
  
  tfl
}
# ---- 

#' Full extraction workflow for one file.
# ---- extract_file
extract_file <- function(file){
  doc <- xml2::read_xml(file) %>%
    xml2::xml_ns_strip()
  
  tfl <- build_tfl(doc, terminal_xpaths, required_xpaths)
  tfl %<>% retrieve_additional_fields(doc)
  
  tfl
}
str(extract_file(data.files[1]), 1)
