#---------------------------------------------------------------------------------------------
# Name: 14_SGCNcollector_POND.r
# Purpose: 
# Author: Molly Moore
# Created: 2019-10-01
# Updated: 
#
# Updates:
#
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------

#load packages
if (!requireNamespace("arcgisbinding", quietly=TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("dplyr", quietly=TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("sf", quietly=TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("plyr", quietly = TRUE)) install.packages("plyr")
require(plyr)

#get paths listed in pathes and settings script
source(here("scripts","SGCN_DataCollection","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()

#paths to POND feature service layers
pond_pts <- 'https://maps.waterlandlife.org/arcgis/rest/services/PNHP/POND/FeatureServer/0'
pond_species <- 'https://maps.waterlandlife.org/arcgis/rest/services/PNHP/POND/FeatureServer/3'

#put in code to load lu_sgcn from sqlite db and create list of sgcn

arc.check_product()

s <- arc.open(pond_species)
species <- arc.select(s) #add code to load only sgcn species from lu_sgcn list

#create list of wpc_ids 

#load in pond_pts

#merge pond_pts with species

#add coa information like season, el_season, data source, data code, etc.

