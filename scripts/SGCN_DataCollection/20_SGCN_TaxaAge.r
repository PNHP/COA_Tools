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

# clear the environments
rm(list=ls())


# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
require(RSQLite)

# creation of summary table
source(here::here("scripts","00_PathsAndSettings.r"))
# read in SGCN data
loadSGCN()

# collapse sgcn down to one season
lu_sgcn <- unique(lu_sgcn[c("ELCODE","SNAME","SCOMNAME","TaxaGroup")])

# get data
SGCN <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb","allSGCNuse"))
SGCN <- arc.select(SGCN)


# get taxa groups
db <- dbConnect(SQLite(), dbname = databasename)
lu_sgcn_taxa <- "SELECT * FROM lu_taxagrp"
lu_sgcn_taxa <- dbGetQuery(db, statement = lu_sgcn_taxa)
dbDisconnect(db) # disconnect the db


# merge
SGCN1 <- merge(SGCN, lu_sgcn_taxa, by.x="TaxaGroup", by.y="code")
SGCN1$LastObs <- as.numeric(SGCN1$LastObs)
SGCN1 <- SGCN1[which(SGCN1$LastObs>=1970),]

library(lattice)
histogram(~SGCN1$LastObs|SGCN1$taxadisplay,   breaks=seq(from=1970,to=2020,by=1), layout=c(5, 5), xlab="Last Observation Year", 
          panel=function(x,...){
            panel.histogram(x,...)  
          panel.abline(v=1994, lty="dotted", col="red", lwd=2)
          })


######################################################################################
# get lu_sgcn and lu_sgcnXpu data from sqlite database
db <- dbConnect(SQLite(), dbname = databasename)
lu_sgcn_SQLquery <- "SELECT ELSeason, ELCODE, SCOMNAME, SNAME, TaxaDisplay, SeasonCode FROM lu_sgcn"
lu_sgcnXpu_SQLquery <- "SELECT unique_id, OccProb, PERCENTAGE, ELSeason FROM lu_sgcnXpu_all"
lu_actionsLevel2_SQLquery <- "SELECT ELSeason, SCOMNAME, SNAME, ActionCategory2, COATool_ActionsFINAL FROM lu_actionsLevel2" #eventually add Group - currently not working
lu_sgcn <- dbGetQuery(db, statement = lu_sgcn_SQLquery)
lu_sgcnXpu <- dbGetQuery(db, statement = lu_sgcnXpu_SQLquery)
lu_actions <- dbGetQuery(db, statement = lu_actionsLevel2_SQLquery)
dbDisconnect(db) # disconnect the db

## minor fixes
lu_sgcnXpu[lu_sgcnXpu=="AAAAE01040_y"] <- "AAAAE01042_y"
lu_sgcnXpu[lu_sgcnXpu=="AMAFB09020_y"] <- "AMAFB09030_y"
lu_sgcnXpu[lu_sgcnXpu=="AMAFB09020_y"] <- "IILEP42010_y"
lu_sgcnXpu[lu_sgcnXpu=="ABPBX03240_y"] <- "ABPBX03240_b"

