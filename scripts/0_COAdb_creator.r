#-------------------------------------------------------------------------------
# Name:        0_COAdb_creator.r
# Purpose:     Create an empty, new COA databases
# Author:      Christopher Tracey
# Created:     2019-02-14
# Updated:     2019-02-20
#
# Updates:
# * 2019-02-20 - minor cleanup and documentation
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------
# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

# create an empty sqlite db
# connect to the database
db <- dbConnect(SQLite(), dbname=databasename) # creates an empty COA database

# disconnect the db
dbDisconnect(db)
