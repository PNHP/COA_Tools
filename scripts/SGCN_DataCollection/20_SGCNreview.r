#---------------------------------------------------------------------------------------------
# Name: 20_SGCNreview.r
# Purpose: 
# Author: Christopher Tracey
# Created: 2017-07-10
# Updated: 2019-02-20
#
# Updates:
# insert date and info
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------
# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
require(RSQLite)

source(here::here("scripts","SGCN_DataCollection","00_PathsAndSettings.r"))

arc.check_product()

######################################################################################
# get SGCN data
db <- dbConnect(SQLite(), dbname = databasename)
lu_sgcn_SQLquery <- "SELECT ELSeason, ELCODE, SCOMNAME, SNAME, TaxaDisplay, SeasonCode FROM lu_sgcn"
lu_sgcnXpu_SQLquery <- "SELECT unique_id, OccProb, PERCENTAGE, ELSeason FROM lu_sgcnXpu_all"
lu_sgcn <- dbGetQuery(db, statement = lu_sgcn_SQLquery)
lu_sgcnXpu <- dbGetQuery(db, statement = lu_sgcnXpu_SQLquery)
dbDisconnect(db) # disconnect the db

print(paste0("There are ",nrow(lu_sgcn)," rows in the master lu_sgcn list from the sqlite database."))
print(paste0("There are ",length(unique(lu_sgcn$ELSeason))," unique ELSeason values in the master lu_sgcn list from the sqlite database."))
print(paste0("There are ",length(unique(lu_sgcn$ELCODE))," unique ELCODE values in the master lu_sgcn list from the sqlite database."))

dupe = lu_sgcn[,c('ELSeason')] # select columns to check duplicates
dups <- lu_sgcn[duplicated(dupe) | duplicated(dupe, fromLast=TRUE),]
if(nrow(dups)>0){
  print('There are duplicate ELSeason records in the master lu_sgcn list from the sqlite database. They include: ')
  print(dups)
} else{
  print('There are no duplicate ELSeason records in the master lu_sgcn list from the sqlite database')
}


print(paste0("There are ",nrow(lu_sgcnXpu)," records in the lu_sgcnXpu table from the sqlite database."))
print(paste0("There are ",length(unique(lu_sgcn$ELSeason))," unique ELSeason values in the lu_sgcnXpu table from the sqlite database."))

lu_sgcn_ELSeason <- unique(lu_sgcn$ELSeason)
lu_sgcnXpu_ELSeason <- unique(lu_sgcnXpu$ELSeason)

setdiff(lu_sgcn_ELSeason,lu_sgcnXpu_ELSeason)
setdiff(lu_sgcnXpu_ELSeason,lu_sgcn_ELSeason)


SGCN <- arc.open(path=here::here("_data/output/SGCN.gdb","allSGCNuse2"))
SGCN <- arc.select(SGCN)


SGCNrecordcount <- aggregate(LastObs~SNAME+DataSource, data=SGCN, FUN=length)
colnames(SGCNrecordcount)[colnames(SGCNrecordcount)=="LastObs"] <- "RecordCount"
SGCN_Max <- aggregate(LastObs~SNAME+DataSource, data=SGCN, max)
colnames(SGCN_Max)[colnames(SGCN_Max)=="LastObs"] <- "MaxYear"
SGCN_Min <- aggregate(LastObs~SNAME+DataSource, data=SGCN, min)
colnames(SGCN_Min)[colnames(SGCN_Min)=="LastObs"] <- "MinYear"

SGCNsummary <- merge(SGCNrecordcount, SGCN_Max, by=c("SNAME","DataSource"))
SGCNsummary <- merge(SGCNsummary, SGCN_Min, by=c("SNAME","DataSource"))
SGCNsummary <- merge(SGCNsummary, lu_sgcn, by="SNAME")



# rearrange the column names
SGCNsummary <- SGCNsummary[c("TaxaDisplay","SCOMNAME","SNAME","DataSource","RecordCount","MinYear","MaxYear")]

# sort
SGCNsummary <- SGCNsummary[order(SGCNsummary$TaxaDisplay,SGCNsummary$SCOMNAME,SGCNsummary$DataSource),]


write.csv(SGCNsummary, "SGCNsummary.csv", row.names=FALSE)

                      