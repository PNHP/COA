# Purpose: to define a set of consistently used objects for a full COA Tool Run
#   run. The goal is to avoid redundancy and improve consistency among scripts.

# Set input paths ----
databasename <- "E:/coa2/coa_bridgetest.sqlite" 
working_directory <- "E:/coa2/COA/COA_WebToolDemo"
graphics_path <- "E:/coa2/COA/COA_WebToolDemo/images/"

# set options   
options(useFancyQuotes = FALSE)

# variables and such
SGCN_SortOrder <- c("AB","AM","AAAB","AAAA","ARAC","ARAD","ARAA","AF","IMBIV","inv_amp","inv_bees","IIHYM","inv_beetgr","inv_beetot","IICOL","inv_buttsk","IITRI","inv_cranfl","ICMAL","IIODO","inv_flatwm","IIORT","inv_isopod","IIEPH","inv_mothcw","inv_mothdg","inv_mother","IILEQ","IILEU","inv_mothsi","inv_mothnc","inv_mothnt","inv_mothot","inv_mothpa","inv_mothsa","IILEX0B","inv_mothte","inv_mothtg","IILEY89","IILEY7P","inv_sawfly","inv_snailf","inv_snailt","ILARA","IZSPN","IICLL,IIPLE","inv_trubug","SenSp") 

# Latex Formating Variables  ##  not sure if this is needed anymore.
col <- "\\rowcolor[gray]{.7}" # for table row groups  https://en.wikibooks.org/wiki/LaTeX/Colors