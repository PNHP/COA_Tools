import arcpy, os

arcpy.env.overwriteOutput = True

def taxa_assign(path):
    with arcpy.da.SearchCursor(path, ["SCOMNAME", "TaxaDisplay"]) as cursor:
        for row in cursor:
            scomname, taxa = row
            if taxa and taxa.startswith("Invertebrate - "):
                taxa = taxa.replace("Invertebrate - ", "")
            elif taxa in ["Bird", "Fish", "Frog", "Lizard", "Mammal", "Salamander", "Snake", "Turtle"]:
                taxa += "s"
            else:
                print(f"Unknown taxa: {taxa}")
            return [scomname, taxa]
        return [None, None]

# Paths to your .aprx file and feature classes
aprx_path = r"H:\Scripts\COA_Tools\_data\output\_update2024q4\SGCN_Projects.aprx"
gdb_path = r"H:\Scripts\COA_Tools\_data\output\_update2024q4\sws.gdb"

# Set the workspace to the geodatabase
arcpy.env.workspace = gdb_path

# Field names
group_field = "TaxaDisplay"  # Attribute to determine group layer
name_field = "SCOMNAME"  # Attribute to rename the layer
order_field = "ELCODE"  # Attribute for ordering layers

# Open the ArcGIS Pro project
aprx = arcpy.mp.ArcGISProject(aprx_path)

# Access the first map (modify if needed)
maps = aprx.listMaps()
map_doc = aprx.listMaps("SGCN County Range Maps")[0]  # Adjust if you have multiple maps

# Dictionary to store layers by group
group_layers = {lyr.name: lyr for lyr in map_doc.listLayers() if lyr.isGroupLayer}

fc_county = sorted(arcpy.ListFeatureClasses("county_*"))
fc_county_paths = []
for f in fc_county:
    path = os.path.join(gdb_path,f)
    fc_county_paths.append(path)

# Iterate through feature classes
for fc in fc_county:
    # Add the feature class as a layer
    layer = map_doc.addDataFromPath(fc)

    new_name, group_name = taxa_assign(layer)

    # Access the required attributes
    with arcpy.da.SearchCursor(fc, [order_field]) as cursor:
        for row in cursor:
            sort_order = row[0]  # Order within the group

    # Check if the group layer exists
    if group_name in group_layers:
        group_layer = group_layers[group_name]

        # Add the layer to the group layer
        map_doc.addLayerToGroup(group_layer, layer, "BOTTOM")

        # Rename the layer
        new_layer = map_doc.listLayers(layer.name)[-1]  # Get the newly added layer
        new_layer.name = new_name

        # Store sort order as a custom property (optional)
        new_layer.customProperty = sort_order

# Sort layers within each group
for group_layer in group_layers.values():
    # Get all layers in the group
    layers_in_group = [
        lyr for lyr in map_doc.listLayers() if lyr.longName.startswith(group_layer.longName)
    ]

    # Sort by the attribute used for ordering (alphabetically)
    sorted_layers = sorted(layers_in_group, key=lambda lyr: lyr.customProperty.lower())  # Ensure case-insensitivity

    # Reorder layers in the group
    for i, layer in enumerate(sorted_layers):
        map_doc.moveLayer(group_layer, layer, "BOTTOM")

# Save the changes
aprx.save()

print("Feature classes added and organized successfully!")
