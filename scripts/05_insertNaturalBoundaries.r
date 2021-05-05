#-------------------------------------------------------------------------------
# Name:        2a_insertNaturalBoundaries.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-02-20
# Updated:     
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

## Natural Boundaries
NaturalBoundaries <- read.csv(here::here("_data","input","lu_NaturalBoundaries.csv"), stringsAsFactors=FALSE)
# newHUC <- read.csv(here::here("_data","input","lu_HUCsNEW.csv"), stringsAsFactors=FALSE, colClasses=c("huc12"="character", "huc8"="character"))
# newHUC <- newHUC[c("unique_id", "huc8", "huc12")]
# NaturalBoundaries <- NaturalBoundaries[c("unique_id","PROVINCE","SECTION_","ECO_NAME","huc8","huc12")]
# NaturalBoundaries <- merge(NaturalBoundaries, newHUC, by="unique_id", all.y=TRUE)
# setdiff(HUCname$HUC8,unique(NaturalBoundaries$HUC8))
# setdiff(unique(NaturalBoundaries$HUC8), HUCname$HUC8)
# setdiff(HUCname$HUC12,unique(NaturalBoundaries$HUC12))
# setdiff(unique(NaturalBoundaries$HUC12), HUCname$HUC12)
trackfiles("natural boundaries", here::here("_data","input","lu_NaturalBoundaries.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_NaturalBoundaries", NaturalBoundaries, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(NaturalBoundaries)

## HUC names
HUCname <- read.csv(here::here("_data","input","lu_HUCname.csv"), stringsAsFactors=FALSE, colClasses=c("HUC12"="character", "HUC8"="character"))
HUCname <- HUCname[order(HUCname$HUC12name),]
trackfiles("HUC names lookup", here::here("_data","input","lu_HUCname.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_HUCname", HUCname, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(HUCname)

