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
  && pip install psycopg2 mplleaflet feather-format

# Install R and packages
  # Conda provided binaries
RUN conda install -y r-base r-tidyverse \
  && conda install -y r-feather r-data.table r-xml r-devtools r-dbi

  # CRAN packages built from conda-forge
  # NB: This causes numerous **downgrades**
RUN conda install -y -c conda-forge r-rgdal r-rpostgresql \

  # GitHub-only packages
  && Rscript -e "devtools::install_git('git://github.com/dantonnoriega/xmltools', dependencies = FALSE)"

# Install JupyterLab and R Kernel
RUN conda install -y -c conda-forge jupyterlab \
  && conda install -y r-irkernel

EXPOSE 8888

ENV getwd /home/london-tube
RUN mkdir $getwd
WORKDIR $getwd

ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--allow-root"]
