tool_exec <- function(in_params, out_params)
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
  
# options   
options(useFancyQuotes = FALSE)

# variables
PU_area <- 40468.38 # area of full planning unit in square meters

# define parameters to be used in ArcGIS tool
#   planning_units = "X:/coa/coa_Rbridge/test_pu1.shp"
project_name = in_params[[1]] # project_name <- "Manual Test Project"
planning_units = in_params[[2]]
out_table = in_params[[3]]

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
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")

############## County Names and Other details
# get a list of the unique county FIPs from the PUID field
county_FIPS <- substr(pu_list,1,3)
# connect to the database and lookup the county name
SQLquery_county <- paste("SELECT COUNTY_NAM, FIPS_COUNT"," FROM lu_CountyName ","WHERE FIPS_COUNT IN (", paste(toString(sQuote(county_FIPS)), collapse = ", "), ")")
aoi_county <- dbGetQuery(db, statement = SQLquery_county )
print(paste(aoi_county$COUNTY_NAM," COUNTY", sep="") )
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
SQLquery_HabTerr <- paste("SELECT unique_id, variable, value", # need to change these names
                  " FROM lu_HabTerr ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)),collapse = ", "), ")")
aoi_HabTerr <- dbGetQuery(db, statement = SQLquery_HabTerr)
#calculate acres of each habitat
aoi_HabTerr$acres <- as.numeric(aoi_HabTerr$value) * 10 # "10" is the number of acres in a planning unit
aoi_HabTerr$value <- NULL
# reduce by removing unique planning units
aoi_HabTerr1 <- aoi_HabTerr[c(-1)] # drop the puid column
colnames(aoi_HabTerr1)[colnames(aoi_HabTerr1) == 'variable'] <- 'habitat'
aoi_HabTerr2 <- aggregate(aoi_HabTerr1$acres, by=list(aoi_HabTerr1$habitat) , FUN=sum)

colnames(aoi_HabTerr2)[colnames(aoi_HabTerr2) == 'Group.1'] <- 'habitat'
colnames(aoi_HabTerr2)[colnames(aoi_HabTerr2) == 'x'] <- 'acres'
aoi_HabTerr2 <- aoi_HabTerr2[order(-aoi_HabTerr2$acres),]
if(nrow(aoi_HabTerr2)>2) {  # need three different ones for the pie char to work
  library("RColorBrewer")
  pielab <- as.list(aoi_HabTerr2$habitat)
  pie(aoi_HabTerr2$acres,labels=aoi_HabTerr2$acres, col=brewer.pal(nrow(aoi_HabTerr2),"Set1") )
  legend("bottomleft", legend=pielab, cex = 0.8,bty="n", fill=brewer.pal(nrow(aoi_HabTerr2),"Set1") )
}

print("- - - - - - - - - - - - -")
print("Terrestrial and Palustrine Habitats -- ")
ht <- paste(unique(paste(aoi_HabTerr2$habitat," - ", aoi_HabTerr2$acres, " acres",sep="")) , sep= " ")
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
  print("Lotic Habitats -- ")
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
z = unique(aoi_ProtectedLand$site_nm)
print(z)

############## THREATS ###############
SQLquery_luThreats <- paste("SELECT unique_id, WindTurbines, WindCapability, ShaleGas,ShaleGasWell,StrImpAg,StrmImpAMD"," FROM lu_threats ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
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
# add in something about wind turbines
if(any(aoi_Threats$ShaleGas=='y')) print("Site overlaps potential shale gas resource.")
# add in something about gas wells.

############## SGCN
# build query to select planning units within area of interest from SGCNxPU table
SQLquery <- paste("SELECT unique_id, ELCODE, SeasonCode, OccProb, El_Season, AREA"," FROM lu_SGCNxPU ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
# create SGCNxPU dataframe containing selected planning units
aoi_sgcnXpu <- dbGetQuery(db, statement = SQLquery)

aoi_sgcnXpu$AREA <- round(as.numeric(aoi_sgcnXpu$AREA),5)
# report on number of records in dataframe
print("")
print("- - - - - - - - - - - - -")
y = paste(nrow(aoi_sgcnXpu), "records in SGCNxPU dataframe", sep= " ")
print(y)

# dissolve table based on elcode and season, keeping records with highest summed area within group
aoi_sgcnXpu1 <- aggregate(aoi_sgcnXpu$AREA~El_Season+OccProb,aoi_sgcnXpu,FUN=sum)
aoi_sgcnXpu2 <- do.call(rbind,lapply(split(aoi_sgcnXpu1, aoi_sgcnXpu1$El_Season), function(chunk) chunk[which.max(chunk$`aoi_sgcnXpu$AREA`),]))
colnames(aoi_sgcnXpu2)[colnames(aoi_sgcnXpu2) == 'El_Season'] <- 'ELSeason'
elcodes <- aoi_sgcnXpu2$ELSeason
SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, Environment, TaxaGroup, ELSeason"," FROM lu_SGCN ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
aoi_sgcn <- dbGetQuery(db, statement=SQLquery_lookupSGCN)
# merge species information to the planning units
aoi_sgcnXpu2 <- merge(aoi_sgcnXpu2, aoi_sgcn, by="ELSeason")
print("-------------")
print(paste(aoi_sgcnXpu2$SCOMNAME,"-",aoi_sgcnXpu2$OccProb,"occ. prob.",sep=" "))

############## Actions
SQLquery_actions <- paste("SELECT ELCODE, CommonName, ScientificName, Sensitive, IUCNThreatLv1, ThreatCategory, EditedThreat, ActionLv1, ActionCategory1,COATool_Action, ActionPriority, ELSeason"," FROM lu_actions ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
aoi_actions <- dbGetQuery(db, statement=SQLquery_actions)
print( paste(aoi_actions$ScientificName,aoi_actions$EditedThreat,aoi_actions$COATool_Action,sep=" - ") )

# create a table version of the actions.
aoi_actionstable <- aoi_actions[,c("ScientificName","EditedThreat","Sensitive","COATool_Action","ActionPriority")]


# disconnect the SQL database
# dbDisconnect()  #### This seems to be causing a crash.

##############  report generation
#setwd(loc_outMetadata)
#loc_scripts <- "X:/coa/coa_Rbridge"

#knit2pdf(paste(loc_scripts,"results_knitr.rnw",sep="/"), output=paste("results_",Sys.Date(), ".tex",sep=""))

}
