#-------------------------------------------------------------------------------
# Name:        8_Indexes.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-04-09
# Updated:     
#
# To Do List/Future ideas:
# * 
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

olddatabasename <- "coa_bridgetest_previous.sqlite" 
olddatabasename <- here::here("_data","output",olddatabasename)


db <- dbConnect(SQLite(), dbname=olddatabasename) # connect to the database
sgcnXpu <- dbReadTable(db, "lu_sgcnXpu_all") # write the table to the sqlite
dbDisconnect(db) # disconnect the db



CREATE INDEX habitat ON lu_HabTerr (unique_id, Code);
CREATE INDEX habitataq ON lu_LoticData (unique_id, SUM_23);
CREATE INDEX maindex ON lu_sgcnXpu_all (unique_id,ELSeason);
CREATE INDEX muni ON lu_muni (unique_id);
CREATE INDEX natbound ON lu_NaturalBoundaries (unique_id);
CREATE INDEX proland ON lu_ProtectedLands_25 (unique_id);
CREATE INDEX threats ON lu_threats (unique_id);




