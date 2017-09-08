#---------------------------------------------------------------------------------------------
# Name: SGCNcollector_BAMONA.R
# Purpose: 
# Author: Christopher Tracey
# Created: 2017-07-10
# Updated: 
#
# Updates:
# insert date and info
# * 2016-08-17 - got the code to remove NULL values from the keys to work; 
#                added the complete list of SGCN to load from a text file;
#                figured out how to remove records where no occurences we found;
#                make a shapefile of the results  
#
# To Do List/Future Ideas:
# * check projection
# * wkt integration
# * filter the occ_search results on potential data flags -- looks like its pulling 
#   the coordinates from iNat that are obscured.  
# * might be a good idea to create seperate reports with obscured records
#-------

setwd("C:/Users/ctracey/Dropbox (PNHP @ WPC)/coa/COA/SGCN_DataCollection")

library('rgbif')
library('plyr')
library('data.table')
library('rgdal')  # for vector work; sp package should always load with rgdal. 
library('raster')   # for metadata/attributes- vectors or rasters
library('lubridate')


# read in the SGCn lookup
lu_sgcn <- read.csv("lu_sgcn.csv")
# add a field for ELSEASON
lu_sgcn$ELSEASON <- paste(lu_sgcn$ELCODE,lu_sgcn$SeasonCode,sep="-")

# subset to the species group one wants to query
sgcn_query <- lu_sgcn[which(lu_sgcn$TaxaGroup=="inv_buttsk"|lu_sgcn$TaxaGroup=="inv_mothcw"|lu_sgcn$TaxaGroup=="inv_mother"|lu_sgcn$TaxaGroup=="inv_mothdg"|lu_sgcn$TaxaGroup=="inv_mothsi"|lu_sgcn$TaxaGroup=="inv_mothnc"|lu_sgcn$TaxaGroup=="inv_mothcw"|lu_sgcn$TaxaGroup=="inv_mothnt"|lu_sgcn$TaxaGroup=="inv_mothot"|lu_sgcn$TaxaGroup=="inv_mothpa"|lu_sgcn$TaxaGroup=="inv_mothsa"|lu_sgcn$TaxaGroup=="inv_mothte"|lu_sgcn$TaxaGroup=="inv_mothtg"|lu_sgcn$TaxaGroup=="IILEX0B"|lu_sgcn$TaxaGroup=="IILEU"|lu_sgcn$TaxaGroup=="IILEQ" |lu_sgcn$TaxaGroup=="IILEY7P"),]
splist <- factor(sgcn_query$SNAME) # generate a species list to query gbif

bamona_moths <- read.csv("SpeciesData/BAMONA_PA_moths.csv")
bamona_butterflies <- read.csv("SpeciesData/BAMONA_PA_butterflies.csv")
bamona <- rbind(bamona_butterflies,bamona_moths)

selectedRows <- (bamona$Scientific.Name %in% splist )
bamonaReduced <- bamona[selectedRows,]
bamonaReduced <- bamonaReduced[which(bamonaReduced$County.Centroid!="county record"),] # removes the county level records

bamonaReduced$LASTOBS <- parse_date_time(bamonaReduced$Date.of.Observation, "mdY")

bamonaReduced$DataSource <- "BAMONA"
bamonaReduced$SeasonCode <- "y"
setnames(bamonaReduced, "Scientific.Name", "SNAME")
setnames(bamonaReduced, "Common.Name", "SCOMNAME")
setnames(bamonaReduced, "BAMONA.Record.Number", "DataID")
setnames(bamonaReduced, "Long.EPSG.4326", "Longitude")
setnames(bamonaReduced, "Lat.EPSG.4326", "Latitude")

# delete the colums we don't need from the BAMONA dataset
keeps <- c("SNAME","DataID","DataSource","Longitude","Latitude","LASTOBS","SeasonCode")
bamonaReduced <- bamonaReduced[keeps]

# delete the columns from the lu_sgcn layer and 
keeps <- c("SNAME","SCOMNAME","ELCODE","TaxaGroup","Environment")
sgcn_query <- sgcn_query[keeps]

# join the data to the sgcn lookup info
bamona <-  join(bamonaReduced,sgcn_query,by=c('SNAME'))

# create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
# note that the easting and northing columns are in columns 5 and 6
SGCNbamona <- SpatialPointsDataFrame(bamona[,4:5],bamona,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS, proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
plot(SGCNbamona,main="Map of SGCN Locations")
# write a shapefile
writeOGR(SGCNbamona, getwd(),"SGCN_FromBAMONA", driver="ESRI Shapefile")

