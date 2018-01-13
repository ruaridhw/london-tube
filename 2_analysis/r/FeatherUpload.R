#' ---
#' title: "Feather Upload"
#' ---
#'
#' This script reads a directory of Feather files as output from XMLParsing.py
#' and pushes the dataframes to a PostgreSQL database.
#'
#' Note: Since the `dbWriteTable` statement uses `append = TRUE` to upload
#' successive dataframes to the same table, if recalling this upload procedure
#' all tables will need to be manually truncated first.
#' 
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/r/FeatherUpload.R)
# ---- docker, engine="bash", eval=F
# docker run --name postgres_london_tube -p 5432:5432 -d -e POSTGRES_PASSWORD=mysecretpassword postgres:alpine

library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
host <- "localhost"
user <- "postgres"
password <- "mysecretpassword"

#' Create database if it doesn't already exist

# con <- dbConnect(drv, host = host, user = user, password = password,
#                  dbname = "postgres")
# dbSendQuery(con, "CREATE DATABASE londontubepython;")
# dbDisconnect(con)

get_con <- function() dbConnect(drv, host = host, user = user, password = password,
                                dbname = "londontubepython")

source("r/VariableCreation.R") # Load required Variable Creation functions

library(feather)
con <- get_con()
files <- list.files("../1_data/1_2_processed_data", full.names = TRUE) # relative to london-tube.Rproj
then <- Sys.time()
lapply(files, function(file){
  df <- feather::read_feather(file)
  tablename <- substring(basename(tools::file_path_sans_ext(file)), 5)

  # Dispatch appropriate modification procedure depending on the tablename
  df <- modify_df(tablename, df)

  dbWriteTable(con, tablename, df, append = TRUE, row.names = FALSE)
})

#' RPostgreSQL does not support "time" db data type.
#' [Uploads POSIXct as "timestamp with time zone"](https://github.com/tomoakin/RPostgreSQL/blob/f93cb17cf584d57ced5045a46d16d2bfe05a2769/RPostgreSQL/R/PostgreSQLSupport.R#L717)
#' so we need to strip date and timezone
dbSendQuery(con, paste('ALTER TABLE "VehicleJourneys"',
                       'ALTER COLUMN "DepartureTime" TYPE time(6) USING "DepartureTime"::time(6);'
                       ))

now <- Sys.time()
dbDisconnect(con)
now - then
#> Time difference of 28.46938 secs
