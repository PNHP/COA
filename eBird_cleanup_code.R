setwd("W:/Heritage/Heritage_Projects/1332_PGC_COA/species_data/eBird_PA_Oct2016")

eBirdSGCNList <- read.csv("Birds_eBird_Eligible.csv") # this is the list of SGCN bird names
birdnames <- eBirdSGCNList$CommonName # turns the above into a list

eBird2016clean <- read.delim("eBird2016clean.txt")

eBirdclean <- eBird2016clean[eBird2016clean$COMMON.NAME %in% birdnames, ] #subsets by bird name
eBirdclean$COMMON.NAME <- droplevels(eBirdclean$COMMON.NAME)

# gets rid of the bad data lines
eBirdclean$lat <- as.numeric(as.character(eBirdclean$LATITUDE))
eBirdclean$lon <- as.numeric(as.character(eBirdclean$LONGITUDE))
eBirdclean <- eBirdclean[!is.na(as.numeric(as.character(eBirdclean$lat))),]
eBirdclean <- eBirdclean[!is.na(as.numeric(as.character(eBirdclean$lon))),]

### Filter out Personal locations and Hotspots and then by Casual Obs and Stationary Counts
eBirdclean <- eBirdclean[which(eBirdclean$LOCALITY.TYPE=="P"|eBirdclean$LOCALITY.TYPE=="H"),]
eBirdclean <- eBirdclean[which(eBirdclean$PROTOCOL.TYPE=="eBird - Casual Observation"|eBirdclean$PROTOCOL.TYPE=="eBird - Stationary Count"),]

### Next filter out records by Focal Season for each SGCN using day-of-year
library(lubridate)
eBirdclean$dayofyear <- yday(eBirdclean$OBSERVATION.DATE) ## Add day of year to eBird dataset based on the observation date.
birdseason <- read.csv("birdseason.csv")

eBirdclean$COMMON.NAME <- droplevels(eBirdclean$COMMON.NAME)

### assign a migration date to each ebird observation.
for(i in 1:nrow(birdseason)){
  comname<-birdseason[i,1]
  season<-birdseason[i,2]
  startdate<-birdseason[i,3]
  enddate<-birdseason[i,4]
  eBirdclean$season[eBirdclean$COMMON.NAME==comname & eBirdclean$dayofyear>startdate & eBirdclean$dayofyear<enddate] <- as.character(season)
}

# drops any species that has an NA due to be outsite the season dates
eBirdclean <- eBirdclean[!is.na(eBirdclean$season),]
# drops the unneeded columns. please modify the list.
keeps <- c("COMMON.NAME","SCIENTIFIC.NAME","lat","lon","LOCALITY.TYPE","PROTOCOL.TYPE","dayofyear","season" )
eBirdclean <- eBirdclean[keeps]

#create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
library(rgdal)  # for vector work; sp package should always load with rgdal. 
library (raster)   # for metadata/attributes- vectors or rasters
# note that the easting and northing columns are in columns 4 and 5
ebird_extract <- SpatialPointsDataFrame(eBirdclean[,4:3],eBirdclean,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS  ,proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
plot(ebird_extract,main="Pennsylvania eBird points")
# write a shapefile
writeOGR(ebird_extract, getwd(),"ebird_extract", driver="ESRI Shapefile")

### Filter out just Traveling Count data
#eBirdclean_traveling <- eBirdclean[which(eBirdclean$PROTOCOL.TYPE=="eBird - Traveling Count"),]
# we'll use the travel counts later