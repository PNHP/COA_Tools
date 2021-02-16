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

source(here::here("scripts","00_PathsAndSettings.r"))

######################################################################################
# get lu_sgcn and lu_sgcnXpu data from sqlite database
db <- dbConnect(SQLite(), dbname=databasename)
lu_sgcn_SQLquery <- "SELECT ELSeason, ELCODE, SCOMNAME, SNAME, TaxaDisplay, SeasonCode FROM lu_sgcn"
lu_sgcnXpu_SQLquery <- "SELECT unique_id, OccProb, PERCENTAGE, ELSeason FROM lu_sgcnXpu_all"
lu_actionsLevel2_SQLquery <- "SELECT ELSeason, SCOMNAME, SNAME, ActionCategory2, COATool_ActionsFINAL FROM lu_actionsLevel2" #eventually add Group - currently not working
lu_sgcn <- dbGetQuery(db, statement=lu_sgcn_SQLquery)
lu_sgcnXpu <- dbGetQuery(db, statement=lu_sgcnXpu_SQLquery)
lu_actions <- dbGetQuery(db, statement=lu_actionsLevel2_SQLquery)
dbDisconnect(db) # disconnect the db

## minor fixes
lu_sgcnXpu[lu_sgcnXpu=="AAAAE01040_y"] <- "AAAAE01042_y" # mudpuppy
lu_sgcnXpu[lu_sgcnXpu=="AMAFB09020_y"] <- "AMAFB09030_y" # northern flying squirrel
lu_sgcnXpu[lu_sgcnXpu=="AMAFB09020_y"] <- "IILEP42010_y" # arctic skipper
lu_sgcnXpu[lu_sgcnXpu=="ABPBX03240_y"] <- "ABPBX03240_b" # cerulean warbler

# i think this gets rid of some bad records, mayb strays from the biotics import
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


###################################################
# creation of summary table
source(here::here("scripts","00_PathsAndSettings.r"))
# read in SGCN data
loadSGCN()

# collapse sgcn down to one season
lu_sgcn <- unique(lu_sgcn[c("ELCODE","SNAME","SCOMNAME","TaxaGroup")])

# add in taxa display
db <- dbConnect(SQLite(), dbname=databasename)
taxagrp <- dbGetQuery(db, statement="SELECT * FROM lu_taxagrp")
dbDisconnect(db)


lu_sgcn <- merge(lu_sgcn, taxagrp[c("code","taxadisplay")], by.x="TaxaGroup", by.y="code")

# get data
SGCN <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb","allSGCNuse"))
SGCN <- arc.select(SGCN)

unique(SGCN$DataSource)

# replace some values
SGCN[SGCN=="PGC Grouse Data"] <- "PGC"
SGCN[SGCN=="PGC Woodcock Data"] <- "PGC"
SGCN[SGCN=="PGC_DougGross"] <- "PGC"
SGCN[SGCN=="PGC waterfowl"] <- "PGC"
SGCN[SGCN=="PFBC_DPF"] <- "PFBC"
SGCN[SGCN=="bat_EPFUabc"] <- "PGC"
SGCN[SGCN=="bat_EPFUcontrap"] <- "PGC"
SGCN[SGCN=="bat_EPFUhiber"] <- "PGC"
SGCN[SGCN=="bat_EPFUPGCtrap"] <- "PGC"
SGCN[SGCN=="bat_LANOcontrap"] <- "PGC"
SGCN[SGCN=="bat_LANOPGCtrap"] <- "PGC"
SGCN[SGCN=="PNHP CPP"] <- "PGC"
           



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
SGCNsummary <- SGCNsummary[c("taxadisplay","SCOMNAME","SNAME","DataSource","RecordCount","MinYear","MaxYear")]
# sort
SGCNsummary <- SGCNsummary[order(SGCNsummary$taxadisplay,SGCNsummary$SCOMNAME,SGCNsummary$DataSource),]
# rename columns
names(SGCNsummary) <- c("Taxonomic Group","Common Name","Scientific Name","Data Source","Record Count","MinYear","MaxYear")

SGCNsummary <- SGCNsummary[which(!is.na(SGCNsummary$`Taxonomic Group`)),]


a1 <- "The following information regarding Wildlife Action Plan Conservation Opportunity Area Tool data sources, number of records for each data source, and the record dates is provided by the Pennsylvania Natural Heritage Program (PNHP) for reference purposes. Please contact Pennsylvania Game Commission (birds, mammals, terrestrial invertebrates; PGCSWAP@pa.gov) or Pennsylvania Fish & Boat Commission (fish, amphibians, reptiles, aquatic or terrestrial invertebrates; RA-FBSWAP@pa.gov) for more information."
b1 <- "KEY: BAMONA = Butterflies and Moths of North America; BBA_PtCt = Pennsylvania Breeding Bird Atlas point counts (Wilson et al. 2012); DillonSnails = aquatic snail records contributed by an expert in the field; eBird = free bird sighting database administered by Cornell Lab of Ornithology (ebird.org); GBIF = Global Biodiversity Information Facility, an open access index of species occurrence records (more information can be found at https://www.gbif.org/en/what-is-gbif); iNaturalist = (www.inaturalist.org); PFBC = Pennsylvania Fish & Boat Commission data; PGC = Pennsylvania Game Commission data; PNHP Biotics = Pennsylvania Natural Heritage Program database of unique, threatened or endangered species that is linked with NatureServe, a global biodiversity conservation organization (more information can be found at http://www.natureserve.org/conservation-tools/biotics-5); PNHP POND = Pond Observation Networked Database, a database of vernal pool data; PSU-Brittingham-Miller = bird data from a Pennsylvania State University research lab; TREC = Tom Ridge Environmental Center in Erie, PA; USFS-NRS = SGNC data contributed by the Allegheny National Forest; Xerces = Xerces Society, an invertebrate conservation organization (more information can be found at https://xerces.org/)." 


options(useFancyQuotes = FALSE)
sink(here::here("_data","output",updateName,paste("SGCNsummary",updateName,".csv",sep="")))
cat(paste(dQuote(a1),"\n" , sep=" "))
cat(paste(dQuote(b1),"\n" , sep=" "))
cat("\n")
write.table(SGCNsummary, row.names=FALSE, col.names=TRUE, sep=",")
sink()                      
options(useFancyQuotes = TRUE)



