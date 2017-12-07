#-------------------------------------------------------------------------------
# Name:        Habitat Association Joins
# Purpose:     Joins SGCN habitat association .csv to habitat raster layer and
#              outputs SGCN habitat association raster for each SGCN .csv.
#              Only include SGCN .csv files in the working directory, otherwise
#              script will break.
#
# Author:      MMoore
#
# Created:     31/10/2017
# Copyright:   (c) MMoore 2017
# Licence:     <your licence>
#-------------------------------------------------------------------------------

#import packages
import os, arcpy, glob, re, datetime

print("process beginning at: "+datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

#set directories and environmental variables
arcpy.env.overwriteOutput = True
arcpy.env.qualifiedFieldNames = False
wd = r'H:\Projects\COA\HabitatAssociations' # folder location of raster and SGCN habitat association .csv files - make sure only SGCN .csv files are in this folder.
gdb = r'H:\Projects\COA\HabitatAssociations\OutputHabAss.gdb' # output GDB where SGCN habitat association rasters will be written
raster = r'H:\Projects\COA\HabitatAssociations\Habitat_TerrLent_HUC08.tif' # habitat raster layer

#create raster layer from input habitat raster to allow join
r = arcpy.MakeRasterLayer_management(raster, "raster")

#create list of SGCN .csv files in directory to be used in loop
files = []
for f in os.listdir(wd):
    if f.endswith(".csv"):
        files.append(f)

#define num for progress reporting
num = 0

#begin loop through list of SGCN .csv files
for f in files:
    #join .csv to raster via code value
    join = arcpy.AddJoin_management(r, "code", os.path.join(wd, f), "code", "KEEP_COMMON")
    #format output name
    out_name = f.split('_',1)[1]
    out_name = f.split('.',1)[0]
    #copy to new raster
    arcpy.CopyRaster_management(join, os.path.join(gdb, "HabAssoc_"+out_name))
    #remove join
    arcpy.RemoveJoin_management(join)
    #progress reporting
    num += 1
    print str(num)+'/'+str(len(files))+' rasters complete at '+ datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

print("process complete at: "+datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))