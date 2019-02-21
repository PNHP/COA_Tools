#-------------------------------------------------------------------------------
# Name:        6_Threats.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-02-20
#
# Updates:
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

## Threats
threats <- read.csv(here("_data","input","lu_threats.csv"), stringsAsFactors=FALSE)
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_threats", threats, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(threats)
