#-------------------------------------------------------------------------------
# Name:        COA_table_compiler
# Purpose:
# Author:      Molly Moore
# Created:     2017-06-02
# Updated:
#
# To Do List/Future ideas:
#-------------------------------------------------------------------------------

# import system modules
import arcpy, os, datetime
from arcpy import env
from arcpy.sa import *
from itertools import groupby
from operator import itemgetter

# Set tools to overwrite existing outputs
arcpy.env.overwriteOutput = True

arcpy.env.qualifiedFieldNames = False
arcpy.env.workspace = r'in_memory'

pu = arcpy.GetParameterAsText(0) # selected planning polygon unit
hab = arcpy.GetParameterAsText(1) # habitat lookup table
species = arcpy.GetParameterAsText(2) # species probability lookup table
species_info = arcpy.GetParameterAsText(3) # species information table
actions = arcpy.GetParameterAsText(4) # actions/threats lookup table
scratch = arcpy.GetParameterAsText(5) # workspace to send intermediate tables - will b
outputTable = arcpy.GetParameterAsText(6) # output table

with arcpy.da.SearchCursor(pu, "unique_id") as cursor:
    selected_pu = sorted({row[0] for row in cursor})
selected_pu = [str(x) for x in selected_pu]

where_clause = """{} IN """.format(arcpy.AddFieldDelimiters(hab, "unique_id")) + str(tuple(selected_pu))
selected_hab = arcpy.TableToTable_conversion(hab, scratch, "_selected_hab_TEMP", where_clause)

# Get all numeric fields that aren't required.
fields = [f.name for f in arcpy.Describe(selected_hab).fields
            if f.type.upper() in ['DOUBLE', 'INTEGER', 'SINGLE', 'SMALLINTEGER']
            and not f.required]

for field in fields:
    with arcpy.da.SearchCursor(selected_hab, field) as cursor:
        summed_total = 0
        count = 0
        for row in cursor:
            summed_total = summed_total + row[0]
            count += 1

    with arcpy.da.UpdateCursor(selected_hab, field) as cursor:
        for row in cursor:
            value = summed_total / count
            row[0] = value
            cursor.updateRow(row)

# Convert to numpy array, casting nulls to 0.
arr = arcpy.da.FeatureClassToNumPyArray(selected_hab, fields, null_value=0)

# Find all fields whose sum are 0.
delete = [field for field in fields if not arr[field].sum()]
print("Deleting '{}'".format(", ".join(delete)))
arcpy.DeleteField_management(selected_hab, delete)

SGCN = arcpy.MakeTableView_management(species, "species_view", where_clause)
arcpy.AddJoin_management(SGCN, "unique_id", selected_hab, "unique_id")
arcpy.AddJoin_management(SGCN, "El_Season", species_info, "ElSeason")
SGCN = arcpy.TableToTable_conversion(SGCN, "in_memory", "SGCN")
basename = os.path.basename(species)
statistics = arcpy.Statistics_analysis(SGCN, os.path.join(scratch, '_statistics_TEMP'), "OccProb COUNT", ['El_Season', 'OccProb'])

arcpy.AddField_management(statistics, "prob_code", "SHORT", '', '', 1)
with arcpy.da.UpdateCursor(statistics, ["OccProb", "prob_code"]) as cursor:
    for row in cursor:
        if row[0] == 'High':
            row[1] = 3
        elif row[0] == 'Medium':
            row[1] = 2
        elif row[0] == 'Low':
            row[1] = 1
        cursor.updateRow(row)

case_fields = ["El_Season"] # defining fields within which to create groups
max_field = ["FREQUENCY", "prob_code"] # define field to sort within groups
sql_orderby = "ORDER BY " + ",".join("{} DESC".format(field) for field in case_fields + max_field) # sql code to order by case fields and max field within unique groups

with arcpy.da.UpdateCursor(statistics, "*", sql_clause=(None, sql_orderby)) as cursor:
    case_func = itemgetter(*(cursor.fields.index(fld) for fld in case_fields)) #get field index for field in case_fields from entire list of fields and return item
    for key, group in groupby(cursor, case_func): #grouping by case_func (unique combo of case_fields)
        next(group) #iterate through groups
        for extra in group:
            cursor.deleteRow()

