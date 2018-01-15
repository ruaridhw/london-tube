#' ---
#' title: "Get Data"
#' ---
#'
#' Downloads the necessary data files from the TfL API.
#'
#' Relies on the local file `tfl-developer-passwords.R` having
#' valid `app_id` and `app_key` TfL API credentials.
#'
#' Source code used in [ManagingData.Rmd](ManagingData.html).
#' For full documentation and commentary see that report instead.
#'
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/r/GetData.R)

# ---- proj_setup
# Use paths relative to RStudio Project
root.dir <- rprojroot::find_rstudio_root_file()
# Set where we want the extracted files to end up
data.dir <- file.path(root.dir, "1_data/1_1_raw_data")
dir.create(data.dir, showWarnings = FALSE)

# ---- download_zip
# Load app_id and app_key variables from a local passwords file
source(file.path(root.dir, "2_analysis/r/tfl-developer-passwords.R"))
stopifnot(exists("app_id"), exists("app_key"))
dataset_url <- "http://data.tfl.gov.uk/tfl/syndication/feeds/journey-planner-timetables.zip"
dataset_url <- paste0(dataset_url, "?app_id=", app_id, "&app_key=", app_key)
download.file(dataset_url, file.path(data.dir, "timetables.zip"))

# ---- unzip
unzip(file.path(data.dir, "timetables.zip"),
      exdir = file.path(data.dir, "timetables"))
unzip(list.files(file.path(data.dir, "timetables"),
                 pattern = "LULDLR", full.names = TRUE),
      exdir = file.path(data.dir, "/timetables/data"))

# ---- show_xml_files
data.files <- list.files(file.path(data.dir, "/timetables/data"),
                         pattern = "tfl_1-[^.]+\\.xml", full.names = TRUE)
head(basename(data.files))
