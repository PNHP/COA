#-------------------------------------------------------------------------------
# Name:        COA_Tabulate_Habitat_Processesing
# Purpose:     Tabulates proportion of habitat area within each planning polygon
#              unit. Calculated using a polygon representation of the raster
#              habitat surface.
# Author:      Molly Moore
# Created:     2016-07-18
# Updated:     2016-07-25
#
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

# import system modules
import arcpy, os, datetime
from arcpy import env
from arcpy.sa import *

# Set tools to overwrite existing outputs
arcpy.env.overwriteOutput = True

def tabulateHabitat(inFC, zoneField, habitatFC, classField, habitatTable):

    # tabulate area through polygon intersection
    zoneTable = os.path.join("in_memory", "zoneTable")
    arcpy.TabulateIntersection_analysis(inFC, zoneField, habitatFC, zoneTable,
    classField)

    # create pivot table from polygon intersection
    arcpy.PivotTable_management(zoneTable, zoneField, classField, "PERCENTAGE",
    habitatTable)

    # delete null values
    with arcpy.da.UpdateCursor(habitatTable, zoneField) as cursor:
        for row in cursor:
            if row[0] == None:
                cursor.deleteRow()

    # generate list containing all fields that are stored as double to prepare
    # for proportion calculations
    class_list = []
    fields = arcpy.ListFields(habitatTable, field_type = "Double")
    for field in fields:
        class_list.append(field.name)

    # create proportions from habitat area by dividing habitat percentage by 100
    with arcpy.da.UpdateCursor(habitatTable, class_list) as cursor:
        for row in cursor:
            for n in range(0, len(class_list)):
                row[n] = round(row[n] / 100, 3) # dividing percentage by 100 to get proportion
                cursor.updateRow(row)

##inFC = r'Database Connections\COA.Default.pgh-gis.sde\COA.DBO.PlanningUnits\COA.DBO.PlanningUnit_Hex10acre'
##zoneField = "unique_id"
##habitatFC = r'W:\Heritage\Heritage_Projects\1332_PGC_COA\COA_DataToServer.gdb\Habitat_Terrestrial'
##classField = "HABITAT"
##habitatTable = r'W:\Heritage\Heritage_Projects\1332_PGC_COA\COA_DataToServer.gdb\Terrestrial_Habitat'

inFC = arcpy.GetParameterAsText(0)
zoneField = arcpy.GetParameterAsText(1)
habitatFC = arcpy.GetParameterAsText(2)
classField = arcpy.GetParameterAsText(3)
habitatTable = arcpy.GetParameterAsText(4)

tabulateHabitat(inFC, zoneField, habitatFC, classField, habitatTable)