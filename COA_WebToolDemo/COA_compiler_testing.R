tool_exec <- function(in_params, out_params)  #
{
#library(arcgisbinding)
#arc.check_product()

# check and load required libraries  
if (!requireNamespace("RSQLite", quietly = TRUE))
  install.packages("RSQLite")
require(RSQLite)
if (!requireNamespace("knitr", quietly = TRUE))
  install.packages("knitr")
require(knitr)
if (!requireNamespace("data.table", quietly = TRUE))
  install.packages("data.table")
require(data.table)
if (!requireNamespace("xtable", quietly = TRUE))
  install.packages("xtable")
require(xtable)
  
# options   
options(useFancyQuotes = FALSE)

# variables
PU_area <- 40468.38 # area of full planning unit in square meters

# define parameters to be used in ArcGIS tool
#   planning_units = "E:/coa2/test_pu1.shp"
project_name = in_params[[1]] # project_name <- "Manual Test Project"
planning_units = in_params[[2]]
#out_table = in_params[[3]]

print(paste("Project Name: ",project_name, sep=""))
print(date())
print("- - - - - - - - - - - - -")

# load and report on selected planning units
pu <- arc.open(planning_units)
selected_pu <- arc.select(pu)

area_pu_total <- paste("Project Area: ",nrow(selected_pu)*10," acres ","(",nrow(selected_pu), " planning units selected) ", sep="") # convert square meters to acres
print(area_pu_total)

# create list of unique ids for selected planning units
pu_list <- selected_pu$unique_id

# create connection to sqlite database
db <- dbConnect(SQLite(), dbname = "E:/coa2/coa_bridgetest.sqlite")

############## County Names and Other details
# get a list of the unique county FIPs from the PUID field
county_FIPS <- substr(pu_list,1,3)
# connect to the database and lookup the county name
SQLquery_county <- paste("SELECT COUNTY_NAM, FIPS_COUNT"," FROM lu_CountyName ","WHERE FIPS_COUNT IN (", paste(toString(sQuote(county_FIPS)), collapse = ", "), ")")
aoi_county <- dbGetQuery(db, statement = SQLquery_county )
counties <-  paste(aoi_county$COUNTY_NAM," COUNTY", sep="") 
print(counties)

SQLquery_muni <- paste("SELECT unique_id, FIPS_MUN_P"," FROM lu_muni ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_muni <- dbGetQuery(db, statement = SQLquery_muni )
aoi_muni$unique_id <- NULL
aoi_muni1 <-  unique(aoi_muni)
aoi_muni1 <- as.vector(aoi_muni1$FIPS_MUN_P)
SQLquery_muni_name <- paste("SELECT FIPS_MUN_P, Name_Proper_Type"," FROM lu_muni_names ","WHERE FIPS_MUN_P IN (", paste(toString(sQuote(aoi_muni1)), collapse = ", "), ")")
aoi_muni_name <- dbGetQuery(db, statement = SQLquery_muni_name )

munis <- paste(aoi_muni_name$Name_Proper_Type, sep=",")
print(munis)

## do we want to add PGC/PFBC district information to the table here???

############## Natural Boundaries
SQLquery_luNatBound <- paste("SELECT unique_id, HUC12, PROVINCE, SECTION_, ECO_NAME"," FROM lu_NaturalBoundaries ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_NaturalBoundaries <- dbGetQuery(db, statement = SQLquery_luNatBound )
HUC_list <- unique(aoi_NaturalBoundaries$HUC12)
# HUC Name lookup
SQLquery_HUC <- paste("SELECT HUC8, HUC12, HUC8name, HUC12name", 
                             " FROM lu_HUCname ",
                             "WHERE HUC12 IN (", paste(toString(sQuote(HUC_list)), collapse = ", "), ")")
aoi_HUC <- dbGetQuery(db, statement = SQLquery_HUC )

#aoi_NaturalBoundaries <- merge(aoi_NaturalBoundaries,)
print("- - - - - - - - - - - - -")
w = paste("Physiographic Province -- ",unique(paste(aoi_NaturalBoundaries$PROVINCE,aoi_NaturalBoundaries$SECTION,sep=" - ")) , sep= " ")
print(w)
v = paste("Ecoregion -- ",unique(aoi_NaturalBoundaries$ECO_NAME), sep= " ")
print(v)

u1 = paste("HUC8 --",unique(aoi_HUC$HUC8name), sep= " ")
u2 = paste("HUC12 --",unique(aoi_HUC$HUC12name), sep= " ")
print(u1)
print(u2)

############# Habitats
SQLquery_HabTerr <- paste("SELECT unique_id, Code, PERCENTAGE", # need to change these names
                  " FROM lu_HabTerr ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)),collapse = ", "), ")")
aoi_HabTerr <- dbGetQuery(db, statement = SQLquery_HabTerr)
#calculate acres of each habitat
aoi_HabTerr$acres <- as.numeric(aoi_HabTerr$PERCENTAGE) * 10 # "10" is the number of acres in a planning unit
aoi_HabTerr$PERCENTAGE <- NULL
# reduce by removing unique planning units
aoi_HabTerr1 <- aoi_HabTerr[c(-1)] # drop the puid column
#colnames(aoi_HabTerr1)[colnames(aoi_HabTerr1) == 'variable'] <- 'habitat'
aoi_HabTerr2 <- aggregate(aoi_HabTerr1$acres, by=list(aoi_HabTerr1$Code) , FUN=sum)
#aoi_HabTerr2$acres <- round(as.numeric(aoi_HabTerr2$acres,2))

colnames(aoi_HabTerr2)[colnames(aoi_HabTerr2) == 'Group.1'] <- 'Code'
colnames(aoi_HabTerr2)[colnames(aoi_HabTerr2) == 'x'] <- 'acres'
aoi_HabTerr2 <- aoi_HabTerr2[order(-aoi_HabTerr2$acres),]

## updated habitat information
# 1 get the habitats
HabCodeList <- aoi_HabTerr2$Code
# 2 get the names for the habitats
SQLquery_NamesHabTerr <- paste("SELECT Code, Habitat, Class, Macrogroup, MODIFIER, PATTERN, FORMATION, type ", # need to change these names
                          " FROM lu_HabitatName ","WHERE Code IN (", paste(toString(sQuote(HabCodeList)),collapse = ", "), ")")
aoi_NamesHabTerr <- dbGetQuery(db, statement = SQLquery_NamesHabTerr)
aoi_HabTerr2 <- merge(aoi_HabTerr2, aoi_NamesHabTerr, by="Code")

aoi_HabTerr2 <- aoi_HabTerr2[order(aoi_HabTerr2$type, -aoi_HabTerr2$acres),]

# make a chart of the habitats. Just for kicks!
if(nrow(aoi_HabTerr2)>2&&nrow(aoi_HabTerr2)<9 ) {  # need three different ones for the pie chart to work, the color scheme also wont work above 8 types
  library("RColorBrewer")
  pielab <- as.list(aoi_HabTerr2$Habitat)
  pie(aoi_HabTerr2$acres,labels=aoi_HabTerr2$acres, col=brewer.pal(nrow(aoi_HabTerr2),"Set1") )
  legend("bottomleft", legend=pielab, cex=0.8,bty="n", fill=brewer.pal(nrow(aoi_HabTerr2),"Set1") )
}

# make a table of the results
print("- - - - - - - - - - - - -")
print("Terrestrial and Palustrine Habitats -- ")
ht <- paste(unique(paste(aoi_HabTerr2$Habitat," - ", round(aoi_HabTerr2$acres,2), " acres",sep="")) , sep= " ")
print(ht)

# aquatics 
SQLquery_HabLotic <- paste("SELECT unique_id, Shape_Length, SUM_23, DESC_23", # need to change these names
                          " FROM lu_LoticData ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_HabLotic <- dbGetQuery(db, statement = SQLquery_HabLotic)
if( nrow(aoi_HabLotic)>0 ) {
  aoi_HabLotic1 <- aoi_HabLotic[c(-1)] # drop the puid column
  aoi_HabLotic2 <- aggregate(as.numeric(aoi_HabLotic1$Shape_Length), by=list(aoi_HabLotic1$DESC_23), FUN=sum)
  colnames(aoi_HabLotic2)[colnames(aoi_HabLotic2) == 'Group.1'] <- 'habitat'
  colnames(aoi_HabLotic2)[colnames(aoi_HabLotic2) == 'x'] <- 'length'
  print("Streams and Rivers -- ")
  hl <- paste(unique(paste(aoi_HabLotic2$habitat," - ", round(aoi_HabLotic2$length*0.000621371,2),"miles (",round(aoi_HabLotic2$length/1000,2), "km)",sep="")) , sep= " ")
  print(hl)
} else {
  print("No mapped streams in the NHD dataset.")
}

############## PROTECTED LAND ###############
SQLquery_luProtectedLand <- paste("SELECT unique_id, site_nm, manager, owner_typ", " FROM lu_ProtectedLands_25 ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_ProtectedLand <- dbGetQuery(db, statement = SQLquery_luProtectedLand )
print("- - - - - - - - - - - - -")
print("Protected Land")
if( nrow(aoi_ProtectedLand)>0 ) {
  z = unique(aoi_ProtectedLand$site_nm)
  print(z)
} else {
  print("No mapped protected land in the project area.")
}

############## THREATS ###############
SQLquery_luThreats <- paste("SELECT unique_id, WindTurbines, WindCapability, ShaleGas,ShaleGasWell,StrImpAg,StrImpAMD"," FROM lu_threats ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_Threats <- dbGetQuery(db, statement = SQLquery_luThreats )

data_wind <- table(aoi_Threats$WindCapability)
#plot(data_wind)
#pie(data_wind,main="Wind Capability for this site")

print("- - - - - - - - - - - - -")
print("Threats (note: threats will likely not be directly shown in the final tool)")
if(max(aoi_Threats$WindCapability)>2) { # selected '2' as class 3 and above are thought to have commercial wind energy potential
  print("Class 3 wind power potential at this site.")
} else {
  print("No significant wind resources known at this site.")
}
# wind turbines
if(any(aoi_Threats$WindTurbines =='y')) print("Wind turbines present within the AOI.")
# shale gas
if(any(aoi_Threats$ShaleGas=='y')) {
  print("Site overlaps potential shale gas resource.")
} else {
  print("No known shale resource within this AOI.")
}
# gas wells
if(any(aoi_Threats$ShaleGasWell=='y')) print("Shale gas well pads present within the AOI.")

############## SGCN
# build query to select planning units within area of interest from SGCNxPU table
SQLquery <- paste("SELECT unique_id, El_Season, OccProb, PERCENTAGE"," FROM lu_sgcnXpu_all ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
# create SGCNxPU dataframe containing selected planning units
aoi_sgcnXpu <- dbGetQuery(db, statement = SQLquery)
aoi_sgcnXpu$PERCENTAGE <- round(as.numeric(aoi_sgcnXpu$PERCENTAGE),5)
# report on number of records in dataframe
print("- - - - - - - - - - - - -")
y = paste(nrow(aoi_sgcnXpu), "records in SGCNxPU dataframe", sep= " ")
print(y)

# dissolve table based on elcode and season, keeping records with highest summed area within group
aoi_sgcnXpu1 <- aggregate(aoi_sgcnXpu$PERCENTAGE~El_Season+OccProb,aoi_sgcnXpu,FUN=sum)
aoi_sgcnXpu2 <- do.call(rbind,lapply(split(aoi_sgcnXpu1, aoi_sgcnXpu1$El_Season), function(chunk) chunk[which.max(chunk$`aoi_sgcnXpu$PERCENTAGE`),]))
colnames(aoi_sgcnXpu2)[colnames(aoi_sgcnXpu2) == 'El_Season'] <- 'ELSeason'
# drop all the low occurence probability values from the table
##aoi_sgcnXpu2 <- aoi_sgcnXpu2[ which(aoi_sgcnXpu2$OccProb!="Low"), ]

# join SGCN name data sgcn_aoi table
elcodes <- aoi_sgcnXpu2$ELSeason
SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, SeasonCode, SENSITV_SP, Environment, TaxaGroup, ELSeason, CAT1_glbl_reg, CAT2_com_sp_com, CAT3_cons_rare_native, CAT4_datagaps "," FROM lu_SGCN ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
aoi_sgcn <- dbGetQuery(db, statement=SQLquery_lookupSGCN)
# deal with sensitive species
setDT(aoi_sgcn)[SENSITV_SP=="Y", SNAME:=paste0("{{ ",SNAME," }}")]

# before the merge, set the priority for the SGCN based on the highest value in a number of categories
aoi_sgcn[, "CAT_min"] <- apply(aoi_sgcn[, 10:13], 1, min) # get the minumum across categories
aoi_sgcn$CAT_Weight <- 1 / as.numeric(aoi_sgcn$CAT_min) # take the inverse
# merge species information to the planning units
aoi_sgcnXpu2 <- merge(aoi_sgcnXpu2, aoi_sgcn) #, by="ELSeason"
aoi_sgcnXpu2 <- aoi_sgcnXpu2[order(aoi_sgcnXpu2$TaxaGroup),]
# add a weight based on the Occurence probability
aoi_sgcnXpu2$OccWeight[aoi_sgcnXpu2$OccProb=="Low"] <- 0.6
aoi_sgcnXpu2$OccWeight[aoi_sgcnXpu2$OccProb=="Medium"] <- 0.8
aoi_sgcnXpu2$OccWeight[aoi_sgcnXpu2$OccProb=="High"] <- 1

# Calcuate species priority
aoi_sgcnXpu2$SGCNpriority <- aoi_sgcnXpu2$CAT_Weight * aoi_sgcnXpu2$OccWeight
aoi_sgcnXpu2 <- aoi_sgcnXpu2[order(-aoi_sgcnXpu2$SGCNpriority),]
print("-------------")
print(paste(aoi_sgcnXpu2$SCOMNAME,"-",aoi_sgcnXpu2$SeasonCode,"-",aoi_sgcnXpu2$OccProb,"prob."," - SGCN Priority = ",round(aoi_sgcnXpu2$SGCNpriority,2),sep=" "))

keeps <- c("SCOMNAME","SNAME","OccProb")
aoi_sgcn_results <- aoi_sgcnXpu2[keeps]

############## Actions
SQLquery_actions <- paste("SELECT ELCODE, CommonName, ScientificName, Sensitive, IUCNThreatLv1, ThreatCategory, EditedThreat, ActionLv1, ActionCategory1,COATool_Action, ActionPriority, ELSeason"," FROM lu_actions ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
aoi_actions <- dbGetQuery(db, statement=SQLquery_actions)
print( paste(aoi_actions$ScientificName,aoi_actions$EditedThreat,aoi_actions$COATool_Action,sep=" - ") )

# create a table version of the actions.
aoi_actionstable <- aoi_actions[,c("ScientificName","EditedThreat","Sensitive","COATool_Action","ActionPriority")]


# disconnect the SQL database
# dbDisconnect()  #### This seems to be causing a crash.

##############  report generation
setwd("E:/coa2/COA/COA_WebToolDemo")
loc_scripts <- "E:/coa2/COA/COA_WebToolDemo"

knit2pdf(paste(loc_scripts,"results_knitr.rnw",sep="/"), output=paste("results_",Sys.Date(), ".tex",sep=""))



}
