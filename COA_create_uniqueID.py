#-------------------------------------------------------------------------------
# Name:        COA_create_uniqueID
# Purpose:     Creates unique ID for each planning unit with county FIPS code
#              as first 3 digits and a 7 digit unique identifier.
# Author:      Molly Moore
# Created:     2016-07-25
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

def createID(inputHex, counties, IDHex):
    # spatial join - create a new fieldmappings and add the two input feature
    # classes as objects
    fieldmappings = arcpy.FieldMappings()
    fieldmappings.addTable(inputHex)
    fieldmappings.addTable(counties)

    # first gets FIPS_COUNT fieldmap which is a field in the counties feature
    # class - the output will have the planning polygons with the attributes of
    # the counties
    countyFIPS = fieldmappings.findFieldMapIndex("FIPS_COUNT")
    fieldmap = fieldmappings.getFieldMap(countyFIPS)

    # get the output field's properties as a field object
    field = fieldmap.outputField

    # rename the field and pass the updated field object back into the field map
    field.name = "county_FIPS"
    field.aliasName = "County FIPS"
    fieldmap.outputField = field

    # set the merge rule to first and then replace the old fieldmap in the mappings
    # object with the updated one
    fieldmap.mergeRule = "first"
    fieldmappings.replaceFieldMap(countyFIPS, fieldmap)
    fieldmappings.replaceFieldMap(countyFIPS, fieldmap)

    # delete fields from county feature except county_FIPS
    for field in fieldmappings.fields:
        if field.name not in ["county_FIPS"]:
           fieldmappings.removeFieldMap(fieldmappings.findFieldMapIndex(field.name))

    # run the spatial join tool, using the defaults for the join operation and join
    # type
    arcpy.SpatialJoin_analysis(inputHex, counties, IDHex, "#",
    "#", fieldmappings)

    # delete null county_FIPS values - planning polygons outside county layer
    with arcpy.da.UpdateCursor(IDHex, "county_FIPS") as cursor:
        for row in cursor:
            if row[0] == None:
               cursor.deleteRow()

    # create unique identifier
    arcpy.AddField_management(IDHex, "id_num", "TEXT", 10)

    # populate unique identifier field
    field = "id_num"
    def autoIncrement(start=0,step=1):
        i=start
        while 1:
            yield i
            i+=step

    incrementCursor = arcpy.UpdateCursor(IDHex) #There is no guarantee of order here
    incrementer = autoIncrement(1,1)
    for row in incrementCursor:
        row.setValue(field, incrementer.next()) #Note use of next method
        incrementCursor.updateRow(row)

    del incrementCursor

    # pad with zeroes at beginning of id field to ensure identifiers have same
    # number of significant digits
    with arcpy.da.UpdateCursor(IDHex, "id_num") as cursor:
        for row in cursor:
            row[0] = row[0].zfill(7)
            cursor.updateRow(row)

    # add field for unique ID and concatenate county FIPS and identifier
    arcpy.AddField_management(IDHex, "unique_id", "TEXT", "", "", 11,
    "Planning Polygon ID")
    # concatenate
    arcpy.CalculateField_management(IDHex, "unique_id",
    "!county_FIPS! + '_' + !id_num!", "PYTHON_9.3")

    # delete fields that are not needed - could change these if needed
    fields = arcpy.ListFields(IDHex)
    keepFields = ["OBJECTID", "Shape", "unique_id", "Shape_Area", "Shape_Length"]
    dropFields = [f.name for f in fields if f.name not in keepFields]
    # delete fields
    arcpy.DeleteField_management(IDHex, dropFields)

inputHex = arcpy.GetParameterAsText(0)
counties = arcpy.GetParameterAsText(1)
IDHex = arcpy.GetParameterAsText(2)

print "Processing started at" + time.strftime("%c") # print start time
createID(inputHex, counties, IDHex)
print "Processing completed at" + time.strftime("%c") # print start time
