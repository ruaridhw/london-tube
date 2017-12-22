library(data.table)
library(tibble)
library(feather)
library(RPostgreSQL)
library(magrittr)
library(lubridate)
library(rgdal)

drv <- dbDriver("PostgreSQL")
host <- "localhost"
user <- "postgres"
password <- "mysecretpassword"

# con <- dbConnect(drv, host = host, user = user, password = password,
#                  dbname = "postgres")
# dbSendQuery(con, "CREATE DATABASE londontubepython;")
# dbDisconnect(con)
get_con <- function() dbConnect(drv, host = host, user = user, password = password,
                                dbname = "londontubepython")

con <- get_con()
files <- list.files("1_data/1_2_processed_data", full.names = TRUE) # relative to london-tube.Rproj
then <- Sys.time()
lapply(files, function(file){
  df <- feather::read_feather(file)
  tablename <- substring(basename(tools::file_path_sans_ext(file)), 5)

  if(tablename == "StopPoints") {
    # Define proj4 coordinate systems
    bng = "+init=epsg:27700"
    latlon = "+proj=longlat +datum=WGS84"

    # Create spatial object using BNG coordinates
    coord.bng <-
      with(df,
           SpatialPointsDataFrame(cbind(Place_Location_Easting, Place_Location_Northing) %>%
                                    as.integer() %>% matrix(ncol = 2),
                                  data = data.table(AtcoCode,
                                                    Descriptor_CommonName,
                                                    Place_NptgLocalityRef),
                                  proj4string = CRS(bng)))

    # Cast as latlon coordinates
    coord.latlon <- spTransform(coord.bng, CRS(latlon))

    # Replace dataframe
    df <- as_tibble(coord.latlon)
    names(df) <- c("AtcoCode","CommonName","NptgLocalityRef","Longitude","Latitude")
  } else if (tablename == "VehicleJourneys") {
    df %<>% within({
      DepartureTime %<>% as.POSIXct(format="%T")
      DepartureMins <- DepartureTime %>% {lubridate::minute(.) + 60 * lubridate::hour(.)}
    })
  } else if (tablename == "JourneyPatternTimingLinks") {
    df %<>% within({
      From_SequenceNumber	%<>% as.integer
      To_SequenceNumber	%<>% as.integer
      RunTime %<>% substr(3, 3) %>% as.integer
      WaitTime %<>% substr(3, 3) %>% as.integer
      JourneyTime <- RunTime + ifelse(is.na(WaitTime), 0, WaitTime)
    })
  } else if (tablename == "RouteLinks") {
    df %<>% within({
      Distance	%<>% as.integer
    })
  } else if (tablename == "Services") {
    df %<>% within({
      OpPeriod_StartDate %<>% as.Date
      OpPeriod_EndDate %<>% as.Date
    })
  }
  dbWriteTable(con, tablename, df, append = TRUE, row.names = FALSE)
})

#' RPostgreSQL does not support "time" db data type.
#' [Uploads POSIXct as "timestamp with time zone"][1] so we need to strip date and timezone
#' [1]: https://github.com/tomoakin/RPostgreSQL/blob/f93cb17cf584d57ced5045a46d16d2bfe05a2769/RPostgreSQL/R/PostgreSQLSupport.R#L717
dbSendQuery(con, paste('ALTER TABLE "VehicleJourneys"',
                       'ALTER COLUMN "DepartureTime" TYPE time(6) USING "DepartureTime"::time(6);'
                       ))

now <- Sys.time()
dbDisconnect(con)
now - then
#> Time difference of 53.60473 secs
