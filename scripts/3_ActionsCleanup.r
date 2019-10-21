#-------------------------------------------------------------------------------
# Name:        ActionsCleanup.r
# Purpose:     Cleann up and format the actions spreadsheet for the COA tool.
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


if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)

# Set input paths ----
databasename <- "coa_bridgetest.sqlite" 
databasename <- here::here("_data","output",databasename)


##############################################################################################################
# load lu_sgcn for latter integrity checks
# function to load SGCN species list
loadSGCN <- function(taxagroup) {
  if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)
  db <- dbConnect(SQLite(), dbname = databasename)
  SQLquery <- paste("SELECT ELCODE, SNAME, SCOMNAME, TaxaGroup, SeasonCode, ELSeason"," FROM lu_sgcn ")
  lu_sgcn <- dbGetQuery(db, statement = SQLquery)
  if(missing(taxagroup)){
    lu_sgcn <<- lu_sgcn
    sgcnlist <<- unique(lu_sgcn$SNAME)
  } else {
    lu_sgcn <<- lu_sgcn[which(lu_sgcn$TaxaGroup==taxagroup),] # limit by taxagroup code
    sgcnlist <<- unique(lu_sgcn$SNAME)
  }
  dbDisconnect(db) # disconnect the db
}

loadSGCN()


##############################################################################################################
#get the threats template
COA_actions_file <- list.files(path=here::here("_data/input"), pattern=".xlsx$")  # --- make sure your excel file is not open.
COA_actions_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 5
COA_actions_file <- here::here("_data/input",COA_actions_file[n])

#get a list of the sheets in the file
COA_actions_sheets <- getSheetNames(COA_actions_file)
#look at the output and choose which excel sheet you want to load
# Enter the actions sheet (eg. "lu_actionsLevel2") 
COA_actions_sheets # list the sheets
n <- 3 # enter its location in the list (first = 1, second = 2, etc)
COA_actions <- read.xlsx(xlsxFile=COA_actions_file, sheet=COA_actions_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

# rename two problematic fields
names(COA_actions)[names(COA_actions) == ''] <- 'SpeciesID'
names(COA_actions)[names(COA_actions) == 'Reference#'] <- 'ReferenceID'

# cleanup
rm(n)

#############################################################################################################
# checks on data integrity

# print ELSeason values that are in actions table, but not in lu_sgcn table
sgcn_actionnorecord <- setdiff(COA_actions$ELSeason, lu_sgcn$ELSeason)
print("The following ELSeason records are found in the lu_actions table, but do not have matching records in the lu_sgcn table: ")
print(sgcn_actionnorecord)

# get list of rows from actions table that include null or blank ELSeason values
actions_null_ELCODE <- lu_actions[is.na(lu_actions$ELSeason)==TRUE,]
if(nrow(actions_null_ELCODE)>0){
  print('There are null or blank ELSeason values in the actions table from the sqlite database. They include: ')
  print(actions_null_ELCODE[,names(actions_null_ELCODE)!="COATool_ActionsFINAL"])
} else{
  print('There are no null or blank ELSeason values in the actions table from the sqlite database! Yay!')
}
print(unique(sort(lu_actions$ActionCategory2)))


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

# # check if url exist
# library(RCurl)
# for(l in 1:nrow(COA_references)){
#   if(isTRUE(url.exists(COA_references$LINK[l], .header=FALSE))){
#     print(paste("url for -",COA_references$REF_NAME[l],"- is valid"), sep=" ")
#   }  else if(isFALSE(url.exists(COA_references$LINK[l]))){
#     print(paste("url for -",COA_references$REF_NAME[l],"- is not valid"), sep=" ")
#   }
# }

# 
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_BPreference", COA_references, overwrite=TRUE) # write the output to the sqlite db
dbDisconnect(db) # disconnect the db
rm(COA_references)

## research needs
SGCNresearch <- read.csv(here("_data","input","lu_SGCNresearch.csv"), stringsAsFactors=FALSE)

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_SGCNresearch", SGCNresearch, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

## survey needs
SGCNsurvey <- read.csv(here("_data","input","lu_SGCNsurvey.csv"), stringsAsFactors=FALSE)

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_SGCNsurvey", SGCNsurvey, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db


