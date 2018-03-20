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

print "start time: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
species_type = raw_input("terrestrial or aquatic species? (enter terrestrial or aquatic): ")

# set default to overwrite output datasets with same name
arcpy.env.overwriteOutput = True
arcpy.env.workspace = r'H:\Projects\COA_SpeciesData\COA_SGCN_SDM_terrestrial.gdb\SDM'
if species_type == 'terrestrial':
    featureclasses = arcpy.ListFeatureClasses(feature_type = "Polygon")
elif species_type == 'aquatic':
    featureclasses = arcpy.ListFeatureClasses(feature_type = "Polyline")

# set paths
target_features = r'C:\Users\mmoore\Documents\ArcGIS\COA_Species.gdb\PlanningUnit_Hex10acre'
outTable = r'H:\Projects\COA_SpeciesData\COA_SGCN_SDM_Tables.gdb'

species_intersects = []

# loop for each SDM layer
for fc in featureclasses:
    print fc + " started at: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    join_features = os.path.join(arcpy.env.workspace, fc)
    # output path/name
    intersect = os.path.join(outTable, fc)
    classFeatures = ["ELCODE", "SeasonCode", "OccProb"]

    # tabulate intersection between PU and SGCN layers
    arcpy.TabulateIntersection_analysis(target_features, "unique_id", join_features, intersect, classFeatures)

    # delete PUs that have less than 10% overlapping SGCN - THIS SHOULD ONLY BE DONE FOR TERRESTRIAL SPECIES. NOT AQUATIC SPECIES.
    if species_type == 'terrestrial':
        with arcpy.da.UpdateCursor(intersect, "PERCENTAGE") as cursor:
            for row in cursor:
                if row[0] > 10:
                    pass
                else:
                    cursor.deleteRow()
    else:
        pass

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

    species_intersects.append(intersect)
    print fc + " finished at: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

#merge county SGCNxPU datasets and delete identical
merge = arcpy.Merge_management(species_intersects, os.path.join(outTable, "SGCN_SDMxPU_", species_type))
#arcpy.DeleteIdentical_management(merge, ["unique_id", "ELCODE", "SeasonCode", "OccProb"])

print "end time: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")