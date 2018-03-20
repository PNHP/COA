import arcpy, os, datetime
from arcpy import env
from arcpy.sa import *
from itertools import groupby
from operator import itemgetter

print "start time: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

arcpy.env.overwriteOutput = True

target_features = r'C:\Users\mmoore\Documents\ArcGIS\COA.gdb\PlanningUnit_Hex10acreRaster'
sdm_folder = r'C:\Users\mmoore\Documents\ArcGIS\SDMs.gdb'
outTable = r'C:\Users\mmoore\Documents\ArcGIS\out_tables.gdb'
arcpy.env.workspace = sdm_folder
sdms = arcpy.ListRasters()

species_tables = []

for sdm in sdms:
    print sdm + " started at: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sdm_path = os.path.join(sdm_folder,sdm)
    arcpy.CheckOutExtension("Spatial")
    tab_area = TabulateArea(target_features,"unique_id",sdm,"Value",os.path.join(outTable,"tab_area_temp"),"30")
    sdm_table = arcpy.TransposeFields_management(tab_area,"VALUE_1 Low;VALUE_2 Medium",os.path.join(outTable,sdm),"OccProb","PERCENTAGE","unique_id")
    arcpy.AddField_management(sdm_table,"ElSeason","TEXT","","",20,"ElSeason")
    with arcpy.da.UpdateCursor(sdm_table,["OccProb","PERCENTAGE","ElSeason"]) as cursor:
        for row in cursor:
            row[1] = (int(row[1])/40468.383184)*100
            cursor.updateRow(row)
            row[2] = sdm
            cursor.updateRow(row)
            if row[0] == "VALUE_1":
                row[0] = "Low"
            elif row[0] == "VALUE_2":
                row[0] = "Medium"
                cursor.updateRow(row)

    with arcpy.da.UpdateCursor(sdm_table, "PERCENTAGE") as cursor:
        for row in cursor:
            if row[0] > 10:
                pass
            else:
                cursor.deleteRow()

    case_fields = ["unique_id", "ElSeason"]
    max_field = "PERCENTAGE"
    sql_orderby = "ORDER BY {}, {} DESC".format(",".join(case_fields), max_field)

    # use groupby cursor to order by percent coverage
    with arcpy.da.UpdateCursor(sdm_table, "*", sql_clause=(None, sql_orderby)) as cursor:
        case_func = itemgetter(*(cursor.fields.index(fld) for fld in case_fields))
        for key, group in groupby(cursor, case_func):
            next(group)
            for extra in group:
                cursor.deleteRow()

    species_tables.append(sdm_table)
    arcpy.Delete_management(tab_area)
    print sdm + " finished at: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

merge = arcpy.Merge_management(species_tables, os.path.join(outTable, "SGCN_SDMxPU"))
print "end time: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


