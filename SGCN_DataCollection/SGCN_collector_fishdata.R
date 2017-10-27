library("dplyr")
library("data.table")

setwd("E:/COA/NewFishData")
fishdata <- read.csv("New_Fish_All_Species.csv")

# get rid of rows that are all NA
fishdata <- fishdata[rowSums(is.na(fishdata)) != ncol(fishdata),]
# various field cleanup
fishdata$Common_Name <- as.factor(fishdata$Common_Name)
fishdata$Genus <- as.factor(fishdata$Genus)
fishdata$Species <- as.factor(fishdata$Species)
fishdata$SNAME <- as.factor(paste(fishdata$Genus,fishdata$Species))
fishdata$DataSource <- "PFBC_DPF"
fishdata$DataID <- paste(fishdata$TSN,"_",fishdata$RecordID,sep="")

setnames(fishdata , old=c("Common_Name","Long","Date"),new=c("SCOMNAME","Lon","LASTOBS"))
fishdata$Taxonomic_Group <- "AF"

# replace the older taxonomy with updated names from the SWAP.  Need to do this before the ELCODE join
levels(fishdata$SNAME)[levels(fishdata$SNAME)=="Acipenser oxyrinchus"] <- "Acipenser oxyrhynchus"
levels(fishdata$SNAME)[levels(fishdata$SNAME)=="Cottus sp."] <- "Cottus sp. cf. cognatus"
levels(fishdata$SNAME)[levels(fishdata$SNAME)=="Notropis dorsalis"] <- "Hybopsis dorsalis"
levels(fishdata$SNAME)[levels(fishdata$SNAME)=="Lota sp."] <- "Lota sp. cf. lota"
levels(fishdata$SNAME)[levels(fishdata$SNAME)=="Lota sp. "] <- "Lota sp. cf. lota" # extra space after "sp."
levels(fishdata$SNAME)[levels(fishdata$SNAME)=="Notropis heterolepis"] <- "Notropis heterodon"

# add in the ELCODE
SGCNfish <- read.csv("SGCNfish.csv")
ELCODES <- SGCNfish[,c("ELCODE","Scientific_Name")]
setnames(ELCODES, old=c("Scientific_Name"),new=c("SNAME"))
levels(ELCODES$SNAME)[levels(fishdata$SNAME)=="Polyodon spathulaÂ"] <- "Polyodon spathula"
fishdata <- merge(x = fishdata, y = ELCODES, by = "SNAME")  # inner join of the above

# drops the unneeded columns. please modify the list.
keeps <- c("SNAME","SCOMNAME","Taxonomic_Group","ELCODE","DataSource","DataID","LASTOBS","Lat","Lon")
fishdata <- fishdata[keeps]

fishdata$ELSeason <- paste(fishdata$ELCODE,"-y",sep="")
fishdata$Lat <- as.numeric(as.character(fishdata$Lat))

fishdata <- fishdata[complete.cases(fishdata), ]

#create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
library(rgdal)  # for vector work; sp package should always load with rgdal. 
library (raster)   # for metadata/attributes- vectors or rasters
# note that the easting and northing columns are in columns 4 and 5
sgcn_fish <- SpatialPointsDataFrame(fishdata[,9:8],fishdata,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS  ,proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
plot(sgcn_fish,main="Pennsylvania SGCN fish points")
# write a shapefile
writeOGR(sgcn_fish, getwd(),"sgcn_fish", driver="ESRI Shapefile")






