#load packages
library(raster)
library(rgeos)
library(rgdal)

#establish paths
pu_lyr <- "C:/Users/mmoore/Documents/ArcGIS/Shapefiles/PlanningUnit_Hex10acre" #path to hexagon layer
sdm_folder <- "C:/Users/mmoore/Documents/ArcGIS/SDM_shapefiles" #path to folder where SDM shapefiles are stored

#load planning unit layer
pu <- readOGR(dirname(pu_lyr), layer=basename(pu_lyr))
#create list of all files with .shp extension
sdms <- list.files(path=sdm_folder, pattern = ".shp")
#exclude everything except the file name
sdms <- unique(sapply(strsplit(sdms,"\\."),head,1))
#create empty dataframe where rows will be bound
final <- data.frame()

#begin loop through SDM layers
for(sdm in sdms){
  #load in SDM layer
  sgcn <- readOGR(sdm_folder, layer=sdm)
  #intersect planning unit and sdm layer
  i <- intersect(pu, sgcn)
  #calculate percent area of intersect
  i$percent.area <- abs(area(i))/i$Shape_Area.1*100
  
  # create data frame and delete records with < 15% area overlap
  d <- data.frame(i)
  d <- d[d$percent.area>15,] # THIS SHOULD NOT BE DONE WITH AQUATIC SPECIES
  
  ###############################################################
  ### NEED TO ADD CODE TO DELETE IDENTICAL PLANNING UNIT/SGCN ###
  ### ROWS WITH DIFFERENT OCCPROB BASED ON LARGER PERCENT #######
  ###############################################################
  
  final <- rbind(d, final)
}




