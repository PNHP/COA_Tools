#-------------------------------------------------------------------------------
# Name:        03a_insertSpeciesAccountPages.r
# Purpose:     
# Author:      mmoore
# Created:     2022-07-11
# Updates:
#
#
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if(!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

##############################################################################################################
# load lu_sgcn for latter integrity checks
loadSGCN()
##############################################################################################################
## load in Species Account Pages csv
SpeciesAccountPages <- read.csv(here::here("_data","input","lu_SpeciesAccountPages.csv"), stringsAsFactors=FALSE)
sgcn_SpeciesAccountPages <- setdiff(SpeciesAccountPages$ELCODE, lu_sgcn$ELCODE)
print("The following ELCODE records are found in the SpeciesAccountPages table, but do not have matching records in the lu_sgcn table: ")
print(sgcn_SpeciesAccountPages)

trackfiles("Species Account Pages", here::here("_data","input","lu_SpeciesAccountPages.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SpeciesAccountPages", SpeciesAccountPages, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

