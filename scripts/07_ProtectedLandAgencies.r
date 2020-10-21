#-------------------------------------------------------------------------------
# Name:        5_ProtectedLandAgencies.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-02-20
#
# Updates:
#
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())



if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

## Protected Land
ProtectedLands <- read.csv(here::here("_data","input","lu_ProtectedLands_25.csv"), stringsAsFactors=FALSE)
trackfiles("Protected Lands", here::here("_data","input","lu_ProtectedLands_25.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_ProtectedLands_25", ProtectedLands, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(ProtectedLands)

## Agency Districts
AgencyDistricts <- read.csv(here::here("_data","input","lu_AgencyDistricts.csv"), stringsAsFactors=FALSE)
trackfiles("AgencyDistricts", here::here("_data","input","lu_AgencyDistricts.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_AgencyDistricts", AgencyDistricts, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(AgencyDistricts)

## PGC Regions
PGC_RegionName <- read.csv(here::here("_data","input","lu_PGC_RegionName.csv"), stringsAsFactors=FALSE)
trackfiles("PGC Regions", here::here("_data","input","lu_PGC_RegionName.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_PGC_RegionName", PGC_RegionName, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(PGC_RegionName)

