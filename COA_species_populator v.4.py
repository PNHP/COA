#-------------------------------------------------------------------------------
# Name:        COA_species_populator
# Purpose:     Populates planning units with occurrence probability for SGCNs.
#              Current version populates planning unit with occurrence
#              probability that has the largest proportion overlap with planning
#              unit and only populates planning units with greater than 25%
#              coverage by SGCN.
# Author:      Molly Moore
# Created:     2016-08-25
# Updated:     N/A
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

################################################################################
# Define global variables and functions to be used throughout toolbox
################################################################################

def SpatialJoin(target_features, join_features, outTable):
        # Calculate intersection between Target Feature and Join Features
        intersect = "in_memory\\intersect"
        arcpy.analysis.Intersect([target_features, join_features], intersect, "ALL")

        # delete PUs that have less than 10% (4046.86 square meters) of area overlapped by protected lands
        # could change this threshold if needed
        with arcpy.da.UpdateCursor(intersect, "SHAPE@AREA") as cursor:
            for row in cursor:
                if row[0] > 4046.86:
                    pass
                else:
                    cursor.deleteRow()

        arcpy.AddField_management(intersect, "ELCODE_season", "TEXT", "", "", 50)
        expression = """!ELCODE! + "_" + !SeasonCode!"""
        arcpy.CalculateField_management(intersect, "ELCODE_season", expression, "PYTHON_9.3")

        intersect_dissolve = arcpy.Dissolve_management(intersect, "in_memory\\intersect_dissolve", ["unique_id", "ELCODE_season", "OccProb"])

        arcpy.PivotTable_management(intersect_dissolve, "unique_id", "ELCODE_season", "OccProb", outTable)

target_features = arcpy.GetParameterAsText(0) # planning polygon unit
join_features = arcpy.GetParameterAsText(1) # protected lands layer
outTable = arcpy.GetParameterAsText(2)

SpatialJoin(target_features, join_features, outTable)