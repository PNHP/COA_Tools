### This code snippet updates SNAMEs in CPPs and ER polygons to current Biotics dataset based on matching EO_IDs

import arcpy

eo_ptreps = r"https://gis.waterlandlife.org/server/rest/services/PNHP/Biotics_READ_ONLY/FeatureServer/0"
cpp_core = r"https://gis.waterlandlife.org/server/rest/services/PNHP/CPP_EDIT/FeatureServer/0"
cpp_supporting = r"https://gis.waterlandlife.org/server/rest/services/PNHP/CPP_EDIT/FeatureServer/1"
current_er = r"W:\Heritage\Heritage_Data\Environmental_Review\_ER_POLYS\ER_Polys.gdb\PA_ERPOLY_ALL_20250123_albers"

# create dictionary of EOID and SNAME from current biotics layer
eo_dict = {row[0]: row[1] for row in arcpy.da.SearchCursor(eo_ptreps, ["EO_ID", "SNAME"]) if
                    row[0] is not None}

print("checking the ER polys")
# update ER polygons with current names
with arcpy.da.UpdateCursor(current_er, ["EOID", "SNAME"]) as cursor:
    for row in cursor:
        for k, v in eo_dict.items():
            if k == row[0] and row[1] != v:
                print("changing sname from "+row[1]+" to " + v)
                row[1] = v
                cursor.updateRow(row)
        else:
            pass

print("checking the CPP cores")
# update CPP core polygons with current names
with arcpy.da.UpdateCursor(cpp_core, ["EO_ID", "SNAME"]) as cursor:
    for row in cursor:
        for k, v in eo_dict.items():
            if k == row[0] and row[1] != v:
                print("changing sname from "+row[1]+" to " + v)
                row[1] = v
                cursor.updateRow(row)
        else:
            pass

print("checking the CPP supporting polys")
# update CPP core polygons with current names
with arcpy.da.UpdateCursor(cpp_supporting, ["EO_ID", "SNAME"]) as cursor:
    for row in cursor:
        for k, v in eo_dict.items():
            if k == row[0] and row[1] != v:
                print("changing sname from "+row[1]+" to " + v)
                row[1] = v
                cursor.updateRow(row)
        else:
            pass