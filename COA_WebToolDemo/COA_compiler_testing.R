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
  if (!requireNamespace("gdata", quietly = TRUE))
    install.packages("gdata")
  require(gdata)
  if (!requireNamespace("dplyr", quietly = TRUE))
    install.packages("dplyr")
  require(dplyr)
  if (!requireNamespace("lettercase", quietly = TRUE))
    install.packages("lettercase")
  require(lettercase)
  
  # options   
  options(useFancyQuotes = FALSE)
  
  # Chris variables
  databasename <- "E:/coa2/coa_bridgetest.sqlite" #Chris' database path
  working_directory <- "E:/coa2/COA/COA_WebToolDemo"
  # Molly variables
  #databasename <- "C:/coa/coa_bridgetest.sqlite" #Molly's database path
  #working_directory <- "C:/coa/script_tool" #folder location of .rnw script and .png files
  
  # Latex Formating Variables
  col <- "\\rowcolor[gray]{.7}" # for table row groups  https://en.wikibooks.org/wiki/LaTeX/Colors
  
  # define parameters to be used in ArcGIS tool
  project_name = in_params[[1]]
  planning_units <- in_params[[2]]
  #AgencyPersonnel <- in_params[[3]] 
  #project_name <- "Manual Test Project"
  #planning_units <- "C:/coa/planning_unit_test.shp"
  #planning_units <- "E:/coa2/test_pu1.shp"
  print(paste("Project Name: ",project_name, sep=""))
  print(date())
  
  # load and report on selected planning units
  pu <- arc.open(planning_units)
  selected_pu <- arc.select(pu)
  area_pu_total <- paste("Project Area: ",nrow(selected_pu)*10," acres ","(",nrow(selected_pu), " planning units selected) ", sep="") # convert square meters to acres

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

  ## do we want to add PGC/PFBC district information to the table here???
  ############## Natural Boundaries
  SQLquery_luNatBound <- paste("SELECT unique_id, HUC12, PROVINCE, SECTION_, ECO_NAME"," FROM lu_NaturalBoundaries ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_NaturalBoundaries <- dbGetQuery(db, statement = SQLquery_luNatBound )
  HUC_list <- unique(aoi_NaturalBoundaries$HUC12)
  # HUC Name lookup
  SQLquery_HUC <- paste("SELECT HUC8, HUC12, HUC8name, HUC12name"," FROM lu_HUCname ","WHERE HUC12 IN (", paste(toString(sQuote(HUC_list)), collapse = ", "), ")")
  aoi_HUC <- dbGetQuery(db, statement = SQLquery_HUC )
  #print("- - - - - - - - - - - - -")
  w = paste("Physiographic Province -- ",unique(paste(aoi_NaturalBoundaries$PROVINCE,aoi_NaturalBoundaries$SECTION,sep=" - ")) , sep= " ")
  #print(w)
  v = paste("Ecoregion -- ",unique(aoi_NaturalBoundaries$ECO_NAME), sep= " ")
  #print(v)
  u1 = paste("HUC8 --",unique(aoi_HUC$HUC8name), sep= " ")
  u2 = paste("HUC12 --",unique(aoi_HUC$HUC12name), sep= " ")

  ############# Habitats  ##################################
  print("Looking up Habitats with the AOI") # report out to ArcGIS
  SQLquery_HabTerr <- paste("SELECT unique_id, Code, PERCENTAGE"," FROM lu_HabTerr ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)),collapse = ", "), ")")
  aoi_HabTerr <- dbGetQuery(db, statement = SQLquery_HabTerr)
  aoi_HabTerr$acres <- as.numeric(aoi_HabTerr$PERCENTAGE) * 10 #calculate acres of each habitat; "10" is the number of acres in a planning unit
  aoi_HabTerr$PERCENTAGE <- NULL
  # reduce by removing unique planning units
  aoi_HabTerr <- aoi_HabTerr[c(-1)] # drop the puid column
  aoi_HabTerr <- aggregate(aoi_HabTerr$acres, by=list(aoi_HabTerr$Code) , FUN=sum)
  colnames(aoi_HabTerr)[colnames(aoi_HabTerr) == 'Group.1'] <- 'Code'
  colnames(aoi_HabTerr)[colnames(aoi_HabTerr) == 'x'] <- 'acres'
  aoi_HabTerr <- aoi_HabTerr[order(-aoi_HabTerr$acres),]
  
  ## updated habitat information
  HabCodeList <- aoi_HabTerr$Code # 1 get the habitats
  SQLquery_NamesHabTerr <- paste("SELECT Code, Habitat, Class, Macrogroup, PATTERN, FORMATION, type ", # need to change these names
                                 " FROM lu_HabitatName ","WHERE Code IN (", paste(toString(sQuote(HabCodeList)),collapse = ", "), ")")
  aoi_NamesHabTerr <- dbGetQuery(db, statement = SQLquery_NamesHabTerr)
  aoi_HabTerr <- merge(aoi_HabTerr, aoi_NamesHabTerr, by="Code")
  #######################################
  HabNameList <- aoi_HabTerr$Habitat # 1 get the habitats
  SQLquery_NamesHabTerr <- paste("SELECT Habitat, Class, Macrogroup, PATTERN, FORMATION, type ", # need to change these names
                                 " FROM lu_HabitatName ","WHERE Habitat IN (", paste(toString(sQuote(HabNameList)),collapse = ", "), ")")
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
    # pass this to the knitr for inclusion in the report.

  ############## PROTECTED LAND ###############
  print("Looking up Protected Land with the AOI") # report out to ArcGIS  
  SQLquery_luProtectedLand <- paste("SELECT unique_id, site_nm, manager, owner_typ", " FROM lu_ProtectedLands_25 ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_ProtectedLand <- dbGetQuery(db, statement = SQLquery_luProtectedLand )

  ############## THREATS ###############
  print("Looking up Threats with the AOI") # report out to ArcGIS
  SQLquery_luThreats <- paste("SELECT unique_id, WindTurbines, WindCapability, ShaleGas,ShaleGasWell,StrImpAg,StrImpAMD"," FROM lu_threats ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_Threats <- dbGetQuery(db, statement = SQLquery_luThreats )
  
  ##############  SGCN  ########################################
  # build query to select planning units within area of interest from SGCNxPU table
  print("Looking up SGCN with the AOI") # report out to ArcGIS
  SQLquery <- paste("SELECT unique_id, El_Season, OccProb, PERCENTAGE"," FROM lu_sgcnXpu_all ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  # create SGCNxPU dataframe containing selected planning units
  aoi_sgcnXpu <- dbGetQuery(db, statement = SQLquery)
  colnames(aoi_sgcnXpu)[colnames(aoi_sgcnXpu) == 'El_Season'] <- 'ELSeason'
  aoi_sgcnXpu$AREA <- round((as.numeric(aoi_sgcnXpu$PERCENTAGE) * 0.1),4) # used 0.1 because the percentate ranges from 0-100 so this works to convert to 10acres
  # dissolve table based on elcode and season, keeping all High records  and then med/low with highest summed area within group
  # pick the highest area out of medium and low probabilities
  aoi_sgcnXpu_MedLow <- aoi_sgcnXpu[aoi_sgcnXpu$OccProb!="High",]
  aoi_sgcnXpu_MedLow <- aggregate(aoi_sgcnXpu_MedLow$AREA~ELSeason+OccProb,aoi_sgcnXpu_MedLow,FUN=sum)
  aoi_sgcnXpu_MedLow <- do.call(rbind,lapply(split(aoi_sgcnXpu_MedLow, aoi_sgcnXpu_MedLow$ELSeason), function(chunk) chunk[which.max(chunk$`aoi_sgcnXpu_MedLow$AREA`),]))
  colnames(aoi_sgcnXpu_MedLow)[colnames(aoi_sgcnXpu_MedLow) == 'aoi_sgcnXpu_MedLow$AREA'] <- 'AREA'
  
  # subset the high values out of the DF
  if ( length(which(aoi_sgcnXpu$OccProb=="High") > 0 ) ){
    aoi_sgcnXpu_High <- aoi_sgcnXpu[aoi_sgcnXpu$OccProb=="High",]
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
  SQLquery_lookupSGCN <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, SeasonCode, SENSITV_SP, Environment, TaxaGroup, ELSeason, CAT1_glbl_reg, CAT2_com_sp_com, CAT3_cons_rare_native, CAT4_datagaps, WebAddress "," FROM lu_SGCN ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
  aoi_sgcn <- dbGetQuery(db, statement=SQLquery_lookupSGCN)
  # deal with sensitive species
  setDT(aoi_sgcn)[SENSITV_SP=="Y", SNAME:=paste0("[[ ",SNAME," ]]")]
  # before the merge, set the priority for the SGCN based on the highest value in a number of categories
  aoi_sgcn[, "CAT_min"] <- apply(aoi_sgcn[, 10:13], 1, min) # get the minumum across categories
  aoi_sgcn$PriorityWAP <- 1 / as.numeric(aoi_sgcn$CAT_min) # take the inverse
  # merge species information to the planning units
  aoi_sgcnXpu_final <- merge(aoi_sgcnXpu_final, aoi_sgcn) #, by="ELSeason"
  # add a weight based on the Occurence probability
  aoi_sgcnXpu_final$OccWeight[aoi_sgcnXpu_final$OccProb=="Low"] <- 0.6
  aoi_sgcnXpu_final$OccWeight[aoi_sgcnXpu_final$OccProb=="Medium"] <- 0.8
  aoi_sgcnXpu_final$OccWeight[aoi_sgcnXpu_final$OccProb=="High"] <- 1
  # drop all the low occurence probability values from the table
  ## get a list of Low Occ Prob species to put into a text section in the report
  aoi_sgcnXpu_LowOccProb <- aoi_sgcnXpu_final[ which(aoi_sgcnXpu_final$OccProb=="Low"), ]
  aoi_sgcnXpu_LowOccProb <- aoi_sgcnXpu_LowOccProb[c("SCOMNAME","SNAME")]
  aoi_sgcnXpu_LowOccProb$name <-paste(aoi_sgcnXpu_LowOccProb$SCOMNAME," (\\textit{",aoi_sgcnXpu_LowOccProb$SNAME,"})",sep="")
  aoi_sgcnXpu_LowOccProb <- paste(aoi_sgcnXpu_LowOccProb$name, collapse = ", ")
  aoi_sgcnXpu_final <- aoi_sgcnXpu_final[ which(aoi_sgcnXpu_final$OccProb!="Low"), ]
  # replace the breeding codes with full names
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="b"] <- "Breeding"
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="m"] <- "Migration"
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="w"] <- "Wintering"
  aoi_sgcnXpu_final$SeasonCode[aoi_sgcnXpu_final$SeasonCode=="y"] <- "Year-round"
  # move sensitive species to their own taxagroup
  aoi_sgcnXpu_final$TaxaGroup[aoi_sgcnXpu_final$SENSITV_SP=="Y"] <- "SenSp"
  aoi_sgcnXpu_final <- aoi_sgcnXpu_final[order(aoi_sgcnXpu_final$TaxaGroup,aoi_sgcnXpu_final$OccProb),]
  # resort to the SWAP order
  SWAPorder <- as.matrix(  c("AB","AM","AAAB","AAAA","ARAC","ARAD","ARAA","AF","IMBIV",
     "inv_amp","inv_bees","IIHYM","inv_beetgr","inv_beetot","IICOL","inv_buttsk","IITRI","inv_cranfl","ICMAL","IIODO","inv_flatwm","IIORT","inv_isopod","IIEPH","inv_mothcw","inv_mothdg","inv_mother","IILEQ","IILEU","inv_mothsi","inv_mothnc","inv_mothnt","inv_mothot","inv_mothpa","inv_mothsa","IILEX0B","inv_mothte","inv_mothtg","IILEY89","IILEY7P","inv_sawfly","inv_snailf","inv_snailt","ILARA","IZSPN","IICLL,IIPLE","inv_trubug","SenSp") )
  TaxaGrpInAOI <- unique(aoi_sgcnXpu_final$TaxaGroup)
  SWAPorder1 <- SWAPorder[(SWAPorder %in% TaxaGrpInAOI),]
  #TargetOrder <- aoi_actionstable_Agg$Group.1
  aoi_sgcnXpu_final <- aoi_sgcnXpu_final
  aoi_sgcnXpu_final$TaxaGroup <- reorder.factor(aoi_sgcnXpu_final$TaxaGroup,new.order=SWAPorder1)
  aoi_sgcnXpu_final <- aoi_sgcnXpu_final %>% arrange(TaxaGroup)
  ## add a line to join the taxagroups
  SQLquery_taxagrp <- paste("SELECT code, taxagroup, taxadisplay"," FROM lu_taxagrp ")
  lu_taxagrp <- dbGetQuery(db, statement=SQLquery_taxagrp)
  # subset to needed columns
  keeps <- c("SCOMNAME","SNAME","OccWeight","PriorityWAP")
  aoi_sgcn_results <- aoi_sgcnXpu_final[keeps]
  
  ############## Actions  ##################################
  print("Looking up Conservation Actions with the AOI") # report out to ArcGIS
  SQLquery_actions <- paste("SELECT ELCODE, CommonName, ScientificName, Sensitive, IUCNThreatLv1, ThreatCategory, EditedThreat, ActionLv1, ActionCategory1,COATool_Action, ActionPriority, ELSeason, AgencySpecific, ConstraintWind, ConstraintShale"," FROM lu_actions ","WHERE ELSeason IN (", paste(toString(sQuote(elcodes)), collapse = ", "), ")")
  aoi_actions <- dbGetQuery(db, statement=SQLquery_actions)
  # create a table version of the actions.
  aoi_actions <- merge(aoi_actions,aoi_sgcnXpu_final,by="ELSeason")
  aoi_actionstable <- aoi_actions[,c("ScientificName","CommonName","ELSeason","EditedThreat","Sensitive","ActionLv1","ActionCategory1","COATool_Action","ActionPriority","PriorityWAP","OccWeight","AgencySpecific","ConstraintWind","ConstraintShale" )]
  
#  # remove actions that are agency specific
#  if (AgencyPersonnel=="PFBC") {
#    aoi_actionstable <- aoi_actionstable[aoi_actionstable$AgencySpecific!="PGC", ]
#  } else if (AgencyPersonnel=="PGC") {  
#    aoi_actionstable <- aoi_actionstable[aoi_actionstable$AgencySpecific!="PFBC", ]
#  } else {
#    aoi_actionstable <- aoi_actionstable[is.na(aoi_actionstable$AgencySpecific), ]
#  }
  
  #remove actions that are only appropiate for wind issues when the AOI is not within the wind region.
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
  ################
    
  #aoi_actionstable$OccProb <- as.numeric(aoi_actionstable$OccProb)
  aoi_actionstable$ActionPriority[aoi_actionstable$ActionPriority==2] <- 0.8
  aoi_actionstable$ActionPriority[aoi_actionstable$ActionPriority==3] <- 0.6
  aoi_actionstable$ActionPriority[aoi_actionstable$ActionPriority=="NA"] <- 0
  aoi_actionstable$ActionPriority <- as.numeric(aoi_actionstable$ActionPriority)
  aoi_actionstable$FinalPriority <- aoi_actionstable$OccWeight * aoi_actionstable$ActionPriority * aoi_actionstable$PriorityWAP
  
  #Aggregate the Actions
  aoi_actionstable_Agg <- aggregate(aoi_actionstable$FinalPriority, by=list(aoi_actionstable$ActionCategory1),FUN=sum)
  aoi_actionstable_Agg <- aoi_actionstable_Agg[order(-aoi_actionstable_Agg$x),]
  # create a quantile scaled value of the AIS in order to assign "High","Medium", and "Low" priorities to the action group
  aoi_actionstable_Agg$quant <- with(aoi_actionstable_Agg, .bincode(x, breaks=qu <- quantile(x, probs=seq(0,1,1/3),na.rm=TRUE),(labels=(as.numeric(gsub("%.*","",names(qu))))/100)[-1], include.lowest=TRUE))
  aoi_actionstable_Agg$quant1[aoi_actionstable_Agg$quant %in% 3] <- "High"
  aoi_actionstable_Agg$quant1[aoi_actionstable_Agg$quant %in% 2] <- "Medium"
  aoi_actionstable_Agg$quant1[aoi_actionstable_Agg$quant %in% 1] <- "Low"
 
  # sort the individual actions by the priority in summerized categories
  TargetOrder <- aoi_actionstable_Agg$Group.1
  actionstable_working <- aoi_actionstable
  actionstable_working$ActionCategory1 <- reorder.factor(actionstable_working$ActionCategory1,new.order=TargetOrder)
  actionstable_working <- actionstable_working %>% arrange(ActionCategory1)
  actionstable_working <- actionstable_working[c("COATool_Action","CommonName","ActionCategory1")]
  actionstable_working <- unique(actionstable_working)
  actionstable_working <- aggregate(CommonName ~., actionstable_working, toString)

  # subset for presentation
  action_results <- actionstable_working[c("COATool_Action","CommonName")]
  action_results$COATool_Action <- sanitize(action_results$COATool_Action, type="latex")
  # this does the above but for every action
  #aoi_actionstable_Agg1 <- aggregate(aoi_actionstable$FinalPriority, by=list(aoi_actionstable$COATool_Action),FUN=sum)
  #write.csv(aoi_actionstable_Agg1, "actions_by_ind.csv")

  ############## Agency Districts ###############
  print("Looking up Agency Regions with the AOI") # report out to ArcGIS
  SQLquery_luAgency <- paste("SELECT unique_id, pgc_DistNum, pgc_RegionID, pgc_Region, pgc_District, pfbc_Name, pfbc_Region, pfbc_District, dcnr_DistrictNum, dcnr_DistrictName "," FROM lu_AgencyDistricts ","WHERE unique_id IN (", paste(toString(sQuote(pu_list)), collapse = ", "), ")")
  aoi_Agency <- dbGetQuery(db, statement = SQLquery_luAgency )
  aoi_Agency$unique_id <- NULL
  aoi_Agency <- unique(aoi_Agency)
  
  ##############  report generation  #######################
  print("Generating the PDF report...") # report out to ArcGIS
  setwd(working_directory)
  
  env <- arc.env()
  
  
  #write the pdf
  knit2pdf(paste(working_directory,"results_knitr.rnw",sep="/"), output=paste("results_",Sys.Date(), ".tex",sep=""))
  #delete excess files from the pdf creation
  fn_ext <- c(".tex",".log",".aux",".out")
  for(i in 1:NROW(fn_ext)){
    fn <- paste("results_",Sys.Date(),fn_ext[i],sep="")
    if (file.exists(fn)){ 
      file.remove(fn)
      # print(paste("Deleted ", fn,"from directory") )
    }
  }
  # disconnect the SQL database
  dbDisconnect(db)
  # create and open the pdf
  pdf.path <- paste(working_directory, paste("results_",Sys.Date(), ".pdf",sep=""), sep="/")
  system(paste0('open "', pdf.path, '"'))
  
  ############# Add statisical information the database ##############################
  
  
  # close out tool
  }

