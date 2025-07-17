"""
Name: COA Range Map .aprx Creator
Purpose: Takes sws.gdb geodatabase of COA range feature classes and loads and formats layers in the COA range map
template .aprx.
Author: Molly Moore for Pennsylvania Natural Heritage Program
Created Date: 2025-01-14
"""

import arcpy, os, sys, datetime

current_time = datetime.datetime.now()
print(current_time.strftime("%Y-%m-%d %H:%M:%S"))

############## CHANGE PATH BELOW !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# set folder where sws.gdb and .aprx files are included
folder = r'H:\Scripts\COA_Tools\_data\output\_update2025q2'
gdb_name = "sws.gdb"
db = os.path.join(folder, gdb_name)

# Desired fields
desiredFields = [
    'COUNTY_NAM', 'NAME', 'TaxaDisplay', 'SCOMNAME', 'SNAME', 'y', 'b', 'm', 'w',
    'Occurrence', 'GRANK', 'SRANK', 'USESA', 'SPROT', 'PBSSTATUS', 'PrimMacro', 'OBJECTID', 'Shape'
]

# DEFINE FUNCTIONS BELOW
# Function to update field aliases
def update_field_aliases(feature_class):
    alias_map = {
        "COUNTY_NAM": "County Name",
        "NAME": "Watershed Name",
        "TaxaDisplay": "Taxonomic Group",
        "SCOMNAME": "Common Name",
        "SNAME": "Scientific Name",
        "b": "Breeding (B) Species of Greatest Conservation Need",
        "m": "Migratory (M) Species of Greatest Conservation Need",
        "w": "Wintering (W) Species of Greatest Conservation Need",
        "y": "Year-round Species of Greatest Conservation Need",
        "Occurrence": "Occurrence",
        "GRANK": "Global Rank",
        "SRANK": "State Rank",
        "USESA": "Federal Status",
        "SPROT": "State Status",
        "PBSSTATUS": "Pennsylvania Biological Survey Status",
        "PrimMacro": "Primary Habitat",
    }
    try:
        fields = {field.name: field for field in arcpy.ListFields(feature_class)}
        for field_name, alias in alias_map.items():
            if field_name in fields and fields[field_name].aliasName != alias:
                arcpy.AlterField_management(
                    feature_class,
                    field_name,
                    new_field_name=field_name,
                    new_field_alias=alias
                )
    except Exception as e:
        print(f"Error processing {feature_class}: {e}")


arcpy.env.workspace = db
# List all feature classes in the geodatabase
feature_classes = arcpy.ListFeatureClasses()
length = len(feature_classes)
number = 1
for fc in feature_classes:
    print("Updating field aliases for: " + fc + ": "+str(number)+"/"+str(length))
    path = os.path.join(db, fc)
    update_field_aliases(path)
    number += 1

current_time = datetime.datetime.now()
print(current_time.strftime("%Y-%m-%d %H:%M:%S"))
