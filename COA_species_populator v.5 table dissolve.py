#-------------------------------------------------------------------------------
# Name:        COA_species_populator
# Purpose:     Populates planning units with occurrence probability for SGCNs.
#              Current version populates planning unit with occurrence
#              probability of SGCNs. If more than one of a single SGCN is
#              present, the occurrence probability is filled with the SGCN that
#              has the largest proportion overlap with planning unit and only
#              populates planning units with greater than 10% coverage by SGCN.
# Author:      Molly Moore
# Created:     2016-08-25
# Updated:     2017-05-08
#
# To Do List/Future ideas:
#   - currently handles statewide occurrence dataset well (runs in ~4.5 hours)
#   - currently does not run with statewide SDM derived occurrence dataset (runs in 2.5 hours and produces empty output)
#   - currently runs well with county-wide SDM derived occurrence dataset
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
join_features = arcpy.GetParameterAsText(1) # SGCN occurrence probability layer - should be polygon layer
outTable = arcpy.GetParameterAsText(2) # the output path and name of SGCN table
scratch = arcpy.GetParameterAsText(3) # scratch GDB where temporary/intermediate files are stored

################################################################################
# Define global variables and functions to be used throughout toolbox
################################################################################

# Calculate intersection between Target Feature and Join Features and produces output table
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

# add field to combine ELCODE and SeasonCode to have unique pairing to use in pivot table output
arcpy.AddField_management(intersect, "ELCODE_season", "TEXT", "", "", 50)
expression = """!ELCODE! + "_" + !SeasonCode!"""
arcpy.CalculateField_management(intersect, "ELCODE_season", expression, "PYTHON_9.3")

# tabular dissolve to delete records with identical unique id, ELCODE_season, and Occurrence Probability fields
arcpy.DeleteIdentical_management(intersect, ["unique_id", "ELCODE_season", "OccProb"])

# groupby iterator used to keep records with highest proportion overlap
case_fields = ["unique_id", "ELCODE", "SeasonCode"] # defining fields within which to create groups
max_field = "PERCENTAGE" # define field to sort within groups
sql_orderby = "ORDER BY {}, {} DESC".format(",".join(case_fields), max_field) # sql code to order by case fields and max field within unique groups

with arcpy.da.UpdateCursor(intersect, "*", sql_clause=(None, sql_orderby)) as cursor:
    case_func = itemgetter(*(cursor.fields.index(fld) for fld in case_fields)) #get field index for field in case_fields from entire list of fields and return item
    for key, group in groupby(cursor, case_func): #grouping by case_func (unique combo of case_fields)
        next(group) #iterate through groups
        for extra in group:
            cursor.deleteRow() #delete extra rows in group that are below that with highest proportion/percentage

arcpy.PivotTable_management(intersect, "unique_id", "ELCODE_season", "OccProb", outTable) #pivot table so that EL_season is across the top, filled with OccProb - Take this step out if a flattened table with multiple records per planning code is desired

