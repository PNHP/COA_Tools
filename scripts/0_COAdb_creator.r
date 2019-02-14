#-------------------------------------------------------------------------------
# Name:        0_COAdb_creator.r
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

## create an empty sqlite db

# Set input paths ----
databasename <- "coa_bridgetest.sqlite" 
databasename <- here("_data","output",databasename)

# connect to the database
db <- dbConnect(SQLite(), dbname=databasename)



# disconnect the db
dbDisconnect(db)
