#' ---
#' title: "Variable Creation"
#' author: "Ruaridh Williamson"
#' ---

#' Functions to assist with typecasting variables from raw XML extraction
#' and creation of new calculated fields prior to upload to a DBMS

library(data.table)
library(tibble)
library(magrittr)
library(lubridate)

#' This function relies on sp, rgdal, tibble and magrittr
# ---- modify_StopPoints
library(rgdal)
modify_StopPoints <- function(df){
  # Define proj4 coordinate systems
  bng = "+init=epsg:27700"
  latlon = "+proj=longlat +datum=WGS84"

  # Create spatial object using BNG coordinates
  coord.bng <-
    with(df,
         SpatialPointsDataFrame(cbind(Place_Location_Easting, Place_Location_Northing) %>%
                                  as.integer() %>% matrix(ncol = 2),
                                data = tibble(AtcoCode,
                                              Descriptor_CommonName,
                                              Place_NptgLocalityRef),
                                proj4string = CRS(bng)))

  # Cast as latlon coordinates
  coord.latlon <- spTransform(coord.bng, CRS(latlon))

  # Replace dataframe
  df <- as_tibble(coord.latlon)
  names(df) <- c("AtcoCode","CommonName","NptgLocalityRef","Longitude","Latitude")
  df
}


# ---- modify_VehicleJourneys
modify_VehicleJourneys <- function(df){
  within(df, {
    DepartureTime %<>% as.POSIXct(format="%T")
    # Extract number of minutes since midnight from DepartureTime
    DepartureMins <- DepartureTime %>% {lubridate::minute(.) + 60 * lubridate::hour(.)}
  })
}


# ---- modify_JourneyPatternTimingLinks
modify_JourneyPatternTimingLinks <- function(df){
  within(df, {
    From_SequenceNumber %<>% as.integer
    To_SequenceNumber %<>% as.integer
    # Extract timings from RunTime and WaitTime to create JourneyTime
    RunTime %<>% substr(3, 3) %>% as.integer
    WaitTime %<>% substr(3, 3) %>% as.integer
    JourneyTime <- RunTime + ifelse(is.na(WaitTime), 0, WaitTime)
  })
}


# ---- modify_RouteLinks
modify_RouteLinks <- function(df){
  within(df, {
    Distance %<>% as.integer
  })
}


# ---- modify_Services
modify_Services <- function(df){
  within(df, {
    OpPeriod_StartDate %<>% as.Date
    OpPeriod_EndDate %<>% as.Date
  })
}


#' Convenience dispatch function
# ---- modify
modify_df <- function(tablename, df){
  if(tablename %in% c("StopPoints", "VehicleJourneys", "JourneyPatternTimingLinks", "RouteLinks", "Services")) {
    df %<>% list %>% do.call(what = paste0("modify_", tablename))
  }
  df
}
