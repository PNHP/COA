
library(lubridate)
library(data.table)


# list of snail SGCN
SGCN <- read.csv("sgcn.csv")
keeps <- c("ELCODE","Scientific_Name")
SGCN <- SGCN[keeps]

setnames(SGCN, old=c("Scientific_Name"),new=c("SNAME"))
SGCN <- unique(SGCN)


# import the moth and butterfly data
dataMoths <- read.csv("BAMONA_PA_moths.csv")
dataButterflies <- read.csv("BAMONA_PA_butterflies.csv")

# combine into one dataset
dataAll <- rbind(dataMoths,dataButterflies)

# process the date file into something parsable
### this reference helps with formats: http://pubs.opengroup.org/onlinepubs/000095399/utilities/date.html
dataAll$newdate <- parse_date_time(dataAll$Date.of.Observation , c("dby"))
dataAll$Date.of.Observation <- NULL # delete the old field

# subset the records
dataAll <- droplevels(dataAll[which(dataAll$County.Centroid !='county record'), ]) # parses by county level records

# change column names
setnames(dataAll, old=c("Scientific.Name","Common.Name"),new=c("SNAME","SCOMNAME"))
setnames(dataAll, old=c("Long.EPSG.4326","Lat.EPSG.4326"),new=c("lon","lat"))
setnames(dataAll, old=c("BAMONA.Record.Number"),new=c("DataID"))

# merge
Leps <- merge(x=dataAll, y=SGCN, by="SNAME")

#add some fields
Leps$DataSource <- "BAMONA"
Leps$taxagrp <- NA
Leps$taxagrp <- ifelse(substr(Leps$ELCODE, 3, 5) == "LEP", as.character("IB"),ifelse(substr(Leps$ELCODE, 5, 5) != "P", as.character("IM"),NA))

# drops a bunch of variables that are not needed
## drop a bunch of columns that we don't need
keeps <- c("DataSource","taxagrp","lon","lat","DataID","SNAME","SCOMNAME","ELCODE")
Leps <- Leps[keeps]



#create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
library(rgdal)  # for vector work; sp package should always load with rgdal. 
library (raster)   # for metadata/attributes- vectors or rasters
# note that the easting and northing columns are in columns 4 and 5
Leps4COA <- SpatialPointsDataFrame(Leps[,3:4],Leps,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS  ,proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
plot(Leps4COA,main="Pennsylvania Bamona points")
# write a shapefile
writeOGR(Leps4COA, getwd(),"Leps4COA", driver="ESRI Shapefile")

