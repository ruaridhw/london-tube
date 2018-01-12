#' ---
#' title: "SQL Tables"
#' ---
#'
#' This script is part of the R extraction process and follows on from
#' [GetTablesFromXPaths.R](GetTablesFromXPaths.html) and
#' [VariableCreation.R](VariableCreation.html) by providing the functions
#' to push the resulting `tfl` object to a PostgreSQL database.
#' 
#' This is in contrast to the (significantly more efficient) Python extraction
#' script [FeatherUpload.R](FeatherUpload.html) which follows on from
#' [XMLParsing.py](XMLParsing.html) and is used in [PrepareData.sh](PrepareData.html).
#'
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/r/SQLTables.R)
# ---- docker, engine="bash", eval=F
# docker run --name postgres_london_tube -p 5432:5432 -d -e POSTGRES_PASSWORD=mysecretpassword postgres:alpine

#' Define row uniqueness
# ---- sql_keys
primarykeys <- list(
  NptgLocalities = '"NptgLocalityRef"',
  StopPoints = '"AtcoCode"',
  RouteLinks = '"RouteLinkID"',
  Routes = '"PrivateCode"',
  JourneyPatternTimingLinks = '"JourneyPatternTimingLinkID"',
  Services = '"ServiceCode"',
  JourneyPatterns = '"JourneyPatternID"',
  VehicleJourneys = '"VehicleJourneyCode"'
)

# ---- create_db
library(RPostgreSQL)

drv <- dbDriver("PostgreSQL")
host <- "localhost"
user <- "postgres"
password <- "mysecretpassword"

con <- dbConnect(drv, host = host, user = user, password = password,
                 dbname = "postgres")
dbSendQuery(con, "CREATE DATABASE londontube;")
dbDisconnect(con)
# ---- 

#' Create connection function for later use
# ---- get_con
get_con <- function() dbConnect(drv = dbDriver("PostgreSQL"), host = "localhost",
                                dbname = "londontube",
                                user = "postgres", password = "mysecretpassword")
# ---- 

#' Setup "CREATE TABLE ... INSERT INTO" template"
# ---- create_tables
create_tables <- function(tablename, tabledata, primary_key_cols, con){
  # Insert data
  dbWriteTable(con, tablename, tabledata, overwrite = TRUE, row.names = FALSE)
  
  # Add Primary Keys
  query <- sprintf(
    "ALTER TABLE %1$s
    ADD PRIMARY KEY (%2$s);",
    tablename, # Current table name
    paste(primary_key_cols, collapse = ", ") # PK columns
  )
  
  # Run queries
  dbExecute(con, query)
}

# Build database with the same tablenames as input data
con <- get_con()
table_creation <- purrr::pmap(list(tolower(names(tfl)), tfl, primarykeys), create_tables, con)
dbDisconnect(con)
# ---- 
