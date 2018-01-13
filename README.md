London Underground
================
<https://ruaridhw.github.io/london-tube/>

# Welcome

Transport for London’s Open Data repository was recently valued by
Deloitte as providing up to [£130mil of economic
benefits](https://tfl.gov.uk/info-for/media/press-releases/2017/october/tfl-s-free-open-data-boosts-london-s-economy)
for the City of London by allowing 600 third-party transport apps access
to real-time transit information via a common Application Programming
Interface.

This project is split into two parts which tackle various analytical
methods and visualisations applied to a segment of this API; network
timetabling data.

The dataset being explored is a live feed of the Transport for London
network timetables. As described on the TfL website:

> The Journey Planner timetable feed contains up-to-date standard
> timetables for London Underground, bus, DLR, TfL Rail and river
> services. The timetables are updated every seven days.

The dataset is freely available and is bound by the [TfL Open Data
License](https://tfl.gov.uk/corporate/terms-and-conditions/transport-data-service).

## Part One: Managing Data

Prior to any form of analysis, we need a structured, rectangular
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
tube, train, bus, ferry or tram timetable across Great Britain as the
extraction process is built around a generic XML schema used by the UK
Department for Transport.

## Part Two: Visualising Data

Once the data has been extracted, cleaned and normalised, the second
part looks at different ways to visualise network timetable data and
apply journey planner algorithms to calculate the fastest routes to get
across London. Specifically, the notebook compares the depiction of the
famous London Underground map with a visualisation of the tube lines and
stations in reality and uses this plot to illustrate the movement of
train vehicles over time through spatiotemporal animation.

As with any data science project, the vast majority of the time is spent
performing tasks from Part One however equal weight has been given to
each in the resulting notebooks in terms of content.

## Context

This project was completed in partial fulfilment of a course for the MSc
Analytics and Operations Research at the London School of Economics. Any
analysis presented here was designed foremost to align to the course
principles and methodologies covered.

The requirements of the course are to provide the analysis in the form
of exploratory notebooks (Part One and Two respectively) however in the
interests of full reproducibility of the project all additional analysis
files are included with a script outlining the overall workflow.

The course content covered in Part One is

  - Using data from the Internet, parsing XML web data (Week 4)
  - Working with APIs and authentication (Week 5)
  - Manipulation, transformation and extraction of data into “tidy” form
    (Week 2)
  - Relational databases and table normalisation (Week 3)

Part Two looks at

  - Exploratory data visualisation using Matplotlib (Weeks 7 and 8)
  - Graph algorithms and visualisation (Week 11)
  - Querying RESTful APIs and parsing JSON data (Weeks 4 and 5)

The content from Week 1

  - Version control, website publishing and GitHub pages

is inherent in the publication of this website.
