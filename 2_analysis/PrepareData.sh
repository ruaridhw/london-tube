#!/usr/bin/env bash
#' ---
#' title: "Prepare Data"
#' author: "Ruaridh Williamson"
#' ---
#'
#' This script performs all the necessary actions to scrape the directory
#' of XML timetables from the 1_data/1_1_raw_data/timetables/data folder
#' and pushes all of the tables to a PostgreSQL instance.

#' XMLParsing.py contains the locations of the input and output data directories
#' It parses the raw XML to a number of Pandas dataframes and dumps a directory
#' of Feather files for interpretation by R
#' For usage see `python3 python/XMLParsing.py --help`
python3 python/XMLParsing.py ../1_data/1_1_raw_data/timetables/data ../1_data/1_2_processed_data

#' FeatherUpload.R reads the Feather files and appends them to existing tables
#' in a PostgreSQL database. The connection settings are self-contained within
#' this script.
Rscript r/FeatherUpload.R
