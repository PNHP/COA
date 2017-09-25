


# check and load required libraries  
if (!requireNamespace("RSQLite", quietly = TRUE))
  install.packages("RSQLite")
require(RSQLite)

library(arcgisbinding)
library(spdplyr)
arc.check_product()

setwd("E:/COA")

# options   
options(useFancyQuotes = FALSE)

# variables
databasename = "E:/coa2/coa_bridgetest.sqlite"

pu <- arc.open("E:/coa2/sgcn_maps/sgcnmaps1.gdb/pu10")

# create connection to sqlite database
db <- dbConnect(SQLite(), dbname = databasename)
# get a list of sgcn in the database
SQLquery_sgcn_present <- paste("SELECT El_Season"," FROM lu_sgcnXpu_all ")
lu_sgcnSpatial <- dbGetQuery(db, statement=SQLquery_sgcn_present)
lu_sgcnSpatial <- unique(lu_sgcnSpatial) 

# create SGCNxPU dataframe containing for selected SGCN
#sgcnXpu <- dbGetQuery(db, statement = SQLquery)

SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, SeasonCode, SENSITV_SP, Environment, TaxaGroup, ELSeason, CAT1_glbl_reg, CAT2_com_sp_com, CAT3_cons_rare_native, CAT4_datagaps "," FROM lu_SGCN ")
lu_sgcn <- dbGetQuery(db, statement=SQLquery_lookupSGCN)

lu_sgcnSpatial1 <- lu_sgcnSpatial[lu_sgcnSpatial$El_Season %in% lu_sgcn$ELSeason,]

# add in species with more than 100,000 records to skip for now.
sp_gt100k <-as.character(c("ABPBK01010_b","ABPBJ19010_b","ABPBX45040_b","ABPBX94050_b","ABNKD06020_b","ABPBXB2020_b","ABPAE33040_b","ABPBX10030_b","ABPBX03100_b","ABPBX99010_b","ABPBX03240_b","ABPBXA0020_b","ABPBXA9010_b","ARAAD08012_y","ABPBX01020_b","ABPBX03190_b","ABPBA01010_b","ABPBX03050_b","ABNLC11010_b","ABPBX95010_b","ABPBX24010_b","ABPBX16030_b","ABPBG09050_b","ABNTA07070_b","ARADE01010_y","ABPBX11010_b","IILEPA2020_y","IILEPK4060_y","ABPAU01010_b","AMAJF05010_y","AMAFB09020_y","AFCHA05030_y","AMACC01100_b","ABNYF04040_b",
"AMAFF08100_y","ABNME08020_b","ABNME05030_b","AMACC01130_y","ABPBJ18100_b","ABPBX01030_b","ARADE02040_y","ARAAD02040_y","ABPAU08010_b","ABPBXA0030_b","ARADE03011_y","ABPBX01060_b","ABPBX10020_b","ABPBXA4020_b","AAABH01170_y","AMABA01153_y","ABNNF19020_b"))

lu_sgcnSpatial1 <- lu_sgcnSpatial1[ !(lu_sgcnSpatial1 %in% sp_gt100k)]


for (i in 14:NROW(lu_sgcnSpatial1) ){   #1:NROW(lu_sgcnSpatial1)
  print(lu_sgcnSpatial1[i])
  # get planning unit data 
  SQLquery <- paste("SELECT unique_id, El_Season, OccProb, PERCENTAGE"," FROM lu_sgcnXpu_all ","WHERE El_Season IN (", paste(toString(sQuote(lu_sgcnSpatial1[i])), collapse = ", "), ")")
  # create SGCNxPU dataframe containing for selected SGCN
  sgcnXpu <- dbGetQuery(db, statement = SQLquery)
  assign(paste("sgcnXpu",lu_sgcnSpatial1[i],sep="_"), sgcnXpu ) 
  # add code to assign occ prob
  print(" species by planning units selected")
  
  pu_list <- get(paste("sgcnXpu_",lu_sgcnSpatial1[i],sep=""))      
  pu_list <- pu_list$unique_id
  print("planning units list generated")
  
  selpu <- arc.select(pu, fields=c("unique_id"), where_clause=paste("unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")") )
  
# convert to a spatial object, see: https://geonet.esri.com/thread/196578-impossible-to-use-dplyr-join-functions-on-data-frames
  selpu.sp <- arc.data2sp(selpu)
  print("got the hexes that match the sgcn")
  
  joined <- left_join(selpu.sp, sgcnXpu, by="unique_id", copy=TRUE)
  selpu1 <- arc.sp2data(joined)

  arc.write(path=paste("E:/coa2/sgcn_maps/results/", lu_sgcnSpatial1[i] ,".shp",sep=""), data=selpu1, shape_info=arc.shapeinfo(selpu)) 
  
  sgcnXpu <- NULL
  selpu <-NULL
  selpu.sp <- NULL
  selpu1 <- NULL
  pu_list <- NULL
  joined <- NULL
  
}




dbDisconnect(db) 



