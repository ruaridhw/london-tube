FROM continuumio/anaconda3:latest
LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/ruaridhw/london-tube" \
      org.label-schema.vendor="" \
      maintainer="Ruaridh Williamson <ruaridh.williamson@gmail.com>"

# Install system dependencies
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list.d/pgdg.list \
  # Add postgres sources
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    # Required for mplleaflet
    libgl1-mesa-glx \
    # Required for rgdal
    libgdal1-dev libproj-dev \
    # Required for RPostgreSQL
    libpq-dev postgresql-server-dev-9.6 \

# Install additional Python packages
  && pip install psycopg2 mplleaflet feather-format \

# Install R and packages
  # Conda provided binaries
  && conda install -y r-base r-tidyverse \
  && conda install -y r-feather r-data.table r-xml r-devtools r-sp r-dbi \

  # CRAN packages built from source
  #&& conda install conda-build \
  #&& conda skeleton cran rgdal RPostgreSQL \
  #&& conda build r-rgdal r-rpostgresql \
  #&& conda install -c local r-rgdal r-rpostgresql

  # GitHub-only packages
  && Rscript -e "devtools::install_git('git://github.com/dantonnoriega/xmltools', dependencies = FALSE)" \

CMD ["/bin/bash"]
