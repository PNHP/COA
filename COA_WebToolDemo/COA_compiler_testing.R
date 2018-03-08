tool_exec <- function(in_params, out_params)  #
{
  # library(arcgisbinding)
  # arc.check_product()
  
  # check and load required libraries  
  if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)
  if (!requireNamespace("knitr", quietly = TRUE)) install.packages("knitr")
  require(knitr)
  if (!requireNamespace("data.table", quietly = TRUE)) install.packages("data.table")
  require(data.table)
  if (!requireNamespace("xtable", quietly = TRUE)) install.packages("xtable")
  require(xtable)
  if (!requireNamespace("gdata", quietly = TRUE)) install.packages("gdata")
  require(gdata)
  if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
  require(dplyr)
  if (!requireNamespace("lettercase", quietly = TRUE)) install.packages("lettercase")
  require(lettercase)
  if (!requireNamespace("mailR", quietly = TRUE)) install.packages("mailR")
  require(mailR)
  if (!requireNamespace("Hmisc", quietly = TRUE)) install.packages("Hmisc")
  require(Hmisc)
 
  ## The line directly below (loc_scripts) needs your attention
  loc_scripts <- "E:/coa2/COA/COA_WebToolDemo"
  source(paste(loc_scripts, "0_PathsAndSettings.R", sep = "/"))
  setwd(working_directory)
  # get a list of the codes for viewing of senstive species
  codetable <- read.csv("codes.csv",stringsAsFactors=FALSE)
  
  # define parameters to be used in ArcGIS tool
  project_name <- in_params[[1]]
  planning_units <- in_params[[2]]
  recipients <- in_params[[3]]
  AgencyPersonnel <- in_params[[4]] 
  
  ## move this to an if statement
  # project_name <- "Manual Test Project"
  # planning_units <- "E:/coa2/test_pu1.shp"
  # planning_units <- "E:/coa2/test_pu1_DevoidOfSGCN.shp"
  # planning_units <- "E:/coa2/test_pu_FrickPark.shp"
  # AgencyPersonnel <- NULL   ### delete values this one
  if(!is.null(AgencyPersonnel)){
    AgDis <- codetable[match(AgencyPersonnel,codetable$password),1]
    #AgDis <- paste("You are viewing this output as",AgDis,"staff and some sensitive species may be displayed.",sep=" ")
  }else if(is.null(AgencyPersonnel)){
    AgDis <- "public"
  } 
  print(AgDis) ### remove  # probably should insert something into SQL lite if the passcode is used
  
  print(paste("Project Name: ",project_name, sep=""))
  print(date())
  # load and report on selected planning units
  pu <- arc.open(planning_units)
  selected_pu <- arc.select(pu)
  area_pu_total <- paste("Project Area: ",nrow(selected_pu)*10," acres ","(",nrow(selected_pu), " planning units selected) ", sep="") 
  # create list of unique ids for selected planning units
  pu_list <- selected_pu$unique_id
  
  # create connection to sqlite database
  db <- dbConnect(SQLite(), dbname = databasename)
  
  ############## County Names and Other details ########################
  # get a list of the unique county FIPs from the PUID field
  county_FIPS <- substr(pu_list,1,3)
  # connect to the database and lookup the county name
  SQLquery_county <- paste("SELECT COUNTY_NAM, FIPS_COUNT"," FROM lu_CountyName ","WHERE FIPS_COUNT IN (", paste(toString(sQuote(county_FIPS)), collapse = ", "), ")")
  aoi_county <- dbGetQuery(db, statement = SQLquery_county )
  counties <-  paste(aoi_county$COUNTY_NAM," COUNTY", sep="") 
  SQLquery_muni <- paste("SELECT unique_id, FIPS_MUN_P"," FROM lu_muni ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_muni <- dbGetQuery(db, statement = SQLquery_muni )
  aoi_muni$unique_id <- NULL
  aoi_muni <-  unique(aoi_muni)
  aoi_muni <- as.vector(aoi_muni$FIPS_MUN_P)
  SQLquery_muni_name <- paste("SELECT FIPS_MUN_P, Name_Proper_Type"," FROM lu_muni_names ","WHERE FIPS_MUN_P IN (", paste(toString(sQuote(aoi_muni)), collapse = ", "), ")")
  aoi_muni_name <- dbGetQuery(db, statement = SQLquery_muni_name )
  munis <- paste(aoi_muni_name$Name_Proper_Type, sep=",")

  ############## Natural Boundaries
  SQLquery_luNatBound <- paste("SELECT unique_id, HUC12, PROVINCE, SECTION_, ECO_NAME"," FROM lu_NaturalBoundaries ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_NaturalBoundaries <- dbGetQuery(db, statement = SQLquery_luNatBound )
  HUC_list <- unique(aoi_NaturalBoundaries$HUC12)
  SQLquery_HUC <- paste("SELECT HUC8, HUC12, HUC8name, HUC12name"," FROM lu_HUCname ","WHERE HUC12 IN (", paste(toString(sQuote(HUC_list)), collapse = ", "), ")") # HUC Name lookup
  aoi_HUC <- dbGetQuery(db, statement = SQLquery_HUC )
  w = paste("Physiographic Province -- ",unique(paste(aoi_NaturalBoundaries$PROVINCE,aoi_NaturalBoundaries$SECTION,sep=" - ")) , sep= " ")
  v = paste("Ecoregion -- ",unique(aoi_NaturalBoundaries$ECO_NAME), sep= " ")
  u1 = paste("HUC8 --",unique(aoi_HUC$HUC8name), sep= " ")
  u2 = paste("HUC12 --",unique(aoi_HUC$HUC12name), sep= " ")

  ##############  SGCN  ########################################
  # build query to select planning units within area of interest from SGCNxPU table
  print("Looking up SGCN with the AOI") # report out to ArcGIS
  SQLquery <- paste("SELECT unique_id, ELSeason, OccProb, PERCENTAGE"," FROM lu_sgcnXpu_all ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_sgcnXpu <- dbGetQuery(db, statement = SQLquery) # create SGCNxPU dataframe containing selected planning units
  aoi_sgcnXpu$AREA <- round((as.numeric(aoi_sgcnXpu$PERCENTAGE) * 0.1),4) # used 0.1 because the percentate ranges from 0-100 so this converts to 10acres
  # dissolve table based on elcode and season, keeping all High records  and then med/low with highest summed area within group
  # pick the highest area out of medium and low probabilities
  aoi_sgcnXpu_MedLow <- aoi_sgcnXpu[aoi_sgcnXpu$OccProb!="Confirmed",]
  aoi_sgcnXpu_MedLow <- aggregate(aoi_sgcnXpu_MedLow$AREA~ELSeason+OccProb,aoi_sgcnXpu_MedLow,FUN=sum)
  aoi_sgcnXpu_MedLow <- do.call(rbind,lapply(split(aoi_sgcnXpu_MedLow, aoi_sgcnXpu_MedLow$ELSeason), function(chunk) chunk[which.max(chunk$`aoi_sgcnXpu_MedLow$AREA`),]))
  colnames(aoi_sgcnXpu_MedLow)[colnames(aoi_sgcnXpu_MedLow) == 'aoi_sgcnXpu_MedLow$AREA'] <- 'AREA'
  
  # subset the high values out of the DF
  if ( length(which(aoi_sgcnXpu$OccProb=="Confirmed") > 0 ) ){
    aoi_sgcnXpu_High <- aoi_sgcnXpu[aoi_sgcnXpu$OccProb=="Confirmed",]
    aoi_sgcnXpu_High <- aggregate(aoi_sgcnXpu_High$AREA~ELSeason+OccProb,aoi_sgcnXpu_High,FUN=sum)
    colnames(aoi_sgcnXpu_High)[colnames(aoi_sgcnXpu_High) == 'aoi_sgcnXpu_High$AREA'] <- 'AREA'  
    # merge the two together
    aoi_sgcnXpu_MedLow <- aoi_sgcnXpu_MedLow[!(aoi_sgcnXpu_MedLow$ELSeason %in% aoi_sgcnXpu_High$ELSeason),]
    aoi_sgcnXpu_final <- rbind(aoi_sgcnXpu_High,aoi_sgcnXpu_MedLow)
    aoi_sgcnXpu_final <- aoi_sgcnXpu_final[ order( aoi_sgcnXpu_final$OccProb, -aoi_sgcnXpu_final$AREA ), ]
  } else {
    aoi_sgcnXpu_final <- aoi_sgcnXpu_MedLow
  }
  
  # join SGCN name data sgcn_aoi table
  elcodes <- aoi_sgcnXpu_final$ELSeason
  SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, SeasonCode, SENSITV_SP, Environment, TaxaGroup, TaxaDisplay, ELSeason, Agency, CAT1_glbl_reg, CAT2_com_sp_com, CAT3_cons_rare_native, CAT4_datagaps, WebAddress "," FROM lu_SGCN ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
  aoi_sgcn <- dbGetQuery(db, statement=SQLquery_lookupSGCN)
  # before the merge, set the priority for the SGCN based on the highest value in a number of categories
  aoi_sgcn[, "CAT_min"] <- apply(aoi_sgcn[, 10:13], 1, min) # get the minumum across categories
  aoi_sgcn$PriorityWAP <- 1 / as.numeric(aoi_sgcn$CAT_min) # take the inverse
  aoi_sgcnXpu_final <- merge(aoi_sgcnXpu_final, aoi_sgcn) # merge species information to the planning units
  # add a weight based on the Occurence probability
  aoi_sgcnXpu_final$OccWeight[aoi_sgcnXpu_final$OccProb=="Low"] <- 0.6
  aoi_sgcnXpu_final$OccWeight[aoi_sgcnXpu_final$OccProb=="Probable"] <- 0.8
  aoi_sgcnXpu_final$OccWeight[aoi_sgcnXpu_final$OccProb=="Confirmed"] <- 1
  # drop all the low occurence probability values from the table
  aoi_sgcnXpu_LowOccProb <- aoi_sgcnXpu_final[ which(aoi_sgcnXpu_final$OccProb=="Low"), ]
  aoi_sgcnXpu_LowOccProbELSeason <- aoi_sgcnXpu_LowOccProb[c("ELSeason")] # for use later in the script to remove from Survey and Research needs table.
  aoi_sgcnXpu_LowOccProb <- aoi_sgcnXpu_LowOccProb[c("SCOMNAME","SNAME")]
  ## get a list of Low Occ Prob species to put into a text section in the report
  if(is.data.frame(aoi_sgcnXpu_LowOccProb) && nrow(aoi_sgcnXpu_LowOccProb)!=0){
    aoi_sgcnXpu_LowOccProb$name <-paste(aoi_sgcnXpu_LowOccProb$SCOMNAME," (\\textit{",aoi_sgcnXpu_LowOccProb$SNAME,"})",sep="")
    aoi_sgcnXpu_LowOccProb <- paste(aoi_sgcnXpu_LowOccProb$name, collapse = ", ")  # we should develop something to add an ' , and' to the last entry 
  } 
  aoi_sgcnXpu_final <- aoi_sgcnXpu_final[ which(aoi_sgcnXpu_final$OccProb!="Low"), ]
  # replace the breeding codes with full names
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="b"] <- "Breeding"
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="m"] <- "Migration"
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="w"] <- "Wintering"
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="y"] <- "Year-round"
  # move sensitive species to their own taxagroup
  aoi_sgcnXpu_final$TaxaGroup[aoi_sgcnXpu_final$SENSITV_SP=="Y"] <- "SenSp"
  aoi_sgcnXpu_final$TaxaDisplay <- as.character(aoi_sgcnXpu_final$TaxaDisplay)
  aoi_sgcnXpu_final$TaxaDisplay[aoi_sgcnXpu_final$SENSITV_SP=="Y"] <- "Sensitive Species"
  
  ## Join the specific habitat requirements to the SGCN table
  SQLquery_SpecificHab <- paste("SELECT ELSEASON,SNAME,SCOMNAME,SpecificHabitatRequirements"," FROM lu_SpecificHabitatReq ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")") # 
  aoi_SpecificHab <- dbGetQuery(db, statement=SQLquery_SpecificHab)
  aoi_SpecificHab <- aoi_SpecificHab[c("ELSEASON","SpecificHabitatRequirements")]
  aoi_sgcnXpu_final <- merge(aoi_sgcnXpu_final, aoi_SpecificHab, by.x="ELSeason", by.y="ELSEASON")  # merge 
  
  # resort to the SWAP order
  SWAPorder <- as.matrix(SGCN_SortOrder) # loads from the 0_PathsAndSettings.r file
  TaxaGrpInAOI <- unique(aoi_sgcnXpu_final$TaxaDisplay)
  SWAPorder1 <- SWAPorder[(SWAPorder %in% TaxaGrpInAOI),]
  aoi_sgcnXpu_final$TaxaDisplay <- reorder.factor(aoi_sgcnXpu_final$TaxaDisplay,new.order=SWAPorder1)
  aoi_sgcnXpu_final <- aoi_sgcnXpu_final %>% arrange(TaxaDisplay)

  # deal with sensitive species
  aoi_sgcnXpu_final$SCOMNAME<-ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"SENSITIVE SPECIES",aoi_sgcnXpu_final$SCOMNAME)
  aoi_sgcnXpu_final$SNAME<-ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"",aoi_sgcnXpu_final$SNAME)
  aoi_sgcnXpu_final$SeasonCode <-ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"",aoi_sgcnXpu_final$SeasonCode )
  aoi_sgcnXpu_final$CAT1_glbl_reg <- ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"",aoi_sgcnXpu_final$CAT1_glbl_reg)
  aoi_sgcnXpu_final$CAT2_com_sp_com <- ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"",aoi_sgcnXpu_final$CAT2_com_sp_com)
  aoi_sgcnXpu_final$CAT3_cons_rare_native <- ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"",aoi_sgcnXpu_final$CAT3_cons_rare_native)
  aoi_sgcnXpu_final$CAT4_datagaps <- ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"",aoi_sgcnXpu_final$CAT4_datagaps)
  aoi_sgcnXpu_final$SpecificHabitatRequirements <- ifelse(aoi_sgcnXpu_final$SENSITV_SP=="Y" & (aoi_sgcnXpu_final$Agency!=AgDis|is.na(AgDis)),"Specific Habitat Requirements not listed due to species sensitivity",aoi_sgcnXpu_final$SpecificHabitatRequirements)
  
  # subset to needed columns
  aoi_sgcn_results <- aoi_sgcnXpu_final[c("SCOMNAME","SNAME","OccWeight","PriorityWAP","SpecificHabitatRequirements", "CAT1_glbl_reg", "CAT2_com_sp_com", "CAT3_cons_rare_native", "CAT4_datagaps")]

  ############# Habitats  ##################################
  print("Looking up Habitats with the AOI") # report out to ArcGIS
  SQLquery_HabTerr <- paste("SELECT unique_id, Code, PERCENTAGE"," FROM lu_HabTerr ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)),collapse = ", "), ")")
  aoi_HabTerr <- dbGetQuery(db, statement = SQLquery_HabTerr)
  aoi_HabTerr$acres <- as.numeric(aoi_HabTerr$PERCENTAGE) * 10 #calculate acres of each habitat; "10" is the number of acres in a planning unit
  aoi_HabTerr$PERCENTAGE <- NULL
  aoi_HabTerr <- aoi_HabTerr[c(-1)] # drop the puid column    
  aoi_HabTerr <- aggregate(aoi_HabTerr$acres, by=list(aoi_HabTerr$Code) , FUN=sum)
  colnames(aoi_HabTerr)[colnames(aoi_HabTerr) == 'Group.1'] <- 'Code'
  colnames(aoi_HabTerr)[colnames(aoi_HabTerr) == 'x'] <- 'acres'
  aoi_HabTerr <- aoi_HabTerr[order(-aoi_HabTerr$acres),]
  ## updated habitat information
  HabCodeList <- aoi_HabTerr$Code # 1 get the habitats
  SQLquery_NamesHabTerr <- paste("SELECT Code, Habitat, Class, Macrogroup, PATTERN, FORMATION, type "," FROM lu_HabitatName ","WHERE Code IN (", paste(toString(sQuote(HabCodeList)),collapse = ", "), ")")
  aoi_NamesHabTerr <- dbGetQuery(db, statement = SQLquery_NamesHabTerr)
  aoi_HabTerr <- merge(aoi_HabTerr, aoi_NamesHabTerr, by="Code")
  HabNameList <- aoi_HabTerr$Habitat # 1 get the habitats
  SQLquery_NamesHabTerr <- paste("SELECT Habitat, Class, Macrogroup, PATTERN, FORMATION, type "," FROM lu_HabitatName ","WHERE Habitat IN (", paste(toString(sQuote(HabNameList)),collapse = ", "), ")")# need to change these names
  aoi_NamesHabTerr <- dbGetQuery(db, statement = SQLquery_NamesHabTerr)
  aoi_NamesHabTerr <- unique(aoi_NamesHabTerr)
  aoi_HabTerr <- aggregate(aoi_HabTerr$acres, by=list(aoi_HabTerr$Habitat) , FUN=sum)
  colnames(aoi_HabTerr)[colnames(aoi_HabTerr) == 'Group.1'] <- 'Habitat'
  colnames(aoi_HabTerr)[colnames(aoi_HabTerr) == 'x'] <- 'acres'
  aoi_HabTerr <- merge(aoi_HabTerr, aoi_NamesHabTerr, by="Habitat", all.x=FALSE)
  aoi_HabTerr <- aoi_HabTerr[order(aoi_HabTerr$Macrogroup, -aoi_HabTerr$acres),]
  aoi_HabTerr$Macrogroup <- gsub('&', 'and', aoi_HabTerr$Macrogroup)
  # aquatics 
  SQLquery_HabLotic <- paste("SELECT unique_id, Shape_Length, SUM_23, DESC_23", # need to change these names
                             " FROM lu_LoticData ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_HabLotic <- dbGetQuery(db, statement = SQLquery_HabLotic)
  if( nrow(aoi_HabLotic) > 0 ) {
    aoi_HabLotic <- aoi_HabLotic[c(-1)] # drop the puid column
    aoi_HabLotic <- aggregate(as.numeric(aoi_HabLotic$Shape_Length), by=list(aoi_HabLotic$DESC_23), FUN=sum)
    colnames(aoi_HabLotic)[colnames(aoi_HabLotic) == 'Group.1'] <- 'habitat'
    colnames(aoi_HabLotic)[colnames(aoi_HabLotic) == 'x'] <- 'length'
    aoi_HabLotic$length_km <- aoi_HabLotic$length / 1000        # convert to kilometers
    aoi_HabLotic$length_mi <- aoi_HabLotic$length * 0.000621371 # convert to miles
  }
  # special habitats such as seasonal pools and caves
  SQLquery_HabSpecial <- paste("SELECT unique_id, SpecialHabitat"," FROM lu_SpecialHabitats ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)),collapse = ", "), ")")
  aoi_HabSpecial <- dbGetQuery(db, statement = SQLquery_HabSpecial)
  report_SeasonPool <- NA # initialize so it exists
  report_Cave <- NA # initialize so it exists
  if (AgDis!="public") { # Sensitivity Filter
    if(is.data.frame(aoi_HabSpecial) && nrow(aoi_HabSpecial)!=0){
      if(any(aoi_HabSpecial$SpecialHabitat=="Seasonal Pool")){
        report_SeasonPool <- "One or more seasonal pools are located within this area of interest."
      } 
      if(any(aoi_HabSpecial$SpecialHabitat=="Cave")){
        report_Cave <- "One or more caves are located within this area of interest."
      }
    }
  } # pass this to the knitr for inclusion in the report.

  ############## PROTECTED LAND ###############
  print("Looking up Protected Land with the AOI") # report out to ArcGIS  
  SQLquery_luProtectedLand <- paste("SELECT unique_id, site_nm, manager, owner_typ", " FROM lu_ProtectedLands_25 ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_ProtectedLand <- dbGetQuery(db, statement = SQLquery_luProtectedLand )
  #aoi_ProtectedLand <- unique(aoi_ProtectedLand$site_nm)  
  #aoi_ProtectedLand <- paste(aoi_ProtectedLand, collapse = ", ")

  ############## THREATS ###############
  print("Looking up Threats with the AOI") # report out to ArcGIS
  SQLquery_luThreats <- paste("SELECT unique_id, WindTurbines, WindCapability, ShaleGas,ShaleGasWell,StrImpAg,StrImpAMD"," FROM lu_threats ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_Threats <- dbGetQuery(db, statement = SQLquery_luThreats )
  
  ############## Actions  ##################################
  print("Looking up Conservation Actions with the AOI") # report out to ArcGIS
  SQLquery_actions <- paste("SELECT ELSeason, SCOMNAME, SNAME, IUCNThreatLv1, ThreatCategory, EditedThreat, ActionLv1, ActionCategory1,ActionLV2, ActionCategory2,COATool_ActionsFINAL, ActionPriority, AgencySpecific, ConstraintWind, ConstraintShale"," FROM lu_actionsLevel2 ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
  aoi_actions <- dbGetQuery(db, statement=SQLquery_actions)
  # create a table version of the actions.
  aoi_actions <- merge(aoi_actions,aoi_sgcnXpu_final[,c("ELSeason","PriorityWAP","OccWeight","SENSITV_SP")],by="ELSeason")
  aoi_actionstable <- aoi_actions[,c("SNAME","SCOMNAME","ELSeason","EditedThreat","SENSITV_SP","ActionLv1","ActionCategory1","ActionLV2", "ActionCategory2","COATool_ActionsFINAL", "ActionPriority","PriorityWAP","OccWeight","AgencySpecific","ConstraintWind","ConstraintShale" )]

  # remove actions that are agency specific
  if (AgDis=="PFBC") { 
    aoi_actionstable <- aoi_actionstable[aoi_actionstable$AgencySpecific!="PGC", ] 
  } else if (AgDis=="PGC") { 
    aoi_actionstable <- aoi_actionstable[aoi_actionstable$AgencySpecific!="PFBC", ] 
  } else {
    aoi_actionstable <- aoi_actionstable[aoi_actionstable$AgencySpecific!="PFBC"||aoi_actionstable$AgencySpecific!="PGC", ] # is.na(aoi_actionstable$AgencySpecific)
  }
  
  #remove actions that are only appropiate for wind issues when the AOI is not within the wind region.
  aoi_actionstable$ConstraintWind[aoi_actionstable$ConstraintWind==""] <- NA   # set blanks to NA
  aoi_actionstable$ConstraintShale[aoi_actionstable$ConstraintShale==""] <- NA # set blanks to NA
  if(max(aoi_Threats$WindCapability)>2 | any(aoi_Threats$WindTurbines =='y') ) { # selected class 3 and above
    aoi_actionstable <- aoi_actionstable
  } else {
    aoi_actionstable <- aoi_actionstable[ is.na(aoi_actionstable$ConstraintWind) , ]
  }
  #remove actions that are only appropiate for shale issues when the AOI is not within the shale region.
  if( any(aoi_Threats$ShaleGas=='y') | any(aoi_Threats$ShaleGasWell=='y') ) { 
    aoi_actionstable <- aoi_actionstable
  } else {
    aoi_actionstable <- aoi_actionstable[ is.na(aoi_actionstable$ConstraintShale) , ]
  }  
  
  #aoi_actionstable$OccProb <- as.numeric(aoi_actionstable$OccProb)
  aoi_actionstable$ActionPriority[aoi_actionstable$ActionPriority==2] <- 0.8
  aoi_actionstable$ActionPriority[aoi_actionstable$ActionPriority==3] <- 0.6
  aoi_actionstable$ActionPriority[aoi_actionstable$ActionPriority=="NA"] <- 0
  aoi_actionstable$ActionPriority <- as.numeric(aoi_actionstable$ActionPriority)
  aoi_actionstable$FinalPriority <- aoi_actionstable$OccWeight * aoi_actionstable$ActionPriority * aoi_actionstable$PriorityWAP
  
  # delete 'No conservation actions recommended' from table
  aoi_actionstable <- aoi_actionstable[aoi_actionstable$COATool_ActionsFINAL!="No conservation actions recommended.",]

  #Aggregate the Actions
  aoi_actionstable_Agg <- aggregate(aoi_actionstable$FinalPriority, by=list(aoi_actionstable$ActionCategory2),FUN=sum)
  aoi_actionstable_Agg <- aoi_actionstable_Agg[order(-aoi_actionstable_Agg$x),]
  # create a quantile scaled value of the AIS in order to assign "High","Medium", and "Low" priorities to the action group
  aoi_actionstable_Agg$quant <- with(aoi_actionstable_Agg, .bincode(x, breaks=qu <- quantile(x, probs=seq(0,1,1/3),na.rm=TRUE),(labels=(as.numeric(gsub("%.*","",names(qu))))/100)[-1], include.lowest=TRUE))
  aoi_actionstable_Agg$quant1[aoi_actionstable_Agg$quant %in% 3] <- "High"
  aoi_actionstable_Agg$quant1[aoi_actionstable_Agg$quant %in% 2] <- "Medium"
  aoi_actionstable_Agg$quant1[aoi_actionstable_Agg$quant %in% 1] <- "Low"
 
  # sort the individual actions by the priority in summerized categories
  TargetOrder <- aoi_actionstable_Agg$Group.1
  actionstable_working <- aoi_actionstable
  actionstable_working$ActionCategory2 <- reorder.factor(actionstable_working$ActionCategory2,new.order=TargetOrder)
  actionstable_working$ActionCategory2 <- as.character(actionstable_working$ActionCategory2)
  actionstable_working <- actionstable_working %>% arrange(ActionCategory2)
  actionstable_working <- actionstable_working[c("COATool_ActionsFINAL","SCOMNAME","ActionCategory2")]
  actionstable_working <- unique(actionstable_working)
  actionstable_working <- aggregate(SCOMNAME ~., actionstable_working, toString) 
  actionstable_working$AIS <- aoi_actionstable_Agg[,4][match(actionstable_working$ActionCategory2, aoi_actionstable_Agg[,1])]  # add in AIS
  
  # resort to the High, Medium, Low order
  HMLorder <- as.matrix(c("High","Medium","Low")) 
  actionstable_working$AIS <- reorder.factor(actionstable_working$AIS,new.order=HMLorder)
  actionstable_working <- actionstable_working %>% arrange(AIS)
  
  actionCatOrder <- as.matrix(unique(actionstable_working$ActionCategory2)) # for use down a few lines
  # get the count of cats
  library(plyr)
  agg <- count(actionstable_working, c('ActionCategory2','AIS'))
  colnames(agg) <- c("ActionCategory2","AIS", "Count")
  agg$ActionCategory2 <- reorder.factor(agg$ActionCategory2,new.order=actionCatOrder)
  agg <- agg %>% arrange(ActionCategory2)
  
  ################ RESEARCH & SURVEY NEEDS ##################################
  # Research Needs Query and Table Generation
  print("Looking up Research Needs with the AOI") # report out to ArcGIS
  SQLquery_luResearch <-  paste("SELECT ELSeason, ResearchQues_Edited, AgencySpecific "," FROM lu_SGCNresearch ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
  aoi_Research <- dbGetQuery(db, statement = SQLquery_luResearch )  
  aoi_Research <- merge(aoi_sgcn[c("ELSeason","SNAME","SCOMNAME","SENSITV_SP","Agency")],aoi_Research,by="ELSeason") # merge taxonomic and survey information from the SGCN table to here
  aoi_Research$SCOMNAME <- ifelse(aoi_Research$SENSITV_SP=="Y" & (aoi_Research$Agency!=AgDis|is.na(AgDis)),"SENSITIVE SPECIES",aoi_Research$SCOMNAME)
  aoi_Research$SNAME <- ifelse(aoi_Research$SENSITV_SP=="Y" & (aoi_Research$Agency!=AgDis|is.na(AgDis)),"",aoi_Research$SNAME)
  aoi_Research$ResearchQues_Edited <- ifelse(aoi_Research$SENSITV_SP=="Y" & (aoi_Research$Agency!=AgDis|is.na(AgDis)),"Research Needs not listed for species sensitivity reasons",aoi_Research$ResearchQues_Edited)
  # aggregate functions
  aoi_Research_Agg <- setNames(aggregate(aoi_Research$ResearchQues_Edited, list(aoi_Research$ELSeason), paste, collapse="\\item "), c("ELSeason", "ResearchQues_Edited"))
  aoi_Research_Agg <- merge(aoi_Research_Agg, unique(aoi_Research[c("ELSeason","SNAME","SCOMNAME","SENSITV_SP","Agency","AgencySpecific")]),by="ELSeason", all = TRUE)
  # Survey Needs Query and Table Generation
  print("Looking up Survey Needs with the AOI") # report out to ArcGIS
  SQLquery_luSurvey <-  paste("SELECT ELSeason, NumSurveyQuestion_Edited, AgencySpecific "," FROM lu_SGCNsurvey ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
  aoi_Survey <- dbGetQuery(db, statement = SQLquery_luSurvey ) 
  aoi_Survey <- aoi_Survey[aoi_Survey$NumSurveyQuestion_Edited!="No survey needs at this time.", ]
  # merge taxonomic and survey information from the SGCN table to here
  aoi_Survey <- merge(aoi_sgcn[c("ELSeason","SNAME","SCOMNAME","SENSITV_SP","Agency")],aoi_Survey,by="ELSeason")
  aoi_Survey$SCOMNAME <- ifelse(aoi_Survey$SENSITV_SP=="Y" & (aoi_Survey$Agency!=AgDis|is.na(AgDis)),"SENSITIVE SPECIES",aoi_Survey$SCOMNAME)
  aoi_Survey$SNAME <- ifelse(aoi_Survey$SENSITV_SP=="Y" & (aoi_Survey$Agency!=AgDis|is.na(AgDis)),"",aoi_Survey$SNAME)
  aoi_Survey$NumSurveyQuestion_Edited <- ifelse(aoi_Survey$SENSITV_SP=="Y" & (aoi_Survey$Agency!=AgDis|is.na(AgDis)),"Survey Needs not listed for species sensitivity reasons",aoi_Survey$NumSurveyQuestion_Edited) 
  # aggregate functions
  aoi_Survey_Agg <- setNames(aggregate(aoi_Survey$NumSurveyQuestion, list(aoi_Survey$ELSeason), paste, collapse="\\item "), c("ELSeason", "NumSurveyQuestion"))
  # merge the two tables together for the report
  aoi_ResearchSurvey <- merge(aoi_Research_Agg,aoi_Survey_Agg,by="ELSeason",all=TRUE)
  aoi_ResearchSurvey <- aoi_ResearchSurvey[!( aoi_ResearchSurvey$ELSeason %in% aoi_sgcnXpu_LowOccProbELSeason$ELSeason), ]  # deletes ones with a low occurrence probability
  aoi_ResearchSurvey<-aoi_ResearchSurvey[aoi_ResearchSurvey$SCOMNAME!="SENSITIVE SPECIES",] # remove species that are sensitive from the table, based on the PGC/PFC login
  
  ############## Agency Districts ###############
  print("Looking up Agency Regions with the AOI") # report out to ArcGIS
  SQLquery_luAgency <- paste("SELECT unique_id, pgc_DistNum, pgc_RegionID, pgc_Region, pgc_District, pfbc_Name, pfbc_Region, pfbc_District, dcnr_DistrictNum, dcnr_DistrictName "," FROM lu_AgencyDistricts ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_Agency <- dbGetQuery(db, statement = SQLquery_luAgency )
  aoi_Agency$unique_id <- NULL
  aoi_Agency <- unique(aoi_Agency)
  #####################################################################################################################
  ##############  report generation  #######################
  print("Generating the PDF report...") # report out to ArcGIS
  setwd(working_directory)
  daytime <-gsub("[^0-9]", "", Sys.time() )    # makes a report time variable
  username <- gsub("@.*","",recipients)        # strips out the username from the user's email address
  knit2pdf(paste(working_directory,"results_knitr.rnw",sep="/"), output=paste("results_",username,"_",daytime, ".tex",sep=""))   #write the pdf
  #delete excess files from the pdf creation
  fn_ext <- c(".tex",".log",".aux",".out")
  for(i in 1:NROW(fn_ext)){
    fn <- paste("results_",username,"_",daytime, fn_ext[i],sep="")
    if (file.exists(fn)){ 
      file.remove(fn)
    }
  }

  # create and open the pdf
  pdf.path <- paste(working_directory, paste("results_",username,"_",daytime, ".pdf",sep=""), sep="/")
  # system(paste0('open "', pdf.path, '"'))   ## turn off when emailing results.

  # email the pdf to the user
  # https://myaccount.google.com/lesssecureapps?rfn=27&rfnc=1&eid=-7064655018791181504&et=1&asae=2&pli=1 ### need to turn this on.
  sender <- "Christopher Tracey <pacoatest@gmail.com>" # Replace with a valid address
  emailbody <- "email_body.html"
  isValidEmail <- function(x) {grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(x), ignore.case=TRUE)} # move to earlier in the script ??
  if (isValidEmail(recipients)==TRUE){ 
          email <- send.mail(from=sender,
          to=recipients,
          replyTo = c("Christopher Tracey <pacoatest@gmail.com>"),
          subject= paste("COA Tool Results - ",project_name,sep="")  ,
          html=TRUE,
          inline = TRUE,
          body=emailbody, 
          smtp=list(host.name="smtp.gmail.com", port=465, user.name="pacoatest@gmail.com",passwd="U8ABTLet", ssl=TRUE),
          authenticate=TRUE,
          attach.files=pdf.path,
          send=TRUE)  # change from F to T to get the email to send
  }
  print("Email sent")

  ############# Add statistical information the database ##############################
  PlanningUnits <- paste(as.character(selected_pu$unique_id), collapse="|")
  PlanningUnits <- paste("'",PlanningUnits,"'", sep="")
  SQLquery <- paste("INSERT INTO results_testing VALUES (", 
                    paste("'",project_name,"'", sep="")
                    , ",",PlanningUnits,",",paste("'results_",username,"_",daytime, ".pdf'",sep=""),
                      ");", sep = "")
  dbExecute(db, SQLquery)
  ##################################################################################### 
  dbDisconnect(db) # disconnect the SQL database
}# close out tool