lu_sgcnXpu <- lu_sgcnXpu[which(lu_sgcnXpu$ELSeason!="ABNKD06020_y"&lu_sgcnXpu$ELSeason!="ABPBX03120_y"&lu_sgcnXpu$ELSeason!="ABPBX16010_y"&lu_sgcnXpu$ELSeason!="ABNTA07070_y"&lu_sgcnXpu$ELSeason!="ABPBK01010_y"&lu_sgcnXpu$ELSeason!="ABPBX01060_y"&lu_sgcnXpu$ELSeason!="ABPBXA4020_y"&lu_sgcnXpu$ELSeason!="ABNSB13040_y"&lu_sgcnXpu$ELSeason!="ABNNF19020_y"&lu_sgcnXpu$ELSeason!="ABPBA01010_y"&lu_sgcnXpu$ELSeason!="ABPBJ18100_y"&lu_sgcnXpu$ELSeason!="ABPBX05010_y"&lu_sgcnXpu$ELSeason!="ABPAU01010_y"&lu_sgcnXpu$ELSeason!="ABNNM08070_y"&lu_sgcnXpu$ELSeason!="ABPBY06030_y"&lu_sgcnXpu$ELSeason!="ABPBG10020_y"&lu_sgcnXpu$ELSeason!="ABPBX03050_y"&lu_sgcnXpu$ELSeason!="ABPBX03230_y"&lu_sgcnXpu$ELSeason!="ABNME05030_y"&lu_sgcnXpu$ELSeason!="ABNCA03010_y"&lu_sgcnXpu$ELSeason!="AMACC04010_y"&lu_sgcnXpu$ELSeason!="ABNME08020_y"&lu_sgcnXpu$ELSeason!="ABNKC12020_y"&lu_sgcnXpu$ELSeason!="ABNME13030"),]

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_sgcnXpu_all", lu_sgcnXpu, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db


# get number of lu_sgcn records, number of unique ELCODE values, and number of unique ELSeason values
print(paste0("There are ",nrow(lu_sgcn)," rows in the master lu_sgcn list from the sqlite database."))
print(paste0("There are ",length(unique(lu_sgcn$ELSeason))," unique ELSeason values in the master lu_sgcn list from the sqlite database."))
print(paste0("There are ",length(unique(lu_sgcn$ELCODE))," unique ELCODE values in the master lu_sgcn list from the sqlite database."))

# check to make sure base elcode and elseason values match in lu_sgcn table
elcode_matching <- lu_sgcn[sub("\\_.*","",lu_sgcn$ELSeason) != lu_sgcn$ELCODE,]
if(nrow(elcode_matching)>0){
  print('There are records for which the base ELCODE and ELSeason values do not match. These include: ')
  print(elcode_matching)
} else{
  print('All base ELCODE and ELSeason values match! Hooray!')
}

# check for duplicate ELSeason values and print rows containing dup records
dupe <- lu_sgcn[,c('ELSeason')] # select columns to check duplicates
dups <- lu_sgcn[duplicated(dupe) | duplicated(dupe, fromLast=TRUE),]
if(nrow(dups)>0){
  print('There are duplicate ELSeason records in the master lu_sgcn list from the sqlite database. They include: ')
  print(dups)
} else{
  print('There are no duplicate ELSeason records in the master lu_sgcn list from the sqlite database')
}

# get number of records in lu_sgcnXpu table and unique ELSeason values in lu_sgcnXpu table
print(paste0("There are ",nrow(lu_sgcnXpu)," records in the lu_sgcnXpu table from the sqlite database."))
print(paste0("There are ",length(unique(lu_sgcn$ELSeason))," unique ELSeason values in the lu_sgcnXpu table from the sqlite database."))

# check for missing ELSeason values from tables
x <- unique(lu_sgcn$ELSeason)
y <- unique(lu_sgcnXpu$ELSeason)
a <- unique(lu_actions$ELSeason)

# get ELSeason values that are in lu_sgcn table, but not spatially represented in lu_sgcnXpu table
sgcn_nospatial <- setdiff(x,y)
print("The following ELSeason records are found in the lu_sgcn table, but are not spatially represented in the lu_sgcnXpu table: ")
print(lu_sgcn[lu_sgcn$ELSeason %in% sgcn_nospatial,])

# get ELSeason values that are in lu_sgcnXpu table, but do not have a matching ELSeason record in lu_sgcn
sgcn_norecord <- setdiff(y,x)
print("The following ELSeason records are found in the lu_sgcnXpu table, but do not have matching records in the lu_sgcn table: ")
print(sgcn_norecord)

