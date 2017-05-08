##-------------------------------------------------------------------------------
# Name:        COA_Buffer
# Purpose:     Adds specified buffer distance to SGCN points and SGCN lines and
#              merges the output polygon buffers with SGCN polygons. If CPP has
#              been created, feature gets replaced with CPP.
# Author:      Molly Moore
# Created:     2016-07-18
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
# Define global variables and functions to be used in tool
################################################################################

# function to buffer sgcn points and lines with specified distance and merge
# buffers and sgcn polygons into one dataset, sgcn_total

def sgcn_buffer(sgcn_points, point_buff, sgcn_lines, line_buff, sgcn_poly,
    sgcntotal):
    # create point buffer to be stored in memory
    pointbuffTEMP = "in_memory" + "\\" + "ptbuff"
    arcpy.Buffer_analysis(sgcn_points, pointbuffTEMP, point_buff, "FULL",
    "ROUND")

    # create line buffer to be stored in memory
    linebuffTEMP = "in_memory" + "\\" + "lnbuff"
    arcpy.Buffer_analysis(sgcn_lines, linebuffTEMP, line_buff, "FULL",
    "ROUND")

    # use Merge tool to move buffered and sgcn poly features into single dataset
    merge = [pointbuffTEMP, linebuffTEMP, sgcn_poly]
    sgcntotalTEMP = "in_memory\\sgcntotalTEMP"
    arcpy.Merge_management(merge, sgcntotalTEMP)

    sgcn_lyr = arcpy.MakeFeatureLayer_management(sgcntotalTEMP)
    notNULL = arcpy.SelectLayerByAttribute_management(sgcn_lyr, "NEW_SELECTION", "DataID IS NOT NULL")
    polyTEMP = arcpy.Dissolve_management(sgcn_lyr, "in_memory\\polyTEMP", "DataID")

    arcpy.JoinField_management(polyTEMP, "DataID", sgcn_lyr, "DataID")

    sgcn_lyr = arcpy.SelectLayerByAttribute_management(sgcn_lyr, "NEW_SELECTION", "DataID IS NULL")
    arcpy.Merge_management([sgcn_lyr, polyTEMP], sgcntotal)

    deleteFields = ["BUFF_DIST", "ORIG_FID", "DataID_1"]
    arcpy.DeleteField_management(sgcntotal, deleteFields)

def delNullValues(inFC, field):
    with arcpy.da.cursor(inFC, field) as cursor:
        for row in cursor:
            if row[0] == 'No':
                cursor.deleteRow()
            else:
                pass

def burnCPP(cpp_layer, sgcn_layer):
    cpp = {}
    with arcpy.da.SearchCursor(cpp_layer, ["EO_ID", "SHAPE@"]) as sCursor:
        for row in sCursor:
            cpp[str(row[0])] = row[1]

    with arcpy.da.UpdateCursor(sgcn_layer, ["DataSource", "DataID", "SHAPE@"]) as uCursor:
        for row in uCursor:
            recordID = row[1]
            if recordID in cpp:
                row[2] = cpp[recordID]
                uCursor.updateRow(row)

################################################################################
# Define parameters for tool
################################################################################

sgcn_points = arcpy.GetParameterAsText(0)
point_buff = arcpy.GetParameterAsText(1)
sgcn_lines = arcpy.GetParameterAsText(2)
line_buff = arcpy.GetParameterAsText(3)
sgcn_poly = arcpy.GetParameterAsText(4)
cpp_layer = arcpy.GetParameterAsText(5)
sgcntotal = arcpy.GetParameterAsText(6)

################################################################################
# Execute script
################################################################################

sgcn_buffer(sgcn_points, point_buff, sgcn_lines, line_buff, sgcn_poly,
sgcntotal)

try:
    delNullValues(sgcntotal, "DataQuality")
except AttributeError:
    pass

burnCPP(cpp_layer, sgcntotal)
