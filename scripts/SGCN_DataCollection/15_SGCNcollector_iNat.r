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
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("rinat", quietly = TRUE)) install.packages("rinat")
require(rinat)

source(here::here("scripts","00_PathsAndSettings.r"))

# load the r data file
load(file=updateData)

# read in SGCN data
loadSGCN()

a <- list()
for(i in 1:length(sgcnlist[1:2])) {
  a[i] <- get_inat_obs(taxon_name=sgcnlist[i], year = 2019)
}


