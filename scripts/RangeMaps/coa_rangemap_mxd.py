#-------------------------------------------------------------------------------
# Name:        COA Range Map .mxd Creator
# Purpose:     Takes geodatabase of COA range feature classes and loads and
#              formats layers in the COA range template .mxd.
#
# Author:      MollyMoore
#
# Created:     15/11/2018
#-------------------------------------------------------------------------------

#import modules
import arcpy, os, datetime

#set database where species range feature classes are
db = r'C:\_coa\range_maps\Updated_2019_02_28\sws.gdb'

#use this for county range maps - update paths
##mxd = r'C:\_coa\range_maps\Updated_2019_02_28\SGCNCountyRangeMaps.mxd'
##df_name = "SGCN County Range Maps"
##desiredFields = ['COUNTY_NAM','y_prop','b_prop','m_prop','w_prop','SCOMNAME','SNAME','TaxaDisplay','USESA','SPROT','PBSSTATUS','Shape','OBJECTID']

#use this for watershed range maps - update paths
mxd = r'C:\_coa\range_maps\Updated_2019_02_28\SGCNWatershedRangeMaps.mxd'
df_name = "SGCN Watershed Range Maps"
desiredFields = ['HUC08','NAME','COUNTY_NAM','y_prop','b_prop','m_prop','w_prop','SCOMNAME','SNAME','TaxaDisplay','USESA','SPROT','PBSSTATUS','Shape','OBJECTID']

#open mxd for editing
mxd = arcpy.mapping.MapDocument(mxd)
df = arcpy.mapping.ListDataFrames(mxd)[0]


arcpy.env.workspace = db
#use this for county range maps
##fc = arcpy.ListFeatureClasses("county*")
#use this for watershed range maps
fc = arcpy.ListFeatureClasses("huc08*")


total = len(fc)
n = 1

for f in fc:
    print(f+" "+str(n)+r'/'+str(total))
    path = os.path.join(db,f)
    with arcpy.da.SearchCursor(path,["SCOMNAME","TaxaDisplay"]) as cursor:
        for row in cursor:
            scomname = row[0]
            taxa = row[1]

    if taxa is None or scomname is None:
        print(f + " is null")
        pass
    else:
        arcpy.AlterField_management(path,"SCOMNAME",new_field_alias="Common Name")
        arcpy.AlterField_management(path,"SNAME",new_field_alias="Scientific Name")
        arcpy.AlterField_management(path,"TaxaDisplay",new_field_alias="Taxanomic Group")
        arcpy.AlterField_management(path,"USESA",new_field_alias="Federal Status")
        arcpy.AlterField_management(path,"SPROT",new_field_alias="State Status")
        arcpy.AlterField_management(path,"PBSSTATUS",new_field_alias="Pennsylvania Biological Survey Status")
        if len(arcpy.ListFields(path,"COUNTY_NAM"))>0:
            arcpy.AlterField_management(path,"COUNTY_NAM",new_field_alias="County Name")
            arcpy.AlterField_management(path,"y_prop",new_field_alias="Proportion of Year-Round Population")
            arcpy.AlterField_management(path,"b_prop",new_field_alias="Proportion of Breeding Population")
            arcpy.AlterField_management(path,"m_prop",new_field_alias="Proportion of Migration Population")
            arcpy.AlterField_management(path,"w_prop",new_field_alias="Proportion of Wintering Population")
        elif len(arcpy.ListFields(path,"NAME"))>0:
            arcpy.AlterField_management(path,"HUC8",new_field_alias="Watershed Code")
            arcpy.AlterField_management(path,"NAME",new_field_alias="Watershed Name")
            arcpy.AlterField_management(path,"y_prop",new_field_alias="Proportion of Year-Round Population")
            arcpy.AlterField_management(path,"b_prop",new_field_alias="Proportion of Breeding Population")
            arcpy.AlterField_management(path,"m_prop",new_field_alias="Proportion of Migration Population")
            arcpy.AlterField_management(path,"w_prop",new_field_alias="Proportion of Wintering Population")

        else:
            pass

        if taxa == "Bird":
            taxa = "Birds"
        if taxa == "Fish":
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
    ##    elif taxa == "Invertebrate - Craneflies":
    ##        taxa = "Craneflies"
        elif taxa == "Invertebrate - Crayfishes":
            taxa = "Crayfishes"
        elif taxa == "Invertebrate - Dragonflies and Damselflies":
            taxa = "Dragonflies and Damselflies"
        elif taxa == "Invertebrate - Freshwater Snails":
            taxa = "Freshwater Snails"
    ##    elif taxa == "Invertebrate - Grasshoppers":
    ##        taxa = "Grasshoppers"
        elif taxa == "Invertebrate - Mayflies":
            taxa = "Mayflies"
        elif taxa == "Invertebrate - Moths":
            taxa = "Moths"
        elif taxa == "Invertebrate - Mussels":
            taxa = "Mussels"
    ##    elif taxa == "Invertebrate - Sawflies":
    ##        taxa = "Sawflies"
    ##    elif taxa == "Invertebrate - Spiders":
    ##        taxa = "Spiders"
    ##    elif taxa == "Invertebrate - Sponges":
    ##        taxa = "Sponges"
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

        #change layer name to scomname, turn off layer, and add to taxa group
        targetGroupLayer = arcpy.mapping.ListLayers(mxd,taxa,df)[0]
        addLayer = arcpy.mapping.Layer(path)
        addLayer.name = scomname
        addLayer.visible = False
        arcpy.mapping.AddLayerToGroup(df, targetGroupLayer, addLayer, "AUTO_ARRANGE")
        df.name = df_name
        n+=1

#alphabetize layers within groups
group_lyrs = [lyr for lyr in arcpy.mapping.ListLayers(mxd) if lyr.isGroupLayer]
for group_lyr in group_lyrs:
    lyr_names = sorted(lyr.name for lyr in arcpy.mapping.ListLayers(group_lyr) if lyr.isFeatureLayer)
    ref_lyr = arcpy.mapping.ListLayers(group_lyr, lyr_names[0])[0]
    for name in lyr_names:
        if name != ref_lyr.name:
            arcpy.mapping.MoveLayer(df,ref_lyr,arcpy.mapping.ListLayers(group_lyr,name)[0], "AFTER")
            ref_lyr = arcpy.mapping.ListLayers(group_lyr,name)[0]

    for name in lyr_names:
        LayerNeedsFieldsTurnedOff = arcpy.mapping.ListLayers(mxd,name,df)[0]
        field_info = arcpy.Describe(LayerNeedsFieldsTurnedOff).fieldInfo
        for i in range(field_info.count):
            if field_info.getfieldname(i) not in desiredFields:
                field_info.setvisible(i,'HIDDEN')
        arcpy.MakeFeatureLayer_management(LayerNeedsFieldsTurnedOff,'temp_layer','','',field_info)
        refLyr = arcpy.mapping.Layer("temp_layer")
        arcpy.ApplySymbologyFromLayer_management(refLyr,LayerNeedsFieldsTurnedOff)
        arcpy.mapping.UpdateLayer(df,LayerNeedsFieldsTurnedOff,refLyr,False)
        refLyr.name = name
        refLyr.visible = False
        arcpy.Delete_management('temp_layer')
        del LayerNeedsFieldsTurnedOff,refLyr

mxd.save()
