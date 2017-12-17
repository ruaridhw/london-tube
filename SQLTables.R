# docker run --name postgres-london-tube -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres:alpine

# Define row uniqueness
keys <- list(NptgLocalities = "NptgLocalityRef",
             StopPoints = "AtcoCode",
             RouteSections = c("StopPointRef", "StopPointRef1", "Direction"),
             Routes = "PrivateCode",
             JourneyPatternSections = "JourneyPatternTimingLinkID",
             StandardServices = "JourneyPatternID",
             VehicleJourneys = "VehicleJourneyCode"
)

library(RPostgreSQL)
get_con <- function() dbConnect(drv = dbDriver("PostgreSQL"), host = "localhost",
                                dbname = "londontube",
                                user = "postgres", password = "mysecretpassword")

# Setup "CREATE TABLE ... INSERT INTO" template"
create_tables <- function(tablename, tabledata, primary_key_cols, con){
  # Drop and recreate table
  # query <- sprintf("DROP TABLE IF EXISTS %1$s;CREATE TABLE %1$s (%2$s);",
  #   tablename, # table name as string
  #   paste(names(tabledata), collapse = ", ")#, # table cols
  #   #paste(primary_key_cols, collapse = ", ")  # PK cols
  #   )
  # 
  # # Insert data
  # lapply(strsplit(query, ";") %>% unlist, function(x) dbExecute(con, x))
  dbWriteTable(con, tablename, tabledata, overwrite = TRUE, append = FALSE, row.names = FALSE)
}

# Build database with the same tablenames as input data
dbSendQuery(dbConnect(drv = dbDriver("PostgreSQL"), host = "localhost",
                      dbname = "postgres",
                      user = "postgres", password = "mysecretpassword")
            ,"CREATE DATABASE londontube;")
con <- get_con()
table_creation <- purrr::pmap(list(tolower(names(tables)), tables, keys), create_tables, con)
dbDisconnect(con)

