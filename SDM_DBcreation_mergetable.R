library(plyr)
library(arcgisbinding)
arc.check_product()
# options   
options(useFancyQuotes = FALSE)

myvars <- c("unique_id","ELCODE","SeasonCode","OccProb","PERCENTAGE")

filelist <- c(
 "WoodTurtle","ABDU_b","ABDU_w","AlleghenyWoodrat","AmericanKestrel","AMWO","Baltimore","BankSwallow","BOBO","BogTurtle","BRCR","BrookTrout","BTBW","BTNW","BWWA","CanadaWarbler","CeruleanWarbler","Copperhead","EAME","EasternBoxTurtle","EasternHellbender_NHD","EasternMassasauga","EasternSmallfootedBat","EasternSpottedSkunk","EasternWhippoorwill","FISP","flowline_AlasmidontaMarginata","flowline_AlasmidontaUndulata","flowline_AlasmidontaVaricosa","flowline_LampsilisCariosa","flowline_LampsilisRadiata","flowline_LasmigonaSubviridis","flowline_VillosaIris","GRCA","GreenSalamander","GRSP","GWWA","HESP","KEWA","LOWA","MAWR_b","Mudpuppy_NHD","NAWA","NorthernCopperhead","NorthernFlyingSquirrel","NorthernGoshawk","NorthernWaterShrew","NOWA","PRAW","PUMA","RHWO","RockVole","RoughGreenSnake","RUGR","SalamanderMussel_NHD","SAVS","ScarletTanager","ShortheadGarterSnake","Sora","SwainsonsThrush","VESP","VirginiaRail","WestVirginiaWaterShrew","WestVirginiaWhite","WIFL","WinterWren","WoodThrush","WTSP","YBCH"
)
filelist <- as.list(filelist)

for(i in filelist){
  print(i)
  dfnam <- i
  shppath <- paste("e:/coa2/COA_SGCNxPU_Tables.gdb/",i,sep="")
  print(shppath)
  i <- arc.open(shppath)
  i <- arc.select(i)
  i <- i[myvars]
  assign(dfnam, i)
}

dflist <- list(WoodTurtle,ABDU_b,ABDU_w,AlleghenyWoodrat,AmericanKestrel,AMWO,Baltimore,BankSwallow,BOBO,BogTurtle,BRCR,BrookTrout,BTBW,BTNW,BWWA,CanadaWarbler,CeruleanWarbler,Copperhead,EAME,EasternBoxTurtle,EasternHellbender_NHD,EasternMassasauga,EasternSmallfootedBat,EasternSpottedSkunk,EasternWhippoorwill,FISP,flowline_AlasmidontaMarginata,flowline_AlasmidontaUndulata,flowline_AlasmidontaVaricosa,flowline_LampsilisCariosa,flowline_LampsilisRadiata,flowline_LasmigonaSubviridis,flowline_VillosaIris,GRCA,GreenSalamander,GRSP,GWWA,HESP,KEWA,LOWA,MAWR_b,Mudpuppy_NHD,NAWA,NorthernCopperhead,NorthernFlyingSquirrel,NorthernGoshawk,NorthernWaterShrew,NOWA,PRAW,PUMA,RHWO,RockVole,RoughGreenSnake,RUGR,SalamanderMussel_NHD,SAVS,ScarletTanager,ShortheadGarterSnake,Sora,SwainsonsThrush,VESP,VirginiaRail,WestVirginiaWaterShrew,WestVirginiaWhite,WIFL,WinterWren,WoodThrush,WTSP,YBCH)

library(data.table)
sptable <- rbindlist(dflist)
write.csv(sptable,"SGCN_medlow_Xpu.csv")
