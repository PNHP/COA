setwd("W:/Heritage/Heritage_Projects/1332_PGC_COA/species_data/eBird_PA_Oct2016")

eBirdSGCNList <- read.csv("Birds_eBird_Eligible.csv") # this is the list of SGCN bird names
birdnames <- eBirdSGCNList$CommonName # turns the above into a list

eBird2016clean <- read.delim("eBird2016clean.txt")


eBirdclean <- eBird2016clean[eBird2016clean$COMMON.NAME %in% birdnames, ] #subsets by bird name
eBirdclean$COMMON.NAME <- factor(eBirdclean$COMMON.NAME)

#eBirdclean <- read.csv("eBirdclean.csv")
#write.csv(eBirdclean,"eBirdclean.csv")

### Filter out Personal locations and Hotspots and then by Casual Obs and Stationary Counts
eBirdclean_filter <- eBirdclean[which(eBirdclean$LOCALITY.TYPE=="P"|eBirdclean$LOCALITY.TYPE=="H"),]
eBirdclean_filter <- eBirdclean_filter[which(eBirdclean_filter$PROTOCOL.TYPE=="eBird - Casual Observation"|eBirdclean_filter$PROTOCOL.TYPE=="eBird - Stationary Count"),]
eBirdclean_filter <- eBirdclean_filter[order(COMMON.NAME),] #sorts by common name... it may make steps below a little bit faster

### Filter out just Traveling Count data
eBirdclean_traveling <- eBirdclean[which(eBirdclean$PROTOCOL.TYPE=="eBird - Traveling Count"),]
# we'll use the travel counts later

### Next filter out records by Focal Season for each SGCN using day-of-year
library(lubridate)
eBirdclean_filter$dayofyear <- yday(eBirdclean_filter$OBSERVATION.DATE) ## Add day of year to eBird dataset based on the observation date.
birdseason <- read.csv("birdseason.csv")

### assign a migration date to each ebird observation.
for(i in 1:nrow(birdseason)){
  comname<-birdseason[i,1]
  season<-birdseason[i,2]
  startdate<-birdseason[i,3]
  enddate<-birdseason[i,4]
  eBirdclean_filter$season[eBirdclean_filter$COMMON.NAME==comname & eBirdclean_filter$dayofyear>startdate & eBirdclean_filter$dayofyear<enddate] <- as.character(season)
}

# drops any species that has an NA due to be outsite the season dates
eBirdclean_filter1 <- eBirdclean_filter[!is.na(eBirdclean_filter$season),]

# drops the unneeded columns. please modify the list.
keeps <- c("COMMON.NAME","SCIENTIFIC.NAME","LATITUDE","LONGITUDE","LOCALITY.TYPE","PROTOCOL.TYPE","dayofyear","season" )
eBirdclean_filter1 <- eBirdclean_filter1[keeps]


#create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
library(rgdal)  # for vector work; sp package should always load with rgdal. 
library (raster)   # for metadata/attributes- vectors or rasters
# note that the easting and northing columns are in columns 4 and 5
eBirdclean_filter1$LATITUDE <- factor(eBirdclean_filter1$LATITUDE)

eBirdclean_filter1$LATITUDE <- as.numeric(eBirdclean_filter1$LATITUDE)
eBirdclean_filter1$LONGITUDE <- as.numeric(eBirdclean_filter1$LONGITUDE)
ebird_extract <- SpatialPointsDataFrame(eBirdclean_filter1[,4:3],eBirdclean_filter1,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS  ,proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
plot(ebird_extract,main="Pennsylvania eBird points")
# write a shapefile
writeOGR(ebird_extract, getwd(),"ebird_extract", driver="ESRI Shapefile")

