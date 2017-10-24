library(stringr)
library(reshape)
library(plyr)

setwd("E:/COA/HabitatAssocations_Take2/HabitatAssocations")

habitat <- read.csv("HabitatTerr.csv") # read the habitat in
habitat$HUC8 <- str_pad(habitat$HUC8,8,pad="0") #pad a leading zero in front of the HUC8 code that gets stripped on import
habitat$OBJECTID <- NULL
habitat$HUC08 <- NULL
habitat$code <- paste(habitat$Habitat_Terrestr,habitat$HUC8,sep="_") #make a unique habitat code for each habitat/huc combo
habitat$expected <- habitat$Area_m/sum(habitat$Area_m) # calculate the expected value
names(habitat)[names(habitat)=='Value'] <- 'habitat_value'
habitat <- habitat[c("habitat_value", "CLASS", "FORMATION","MACR_2015","HABITAT_1","MODIFIER","code","expected")] # rearrange columns

# load and process species data. this should be the output of the tabulate area command.
sgcn <- read.csv("SGCN_ebirdmovedonly.csv")
sgcn$OBJECTID <- NULL
sgcn_melt <- melt(sgcn, id=c("ELSEASON"),variable_name="habitat_value") # rearrange the table
sgcn_melt <- sgcn_melt[sgcn_melt$value!=0,] # drop any values that are zeros
sgcn_melt$habitat_value <- gsub("VALUE_","",sgcn_melt$habitat_value) #remove the 'VALUE_" part from the string for a merge
# add in the habitats so we can delete the potential spurious observations by class/formation
sgcn_melt <- merge(x=sgcn_melt, y=habitat, by="habitat_value", all.x=TRUE)
# formation subset
formation <- read.csv("lu_SGCN_Formation.csv")
formation$class_expected <- formation$Class
sgcn_melt <- merge(x=sgcn_melt, y=formation, by.x=c("ELSEASON","CLASS"),by.y=c("ELSEASON","Class"), all.x=TRUE)
sgcn_habitat <- ddply(sgcn_melt,.(ELSEASON),transform,observed=value/sum(value)) #calculate the observed proportin for each habitat
sgcn_habitat$chi <- ((sgcn_habitat$observed - sgcn_habitat$expected)/sgcn_habitat$expected)+1 # calculate the chi square value.
sgcn_habitat$chi <- round(sgcn_habitat$chi,2)
sgcn_habitat <- sgcn_habitat[order(sgcn_habitat$ELSEASON,-sgcn_habitat$chi),]

## how to split strings https://stackoverflow.com/questions/15347282/split-delimited-strings-in-a-column-and-insert-as-new-rows
#https://stackoverflow.com/questions/28590469/r-match-between-two-comma-separated-strings

# make files to join to maps
spt1 <- split(sgcn_habitat, sgcn_habitat$ELSEASON)
lapply(names(spt1), function(x){write.csv(spt1[[x]], file = paste("output_", x, ".csv",sep = ""))})


