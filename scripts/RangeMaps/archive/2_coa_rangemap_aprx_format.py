import arcpy, os

# Paths to your .aprx file and feature classes
aprx_path = r"H:\Scripts\COA_Tools\_data\output\_update2024q4\SGCN_Projects.aprx"
gdb_path = r"H:\Scripts\COA_Tools\_data\output\_update2024q4\sws.gdb"

# Set the workspace to the geodatabase
arcpy.env.workspace = gdb_path
arcpy.env.overwriteOutput = True

def taxa_assign(path):
    with arcpy.da.SearchCursor(path, ["SCOMNAME", "TaxaDisplay"]) as cursor:
        for row in cursor:
            scomname, taxa = row
            if taxa and taxa.startswith("Invertebrate - "):
                taxa = taxa.replace("Invertebrate - ", "")
            elif taxa in ["Bird", "Frog", "Lizard", "Mammal", "Salamander", "Snake", "Turtle"]:
                taxa += "s"
            elif taxa == "Fish":
                taxa += "es"
            else:
                print(f"Unknown taxa: {taxa}")
            return [scomname, taxa]
        return [None, None]

def format_map_doc(map_frame_name, fc_list, all_taxa_fc):
    # Open the ArcGIS Pro project
    aprx = arcpy.mp.ArcGISProject(aprx_path)

    # Access the first map (modify if needed)
    map_doc = aprx.listMaps(map_frame_name)[0]  # Adjust if you have multiple maps

    # Dictionary to store layers by group
    group_layers = {lyr.name: lyr for lyr in map_doc.listLayers() if lyr.isGroupLayer}

    length = len(fc_list)
    progress = 1

    # Iterate through feature classes
    for fc in fc_county_paths:
        print(str(progress)+"/"+str(length))
        # Add the feature class as a layer
        layer = map_doc.addDataFromPath(fc)

        new_name, group_name = taxa_assign(layer)

        # Check if the group layer exists
        if group_name in group_layers:
            group_layer = group_layers[group_name]

            # Add the layer to the group layer
            map_doc.addLayerToGroup(group_layer, layer, "BOTTOM")

            # Rename the layer
            new_layer = map_doc.listLayers(layer.name)[-1]  # Get the newly added layer
            new_layer.name = new_name
            new_layer.visible = False

            # Store sort order as a custom property (optional)
            #new_layer.customProperty = sort_order

            # Desired fields
            visible_fields = [
                'COUNTY_NAM', 'NAME', 'TaxaDisplay', 'SCOMNAME', 'SNAME', 'y', 'b', 'm', 'w',
                'Occurrence', 'GRANK', 'SRANK', 'USESA', 'SPROT', 'PBSSTATUS', 'PrimMacro', 'OBJECTID', 'Shape'
            ]

            fields = arcpy.ListFields(new_layer)
            for field in fields:
                if field.name not in visible_fields:
                    layer.fields.remove(field.name)

        map_doc.removeLayer(layer)
        progress += 1

    aprx.save()

    print("Feature classes added and organized successfully!")




fc_county = sorted(arcpy.ListFeatureClasses("county_*"))
fc_county_paths = []
for f in fc_county:
    path = os.path.join(gdb_path,f)
    fc_county_paths.append(path)