# print ELSeason values that are in actions table, but not in lu_sgcn table
sgcn_actionnorecord <- setdiff(a,x)
print("The following ELSeason records are found in the lu_actions table, but do not have matching records in the lu_sgcn table: ")
print(sgcn_actionnorecord)

# print ELSeason values that are in lu_sgcnXpu and in lu_sgcn, but are not in actions table
sgcn_punoaction <- setdiff(y,a)
sgcn_recordnoaction <- subset(sgcn_punoaction,!(sgcn_punoaction %in% sgcn_norecord))
print("The following ELSeason records are found in the lu_sgcnXpu and lu_sgcn tables, but do not have any corresponding actions: ")
print(lu_sgcn[lu_sgcn$ELSeason %in% sgcn_recordnoaction,])
write.csv(lu_sgcn[lu_sgcn$ELSeason %in% sgcn_recordnoaction,],"missing_actions.csv", row.names=FALSE)


# get list of rows from actions table that include null or blank ELSeason values
actions_null_ELCODE <- lu_actions[is.na(lu_actions$ELSeason)==TRUE,]
if(nrow(actions_null_ELCODE)>0){
  print('There are null or blank ELSeason values in the actions table from the sqlite database. They include: ')
  print(actions_null_ELCODE[,names(actions_null_ELCODE)!="COATool_ActionsFINAL"])
} else{
  print('There are no null or blank ELSeason values in the actions table from the sqlite database! Yay!')
}

print(unique(sort(lu_actions$ActionCategory2)))





# creation of summary table
source(here::here("scripts","00_PathsAndSettings.r"))
# read in SGCN data
loadSGCN()

# collapse sgcn down to one season
lu_sgcn <- unique(lu_sgcn[c("ELCODE","SNAME","SCOMNAME","TaxaGroup")])

# get data
SGCN <- arc.open(path=here::here("_data/output",updateName,"SGCN.gdb","allSGCNuse"))
SGCN <- arc.select(SGCN)

# aggregate data by min/max year
SGCNrecordcount <- aggregate(LastObs~SNAME+DataSource, data=SGCN, FUN=length)
colnames(SGCNrecordcount)[colnames(SGCNrecordcount)=="LastObs"] <- "RecordCount"
SGCN_Max <- aggregate(LastObs~SNAME+DataSource, data=SGCN, max)
colnames(SGCN_Max)[colnames(SGCN_Max)=="LastObs"] <- "MaxYear"
SGCN_Min <- aggregate(LastObs~SNAME+DataSource, data=SGCN, min)
colnames(SGCN_Min)[colnames(SGCN_Min)=="LastObs"] <- "MinYear"

SGCNsummary <- merge(SGCNrecordcount, SGCN_Max, by=c("SNAME","DataSource"))
SGCNsummary <- merge(SGCNsummary, SGCN_Min, by=c("SNAME","DataSource"))
SGCNsummary <- merge(SGCNsummary, lu_sgcn, by="SNAME", all.x=TRUE)



# rearrange the column names
SGCNsummary <- SGCNsummary[c("TaxaGroup","SCOMNAME","SNAME","DataSource","RecordCount","MinYear","MaxYear")]

# sort
SGCNsummary <- SGCNsummary[order(SGCNsummary$TaxaGroup,SGCNsummary$SCOMNAME,SGCNsummary$DataSource),]

# replace some values
SGCNsummary[SGCNsummary=="PGC Grouse Data"] <- "PGC"
SGCNsummary[SGCNsummary=="PGC_DougGross"] <- "PGC"
SGCNsummary[SGCNsummary=="PFBC_DPF"] <- "PFBC"

# rename columns
names(SGCNsummary) <- c("Taxonomic Group","Common Name","Scientific Name","Data Source","Record Count","MinYear","MaxYear")


write.csv(SGCNsummary, "SGCNsummary_20191029.csv", row.names=FALSE)

                      





######################
#Fix trec data
###lu_sgcnXpu_notrec <- lu_sgcnXpu[which(lu_sgcnXpu$)]


