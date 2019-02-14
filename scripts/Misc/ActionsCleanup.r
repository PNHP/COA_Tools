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
# connect to the database
db <- dbConnect(SQLite(), dbname=databasename)

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

# write the output to the sqlite db
dbWriteTable(db, "lu_actionsLevel2", COA_actions, overwrite=TRUE)

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

# write the output to the sqlite db
dbWriteTable(db, "BPreference", COA_references, overwrite=TRUE)

# disconnect the db
dbDisconnect(db)



