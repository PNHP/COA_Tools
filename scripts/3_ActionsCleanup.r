#-------------------------------------------------------------------------------
# Name:        ActionsCleanup.r
# Purpose:     Cleann up and format the actions spreadsheet for the COA tool.
# Author:      Christopher Tracey
# Created:     2018-11-01
# Updated:     2019-02-13
#
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
databasename <- here("_data","output",databasename)

#get the threats template
COA_actions_file <- list.files(path=here("_data/input"), pattern=".xlsx$")  # --- make sure your excel file is not open.
COA_actions_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
COA_actions_file <- here("_data/input",COA_actions_file[n])

#get a list of the sheets in the file
COA_actions_sheets <- getSheetNames(COA_actions_file)
#look at the output and choose which excel sheet you want to load

# cleanup
rm(COA_actions_file,COA_actions_sheets,n)

## Actions
# Enter the actions sheet (eg. "lu_actionsLevel2") 
COA_actions_sheets # list the sheets
n <- 3 # enter its location in the list (first = 1, second = 2, etc)
COA_actions <- read.xlsx(xlsxFile=COA_actions_file, sheet=COA_actions_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

# rename two problematic fields
names(COA_actions)[names(COA_actions) == ''] <- 'SpeciesID'
names(COA_actions)[names(COA_actions) == 'Reference#'] <- 'ReferenceID'

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_actionsLevel2", COA_actions, overwrite=TRUE) # write the output to the sqlite db
dbDisconnect(db) # disconnect the db
rm(COA_actions)

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

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "BPreference", COA_references, overwrite=TRUE) # write the output to the sqlite db
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


