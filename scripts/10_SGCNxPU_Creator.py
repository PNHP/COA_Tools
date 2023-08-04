# -------------------------------------------------------------------------------
# Name:        COA_species_populator.py
# Purpose:     Populates planning units with occurrence probability for SGCNs.
#              Current version populates planning unit with occurrence
#              probability of SGCNs. If more than one of a single SGCN is
#              present, the occurrence probability is filled with the SGCN that
#              has the largest proportion overlap with planning unit and only
#              populates planning units with greater than 10% coverage by SGCN.
# Author:      Molly Moore
# Created:     2016-08-25
# Updates:
# 2022-05-10 - updated to include dissolve step at beginning, cleaned up code, removed county loop because no longer needed.
# -------------------------------------------------------------------------------

# import system modules
import arcpy, os, datetime
from arcpy import env
from arcpy.sa import *
from itertools import groupby
from operator import itemgetter

# Set tools to overwrite existing outputs
arcpy.env.overwriteOutput = True

# define path to SGCN database - this will change!!!
sgcn_gdb = r"H:\\Scripts\\COA_Tools\\_data\\output\\_update2023q2\\SGCN.gdb"

# define dataset names - these shouldn't change unless there is larger change
PUs = os.path.join(sgcn_gdb, 'PlanningUnit_Hex10acre')  # planning polygon unit
all_sgcn = os.path.join(sgcn_gdb, 'allSGCNuse')

print("Dissolving SGCN layer!")
# dissolve the allSGCN layer
all_sgcn_diss = arcpy.PairwiseDissolve_analysis(all_sgcn, os.path.join(sgcn_gdb, "allGSCNuse_dissolve"), "ELSeason;OccProb", None, "MULTI_PART")

print("Tabulate Intersect!")
# tabulate intersect between PUs and SGCN dissolve layer
sgcnXpu = arcpy.TabulateIntersection_analysis(PUs, "unique_id", all_sgcn_diss, os.path.join(sgcn_gdb, "SGCNxPU_occurrence"), ["ELSeason", "OccProb"])

print("Do other stuff!")
# delete PUs that have less than 10% (4046.86 square meters) of area overlapped by particular species
# could change this threshold if needed
with arcpy.da.UpdateCursor(sgcnXpu, "PERCENTAGE") as cursor:
    for row in cursor:
        if row[0] > 10:
            pass
        else:
            cursor.deleteRow()

# tabular dissolve to delete records with identical unique id, ELCODE_season, and Occurrence Probability fields
arcpy.DeleteIdentical_management(sgcnXpu, ["unique_id", "ELSeason", "OccProb"])

# groupby iterator used to keep records with highest proportion overlap
case_fields = ["unique_id", "ELSeason"]  # defining fields within which to create groups
max_field = "PERCENTAGE"  # define field to sort within groups
sql_orderby = "ORDER BY {}, {} DESC".format(",".join(case_fields), max_field)  # sql code to order by case fields and max field within unique groups

with arcpy.da.UpdateCursor(sgcnXpu, "*", sql_clause=(None, sql_orderby)) as cursor:
    case_func = itemgetter(*(cursor.fields.index(fld) for fld in case_fields))  # get field index for field in case_fields from entire list of fields and return item
    for key, group in groupby(cursor, case_func):  # grouping by case_func (unique combo of case_fields)
        next(group)  # iterate through groups
        for extra in group:
            cursor.deleteRow()  # delete extra rows in group that are below that with highest proportion/percentage
