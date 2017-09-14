
actions <- read.csv("COA_ThreatsActionsTemplate_v1.2.csv")


# extract action season code and change to lowercase
actions$season <- tolower(substr(actions$ActionSeason,1,1))  ## see the note here about factors, may be somethig to change https://stackoverflow.com/questions/35974571/lower-case-for-a-data-frame-column
# replace empty values with a "y" for yearround SGCN
actions$season[actions$season==""] <- "y"
# create the ELSeason code
actions$ELSeason <- paste(actions$ELCODE,actions$season,sep="_")


write.csv(actions, "temp_csv_for_sqlite/lu_actions.csv")
