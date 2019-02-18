#-------------------------------------------------------------------------------
# Name:        2_insertCountyMuni.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-02-14
# Updated:     2019-02-14
#
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)

# Set input paths ----
databasename <- "coa_bridgetest.sqlite" 
databasename <- here("_data","output",databasename)

## county names
CountyName <- read.csv(here("_data","input","lu_CountyName.csv"), stringsAsFactors=FALSE)
CountyName <- CountyName[order(CountyName$COUNTY_NAM),]
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_CountyName", CountyName, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

rm(CountyName)

## municipal names
MuniName <- read.csv(here("_data","input","lu_muni_names.csv"), stringsAsFactors=FALSE)
MuniName <- MuniName[order(MuniName$Name_Proper_Type),]

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_muni_names", MuniName, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

rm(MuniName)