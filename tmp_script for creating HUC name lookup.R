library(stringr)

setwd("X:/coa/coa_Rbridge/temp_csv_for_sqlite")

huc8 <- read.csv("tmp_HUC08.csv")
huc8$OBJECTID <- NULL
huc8$TNMID <- NULL
huc8$GNIS_ID <- NULL
huc8$MetaSourceID <- NULL
huc8$SourceDataDesc <- NULL
huc8$SourceOriginator <- NULL
huc8$SourceFeatureID <- NULL
huc8$LoadDate <- NULL
huc8$AreaAcres <- NULL
huc8$AreaSqKm  <- NULL
huc8$States <- NULL
huc8$Shape_STArea__ <- NULL
huc8$Shape_STLength__ <- NULL
huc8$GlobalID  <- NULL
huc8$Shape_STArea__1 <- NULL
huc8$Shape_STLength__1 <- NULL
huc8$HUC8 <- str_pad(huc8$HUC8, width=8, pad="0")

huc12 <- read.csv("tmp_HUC12.csv")
huc12$OBJECTID <- NULL
huc12$TNMID <- NULL
huc12$GNIS_ID <- NULL
huc12$MetaSourceID <- NULL
huc12$SourceDataDesc <- NULL
huc12$SourceOriginator <- NULL
huc12$SourceFeatureID <- NULL
huc12$LoadDate <- NULL
huc12$AreaAcres <- NULL
huc12$AreaSqKm  <- NULL
huc12$States <- NULL
huc12$Shape_STArea__ <- NULL
huc12$Shape_STLength__ <- NULL
huc12$GlobalID  <- NULL
huc12$Shape_STArea__1 <- NULL
huc12$Shape_STLength__1 <- NULL
huc12$NonContributingAcres <- NULL
huc12$NonContributingSqKm <- NULL
huc12$HUType <- NULL
huc12$HUMod <- NULL
huc12$ToHUC <- NULL


huc12$HUC12 <- str_pad(huc12$HUC12, width=12, pad="0")
huc12$HUC8 <- substr(huc12$HUC12,1,8)

huclist <- merge(huc12,huc8,by="HUC8")

write.csv(huclist,"lu_HUCname.csv")

