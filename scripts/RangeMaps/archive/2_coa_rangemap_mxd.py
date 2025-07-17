#-------------------------------------------------------------------------------
# Name:        COA Range Map .mxd Creator
# Purpose:     Takes geodatabase of COA range feature classes and loads and
#              formats layers in the COA range template .mxd.
#
# Author:      MollyMoore
#
# Created:     15/11/2018
#-------------------------------------------------------------------------------

#!!!!!!!!!!!CHANGE PATH BELOW!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# set folder where sws gdb and .mxds are included
folder = r'H:\Scripts\COA_Tools\_data\output\_update2024q4'
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
desiredFields = ['COUNTY_NAM','NAME','TaxaDisplay', 'SCOMNAME', 'SNAME', 'y', 'b', 'm', 'w', 'Occurrence', 'GRANK', 'SRANK', 'USESA', 'SPROT', 'PBSSTATUS', 'PrimMacro', 'OBJECTID', 'Shape']
######################################################################################################################################################
#import modules
import arcpy, os, datetime, sys
##################################### PATHS/VARIABLES THAT SHOULD STAY CONSTANT ######################################################################
gdb_name = "sws.gdb"
county_mxd_template = "SGCNCountyRangeMaps.mxd"
watershed_mxd_template = "SGCNWatershedRangeMaps.mxd"

db = os.path.join(folder,gdb_name)
county_mxd = os.path.join(folder,county_mxd_template)
huc_mxd = os.path.join(folder,watershed_mxd_template)
######################################################################################################################################################
def taxa_assign(path):
    print(path)
    with arcpy.da.SearchCursor(path,["SCOMNAME","TaxaDisplay"]) as cursor:
        for row in cursor:
            scomname = row[0]
            taxa = row[1]
    if taxa is None or scomname is None:
        pass
    else:
        if taxa == "Bird":
            taxa = "Birds"
        elif taxa == "Fish":
            taxa = "Fishes"
        elif taxa == "Frog":
            taxa = "Frogs"
        elif taxa == "Invertebrate - Bees":
            taxa = "Bees"
        elif taxa == "Invertebrate - Beetles":
            taxa = "Beetles"
        elif taxa == "Invertebrate - Butterflies":
            taxa = "Butterflies"
        elif taxa == "Invertebrate - Caddisflies":
            taxa = "Caddisflies"
        elif taxa == "Invertebrate - Cave Invertebrates":
            taxa = "Cave Invertebrates"
        elif taxa == "Invertebrate - Craneflies":
            taxa = "Craneflies"
        elif taxa == "Invertebrate - Crayfishes":
            taxa = "Crayfishes"
        elif taxa == "Invertebrate - Dragonflies and Damselflies":
            taxa = "Dragonflies and Damselflies"
        elif taxa == "Invertebrate - Freshwater Snails":
            taxa = "Freshwater Snails"
        elif taxa == "Invertebrate - Grasshoppers":
            taxa = "Grasshoppers"
        elif taxa == "Invertebrate - Mayflies":
            taxa = "Mayflies"
        elif taxa == "Invertebrate - Moths":
            taxa = "Moths"
        elif taxa == "Invertebrate - Mussels":
            taxa = "Mussels"
        elif taxa == "Invertebrate - Sawflies":
            taxa = "Sawflies"
        elif taxa == "Invertebrate - Spiders":
            taxa = "Spiders"
        elif taxa == "Invertebrate - Sponges":
            taxa = "Sponges"
        elif taxa == "Invertebrate - Stoneflies":
            taxa = "Stoneflies"
        elif taxa == "Invertebrate - Terrestrial Snails":
            taxa = "Terrestrial Snails"
        elif taxa == "Invertebrate - True bugs":
            taxa = "True Bugs"
        elif taxa == "Lizard":
            taxa = "Lizards"
        elif taxa == "Mammal":
            taxa = "Mammals"
        elif taxa == "Salamander":
            taxa = "Salamanders"
        elif taxa == "Snake":
            taxa = "Snakes"
        elif taxa == "Turtle":
            taxa = "Turtles"
        else:
            print("Taxa is not in this list!")
    return [scomname,taxa]

def taxa_layer_check(mxd,df_name,fc):
    mxd = arcpy.mapping.MapDocument(mxd)
    df = arcpy.mapping.ListDataFrames(mxd)[0]
    taxa_list = []
    null_list = []
    print("Checking for null attributes in all feature classes and checking for group layers in the template .mxds")
    for f in fc:
        path = os.path.join(db,f)
        t = taxa_assign(path)
        taxa = t[1]
        if taxa is None:
            null_list.append(f)
        if taxa is not None and taxa not in taxa_list:
            taxa_list.append(taxa)
    lyr_list = []
    for lyr in arcpy.mapping.ListLayers(mxd):
        lyr_list.append(lyr.name)

    diff = list(set(taxa_list).difference(lyr_list))

    if null_list:
        print("The following files have null attributes: "+ str(null_list))

    if not diff:
        print("Layers look good! Moving on to next steps.")
        pass
    else:
        print(str(diff)+" is/are not included in your .mxd group layers. Add to layers and try again")
        sys.exit()

