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
from itertools import groupby
from operator import itemgetter

# Set tools to overwrite existing outputs
arcpy.env.overwriteOutput = True


target_features = arcpy.GetParameterAsText(0) # planning polygon unit
join_features = arcpy.GetParameterAsText(1) # protected lands layer
outTable = arcpy.GetParameterAsText(2)
scratch = arcpy.GetParameterAsText(3)

################################################################################
# Define global variables and functions to be used throughout toolbox
################################################################################

# Calculate intersection between Target Feature and Join Features
intersect = os.path.join(scratch, "intersectTEMP")
classFeatures = ["ELCODE", "SeasonCode", "OccProb"]
arcpy.TabulateIntersection_analysis(target_features, "unique_id", join_features, intersect, classFeatures)

# delete PUs that have less than 10% (4046.86 square meters) of area overlapped by protected lands
# could change this threshold if needed
with arcpy.da.UpdateCursor(intersect, "PERCENTAGE") as cursor:
            for row in cursor:
                if row[0] > 10:
                    pass
                else:
                    cursor.deleteRow()

arcpy.AddField_management(intersect, "ELCODE_season", "TEXT", "", "", 50)
expression = """!ELCODE! + "_" + !SeasonCode!"""
arcpy.CalculateField_management(intersect, "ELCODE_season", expression, "PYTHON_9.3")

arcpy.DeleteIdentical_management(intersect, ["unique_id", "ELCODE_season", "OccProb"])

# groupby iterator used to keep records with highest proportion overlap
case_fields = ["unique_id", "ELCODE", "SeasonCode"]
max_field = "PERCENTAGE"

sql_orderby = "ORDER BY {}, {} DESC".format(",".join(case_fields), max_field)

with arcpy.da.UpdateCursor(intersect, "*", sql_clause=(None, sql_orderby)) as cursor:
    case_func = itemgetter(*(cursor.fields.index(fld) for fld in case_fields))
    for key, group in groupby(cursor, case_func):
        next(group)
        for extra in group:
            cursor.deleteRow()

arcpy.PivotTable_management(intersect, "unique_id", "ELCODE_season", "OccProb", outTable)