statistics_view = arcpy.MakeTableView_management(statistics, "statistics_view")
arcpy.AddJoin_management(statistics_view, "El_Season", SGCN, "El_Season")
selected_species_copy = arcpy.CopyRows_management(statistics_view, os.path.join(scratch, "_selected_species_copy_TEMP"))

actions = arcpy.MakeTableView_management(actions, "actions_view")
arcpy.AddJoin_management(actions, "CommonName", selected_species_copy, "SCOMNAME", "KEEP_COMMON")

final_output = arcpy.CopyRows_management(actions, outputTable)

fields = arcpy.ListFields(final_output)
keepFields = ['OBJECTID', 'OID', 'CommonName', 'SNAME', 'OccProb', 'GRANK', 'SRANK', 'SENSITV_SP', 'EditedThreat', 'EditedActions', 'ELCODE', 'SeasonCode', 'Acidic_Cliff_and_Talus', 'Agriculture', 'Allegheny_Cumberland_Dry_Oak_Fo', 'Appalachian__Hemlock__Northern_', 'Appalachian_Shale_Barrens', 'Calcareous_Cliff_and_Talus', 'Central_Appalachian_Alkaline_Gl', 'Central_Appalachian_Pine_Oak_Ro', 'Central_Interior_Highlands_and_', 'Circumneutral_Cliff_and_Talus', 'Coastal_Plain_Tidal_Swamp', 'Cold__Eutrophic__Acidic', 'Cold__Eutrophic__Alkaline', 'Cold__Eutrophic__Circumneutral', 'Cold__Oligo_Mesotrophic__Acidic', 'Cold__Oligo_Mesotrophic__Alkali', 'Cold__Oligo_Mesotrophic__Circum', 'Developed', 'Dry_Oak_Pine_Forest__Central_Ap', 'Great_Lakes_Dune_and_Swale', 'High_Allegheny_Headwater_Wetlan', 'Laurentian_Acadian_Freshwater_M', 'Laurentian_Acadian_Northern_Har', 'Laurentian_Acadian_Pine_Hemlock', 'Laurentian_Acadian_Wet_Meadow_S', 'North_Atlantic_Coastal_Plain_Ba', 'North_Atlantic_Coastal_Plain_Ha', 'North_Central_Appalachian_Acidi', 'North_Central_Appalachian_Large', 'North_Central_Interior_and_Appa', 'North_Central_Interior_and_Ap_1', 'North_Central_Interior_Beech_Ma', 'North_Central_Interior_Large_Ri', 'North_Central_Interior_Wet_Flat', 'Northeastern_Interior_Dry_Mesic', 'Northern_Appalachian_Acadian_Co', 'Open_water', 'Serpentine_Barren___Woodland', 'Shrubland_grassland__mostly_rud', 'South_Central_Interior_Mesophyt', 'Southern_Appalachian_Montane_Pi', 'Southern_Atlantic_Coastal_Plain', 'Tidal_Salt_Marsh__Estuarine_Mar', 'Very_Cold__Eutrophic__Acidic', 'Very_Cold__Eutrophic__Alkaline', 'Very_Cold__Eutrophic__Circumneu', 'Very_Cold__Oligo_Mesotrophic__A', 'Very_Cold__Oligo_Mesotrophic__1', 'Very_Cold__Oligo_Mesotrophic__C', 'Warm_to_Cool__Eutrophic__Acidic', 'Warm_to_Cool__Eutrophic__Alkali', 'Warm_to_Cool__Eutrophic__Circum', 'Warm_to_Cool__Oligo_Mesotrophic', 'Warm_to_Cool__Oligo_Mesotroph_1', 'Warm_to_Cool__Oligo_Mesotroph_2']
dropFields = [x.name for x in fields if x.name not in keepFields]
arcpy.DeleteField_management(final_output, dropFields)