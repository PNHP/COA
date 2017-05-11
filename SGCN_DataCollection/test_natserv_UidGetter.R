#---------------------------------------------------------------------------------------------
# Name: test_natserv_Uid_getter.R
# Purpose: 
# Author: Christopher Tracey
# Created: 2016-09-20
# Updated: 2016-09-21
#
# Updates:
# insert date and info
# * 2016-08-17 - got the code to remove NULL values from the keys to work; 
#                added the complete list of SGCN to load from a text file;
#                figured out how to remove records where no occurences we found;
#                make a shapefile of the results  
#
# To Do List/Future Ideas:
# * 
#-------
library('dplyr')
library('devtools')
devtools::install_github("ropenscilabs/natserv")
library('natserv')

# http://stackoverflow.com/questions/29402528/append-data-frames-together-in-a-for-loop
# http://mazamascience.com/WorkingWithData/?p=912
# http://stackoverflow.com/questions/3402371/combine-two-data-frames-by-rows-rbind-when-they-have-different-sets-of-columns

#reads in the list of SGCN
splist <- readLines("data_SGCNlist.csv")
#nam <- ns_search("Quercus rubra") # use for testing

# version with error handling
splist <- readLines("data_SGCNlist.csv")
datalist = list() #creates an empty list

for (SGCN in splist){
  #ERROR HANDLING
  possibleError <- tryCatch(
    nam <- ns_search(SGCN),
    error=function(e) e
  )
  if(inherits(possibleError, "error")) next
  #REAL WORK
  nam <- ns_search(SGCN)
  #nam$sgcn <- SGCN
  datalist[[SGCN]] <- nam
  print(SGCN) #just for tracking progress
}  #end for

SGCN_list <- bind_rows(datalist)


