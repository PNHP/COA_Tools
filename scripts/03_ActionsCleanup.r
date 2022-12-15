#-------------------------------------------------------------------------------
# Name:        ActionsCleanup.r
# Purpose:     Clean up and format the actions spreadsheet for the COA tool.
# Author:      Christopher Tracey
# Created:     2018-11-01
# Updated:     2019-10-20
#
# Updates:
# * 2019-02-13 - recode everything
# * 2019-02-20 - fix some rm issues
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

##############################################################################################################
# load lu_sgcn for latter integrity checks
loadSGCN()

##############################################################################################################
#get the threats template
COA_actions_file <- list.files(path=here::here("_data/input"), pattern=".xlsx$")  # --- make sure your excel file is not open.
COA_actions_file
#look at the output and choose which excel file you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 11
COA_actions_file <- here::here("_data/input",COA_actions_file[n])

# write to file tracker
trackfiles("COA Actions", COA_actions_file)

#get a list of the sheets in the file
COA_actions_sheets <- getSheetNames(COA_actions_file)
☺#look at the output and choose which excel sheet you want to load
# Enter the actions sheet (eg. "lu_actionsLevel2") 
COA_actions_sheets # list the sheets
n <- 3 # enter its location in the list (first = 1, second = 2, etc)
COA_actions <- read.xlsx(xlsxFile=COA_actions_file, sheet=COA_actions_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

# rename two problematic fields
names(COA_actions)[names(COA_actions) == 'X1'] <- 'SpeciesID'
names(COA_actions)[names(COA_actions) == 'Reference#'] <- 'ReferenceID'


#############################################################################################################
# checks on data integrity

# print ELSeason values that are in actions table, but not in lu_sgcn table
sgcn_actionnorecord <- setdiff(COA_actions$ELSeason, lu_sgcn$ELSeason)
print("The following ELSeason records are found in the lu_actions table, but do not have matching records in the lu_sgcn table: ")
print(sgcn_actionnorecord)

# # get list of rows from actions table that include null or blank ELSeason values
# actions_null_ELCODE <- lu_actions[is.na(lu_actions$ELSeason)==TRUE,]
# if(nrow(actions_null_ELCODE)>0){
#   print('There are null or blank ELSeason values in the actions table from the sqlite database. They include: ')
#   print(actions_null_ELCODE[,names(actions_null_ELCODE)!="COATool_ActionsFINAL"])
# } else{
#   print('There are no null or blank ELSeason values in the actions table from the sqlite database! Yay!')
# }
# print(unique(sort(lu_actions$ActionCategory2)))


#############################################################################################################
# write to the database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_actionsLevel2", COA_actions, overwrite=TRUE) # write the output to the sqlite db
dbDisconnect(db) # disconnect the db
rm(COA_actions)

####################################
## References for the actions
# Enter the references sheet (eg. "lu_BPreference") 
COA_actions_sheets # list the sheets
n <- 4 # enter its location in the list (first = 1, second = 2, etc)
COA_references <- read.xlsx(xlsxFile=COA_actions_file, sheet=COA_actions_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

# rename problematic fields
names(COA_references)[names(COA_references) == 'REFERENCE#'] <- 'ReferenceID'
names(COA_references)[names(COA_references) == 'REFERENCE.NAME'] <- 'REF_NAME'
COA_references$ActionCategory1 <- NULL
COA_references$ActionCategory2 <- NULL

# check if url exist
library(httr)

for(l in 1:nrow(COA_references)){
   if(isFALSE(http_error(COA_references$LINK[l]))){
     print(paste("url for -",COA_references$REF_NAME[l],"- is valid"), sep=" ")
   } else if(isTRUE(http_error(COA_references$LINK[l]))){
     print(paste("url for -",COA_references$REF_NAME[l],"- is NOT VALID"), sep=" ")
   }
  }

# 
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_BPreference", COA_references, overwrite=TRUE) # write the output to the sqlite db
dbDisconnect(db) # disconnect the db
rm(COA_references)

##########################################################
## research needs
SGCNresearch <- read.csv(here::here("_data","input","lu_SGCNresearch.csv"), stringsAsFactors=FALSE)

sgcn_researchnorecord <- setdiff(SGCNresearch$ELSeason, lu_sgcn$ELSeason)
print("The following ELSeason records are found in the SGCNresearch table, but do not have matching records in the lu_sgcn table: ")
print(sgcn_researchnorecord)


db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SGCNresearch", SGCNresearch, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

# write to file tracker
trackfiles("Research Needs", here::here("_data","input","lu_SGCNresearch.csv"))

##########################################################
## survey needs
SGCNsurvey <- read.csv(here::here("_data","input","lu_SGCNsurvey.csv"), stringsAsFactors=FALSE)

sgcn_surveynorecord <- setdiff(SGCNresearch$ELSeason, lu_sgcn$ELSeason)
print("The following ELSeason records are found in the SGCNsurvey table, but do not have matching records in the lu_sgcn table: ")
print(sgcn_surveynorecord)

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SGCNsurvey", SGCNsurvey, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

# write to file tracker
trackfiles("Survey Needs", here::here("_data","input","lu_SGCNsurvey.csv"))
