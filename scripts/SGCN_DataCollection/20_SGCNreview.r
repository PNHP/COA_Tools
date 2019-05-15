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
SQLquery <- paste("SELECT ELCODE, SCOMNAME, SNAME, TaxaDisplay"," FROM lu_sgcn ")
lu_sgcn <- dbGetQuery(db, statement = SQLquery)
dbDisconnect(db) # disconnect the db

lu_sgcn <- unique(lu_sgcn)

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

                      