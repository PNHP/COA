setwd("W:/Heritage/Heritage_Projects/1332_PGC_COA/species_data/eBird_PA_Oct2016")

eBirdSGCNList <- read.csv("Birds_eBird_Eligible.csv")

eBird2016clean <- read.delim("eBird2016clean.txt")

birdnames <- eBirdSGCNList$CommonName
eBirdclean <- eBird2016clean[eBird2016clean$COMMON.NAME %in% birdnames, ]

write.csv(eBirdclean,"eBirdclean.csv")

### Filter out Personal locations and Hotspots and then by Casual Obs and Stationary Counts
eBirdclean_filter <- eBirdclean[which(eBirdclean$LOCALITY.TYPE=="P"|eBirdclean$LOCALITY.TYPE=="H"),]
eBirdclean_filter <- eBirdclean_filter[which(eBirdclean_filter$PROTOCOL.TYPE=="eBird - Casual Observation"|eBirdclean_filter$PROTOCOL.TYPE=="eBird - Stationary Count"),]

### Filter out just Traveling Count data
eBirdclean_traveling <- eBirdclean[which(eBirdclean$PROTOCOL.TYPE=="eBird - Traveling Count"),]

### Next filter out records by Focal Season for each SGCN using Julian date
library(lubridate)
test <- eBirdclean[which(eBirdclean$COMMON.NAME=="Gray Catbird"|eBirdclean$COMMON.NAME=="Red-headed Woodpecker"),]
test$COMMON.NAME <- factor(test$COMMON.NAME)
birdseason <- read.csv("birdseason.csv")
#test$juliandate <- sample(1:365, size = nrow(test), replace = TRUE)
test$dayofyear <- yday(test$OBSERVATION.DATE)

keeps <- c("COMMON.NAME","dayofyear")
test <- test[keeps]

# inspired by http://stackoverflow.com/questions/22475400/r-replace-values-in-data-frame-using-lookup-table
for (j in 1:nrow(test)){
  for (x in 1:nrow(birdseason)){
    if (test[j,1]==birdseason[x,1]&test[j,2]>birdseason[x,3]&test[j,2]<birdseason[x,4]){
      test[j,3]<-birdseason[x,2]
    }
  } 
}
setnames(test, "V3", "season")
