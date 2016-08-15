#-------------------------------------------------------------------------------
# Name:        COA_Tabulate_Habitat_Processesing
# Purpose:     Tabulates proportion of habitat area within each planning polygon
#              unit.
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

def tabulateHabitat(inFC, habitatFC, zoneTableTEMP, habitatTable):
    print "Creating zone table: " + time.strftime("%c")
    # tabulate area through polygon intersection
    arcpy.TabulateIntersection_analysis(inFC, "unique_id", habitatFC,
    zoneTableTEMP, "Habitat") # "Habitat" needs to be changed for aquatic habitat
    print "Zone table complete: " + time.strftime("%c")

    print "Creating pivot table: " + time.strftime("%c")
    # create pivot table from polygon intersection with zone table as input,
    # unique_id as input field, habitat as pivot field, and percentage as value
    # field
    arcpy.PivotTable_management(zoneTableTEMP, "unique_id", "HABITAT", "PERCENTAGE",
    habitatTable) # "HABITAT" needs to be changed for aquatic habitat
    print "Pivot table complete: " + time.strftime("%c")

    # delete null values
    with arcpy.da.UpdateCursor(habitatTable, "unique_id") as cursor:
        for row in cursor:
            if row[0] == None:
                cursor.deleteRow()

    # generate list containing all fields that are stored as double to prepare
    # for proportion calculations
    habitat_list = []
    fields = arcpy.ListFields(habitatTable, field_type = "Double")
    for field in fields:
        habitat_list.append(field.name)

    print "Updating proportions: " + time.strftime("%c")
    # create proportions from habitat area by dividing habitat percentage by 100
    with arcpy.da.UpdateCursor(habitatTable, habitat_list) as cursor:
        for row in cursor:
            for n in range(0, len(habitat_list)):
                row[n] = round(row[n] / 100, 3) # dividing percentage by 100 to get proportion
                cursor.updateRow(row)
    print "tabulateHabitat complete: " + time.strftime("%c")

# set local pathways
inFC = "F:\COA_Tool\COA_Tool.gdb\PlanningPoly\hex10ac" # planning hexagons
habitatFC = "F:\COA_Tool\COA_Tool.gdb\Habitat\TerrestrialHabitat" # habitat layer
zoneTableTEMP = "F:\COA_Tool\COA_Tool.gdb\zoneTable" # output zone table - intermediate/temporary step
habitatTable = "F:\COA_Tool\COA_Tool.gdb\habitatTable" # output habitat table

# run the function
tabulateHabitat(inFC, habitatFC, zoneTableTEMP, habitatTable)

# for use with arctoolbox:
#inFC = arcpy.GetParameterAsText(0)
#habitatFC = arcpy.GetParameterAsText(1)
#zoneTable = arcpy.GetParameterAsText(2)
#habitatTable = arcpy.GetParameterAsText(3)