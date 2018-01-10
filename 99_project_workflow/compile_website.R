## ruaridhw.github.io/london-tube build chain
library(magrittr)

# Setup a clean directory in which to build the site
build_dir <- "_build_site"
if (dir.exists(build_dir)) unlink(build_dir, recursive = TRUE)
dir.create(build_dir)

# Copy across the template site directory files
file.copy(from=list.files("4_media", pattern = "(png|mp4)$", full.names = T), to=build_dir)
file.copy(from=list.files("5_site", full.names = T), to=build_dir)

# Copy all .Rmd files from the 3_notebooks subdirectory
file.copy(from=list.files("3_notebooks", pattern = ".Rmd$", full.names = TRUE), to=build_dir, 
          overwrite = TRUE)

# Copy specific analysis source files
source_files <- c(
  "2_analysis/r/GetTablesFromXPaths.R",
  "2_analysis/r/SQLTables.R",
  "2_analysis/r/VariableCreation.R",
  
  "2_analysis/python/XMLParsing.py",
  "2_analysis/python/TfLTimetable.py",
  "2_analysis/python/ShortestPath.py",
  
  "2_analysis/sql/DaysOfWeekGroups.sql",
  "2_analysis/sql/DepartureBoard.sql",
  "2_analysis/sql/InboundGraph.sql")
file.copy(from=source_files, to=build_dir, overwrite = TRUE)

# Apply knitr::spin to the analysis files to compile them to .Rmd reports
spin_files <- list.files(build_dir, pattern = "\\.(R|py|sql)$", full.names = TRUE)
spin_output <- lapply(spin_files, knitr::spin, format = "Rmd", knit = FALSE) %>% unlist

# Set `eval=FALSE` temporarily to avoid compiling the
# code chunks in the source files beyond plain markdown
knitr::opts_chunk$set(eval = FALSE, python.reticulate = FALSE)
lapply(spin_output, rmarkdown::render, output_format = "github_document")
# Remove Rmd and html preview for source files
file.remove(c(spin_output,spin_files, gsub("Rmd", "html", spin_output)))
knitr::opts_chunk$set(eval = TRUE)

# Render the ManagingData notebook to a GitHub html preview
rmarkdown::render(list.files(build_dir, pattern = "ManagingData", full.names = T),
                  output_format = "github_document", envir = new.env())
# Remove the [R]md files and use the GitHub html preview instead
file.remove(list.files(build_dir, pattern = "ManagingData.R?md", full.names = T))

# Convert the Jupyter notebook to an html document
conda_env <- path.expand("~/anaconda3/envs/st445/bin")
system(sprintf("%s/jupyter nbconvert --to html --template full %s/%s", conda_env,
               rprojroot::find_rstudio_root_file(),"3_notebooks/VisualisingData.ipynb"))
file.copy(from=paste0(rprojroot::find_rstudio_root_file(),"/3_notebooks/VisualisingData.html"),
          to=build_dir, overwrite = TRUE)

# Render the complete site
rmarkdown::render_site(build_dir)
