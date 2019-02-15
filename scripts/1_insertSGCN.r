#-------------------------------------------------------------------------------
# Name:        1_insertSGCN.r
# Purpose:     Create an empty, new COA databases
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

## Read SGCN list in
SGCN <- read.csv(here("_data","input","lu_sgcn.csv"), stringsAsFactors=FALSE) # read in the SGCN list
# delete unneeded columns
drops <- c("OBJECTID","GlobalID","created_user","created_date","last_edited_user","last_edited_date")
SGCN <- SGCN[ , !(names(SGCN) %in% drops)]
rm(drops)

# connect to the database
db <- dbConnect(SQLite(), dbname=databasename)
# write the table to the sqlite
dbWriteTable(db, "lu_SGCN", SGCN, overwrite=TRUE)
# disconnect the db
dbDisconnect(db)

## Taxa Group import
taxagrp <- read.csv(here("_data","input","lu_taxagrp.csv"), stringsAsFactors=FALSE)
taxagrp$OID <- NULL

# connect to the database
db <- dbConnect(SQLite(), dbname=databasename)
# write the table to the sqlite
dbWriteTable(db, "lu_taxgrp", taxagrp, overwrite=TRUE)
# disconnect the db
dbDisconnect(db)

