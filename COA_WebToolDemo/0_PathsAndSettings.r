# Purpose: to define a set of consistently used objects for a full COA Tool Run
#   run. The goal is to avoid redundancy and improve consistency among scripts.

# Set input paths ----
databasename <- "E:/coa2/coa_bridgetest.sqlite" 
working_directory <- "E:/coa2/COA/COA_WebToolDemo"
graphics_path <- "E:/coa2/COA/COA_WebToolDemo/images/"

# set options   
options(useFancyQuotes = FALSE)

# variables and such
SGCN_SortOrder <- c("Bird","Mammal","Amphibian","Snake","Turtle","Lizard","Frog","Salamander","Fish","Invertebrate - Mussels","Invertebrate - Butterflies","Invertebrate - Moths","Invertebrate - Dragonflies and Damselflies","Invertebrate - Bees","Invertebrate - Cave Invertebrates","Invertebrate - Freshwater Snails","Invertebrate - Terrestrial Snails","Invertebrate - Crayfishes","Invertebrate - Spiders","Invertebrate - Beetles","Invertebrate - True bugs","Invertebrate - Grasshoppers","Invertebrate - Caddisflies","Invertebrate - Craneflies","Invertebrate - Sawflies","Invertebrate - Sponges","Invertebrate - Stoneflies","Invertebrate - Mayflies","Sensitive Species") 

# Latex Formating Variables  ##  not sure if this is needed anymore.
col <- "\\rowcolor[gray]{.7}" # for table row groups  https://en.wikibooks.org/wiki/LaTeX/Colors