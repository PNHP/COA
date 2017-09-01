library(arcgisbinding)
arc.check_product()

if (!requireNamespace("RSQLite", quietly = TRUE))
  install.packages("RSQLite")
require(RSQLite)

options(useFancyQuotes = FALSE)

# define parameters to be used in ArcGIS tool
planning_units = "C:/Users/mmoore/Documents/ArcGIS/Default.gdb/PlanningUnits"
#planning_units = in_params[[1]]
out_table = in_params[[2]]

# load and report on selected planning units
pu <- arc.open(planning_units)
selected_pu <- arc.select(pu)
x = paste(nrow(selected_pu), "planning units selected", sep=" ")
print(x)

# create list of unique ids for selected planning units
pu_list <- selected_pu$unique_id

# create connection to sqlite database
db <- dbConnect(SQLite(), dbname = "C:/Users/mmoore/Desktop/__coa_Rbridge/coa_bridgetest.sqlite")
# build query to select planning units within area of interest from SGCNxPU table
SQLquery <- paste("SELECT unique_id, ELCODE, SeasonCode, OccProb, El_Season, AREA", 
                  " FROM lu_SGCNxPU ",
                  "WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
# create SGCNxPU dataframe containing selected planning units
aoi_sgcnXpu <- dbGetQuery(db, statement = SQLquery)
aoi_sgcnXpu$AREA <- round(as.numeric(aoi_sgcnXpu$AREA),5)
# report on number of records in dataframe
y = paste(nrow(aoi_sgcnXpu), "records in SGCNxPU dataframe", sep= " ")
print(y)

# dissolve table based on elcode and season, keeping records with highest summed area within group
aoi_sgcnXpu1 <- aggregate(aoi_sgcnXpu$AREA~ELCODE+OccProb,aoi_sgcnXpu,FUN=sum)
aoi_sgcnXpu2 <- do.call(rbind,lapply(split(aoi_sgcnXpu1, aoi_sgcnXpu1$ELCODE), function(chunk) chunk[which.max(chunk$`aoi_sgcnXpu$AREA`),]))

elcodes <- aoi_sgcnXpu$ELCODE
SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, Environment, TaxaGroup, ElSeason",
                             " FROM lu_SGCN ",
                             "WHERE ELCODE IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
aoi_sgcn <- dbGetQuery(db, statement = SQLquery_lookupSGCN)

aoi_sgcnXpu2 <- merge(aoi_sgcnXpu2, aoi_sgcn, by="ELCODE")

print(paste(aoi_sgcnXpu2$SCOMNAME,"-",aoi_sgcnXpu2$OccProb,"occurrence probability",sep=" "))

