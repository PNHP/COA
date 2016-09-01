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

def SpatialJoinLargestOverlap(target_features, join_features, outTable):
    keep_all = "false" # keep all features during join - do not change
    spatial_rel = "largest_overlap" # do not change
    out_fc = "in_memory\\tempPU" # output planning polygon feature class
    if spatial_rel == "largest_overlap":
        # Calculate intersection between Target Feature and Join Features
        intersect = arcpy.analysis.Intersect([target_features, join_features], "in_memory\\intersect", "ONLY_FID")
        # Find which Join Feature has the largest overlap with each Target Feature
        # Need to know the Target Features shape type, to know to read the SHAPE_AREA oR SHAPE_LENGTH property
        geom = "AREA" if arcpy.Describe(target_features).shapeType.lower() == "polygon" and arcpy.Describe(join_features).shapeType.lower() == "polygon" else "LENGTH"
        fields = ["FID_{0}".format(os.path.splitext(os.path.basename(target_features))[0]),
                  "FID_{0}".format(os.path.splitext(os.path.basename(join_features))[0]),
                  "SHAPE@{0}".format(geom)]

        # delete PUs that have less than 25% (2023.43 square meters) of area overlapped by protected lands
        # could change this threshold if needed
        with arcpy.da.UpdateCursor(intersect, "SHAPE@{0}".format(geom)) as cursor:
            for row in cursor:
                if row[0] > 10117.15:
                    pass
                else:
                    cursor.deleteRow()

        overlap_dict = {}
        with arcpy.da.SearchCursor(intersect, fields) as scur:
            for row in scur:
                try:
                    if row[2] > overlap_dict[row[0]][1]:
                        overlap_dict[row[0]] = [row[1], row[2]]
                except:
                    overlap_dict[row[0]] = [row[1], row[2]]

        # Copy the target features and write the largest overlap join feature ID to each record
        # Set up all fields from the target features + ORIG_FID
        fieldmappings = arcpy.FieldMappings()
        fieldmappings.addTable(target_features)
        fieldmap = arcpy.FieldMap()
        fieldmap.addInputField(target_features, arcpy.Describe(target_features).OIDFieldName)
        fld = fieldmap.outputField
        fld.type, fld.name, fld.aliasName = "LONG", "ORIG_FID", "ORIG_FID"
        fieldmap.outputField = fld
        fieldmappings.addFieldMap(fieldmap)
        # Perform the copy
        arcpy.conversion.FeatureClassToFeatureClass(target_features, os.path.dirname(out_fc), os.path.basename(out_fc), "", fieldmappings)
        # Add a new field JOIN_FID to contain the fid of the join feature with the largest overlap
        arcpy.management.AddField(out_fc, "JOIN_FID", "LONG")
        # Calculate the JOIN_FID field
        with arcpy.da.UpdateCursor(out_fc, ["ORIG_FID", "JOIN_FID"]) as ucur:
            for row in ucur:
                try:
                    row[1] = overlap_dict[row[0]][0]
                    ucur.updateRow(row)
                except:
                    if not keep_all:
                        ucur.deleteRow()
        # Join all attributes from the join features to the output
        joinfields = [x.name for x in arcpy.ListFields(join_features) if not x.required]
        arcpy.management.JoinField(out_fc, "JOIN_FID", join_features, arcpy.Describe(join_features).OIDFieldName, joinfields)

        # delete null records (those planning units that do not have species overlapping)
        with arcpy.da.UpdateCursor(out_fc, "JOIN_FID") as cursor:
            for row in cursor:
                if row[0] == None:
                    cursor.deleteRow()

        arcpy.PivotTable_management(out_fc, "unique_id", "ELCODE", "OccProb",
        outTable)

target_features = arcpy.GetParameterAsText(0) # planning polygon unit
join_features = arcpy.GetParameterAsText(1) # protected lands layer
outTable = arcpy.GetParameterAsText(2)

SpatialJoinLargestOverlap(target_features, join_features, outTable)
