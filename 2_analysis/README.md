# Analysis

The analysis files for this repository comprise two distinct workflows.

The first is used in the Managing Data notebook and involves extracting the
XML data using R prior to variable creation and uploading to PostgreSQL.
This workflow is purely for data manipulation illustration purposes in the
notebook as it is very slow comparatively and therefore the files are setup to
upload just 1 of the 84 data files.

The second workflow is significantly faster as it uses Python's `lxml` library
to scrape the data and dump it to `.feather` files before reverting back to R.

As the files have interdependency, the order of execution matters to populate
directories or setup environment variables.

## Processing

### Pure R
**For exploratory purposes**

1. GetData.R (sources tfl-developer-passwords.R)
2. GetTablesFromXPaths.R
3. SQLTables.R

### Production

1. GetData.R (sources tfl-developer-passwords.R)
2. XMLParsing.py (imports TfLTimetable.py)
3. FeatherUpload.R (sources VariableCreation.R)
4. DaysOfWeekGroups.sql
5. DepartureBoard.sql

This workflow is implemented in PrepareData.sh

## Analysis

The following files are used for analysis purposes rather than extraction:

- InboundGraph.sql
- ShortestPath.py

## Requirements

This project requires a number of dependencies to fully execute the analysis files
and notebooks. Below is an exhaustive list which will vary depending on the
workflow chosen and extent pursued.

### R Packages

- tidyverse (specifically: tibble, purrr, dplyr, magrittr, lubridate, xml2, feather)
- data.table
- XML
- rgdal
- RPostgreSQL
- rprojroot
- xmltools (GitHub only)

### Python Modules

- numpy
- pandas
- matplotlib
- lxml
- networkx
- psycopg2
- requests
- mplleaflet
- feather
- smopy
- click
