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

target_features = r'Database Connections\COA.Working.pgh-gis0.sde\COA.DBO.PlanningUnits\COA.DBO.PlanningUnit_Hex10acre' # planning polygon unit
join_features = r'Database Connections\COA.Working.pgh-gis0.sde\COA.DBO.COA_SGCN\COA.DBO.SGCN_OccFinal' # SGCN occurrence probability layer - should be polygon layer
outGDB = r'C:\Users\mmoore\Documents\ArcGIS\SGCNxPU.gdb' # the output path and name of SGCN table
scratch = r'C:\Users\mmoore\Documents\ArcGIS\COA.gdb'
counties = r'Database Connections\COA.Working.pgh-gis0.sde\COA.DBO.OtherData\COA.DBO.CountyBuffer'

#target_features = arcpy.GetParameterAsText(0) # planning polygon unit
#join_features = arcpy.GetParameterAsText(1) # SGCN occurrence probability layer - should be polygon layer
#outTable = arcpy.GetParameterAsText(2) # the output path and name of SGCN table
#scratch = arcpy.GetParameterAsText(3) # scratch GDB where temporary/intermediate files are stored

################################################################################
# Define global variables and functions to be used throughout toolbox
################################################################################

with arcpy.da.SearchCursor(counties, ['COUNTY_NAM']) as cursor:
    county_list = sorted({row[0] for row in cursor})

pu_lyr = arcpy.MakeFeatureLayer_management(target_features, "pu_lyr")
county_lyr = arcpy.MakeFeatureLayer_management(counties, "county_lyr")
merge_list = []

for county in county_list:
    print "working on " + county + " at " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    arcpy.SelectLayerByAttribute_management(county_lyr, "NEW_SELECTION", '"COUNTY_NAM" = ' + "'%s'"%county)
    arcpy.SelectLayerByLocation_management(pu_lyr, "INTERSECT", county_lyr, "", "NEW_SELECTION", )

    # Calculate intersection between Target Feature and Join Features and produces output table
    intersect = os.path.join(outGDB, county)
    classFeatures = ["ELSeason", "OccProb"]
    arcpy.TabulateIntersection_analysis(pu_lyr, "unique_id", join_features, intersect, classFeatures)
    merge_list.append(intersect)

merge = arcpy.Merge_management(merge_list, os.path.join(outGDB, "SGCNxPU_occurrence"))

# delete PUs that have less than 10% (4046.86 square meters) of area overlapped by particular species
# could change this threshold if needed
with arcpy.da.UpdateCursor(merge, "PERCENTAGE") as cursor:
     for row in cursor:
        if row[0] > 10:
            pass
        else:
            cursor.deleteRow()

#add field to combine ELCODE and SeasonCode to have unique pairing to use in pivot table output
#arcpy.AddField_management(merge, "El_Season", "TEXT", "", "", 50)
#expression = """!ELCODE! + "_" + !SeasonCode!"""
#arcpy.CalculateField_management(merge, "El_Season", expression, "PYTHON_9.3")

# tabular dissolve to delete records with identical unique id, ELCODE_season, and Occurrence Probability fields
arcpy.DeleteIdentical_management(merge, ["unique_id", "ELSeason", "OccProb"])

# groupby iterator used to keep records with highest proportion overlap
case_fields = ["unique_id", "ELSeason"] # defining fields within which to create groups
max_field = "PERCENTAGE" # define field to sort within groups
sql_orderby = "ORDER BY {}, {} DESC".format(",".join(case_fields), max_field) # sql code to order by case fields and max field within unique groups

with arcpy.da.UpdateCursor(merge, "*", sql_clause=(None, sql_orderby)) as cursor:
    case_func = itemgetter(*(cursor.fields.index(fld) for fld in case_fields)) #get field index for field in case_fields from entire list of fields and return item
    for key, group in groupby(cursor, case_func): #grouping by case_func (unique combo of case_fields)
        next(group) #iterate through groups
        for extra in group:
            cursor.deleteRow() #delete extra rows in group that are below that with highest proportion/percentage

#arcpy.PivotTable_management(intersect, "unique_id", "ELCODE_season", "OccProb", outTable) #pivot table so that EL_season is across the top, filled with OccProb - Take this step out if a flattened table with multiple records per planning code is desired

