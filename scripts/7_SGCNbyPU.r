#-------------------------------------------------------------------------------
# Name:        7_SGCNbyPU.r
# Purpose:     Create an empty, new COA databases
# Author:      Christopher Tracey
# Created:     2019-03-31
# Updated:     
#
# To Do List/Future ideas:
# * 
#-------------------------------------------------------------------------------

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)

# Set input paths ----
databasename <- "coa_bridgetest.sqlite" 
databasename <- here("_data","output",databasename)

olddatabasename <- "coa_bridgetest_previous.sqlite" 
olddatabasename <- here("_data","output",olddatabasename)

db <- dbConnect(SQLite(), dbname=olddatabasename) # connect to the database
  sgcnXpu <- dbReadTable(db, "lu_sgcnXpu_all") # write the table to the sqlite
dbDisconnect(db) # disconnect the db

##unique(sgcnXpu$OccProb)

# subset out the known occurences from the older dataset
sgcnXpu_oldK <- sgcnXpu[which(sgcnXpu$OccProb=="k"),]

# delete the known from the older dataset
sgcnXpu_models <- sgcnXpu[which(sgcnXpu$OccProb!="k"),]

## read in the new table the known occurences
sgcnXpu_newK <- read.csv(here("_data","output","sgcnXpu_test","sgcnXpu_K.csv"), stringsAsFactors=FALSE)
sgcnXpu_newK$OBJECTID <- NULL
sgcnXpu_newK$AREA <- NULL
sgcnXpu_newK$OccProb <- tolower(sgcnXpu_newK$OccProb) # put this in lower case since I did it wrong previously
colOrder <- names(sgcnXpu_oldK) # get the sort order of the old df
sgcnXpu_newK <- sgcnXpu_newK[c(colOrder)] # apply the sort order

# bind the new Known table to the model based table
sgcnXpu_newTable <- rbind(sgcnXpu_newK,sgcnXpu_models)

# write the table to the database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
  dbWriteTable(db, "lu_sgcnXpu_all", sgcnXpu_newTable, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db


