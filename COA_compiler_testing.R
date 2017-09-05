tool_exec <- function(in_params, out_params)
{
#library(arcgisbinding)
#arc.check_product()

# check and load required libraries  
if (!requireNamespace("RSQLite", quietly = TRUE))
  install.packages("RSQLite")
require(RSQLite)

# options   
options(useFancyQuotes = FALSE)


# variables
PU_area <- 40468.38 # area of full planning unit in square meters


# define parameters to be used in ArcGIS tool
#planning_units = "X:/coa/coa_Rbridge/test_pu1.shp"
project_name = in_params[[1]]
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

############## County Names and Other details
# get a list of the unique county FIPs from the PUID field
county_FIPS <- substr(pu_list,1,3)
# connect to the database and lookup the county name
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_county <- paste("SELECT COUNTY_NAM, FIPS_COUNT", 
                             " FROM lu_CountyName ",
                             "WHERE FIPS_COUNT IN (", paste(toString(sQuote(county_FIPS)), collapse = ", "), ")")
aoi_county <- dbGetQuery(db, statement = SQLquery_county )
print(paste(aoi_county$COUNTY_NAM," COUNTY", sep="") )
## do we want to add PGC/PFBC district information to the table here???

############## Natural Boundaries
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_luNatBound <- paste("SELECT unique_id, HUC12, PROVINCE, SECTION_, ECO_NAME", 
                             " FROM lu_NaturalBoundaries ",
                             "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
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
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_HabTerr <- paste("SELECT unique_id, variable, value", # need to change these names
                                  " FROM lu_HabTerr ",
                                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_HabTerr <- dbGetQuery(db, statement = SQLquery_HabTerr)
#calculate acres of each habitat
aoi_HabTerr$acres <- as.numeric(aoi_HabTerr$value) * 10 # "10" is the number of acres in a planning unit
# reduce by removing unique planning units
aoi_HabTerr1 <- aoi_HabTerr[c(-1)] # drop the puid column
colnames(aoi_HabTerr1)[colnames(aoi_HabTerr1) == 'variable'] <- 'habitat'
aoi_HabTerr2 <- aggregate(aoi_HabTerr1$acres, by=list(aoi_HabTerr1$habitat) , FUN=sum)
colnames(aoi_HabTerr2)[colnames(aoi_HabTerr2) == 'Group.1'] <- 'habitat'
colnames(aoi_HabTerr2)[colnames(aoi_HabTerr2) == 'x'] <- 'acres'
aoi_HabTerr2 <- aoi_HabTerr2[order(-aoi_HabTerr2$acres),]
pie(aoi_HabTerr2$acres, labels=aoi_HabTerr2$habitat)

print("- - - - - - - - - - - - -")
print("Terrestrial and Palustrine Habitats -- ")
ht <- paste(unique(paste(aoi_HabTerr2$habitat," - ", aoi_HabTerr2$acres, " acres",sep="")) , sep= " ")
print(ht)
print("Lotic Habitats -- ")

############## PROTECTED LAND ###############
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_luProtectedLand <- paste("SELECT unique_id, site_nm, manager, owner_typ", 
                                  " FROM lu_ProtectedLands_25 ",
                                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_ProtectedLand <- dbGetQuery(db, statement = SQLquery_luProtectedLand )

print("- - - - - - - - - - - - -")
print("Protected Land")
z = unique(aoi_ProtectedLand$site_nm)
print(z)
#
##############

############## THREATS ###############
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_luThreats <- paste("SELECT unique_id, WindTurbines, WindCapability, ShaleGas,ShaleGasWell,StrImpAg,StrmImpAMD", 
                                  " FROM lu_threats ",
                                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_Threats <- dbGetQuery(db, statement = SQLquery_luThreats )


data_wind <- table(aoi_Threats$WindCapability)
#plot(data_wind)
#pie(data_wind,main="Wind Capability for this site")

print("- - - - - - - - - - - - -")
print("Threats (note: threats will likely not be directly shown in the final tool)")

if(max(aoi_Threats$WindCapability)>2) {
  print("Class 3 wind power potential at this site.")
} else {
  print("No significant wind resources known at this site.")
}

g = paste("Shale Gas Capable: ",unique(aoi_Threats$ShaleGas), sep= " ")
print(g)


############## SGCN
# create connection to sqlite database
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
# build query to select planning units within area of interest from SGCNxPU table
SQLquery <- paste("SELECT unique_id, ELCODE, SeasonCode, OccProb, El_Season, AREA", 
                  " FROM lu_SGCNxPU ",
                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
# create SGCNxPU dataframe containing selected planning units
aoi_sgcnXpu <- dbGetQuery(db, statement = SQLquery)

aoi_sgcnXpu$AREA <- round(as.numeric(aoi_sgcnXpu$AREA),5)
# report on number of records in dataframe
print("")
print("- - - - - - - - - - - - -")
y = paste(nrow(aoi_sgcnXpu), "records in SGCNxPU dataframe", sep= " ")
print(y)

# dissolve table based on elcode and season, keeping records with highest summed area within group
aoi_sgcnXpu1 <- aggregate(aoi_sgcnXpu$AREA~ELCODE+OccProb,aoi_sgcnXpu,FUN=sum)
aoi_sgcnXpu2 <- do.call(rbind,lapply(split(aoi_sgcnXpu1, aoi_sgcnXpu1$ELCODE), function(chunk) chunk[which.max(chunk$`aoi_sgcnXpu$AREA`),]))

elcodes <- aoi_sgcnXpu$ELCODE
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, Environment, TaxaGroup, ElSeason",
                             " FROM lu_SGCN ",
                             "WHERE ELCODE IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
aoi_sgcn <- dbGetQuery(db, statement = SQLquery_lookupSGCN)

# merge species information to the planning units
aoi_sgcnXpu2 <- merge(aoi_sgcnXpu2, aoi_sgcn, by="ELCODE")
print("-------------")
print(paste(aoi_sgcnXpu2$SCOMNAME,"-",aoi_sgcnXpu2$OccProb,"occ. prob.",sep=" "))



############## Actions








# disconnect the SQL database
#dbDisconnect()  #### This seems to be causing a crash.



}
