#-------------------------------------------------------------------------------
# Name:        4_habitats.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-02-15
# Updated:     2019-02-20
#
# Updates:
# * added priamry macrogroups
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

## Specific Habitat Requirements
SpecificHabitatReq <- read.csv(here("_data","input","lu_SpecificHabitatReq.csv"), stringsAsFactors=FALSE)
SpecificHabitatReq <- SpecificHabitatReq[c("ELSEASON","SNAME","SCOMNAME","Group","SpecificHabitatRequirements" )]
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SpecificHabitatReq", SpecificHabitatReq, overwrite=TRUE) # write the table to the sqlite
  dbDisconnect(db) # disconnect the db
SpecificHabitatReq_NeedInfo <- SpecificHabitatReq[which(SpecificHabitatReq$SpecificHabitatRequirements==""),] # get a list of sgcn of species without specific habitat requirements
write.csv(SpecificHabitatReq_NeedInfo, here("_data","output","needInfo_SpecificHabReq.csv"), row.names=FALSE)
write.csv(as.data.frame(table(SpecificHabitatReq_NeedInfo$Group)), here("_data","output","needInfo_SpecificHabSpecies.csv"), row.names=FALSE)
rm(SpecificHabitatReq, SpecificHabitatReq_NeedInfo)

## Primary Macrogroups
PrimaryMacrogroup <- read.csv(here("_data","input","lu_PrimaryMacrogroup.csv"), stringsAsFactors=FALSE)
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_PrimaryMacrogroup", PrimaryMacrogroup, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## Habitat Names
HabitatName <- read.csv(here("_data","input","lu_HabitatName.csv"), stringsAsFactors=FALSE)
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_HabitatName", HabitatName, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## Terrestrial Habitat Layer
HabTerr <- read.csv(here("_data","input","lu_HabTerr.csv"), stringsAsFactors=FALSE)
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_HabTerr", HabTerr, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## Lotic Habitat Layer
HabLotic <- read.csv(here("_data","input","lu_LoticData.csv"), stringsAsFactors=FALSE)
HabLotic <- HabLotic[c("unique_id","COMID","GNIS_NAME","SUM_23","DESC_23","MACRO_GR","Shape_Length")]
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_LoticData", HabLotic, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## Special Habitats - caves and seasonal pools
HabSpecial <- read.csv(here("_data","input","lu_SpecialHabitats.csv"), stringsAsFactors=FALSE)
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SpecialHabitats", HabSpecial, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db




