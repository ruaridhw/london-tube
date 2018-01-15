London Underground
================
<https://ruaridhw.github.io/london-tube/>

# Introduction

Transport for London’s Open Data repository was recently valued by
Deloitte as providing up to [£130mil of economic
benefits](https://tfl.gov.uk/info-for/media/press-releases/2017/october/tfl-s-free-open-data-boosts-london-s-economy)
for the City of London by allowing 600 third-party transport apps access
to real-time transit information via a common Application Programming
Interface.

This project is split into two parts which tackle various analytical
methods and visualisations applied to a segment of this API; network
timetable data.

The dataset being explored is a live feed of the Transport for London
network timetables. As described on the TfL website:

> The Journey Planner timetable feed contains up-to-date standard
> timetables for London Underground, bus, DLR, TfL Rail and river
> services. The timetables are updated every seven days.

The dataset is freely available and is bound by the [TfL Open Data
License](https://tfl.gov.uk/corporate/terms-and-conditions/transport-data-service).

# Part One: Managing Data

For the simplest means of analysis we need a structured, rectangular
dataset. The first part of the project involves building a reproducible
workflow for refreshing the timetable API feed which is updated on a
weekly basis. It starts with examining the structure of the data source
before extracting all of the relevant data into a “tidy” and normalised
format, adding any additional variables and typecasting extracted
information ready for pushing to a PostgreSQL database for further
analysis. This notebook is written in R for the data manipulation and
PostgreSQL for in-database transformation.

For the purposes of this project, only London Underground timetables are
extracted and processed however the methods presented here extend to any
[coach](https://data.gov.uk/dataset/national-coach-services), [bus,
light rail, ferry or tram
timetable](https://data.gov.uk/dataset/traveline-national-dataset)
across Great Britain as the extraction process is generalised for the
[generic TransXChange XML
schema](https://www.gov.uk/government/collections/transxchange) used by
the UK Department for Transport.

# Part Two: Visualising Data

Once the data has been extracted, cleaned and normalised, the second
part looks at different ways to visualise network timetable data and
apply journey planner algorithms to calculate the fastest routes to get
across London. Specifically, the notebook compares the depiction of the
famous London Underground map with a visualisation of the tube lines and
stations in reality and uses this plot to illustrate the movement of
train vehicles over time through spatiotemporal animation.

As with any data science project, the vast majority of time is spent
performing tasks from Part One however roughly equal weight has been
given to each of the resulting notebooks in terms of content.

# Reproducibility

All of the analysis presented aims to be fully reproducible with the
help of:

1.  [Published Docker
    container](https://hub.docker.com/r/ruaridhw/london-tube/) providing
    all of the necessary R and Python packages pre-installed against an
    Anaconda3 image. The download is roughly 2GB due to the size of the
    full conda distribution.
2.  Snapshot of the data feed API as at the time of analysis

To run the container ensure Docker is installed and call the following
from a Terminal with this repository as the current working
directory.

``` bash
docker run -v "$(pwd)":/home/london-tube -p 8888:8888 -it ruaridhw/london-tube:latest
```

The container will automatically download from Docker Hub and mount in
the current directory. To access JupyterLab go to
<http://localhost:8888> and login with the token shown by the container
and choose “Clear Workspace”.

For an extract of the API feed as at 12th December 2017 used in this
project simply switch Git branches to
[data\_and\_mp4\_files](https://github.com/ruaridhw/london-tube/tree/data_and_mp4_files/1_data)

``` bash
git checkout data_and_mp4_files
```

or [download the branch zip file from
GitHub](https://github.com/ruaridhw/london-tube/archive/data_and_mp4_files.zip).

# Context

This project was completed in partial fulfilment of a course for the MSc
Analytics and Operations Research at the London School of Economics. Any
analysis presented here was designed foremost to align to the course
principles and methodologies covered.

The requirements of the capstone are to summarise the analysis in the
form of exploratory notebooks (Part One and Two) however in the
interests of full reproducibility of the project all additional analysis
files are included with a shell script outlining a reproducible
workflow.

The course content covered in Part One is

  - Using data from the Internet, parsing XML web data (Week 4)
  - Working with APIs and authentication (Week 5)
  - Manipulation, transformation and extraction of data into “tidy” form
    (Week 2)
  - Relational databases and table normalisation (Week 3)

Part Two looks at

  - Data visualisation using Matplotlib (Weeks 7 and 8)
  - Graph algorithms and visualisation (Week 11)
  - Querying RESTful APIs and parsing JSON data (Weeks 4 and 5)

The content from Week 1

  - Version control, website publishing and GitHub pages

is inherent in the publication of this website.

Powered by TfL Open Data

Contains OS data © Crown copyright and database rights 2016
