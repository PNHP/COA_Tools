#-------------------------------------------------------------------------------
# Name:        11_SGCNbyPU.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-03-31
# Updated:     
#
# To Do List/Future ideas:
# * 
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()

olddatabasename <- "coa_bridgetest.sqlite" 
olddatabasename <- here::here("_data","output",updateNameprev,olddatabasename)

db <- dbConnect(SQLite(), dbname=olddatabasename) # connect to the database
sgcnXpu <- dbReadTable(db, "lu_sgcnXpu_all") # write the table to the sqlite
dbDisconnect(db) # disconnect the db

unique(sgcnXpu$OccProb)

sgcnXpu[which(sgcnXpu$OccProb=="confirmed"),"OccProb"] <- "k" # replace these bad values from wherever they are coming from!

# subset out the known occurrences from the older dataset
sgcnXpu_oldK <- sgcnXpu[which(sgcnXpu$OccProb=="k" | (substr(sgcnXpu$ELSeason,start=1,stop=2)=="AF" & sgcnXpu$OccProb=="l")),]

# delete known occurrences, likely occurrences that are fish, and records with blank ELSeason or OccProb values from the older dataset
sgcnXpu_models <- sgcnXpu[which((sgcnXpu$OccProb!="k") & !(substr(sgcnXpu$ELSeason,start=1,stop=2)=="AF" & sgcnXpu$OccProb=="l") & (sgcnXpu$ELSeason!="") & (sgcnXpu$OccProb!="")),]

# remove models that might be considered "bad", like eastern meadowlark
sgcnXpu_models <- sgcnXpu_models[which(sgcnXpu_models$ELSeason!="ABPBXB2020_b"),]

# get a summary of species that have models
speciesListModels <- unique(sgcnXpu_models$ELSeason)
a <- as.data.frame(table(sgcnXpu_models$ELSeason, sgcnXpu_models$OccProb))

## read in the new table the known occurrences
sgcnXpu_newK <- arc.open(here::here("_data","output",updateName,"SGCN.gdb","SGCNxPU_occurrence"))
sgcnXpu_newK <- arc.select(sgcnXpu_newK, c("unique_id","ELSeason","OccProb","PERCENTAGE")) 
sgcnXpu_newK$OccProb <- tolower(sgcnXpu_newK$OccProb) # put this in lower case since I did it wrong previously
colOrder <- names(sgcnXpu_oldK) # get the sort order of the old df
sgcnXpu_newK <- sgcnXpu_newK[c(colOrder)] # apply the sort order
sgcnXpu_newK <-as.data.frame(sgcnXpu_newK) # convert from arc.data to just a df

unique(sgcnXpu$OccProb)

# bind the new Known table to the model based table
sgcnXpu_newTable <- rbind(sgcnXpu_newK,sgcnXpu_models)
sgcnXpu_newTable <- distinct(sgcnXpu_newTable)

# write the table to the database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_sgcnXpu_all", sgcnXpu_newTable, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

# bonus to create a summary table
a <- as.data.frame(table(sgcnXpu$ELSeason))
a1 <- merge(a, lu_sgcn, by.x="Var1", by.y="ELSeason")
write.csv(a1, here::here("_data","output",updateName,"countBySpecies.csv"))

