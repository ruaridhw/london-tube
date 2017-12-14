library(rgdal)

tables$StopPoints <- within(tables$StopPoints, {
  Easting %<>% as.integer
  Northing %<>% as.integer
})

#TODO these projections are ever so slightly off comapred to the
#     Python module convertbng.util.convert_lonlat
#     is there a more accurate projection?
#TODO Check results against Google Maps tube station geocode
wgs84 = "+proj=longlat +datum=WGS84"
bng = "+init=epsg:27700"

attach(tables$StopPoints)
cord.UTM <- SpatialPointsDataFrame(cbind(Easting, Northing)
                                   ,data = data.table(AtcoCode, CommonName, NptgLocalityRef)
                                   ,proj4string = CRS(bng))
detach(tables$StopPoints)

cord.latlon <- spTransform(cord.UTM, CRS(wgs84))
tables$StopPoints <- as_tibble(cord.latlon)
names(tables$StopPoints) <- c("AtcoCode","CommonName","NptgLocalityRef","Lon","Lat")

