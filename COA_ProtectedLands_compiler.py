#-------------------------------------------------------------------------------
# Name:        COA_Protectedlands_compiler
# Purpose:     Compiles PAD (Protected Areas Database) and NCED (National
#              Conservation Easement Dataset) datasets into new feature class
#              of protected lands and populates planning units with that
#              protection unit information that intersects it.
#              Inputs: PAD dataset, NCED dataset, PA county dataset
#              Outputs: Protected lands feature class, Protected lands planning
#                       polygon unit table
# Author:      Molly Moore
# Created:     2016-08-12
# Updated:
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
# Define global variables and functions to be used when running script
################################################################################

exceptions = ["PA", "NE", "NW", "SE", "SW", "US", "SGL", "U.S.", "UPDE", "M.K.", "RAU", "NFG", "MCCD", "DEWA", "APPA", "FCVC"]

# Function to convert attributes from counties, municipalities, usgs quads, and protected lands to title case
def title_except(s, exceptions):
    '''Takes a string and a list of exceptions as input. Returns the string in
    title case, except any words in the exeptions list are not altered.
    string + Python list = string
    ROANOKE SW -> Roanoke SW
    '''
    # Turn string into a list of words
    word_list = s.split()
    # Final is an empty list that words will be appended to
    final = []
    # For each word in the list, append to the final list
    for word in word_list:
        # If the word is in exceptions, append the word. If not, append the word capitalized.
        final.append(word in exceptions and word or word.capitalize())
    # Return the list of final words converted to a string
    return " ".join(final)

def protectedlandslayer(PAD, NCED, counties, outFeature):

    # set local variables in lists to prepare for looping
    ProtectedLands = [PAD, NCED]
    layers = ['PAD', 'NCED']
    county_lyr = arcpy.MakeFeatureLayer_management(counties, "counties_lyr")

    # select protected lands that intersect PA county boundaries and copy - populate
    # list with output feature classes to use in add field loop
    temp_featureclasses = []
    for FC, layer in zip(ProtectedLands, layers):
        outFC = "in_memory" + "\\" + layer
        layer1 = arcpy.MakeFeatureLayer_management(FC, layer)
        selection = arcpy.SelectLayerByLocation_management(layer1, "INTERSECT", county_lyr)
        protected_fc = arcpy.CopyFeatures_management(selection, outFC)
        temp_featureclasses.append(protected_fc)

    # add field to each dataset and populate with data source
    for n, f in zip(layers, temp_featureclasses):
        arcpy.AddField_management(f, "data_src", "TEXT", "", "",
        4, "Data Source", "", "", "")
        expression = '"' + n + '"'
        arcpy.CalculateField_management(f, "data_src",
        expression, "PYTHON_9.3")

    # create new, empty feature class to populate with features from PAD, NCED datasets
    spatial_reference = arcpy.Describe(counties).spatialReference
    newFC = arcpy.CreateFeatureclass_management(os.path.dirname(outFeature), os.path.basename(outFeature),
    "POLYGON", "", "", "", spatial_reference)

    # set characteristics for fields in new feature class
    field_name = ["site_nm", "manager", "owner_typ", "gap_stat", "data_src"]
    field_length = [100, 100, 100, 100, 100, 4]
    field_alias = ["Site Name", "Manager", "Owner Type",
    "GAP Status", "Data Source"]

    # populate new feature class with fields
    for name, length, alias in zip(field_name, field_length, field_alias):
        arcpy.AddField_management(newFC, name, "TEXT", "", "", length, alias)

    PAD_inputFields = ["Loc_Nm", "Loc_Mang", "Own_Type", "GAP_Sts", "data_src"]
    PAD_outputFields = ["site_nm", "manager", "owner_typ", "gap_stat",
        "data_src"]
    schemaType = "NO_TEST"
    subtype = ""

    fieldmappings = arcpy.FieldMappings()
    for input, output in zip(PAD_inputFields, PAD_outputFields):
        outfield1 = output
        input1 = arcpy.FieldMap()

        input1.addInputField("in_memory\\PAD", input)

        output1 = input1.outputField
        output1.name = (outfield1)
        input1.outputField = output1

        fieldmappings.addFieldMap(input1)

    try:
        print "Appending data. . ."
        # Process: Append the feature classes into the empty feature class
        arcpy.Append_management("in_memory\\PAD", newFC, schemaType, fieldmappings, subtype)

    except:
        # If an error occurred while running a tool print the messages
        print arcpy.GetMessages()

    NCED_inputFields = ["sitename", "esmthldr", "owntype", "gapsts", "data_src"]
    NCED_outputFields = ["site_nm", "manager", "owner_typ", "gap_stat",
        "data_src"]

    fieldmappings = arcpy.FieldMappings()
    for input, output in zip(NCED_inputFields, NCED_outputFields):
        outfield1 = output
        input1 = arcpy.FieldMap()

        input1.addInputField("in_memory\\NCED", input)

        output1 = input1.outputField
        output1.name = (outfield1)
        input1.outputField = output1

        fieldmappings.addFieldMap(input1)

    try:
        print "Appending data. . ."
        # Process: Append the feature classes into the empty feature class
        arcpy.Append_management("in_memory\\NCED", newFC, schemaType, fieldmappings, subtype)

    except:
        # If an error occurred while running a tool print the messages
        print arcpy.GetMessages()

