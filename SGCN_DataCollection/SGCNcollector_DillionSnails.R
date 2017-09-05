

library('plyr')
library('data.table')
library('rgdal')  # for vector work; sp package should always load with rgdal. 
library('raster')   # for metadata/attributes- vectors or rasters
library(lubridate)

# read in the SGCn lookup
lu_sgcn <- read.csv("lu_sgcn.csv")
# add a field for ELSEASON
lu_sgcn$ELSEASON <- paste(lu_sgcn$ELCODE,lu_sgcn$SeasonCode,sep="-")

# subset to the species group one wants to query
sgcn_query <- lu_sgcn[which(lu_sgcn$TaxaGroup=="inv_snailf"),]
splist <- factor(sgcn_query$SNAME) # generate a species list to query gbif


snails <- read.csv("SpeciesData/PA-aquatic-snail-data-from_Dillon-14Jan14.csv")
snails$X <- NULL
snails$X.1 <- NULL
snails$X.2 <- NULL
snails$X.3 <- NULL
snails$X.4 <- NULL
snails$X.5 <- NULL
snails$X.6 <- NULL
snails$X.7 <- NULL
snails$X.8 <- NULL
snails$HUC <- NULL
snails$PROJECT <- NULL
snails$COMMONLOC <- NULL
snails$SITE_COMMENTS <- NULL
snails$ROAD_NO <- NULL

snails$LASTOBS <- as.character(substr( parse_date_time(snails$DATE, c("%m/%d/%y","ymd","%mdy","d%by") ), 1, 4))
snails$LASTOBS[is.na(snails$LASTOBS)] <- "NO DATE"

selectedRows <- (snails$SCI_NAME %in% splist )
snailsReduced <- snails[selectedRows,]


snailsReduced$DataSource <- "DillionSnails"
snailsReduced$SeasonCode <- "y"
setnames(snailsReduced, "SCI_NAME", "SNAME")
setnames(snailsReduced, "REF_SITE_NO", "DataID")
setnames(snailsReduced, "LONGITUDE", "Longitude")
setnames(snailsReduced, "LATITUDE", "Latitude")

# delete the colums we don't need from the BAMONA dataset
keeps <- c("SNAME","DataID","DataSource","Longitude","Latitude","LASTOBS","SeasonCode")
snailsReduced <- snailsReduced[keeps]

# delete the columns from the lu_sgcn layer and 
keeps <- c("SNAME","SCOMNAME","ELCODE","TaxaGroup","Environment")
sgcn_query <- sgcn_query[keeps]

# join the data to the sgcn lookup info
snailsReduced <-  join(snailsReduced,sgcn_query,by=c('SNAME'))

# create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
# note that the easting and northing columns are in columns 5 and 6
SGCNaquaticSnails <- SpatialPointsDataFrame(snailsReduced[,4:5],snailsReduced,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS, proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
plot(SGCNaquaticSnails,main="Map of SGCN Locations")
# write a shapefile
writeOGR(SGCNaquaticSnails, getwd(),"SGCNaquaticSnails", driver="ESRI Shapefile")
