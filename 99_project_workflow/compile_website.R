## ruaridhw.github.io/london-tube build chain

# Setup a clean directory in which to build the site
build_dir <- "build_site"
if (dir.exists(build_dir)) unlink(build_dir, recursive = TRUE)
dir.create(build_dir)

# Copy across the template site directory files
file.copy(from=list.files("4_site", full.names = T), to=build_dir)

# Copy all .Rmd files from the 3_notebooks subdirectory
file.copy(from=list.files("3_notebooks", pattern = ".Rmd$", full.names = TRUE), to=build_dir, 
          overwrite = TRUE)

# Copy specific analysis source files
source_files <- c("2_analysis/r/GetTablesFromXPaths.R", "2_analysis/r/SQLTables.R",
                "2_analysis/r/Variable Creation.R",
                "2_analysis/python/XMLParsing.py")
file.copy(from=source_files, to=build_dir, overwrite = TRUE)

# Apply knitr::spin to the analysis files to compile them to .Rmd reports
spin_files <- list.files(build_dir, pattern = "\\.(R|py)$", full.names = TRUE)
spin_output <- lapply(spin_files, knitr::spin, format = "Rmd", knit = FALSE) %>% unlist

# Build a new environment with `eval=FALSE` prespecified to avoid compiling the
# code chunks in the source files beyond plain markdown
no_eval <- new.env()
with(no_eval,
     knitr::opts_chunk$set(eval = FALSE)
)
lapply(spin_output, rmarkdown::render, output_format = "github_document", envir = no_eval)
# Remove Rmd and html preview for source files
file.remove(c(spin_output,spin_files, gsub("Rmd", "html", spin_output)))

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
