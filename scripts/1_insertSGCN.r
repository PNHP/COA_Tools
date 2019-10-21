#-------------------------------------------------------------------------------
# Name:        1_insertSGCN.r
# Purpose:     Create an empty, new COA databases
# Author:      Christopher Tracey
# Created:     2019-02-14
# Updated:     2019-02-14
#
# To Do List/Future ideas:
# * modify to run off the lu_sgcn data on the arc server
#-------------------------------------------------------------------------------

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

# # Set input paths ----
# databasename <- "coa_bridgetest.sqlite" 
# databasename <- here::here("_data","output",databasename)

## Read SGCN list in
SGCN <- read.csv(here::here("_data","input","lu_sgcn.csv"), stringsAsFactors=FALSE) # read in the SGCN list
drops <- c("OBJECTID","GlobalID","created_user","created_date","last_edited_user","last_edited_date") # delete unneeded columns
SGCN <- SGCN[ , !(names(SGCN) %in% drops)]
rm(drops)

# QC to make sure that the ELCODES match the first part of the ELSeason code.
if(length(setdiff(SGCN$ELCODE, gsub("(.+?)(\\_.*)", "\\1", SGCN$ELSeason)))==0){
  print("ELCODEs and ELSeason strings match")
} else {
  print(paste("Codes for ", setdiff(SGCN$ELCODE, gsub("(.+?)(\\_.*)", "\\1", SGCN$ELSeason)), "do not match", sep=""))
}

# write the lu_sgcn table to the database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SGCN", SGCN, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(SGCN)

## Taxa Group import
taxagrp <- read.csv(here::here("_data","input","lu_taxagrp.csv"), stringsAsFactors=FALSE)
taxagrp$OID <- NULL

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_taxagrp", taxagrp, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(taxagrp)

