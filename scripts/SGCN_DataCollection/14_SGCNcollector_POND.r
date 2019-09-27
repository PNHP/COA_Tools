#---------------------------------------------------------------------------------------------
# Name: 1_SGCNcollector_BioticsCPP.r
# Purpose: 
# Author: Christopher Tracey
# Created: 2019-03-11
# Updated: 2018-03-23
#
# Updates:
# insert date and info
# * 2018-03-21 - get list of species that are in Biotics
# * 2018-03-23 - export shapefiles
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------

# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
require(RSQLite)

source(here("scripts","SGCN_DataCollection","00_PathsAndSettings.r"))


######################################################################################
# read in SGCN data
loadSGCN()

