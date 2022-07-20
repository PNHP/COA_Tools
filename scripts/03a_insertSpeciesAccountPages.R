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

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

## load in Species Account Pages csv
SpeciesAccountPages <- read.csv(here::here("_data","input","lu_SpeciesAccountPages.csv"), stringsAsFactors=FALSE)
trackfiles("Species Account Pages", here::here("_data","input","lu_SpeciesAccountPages.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SpeciesAccountPages", SpeciesAccountPages, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
