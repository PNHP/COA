#-------------------------------------------------------------------------------
# Name:        COA_species_populator
# Purpose:
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
# Define global variables and functions to be used throughout toolbox
################################################################################

# function to buffer sgcn points and lines with specified distance and merge
# buffers and sgcn polygons into one dataset, sgcn_total

def sgcn_buffer(sgcn_points, point_buff, sgcn_lines, line_buff, sgcn_poly,
    sgcntotal):
    # create point buffer to be stored in memory
    pointbuffTEMP = "in_memory" + "\\" + "ptbuff"
    arcpy.Buffer_analysis(sgcn_points, pointbuffTEMP, point_buff, "FULL",
    "ROUND", "LIST", "ELCODE")

    # join attributes from original sgcn_points to buffered points
    arcpy.JoinField_management(pointbuffTEMP, "ELCODE", sgcn_points, "ELCODE")

    # delete extra ELCODE field that appeared with join
    deleteFields = ["ELCODE_1"]
    arcpy.DeleteField_management(pointbuffTEMP, deleteFields)

    # create line buffer to be stored in memory
    linebuffTEMP = "in_memory" + "\\" + "lnbuff"
    arcpy.Buffer_analysis(sgcn_lines, linebuffTEMP, line_buff, "FULL",
    "ROUND", "LIST", "ELCODE")

    # join attributes from original sgcn_lines to buffered lines
    arcpy.JoinField_management(linebuffTEMP, "ELCODE", sgcn_lines, "ELCODE")

    # delete extra ELCODE field that appeared with join
    deleteFields = ["ELCODE_1"]
    arcpy.DeleteField_management(linebuffTEMP, deleteFields)

    # use Merge tool to move buffered and sgcn poly features into single dataset
    merge = [pointbuffTEMP, linebuffTEMP, sgcn_poly]
    arcpy.Merge_management(merge, sgcntotal)

sgcn_points = arcpy.GetParameterAsText(0)
point_buff = arcpy.GetParameterAsText(1)
sgcn_lines = arcpy.GetParameterAsText(2)
line_buff = arcpy.GetParameterAsText(3)
sgcn_poly = arcpy.GetParameterAsText(4)
sgcntotal = arcpy.GetParameterAsText(5)

sgcn_buffer(sgcn_points, point_buff, sgcn_lines, line_buff, sgcn_poly,
sgcntotal)

