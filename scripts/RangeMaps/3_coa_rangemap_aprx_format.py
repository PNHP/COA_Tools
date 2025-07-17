import arcpy, os, shutil

# Paths to your .aprx file and feature classes
aprx_template = r'H:\Scripts\COA_Tools\_data\output\templates\SGCN_Projects.aprx'
aprx_path = r"H:\Scripts\COA_Tools\_data\output\_update2025q2\SGCN_Projects.aprx"
gdb_path = r"H:\Scripts\COA_Tools\_data\output\_update2025q2\sws.gdb"

# copy/paste template .aprx to output folder - NOTE: THIS OVERWRITES THE FILE IF IT ALREADY EXISTS!
shutil.copy(aprx_template, aprx_path)

# Desired fields
visible_fields = [
    'COUNTY_NAM', 'NAME', 'TaxaDisplay', 'SCOMNAME', 'SNAME', 'y', 'b', 'm', 'w',
    'Occurrence', 'GRANK', 'SRANK', 'USESA', 'SPROT', 'PBSSTATUS', 'PrimMacro', 'OBJECTID', 'Shape'
]

# Set the workspace to the geodatabase
arcpy.env.workspace = gdb_path
arcpy.env.overwriteOutput = True
temp_folder = os.path.join(os.path.dirname(aprx_path),"scratch_folder")
os.makedirs(temp_folder, exist_ok=True)

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
    for fc in fc_list:
        print("Working on layer '{0}': {1}/{2}".format(fc,progress,length))
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

        map_doc.removeLayer(layer)
        progress += 1


    print("Adding and formatting All Taxa layer.")
    layer = map_doc.addDataFromPath(all_taxa_fc)
    new_layer = map_doc.listLayers(layer.name)[-1]
    new_layer.name = "All Taxa"
    new_layer.visible = False

    aprx.save()

    print("Feature classes added and organized to '{0}' successfully!".format(map_frame_name))


map_frame_county = "SGCN County Range Maps"
map_frame_huc = "SGCN Watershed Range Maps"
fc_county = [os.path.join(gdb_path, fc) for fc in sorted(arcpy.ListFeatureClasses("county_*"))]
fc_huc = [os.path.join(gdb_path, fc) for fc in sorted(arcpy.ListFeatureClasses("HUC8_*"))]
alltaxa_county = os.path.join(gdb_path,"_county_SGCN")
alltaxa_huc = os.path.join(gdb_path,"_HUC8_SGCN")

format_map_doc(map_frame_county,fc_county,alltaxa_county)
format_map_doc(map_frame_huc,fc_huc,alltaxa_huc)