#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      mmoore
#
# Created:     01/12/2017
# Copyright:   (c) mmoore 2017
# Licence:     <your licence>
#-------------------------------------------------------------------------------

import arcpy, arcinfo
from arcpy import env
from arcpy.sa import *
import os
import datetime

pu_folder = r'C:\Users\mmoore\Documents\ArcGIS\COA.gdb\PlanningUnit_Hex10acreRaster'
sdm_folder = r'C:\Users\mmoore\Documents\ArcGIS\SDMs.gdb'
out_tables = r'W:\Heritage\Heritage_Projects\1332_PGC_COA\SGCNxPU_outTables.gdb'

arcpy.env.overwriteOutput = True
arcpy.env.qualifiedFieldNames = False
arcpy.env.workspace = r'C:\Users\mmoore\Documents\ArcGIS\SDMs.gdb'
sdms = arcpy.ListRasters()

arcpy.CheckOutExtension("Spatial")

tables = []
for sdm in sdms:
    raster = pu_folder
    arcpy.env.extent = raster
    el_season = os.path.basename(sdm)
    join_name = os.path.basename(raster)[0:16]
    join_name = join_name[0:16]
    print el_season + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    arcpy.env.workspace = r'C:\Users\mmoore\Documents\ArcGIS\Default.gdb'
    combine = Combine([os.path.join(sdm_folder, sdm), raster])
    combine = arcpy.MakeRasterLayer_management(combine, "combine")
    arcpy.AddJoin_management(combine, join_name, raster, "Value", "KEEP_COMMON")
    out_table = arcpy.TableToTable_conversion(combine, out_tables, el_season)
    arcpy.AddField_management(out_table, "OccProb", "TEXT", "", "", 6)
    arcpy.AddField_management(out_table, "PERCENTAGE", "FLOAT")
    arcpy.AddField_management(out_table, "El_Season", "TEXT", "", "", 15)
    with arcpy.da.UpdateCursor(out_table, ["Count", "Count_1", el_season, "OccProb", "PERCENTAGE", "El_Season"]) as cursor:
        for row in cursor:
            if row[2] == 1:
                row[3] = "Low"
            elif row[2] == 2:
                row[3] = "Medium"
            row[4] = row[0]/row[1]
            row[5] = el_season
            cursor.updateRow(row)
    tables.append(out_table)

fieldmappings = arcpy.FieldMappings()
for table in tables:
    fieldmappings.addTable(table)

# fields to be kept after spatial join
keepFields = ["OID", "unique_id", "OccProb", "PERCENTAGE", "El_Season"]

# remove all fields not in keep fields from field map
for field in fieldmappings.fields:
    if field.name not in keepFields:
        fieldmappings.removeFieldMap(fieldmappings.findFieldMapIndex
        (field.name))

merge = arcpy.Merge_management(tables, os.path.join(out_tables, "SGCNxPU_SDM", fieldmappings))