def edit_attributes(path):
    if len(arcpy.ListFields(path,"COUNTY_NAM"))>0:
        arcpy.AlterField_management(path,"COUNTY_NAM",new_field_name="COUNTY_NAM",new_field_alias="County Name")
    elif len(arcpy.ListFields(path,"NAME"))>0:
        arcpy.AlterField_management(path,"NAME",new_field_name="NAME",new_field_alias="Watershed Name")
    else:
        pass
    arcpy.AlterField_management(path,"TaxaDisplay",new_field_alias="Taxonomic Group")
    arcpy.AlterField_management(path,"SCOMNAME",new_field_alias="Common Name")
    arcpy.AlterField_management(path,"SNAME",new_field_alias="Scientific Name")
    arcpy.AlterField_management(path,"b",new_field_alias="Breeding (B) Species of Greatest Conservation Need")
    arcpy.AlterField_management(path,"m",new_field_alias="Migratory (M) Species of Greatest Conservation Need")
    arcpy.AlterField_management(path,"w",new_field_alias="Wintering (W) Species of Greatest Conservation Need")
    arcpy.AlterField_management(path,"y",new_field_alias="Year-round Species of Greatest Conservation Need")
    arcpy.AlterField_management(path,"Occurrence",new_field_alias="Occurrence")
    arcpy.AlterField_management(path,"GRANK",new_field_alias="Global Rank")
    arcpy.AlterField_management(path,"SRANK",new_field_alias="State Rank")
    arcpy.AlterField_management(path,"USESA",new_field_alias="Federal Status")
    arcpy.AlterField_management(path,"SPROT",new_field_alias="State Status")
    arcpy.AlterField_management(path,"PBSSTATUS",new_field_alias="Pennsylvania Biological Survey Status")
    arcpy.AlterField_management(path,"PrimMacro",new_field_alias="Primary Habitat")

def format_mxd(mxd,df_name,fc,alltaxa):
    mxd = arcpy.mapping.MapDocument(mxd)
    df = arcpy.mapping.ListDataFrames(mxd)[0]
    df.name = df_name

    total = len(fc)
    n = 1
    for f in fc:
        print(f+" "+str(n)+r'/'+str(total))
        path = os.path.join(db,f)
        t = taxa_assign(path)
        scomname = t[0]
        taxa = t[1]
        edit_attributes(f) # added by ct
        #change layer name to scomname, turn off layer, and add to taxa group
        if scomname is None or taxa is None:
            pass
            n+=1
        else:
            targetGroupLayer = arcpy.mapping.ListLayers(mxd,taxa,df)[0]
            addLayer = arcpy.mapping.Layer(path)
##            addLayer.name = scomname
            addLayer.visible = False
            arcpy.mapping.AddLayerToGroup(df, targetGroupLayer, addLayer, "AUTO_ARRANGE")
            n+=1

    for layer in map_doc.listLayers():
        if layer.isFeatureLayer:  # Process only feature layers
            print(f"Processing layer: {layer.name}")

            # Describe the layer to get field information
            field_info = arcpy.Describe(layer).fieldInfo

            # Modify field visibility
            for i in range(0, field_info.count):
                field_name = field_info.getFieldName(i)
                if field_name not in desired_fields:
                    field_info.setVisible(i, 'HIDDEN')

            # Apply the updated field info to the layer using MakeFeatureLayer
            arcpy.management.MakeFeatureLayer(
                layer.dataSource,
                layer.name,
                "",
                "",
                field_info
            )
            print(f"Updated fields for layer: {layer.name}")

    mxd.save()

    for lyr in arcpy.mapping.ListLayers(mxd):
        if not lyr.isGroupLayer:
            with arcpy.da.SearchCursor(lyr,'SCOMNAME') as cursor:
                for row in cursor:
                    scomname = row[0]
            lyr.name = scomname

    mxd.save()
    
    edit_attributes(alltaxa)
    targetGroupLayer = arcpy.mapping.ListLayers(mxd,"All Taxa",df)[0]
    addLayer = arcpy.mapping.Layer(alltaxa)
    addLayer.name = "All Taxa"
    addLayer.visible = False
    arcpy.mapping.AddLayerToGroup(df, targetGroupLayer, addLayer, "AUTO_ARRANGE")

    lyrs = arcpy.mapping.ListLayers(targetGroupLayer)
    for lyr in lyrs:
        if lyr.isFeatureLayer:
            field_info = arcpy.Describe(lyr).fieldInfo
            for i in range(0, field_info.count):
                if field_info.getfieldname(i) not in desiredFields:
                    field_info.setvisible(i, 'HIDDEN')
    mxd.save()

df_name_county = "SGCN County Range Maps"
df_name_huc = "SGCN Watershed Range Maps"
arcpy.env.workspace = db
fc_county = sorted(arcpy.ListFeatureClasses("county_*"))
fc_huc = sorted(arcpy.ListFeatureClasses("HUC8_*"))
alltaxa_county = os.path.join(db,"_county_SGCN")
alltaxa_huc = os.path.join(db,"_HUC8_SGCN")

#print("Checking layers for county .mxd...")
#taxa_layer_check(county_mxd,df_name_county,fc_county)
#print("Checking layers for huc .mxd...")
#taxa_layer_check(huc_mxd,df_name_huc,fc_huc)

format_mxd(county_mxd,df_name_county,fc_county,alltaxa_county)
format_mxd(huc_mxd,df_name_huc,fc_huc,alltaxa_huc)
