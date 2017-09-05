<<<<<<< HEAD
tool_exec <- function(in_params, out_params)
{
#library(arcgisbinding)
#arc.check_product()

# check and load required libraries  
=======
library(arcgisbinding)
arc.check_product()

>>>>>>> origin/master
if (!requireNamespace("RSQLite", quietly = TRUE))
  install.packages("RSQLite")
require(RSQLite)

<<<<<<< HEAD
# options   
options(useFancyQuotes = FALSE)


# variables
PU_area <- 40468.38 # area of full planning unit in square meters


# define parameters to be used in ArcGIS tool
#planning_units = "X:/coa/coa_Rbridge/test_pu1.shp"
project_name = in_params[[1]]
planning_units = in_params[[2]]
out_table = in_params[[3]]
=======
options(useFancyQuotes = FALSE)

# define parameters to be used in ArcGIS tool
planning_units = "C:/Users/mmoore/Documents/ArcGIS/Default.gdb/PlanningUnits"
#planning_units = in_params[[1]]
out_table = in_params[[2]]
>>>>>>> origin/master

# load and report on selected planning units
pu <- arc.open(planning_units)
selected_pu <- arc.select(pu)
x = paste(nrow(selected_pu), "planning units selected", sep=" ")
print(x)
<<<<<<< HEAD
area_pu_total <- paste(nrow(selected_pu)*10," acres",sep="") # convert square meters to acrea
print(area_pu_total)
=======
>>>>>>> origin/master

# create list of unique ids for selected planning units
pu_list <- selected_pu$unique_id

<<<<<<< HEAD

############## Natural Boundaries
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_luNatBound <- paste("SELECT unique_id, HUC12, HUC08, HUC04, PROVINCE, SECTION_, ECO_NAME", 
                             " FROM lu_NaturalBoundaries ",
                             "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_NaturalBoundaries <- dbGetQuery(db, statement = SQLquery_luNatBound )

print("- - - - - - - - - - - - -")
w = paste("Physiographic Province -- ",unique(paste(aoi_NaturalBoundaries$PROVINCE,aoi_NaturalBoundaries$SECTION,sep=" - ")) , sep= " ")
print(w)
v = paste("Ecoregion -- ",unique(aoi_NaturalBoundaries$ECO_NAME), sep= " ")
print(v)
u = paste("HUC12 -- ",unique(aoi_NaturalBoundaries$HUC12), sep= " ")
print(u)


############# Habitats
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_HabTerr <- paste("SELECT unique_id, variable, value", # need to change these names
                                  " FROM lu_HabTerr ",
                                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_HabTerr <- dbGetQuery(db, statement = SQLquery_HabTerr)

print("- - - - - - - - - - - - -")
ht = paste("Habitat -- ",unique(paste(aoi_NaturalBoundaries$PROVINCE,aoi_HabTerr$variable,sep=" - ")) , sep= " ")
print(ht)


############## PROTECTED LAND ###############
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
SQLquery_luProtectedLand <- paste("SELECT unique_id, site_nm, manager, owner_typ", 
                                  " FROM lu_ProtectedLands_25 ",
                                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
aoi_ProtectedLand <- dbGetQuery(db, statement = SQLquery_luProtectedLand )

print("- - - - - - - - - - - - -")
z = paste("Protected Land -- ",unique(aoi_ProtectedLand$site_nm), sep= " ")
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
plot(data_wind)
pie(data_wind,main="Wind Capability for this site")

print("- - - - - - - - - - - - -")
i = paste("Threats - Wind Capability -- ",unique(aoi_Threats$WindCapability), sep= " ")
print(i)
g = paste("Threats - Shale Gas -- ",unique(aoi_Threats$ShaleGas), sep= " ")
print(g)

#
##############


############## SGCN
# create connection to sqlite database
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
=======
# create connection to sqlite database
db <- dbConnect(SQLite(), dbname = "C:/Users/mmoore/Desktop/__coa_Rbridge/coa_bridgetest.sqlite")
>>>>>>> origin/master
# build query to select planning units within area of interest from SGCNxPU table
SQLquery <- paste("SELECT unique_id, ELCODE, SeasonCode, OccProb, El_Season, AREA", 
                  " FROM lu_SGCNxPU ",
                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
# create SGCNxPU dataframe containing selected planning units
aoi_sgcnXpu <- dbGetQuery(db, statement = SQLquery)
<<<<<<< HEAD

aoi_sgcnXpu$AREA <- round(as.numeric(aoi_sgcnXpu$AREA),5)
# report on number of records in dataframe
print("")
print("- - - - - - - - - - - - -")
=======
aoi_sgcnXpu$AREA <- round(as.numeric(aoi_sgcnXpu$AREA),5)
# report on number of records in dataframe
>>>>>>> origin/master
y = paste(nrow(aoi_sgcnXpu), "records in SGCNxPU dataframe", sep= " ")
print(y)

# dissolve table based on elcode and season, keeping records with highest summed area within group
aoi_sgcnXpu1 <- aggregate(aoi_sgcnXpu$AREA~ELCODE+OccProb,aoi_sgcnXpu,FUN=sum)
aoi_sgcnXpu2 <- do.call(rbind,lapply(split(aoi_sgcnXpu1, aoi_sgcnXpu1$ELCODE), function(chunk) chunk[which.max(chunk$`aoi_sgcnXpu$AREA`),]))

elcodes <- aoi_sgcnXpu$ELCODE
<<<<<<< HEAD
db <- dbConnect(SQLite(), dbname = "X:/coa/coa_Rbridge/coa_bridgetest.sqlite")
=======
>>>>>>> origin/master
SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, Environment, TaxaGroup, ElSeason",
                             " FROM lu_SGCN ",
                             "WHERE ELCODE IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
aoi_sgcn <- dbGetQuery(db, statement = SQLquery_lookupSGCN)

<<<<<<< HEAD

############### merge species information to the planning units
aoi_sgcnXpu2 <- merge(aoi_sgcnXpu2, aoi_sgcn, by="ELCODE")
print("-------------")
print(paste(aoi_sgcnXpu2$SCOMNAME,"-",aoi_sgcnXpu2$OccProb,"occurrence probability",sep=" "))
#
##############






# disconnect the SQL database
#dbDisconnect()  #### This seems to be causing a crash.



}
=======
aoi_sgcnXpu2 <- merge(aoi_sgcnXpu2, aoi_sgcn, by="ELCODE")

print(paste(aoi_sgcnXpu2$SCOMNAME,"-",aoi_sgcnXpu2$OccProb,"occurrence probability",sep=" "))

>>>>>>> origin/master
