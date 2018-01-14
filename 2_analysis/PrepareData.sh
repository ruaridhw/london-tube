#!/usr/bin/env bash
#' ---
#' title: "Prepare Data"
#' ---
#'
#' This script performs all the necessary actions to download a directory
#' of XML timetables from the http://data.tfl.gov.uk API
#' and pushes all of the tables to a PostgreSQL instance.

#' The download script relies on the local file `tfl-developer-passwords.R`
#' having valid `app_id` and `app_key` TfL API credentials.
#' It downloads the necessary zip file and unpacks the Underground timetables
#' to a local directory `../1_data/1_1_raw_data/timetables/data`
Rscript r/GetData.R

#' [This script](XMLParsing.html) parses the raw XML to a number of Pandas
#' dataframes and dumps a directory of Feather files for interpretation by R
#' For usage see `python3 python/XMLParsing.py --help`
python3 python/XMLParsing.py ../1_data/1_1_raw_data/timetables/data ../1_data/1_2_processed_data

#' [FeatherUpload.R](FeatherUpload.html) reads the Feather files and appends them
#' to existing tables in a PostgreSQL database. The connection settings are
#' self-contained within this script.
Rscript r/FeatherUpload.R
