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
