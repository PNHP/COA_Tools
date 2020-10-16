#-------------------------------------------------------------------------------
# Name:        4_habitats.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-02-15
# Updated:     2019-02-20
#
# Updates:
# * added primary macrogroups
#
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
  require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

## Specific Habitat Requirements
#get the habitat template
SpecificHab_file <- list.files(path=here::here("_data/input"), pattern=".xlsx$")  # --- make sure your excel file is not open.
SpecificHab_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 2
SpecificHab_file <- here::here("_data/input", SpecificHab_file[n])

trackfiles("Specific Habitats", SpecificHab_file) # write to file tracker

#get a list of the sheets in the file
SpecificHab_sheets <- getSheetNames(SpecificHab_file)
#look at the output and choose which excel sheet you want to load
# Enter the habitat sheet (eg. "lu_actionsLevel2") 
SpecificHab_sheets # list the sheets
n <- 6 # enter its location in the list (first = 1, second = 2, etc)
SpecificHabitatReq <- read.xlsx(xlsxFile=SpecificHab_file, sheet=SpecificHab_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)
SpecificHabitatReq <- SpecificHabitatReq[c("ELSEASON","SNAME","SCOMNAME","Group","SpecificHabitatRequirements" )]

# write to the database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SpecificHabitatReq", SpecificHabitatReq, overwrite=TRUE) # write the table to the sqlite
  dbDisconnect(db) # disconnect the db

SpecificHabitatReq_NeedInfo <- SpecificHabitatReq[which(is.na(SpecificHabitatReq$SpecificHabitatRequirements)),] # get a list of sgcn of species without specific habitat requirements
print('The following SGCN do not have specific habitat requirements.')
SpecificHabitatReq_NeedInfo
 # write.csv(SpecificHabitatReq_NeedInfo, here::here("_data","output","needInfo_SpecificHabReq.csv"), row.names=FALSE)
# write.csv(as.data.frame(table(SpecificHabitatReq_NeedInfo$Group)), here("_data","output","needInfo_SpecificHabSpecies.csv"), row.names=FALSE)
rm(SpecificHabitatReq, SpecificHabitatReq_NeedInfo)



## Primary Macrogroups
loadSGCN()

PrimaryMacrogroup <- read.csv(here::here("_data","input","lu_PrimaryMacrogroup.csv"), stringsAsFactors=FALSE)

trackfiles("Primary Macrogroups", here::here("_data","input","lu_PrimaryMacrogroup.csv")) # write to file tracker


nomatch <- setdiff(lu_sgcn$ELSeason, PrimaryMacrogroup$ELSeason)
nomatch1 <- setdiff(PrimaryMacrogroup$ELSeason, lu_sgcn$ELSeason)
nomatch1

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_PrimaryMacrogroup", PrimaryMacrogroup, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db



## Habitat Names
HabitatName <- read.csv(here::here("_data","input","lu_HabitatName.csv"), stringsAsFactors=FALSE)
trackfiles("Habitat Names Lookup", here::here("_data","input","lu_HabitatName.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_HabitatName", HabitatName, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## Terrestrial Habitat Layer
HabTerr <- read.csv(here::here("_data","input","lu_HabTerr.csv"), stringsAsFactors=FALSE)
trackfiles("Terrestrial Habitats", here::here("_data","input","lu_HabTerr.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_HabTerr", HabTerr, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## Lotic Habitat Layer
HabLotic <- read.csv(here::here("_data","input","lu_LoticData.csv"), stringsAsFactors=FALSE)
HabLotic <- HabLotic[c("unique_id","COMID","GNIS_NAME","SUM_23","DESC_23","MACRO_GR","Shape_Length")]
trackfiles("Lotic Habitats", here::here("_data","input","lu_LoticData.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_LoticData", HabLotic, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## Special Habitats - caves and seasonal pools
HabSpecial <- read.csv(here::here("_data","input","lu_SpecialHabitats.csv"), stringsAsFactors=FALSE)
trackfiles("Special Habitats", here::here("_data","input","lu_SpecialHabitats.csv")) # write to file tracker
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SpecialHabitats", HabSpecial, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db




