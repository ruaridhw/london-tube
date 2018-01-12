#' ---
#' title: "SQL Tables"
#' ---
#'
#' ## Build database
#'
#' Using the primary keys and data types found in the previous section,
#' we can write a function that drops an existing table,
#' builds a new table with the provided keys and
#' data types and populates the table with data. Now, the entire database
#' can be created in one hit by using `pmap` to loop the function over all
#' eight tables sequentially.
#'
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/r/SQLTables.R)
# ---- docker, engine="bash", eval=F
# docker run --name postgres_london_tube -p 5432:5432 -d -e POSTGRES_PASSWORD=mysecretpassword postgres:alpine

#' Define row uniqueness
# ---- sql_keys
key_data <- list(
  NptgLocalities = list(primary_key_cols = "NptgLocalityRef"),
  StopPoints = list(primary_key_cols = "AtcoCode"),
  RouteLinks = list(primary_key_cols = c("StopPointRef", "StopPointRef1", "Direction")),
  Routes = list(primary_key_cols = "PrivateCode"),
  JourneyPatternTimingLinks = list(primary_key_cols = "JourneyPatternTimingLinkID"),
  Services = list(primary_key_cols = "Unknown"),
  JourneyPatterns = list(primary_key_cols = "JourneyPatternID"),
  VehicleJourneys = list(primary_key_cols = "VehicleJourneyCode")
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
create_tables <- function(tablename, tabledata, con){
  dbWriteTable(con, tablename, tabledata, overwrite = TRUE, row.names = FALSE)
}

# Build database with the same tablenames as input data
con <- get_con()
table_creation <- purrr::pmap(list(tolower(names(tfl)), tfl), create_tables, con)
dbDisconnect(con)
# ---- 

# ---- create_tables2
create_tables <- function(tablename, tabledata, key_data, con){
  # Insert data
  dbWriteTable(con, tablename, tabledata, overwrite = TRUE, row.names = FALSE)
  # 
  # #TODO are there any tables with multiple foreign keys?
  # #     if so, ADD FOREIGN KEY needs to be replicated for each using
  # #     paste0(... collapse = ";")
  # 
  # # Add Primary and Foreign Keys
  # queries <- sprintf(
  #   "ALTER TABLE %1$s
  #   ADD PRIMARY KEY (%2$s);
  #   ALTER TABLE %1$s
  #   ADD CONSTRAINT %3$s
  #   FOREIGN KEY (%4$s) 
  #   REFERENCES %5$s(%6$s);",
  # tablename, # Current table name
  # paste(key_data$primary_key_cols, collapse = ", "), # Current table PK columns
  # key_data$foreign_key_name, # Foreign Key constraint name
  # paste(key_data$foreign_key_cols, collapse = ", "), # Current table Foreign Key columns
  # key_data$fk_tablename, # Foreign table name
  # paste(key_data$fk_primary_key_cols, collapse = ", ") # Foreign table PK columns
  # )
  # 
  # # Run queries
  # lapply(strsplit(queries, ";") %>% unlist, dbExecute, con = con)
}