# function to populate planning units with protected lands information
# only information from protected land with greatest area overlap will be
# transferred to planning units
def SpatialJoinLargestOverlap(target_fc, outTable):
    target_features = arcpy.FeatureClassToFeatureClass_conversion(target_fc, "in_memory", "targetTEMP")
    keep_all = "false" # keep all features during join - do not change
    spatial_rel = "largest_overlap" # do not change
    join_features = outFeature # protected lands layer
    out_fc = "in_memory\\tempPU" # output planning polygon feature class
    if spatial_rel == "largest_overlap":
        # Calculate intersection between Target Feature and Join Features
        intersect = arcpy.analysis.Intersect([target_features, join_features], r"in_memory\\intersect", "ONLY_FID")
        # Find which Join Feature has the largest overlap with each Target Feature
        # Need to know the Target Features shape type, to know to read the SHAPE_AREA oR SHAPE_LENGTH property
        geom = "AREA" if arcpy.Describe(target_features).shapeType.lower() == "polygon" and arcpy.Describe(join_features).shapeType.lower() == "polygon" else "LENGTH"
        fields = ["FID_targetTEMP",
                  "FID_{0}".format(os.path.splitext(os.path.basename(join_features))[0]),
                  "SHAPE@{0}".format(geom)]

        # delete PUs that have less than 5% (2023.43 square meters) of area overlapped by protected lands
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

        # delete null records (those planning units that do not have protected
        # lands overlapping)
        with arcpy.da.UpdateCursor(out_fc, "JOIN_FID") as cursor:
            for row in cursor:
                if row[0] == None:
                    cursor.deleteRow()

        # create a new fieldmappings and add the two input feature classes as
        # objects to prepare for table to table conversion
        fieldmappings = arcpy.FieldMappings()
        fieldmappings.addTable(out_fc)

        # remove field map for fields that are not needed
        for field in fieldmappings.fields:
            if field.name not in ["unique_id", "site_nm", "manager", "owner_typ", "gap_stat",
            "cons_purp", "data_src"]:
                fieldmappings.removeFieldMap(fieldmappings.findFieldMapIndex(field.name))

        # convert to table
        arcpy.TableToTable_conversion(out_fc, os.path.dirname(outTable), os.path.basename(outTable), "", fieldmappings, "")


def formatText(protectTable):
    # create list of coded values and descript values
    codedValues = ["FED", "STAT", "LOC", "NGO", "PVT", "DESG", "UNK", "UNK", "UNK", "JOIN", "TRIB" ]
    descriptValues = ["Federal", "State", "Local Government", "Non-Governmental Organization", "Private", "Designation", "Unknown", "Unknown Landowner", "DIST", "Jointly Owned", "Tribe"]

    # change coded owner type values to descriptive values
    with arcpy.da.UpdateCursor(protectTable, "owner_typ") as cursor:
        for row in cursor:
            for code, descript in zip(codedValues, descriptValues):
                if row[0] == descript:
                    row[0] = code
                else:
                    pass
                cursor.updateRow(row)


    # change descriptive values to coded values for gap status by taking only
    # first character
    with arcpy.da.UpdateCursor(protectTable, "gap_stat") as cursor:
        for row in cursor:
            if not row[0] is None:
                row[0] = row[0][0]
                cursor.updateRow(row)

    # change all strings in field to title case with exception of those found in
    # exceptions list
    with arcpy.da.UpdateCursor(protectTable, ["manager", "site_nm"]) as cursor:
        for row in cursor:
            row[0] = title_except(row[0], exceptions)
            row[1] = title_except(row[1], exceptions)
            cursor.updateRow(row)

    # replace any string containing only a number to "Conservation Easement"
    with arcpy.da.UpdateCursor(protectTable, "site_nm") as cursor:
        for row in cursor:
            if row[0].isdigit() is True:
                row[0] = "Conservation Easement"
                cursor.updateRow(row)

# Run the script
if __name__ == '__main__':
    # Get Parameters
    PAD = arcpy.GetParameterAsText(0) # PAD layer
    NCED = arcpy.GetParameterAsText(1) # NCED layer
    counties = arcpy.GetParameterAsText(2) # PA county layer
    outFeature = arcpy.GetParameterAsText(3)

    # run protected lands function to combine PAD and NCED layers
    protectedlandslayer(PAD, NCED, counties, outFeature)

    target_fc = arcpy.GetParameterAsText(4) # planning polygon unit
    outTable = arcpy.GetParameterAsText(5)


    SpatialJoinLargestOverlap(target_fc, outTable)

    formatText(outTable)

    print "finished"