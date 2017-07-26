#-------------------------------------------------------------------------------
# Name:        COA_species_populator
# Purpose:     Populates planning units with occurrence probability for SGCN
#              SDM dataset. This version populates planning unit with occurrence
#              probability of SGCN SDM. If more than one of a single SGCN is
#              present, the occurrence probability is filled with the SGCN that
#              has the largest proportion overlap with planning unit and only
#              populates planning units with greater than 10% coverage by SGCN.
# Author:      Molly Moore
# Created:     2016-08-25
# Updated:     2017-05-08
#
# To Do List/Future ideas:
#-------------------------------------------------------------------------------
# import packages
import arcpy, os, datetime
from arcpy import env
from arcpy.sa import *
from itertools import groupby
from operator import itemgetter

# set default to overwrite output datasets with same name
arcpy.env.overwriteOutput = True

# set paths
target_features = r'C:\Users\mmoore\Documents\ArcGIS\COA_Species.gdb\PlanningUnit_Hex10acre'
join_features = r'C:\Users\mmoore\Documents\ArcGIS\COA_Species.gdb\SGCN_SDM'
outTable = r'C:\Users\mmoore\Documents\ArcGIS\COA_Species.gdb'
pa_county = r'C:\Users\mmoore\Documents\ArcGIS\COA_Species.gdb\PA_County'

# create county and pu feature layers
county_lyr = arcpy.MakeFeatureLayer_management(pa_county, "county_lyr")
target_lyr = arcpy.MakeFeatureLayer_management(target_features, "target")

# create list of counties
with arcpy.da.SearchCursor(pa_county, "COUNTY_NAM") as cursor:
    county_list = sorted({row[0] for row in cursor})
counties = [x.encode('UTF8') for x in county_list]

# create list of county paths for later merge
county_paths = []

# loop for each county
for c in counties:
    county = c
    # select individual county
    county_selection = arcpy.SelectLayerByAttribute_management(county_lyr, "NEW_SELECTION", '"COUNTY_NAM" = ' + "'%s'" %county)
    # select all PUs that intersect selected county
    target_selection = arcpy.SelectLayerByLocation_management(target_lyr, "INTERSECT", county_selection, "", "NEW_SELECTION")
    # create new feature class with selected PUs
    target = arcpy.FeatureClassToFeatureClass_conversion(target_selection, outTable, "target")
    # output path/name
    intersect = os.path.join(outTable, county)
    classFeatures = ["ELCODE", "SeasonCode", "OccProb"]
    # tabulate intersection between PU and SGCN layers
    arcpy.TabulateIntersection_analysis(target, "unique_id", join_features, intersect, classFeatures)

    # delete PUs that have less than 10% overlapping SGCN
    with arcpy.da.UpdateCursor(intersect, "PERCENTAGE") as cursor:
        for row in cursor:
            if row[0] > 10:
                pass
            else:
                cursor.deleteRow()

    case_fields = ["unique_id", "ELCODE", "SeasonCode"]
    max_field = "PERCENTAGE"
    sql_orderby = "ORDER BY {}, {} DESC".format(",".join(case_fields), max_field)

    # use groupby cursor to order by percent coverage
    with arcpy.da.UpdateCursor(intersect, "*", sql_clause=(None, sql_orderby)) as cursor:
        case_func = itemgetter(*(cursor.fields.index(fld) for fld in case_fields))
        for key, group in groupby(cursor, case_func):
            next(group)
            for extra in group:
                cursor.deleteRow()

    county_paths.append(intersect)

# merge county SGCNxPU datasets and delete identical
merge = arcpy.Merge_management(county_paths, os.path.join(outTable, "SGCN_SDMxPU"))
arcpy.DeleteIdentical_management(merge, ["unique_id", "ELCODE", "SeasonCode", "OccProb"])