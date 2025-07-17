#---------------------------------------------------------------------------------------------
# Name: 21_SummaryTable.r
# Purpose: Check difference in numbers of SGCN from last quarter to this quarter.
# Author: Molly Moore
# Created: 2025-07-14
#---------------------------------------------------------------------------------------------

# clear the environments to start fresh
rm(list=ls())

# establish path to paths and settings script to pull in SGCN data
source(here::here("scripts","00_PathsAndSettings.r"))
# read in SGCN data
loadSGCN()

# collapse sgcn down to one season because we are only reporting on species - if we need to in the future, we can do this per season for QC purposes
lu_sgcn <- unique(lu_sgcn[c("ELCODE","SNAME","SCOMNAME","TaxaGroup")])

# load in taxa table from the SQLite table - we will join taxa to summary table to organize species
db <- dbConnect(SQLite(), dbname=databasename)
taxagrp <- dbGetQuery(db, statement="SELECT * FROM lu_taxagrp")
dbDisconnect(db)

# merge in taxa display by the taxa code
lu_sgcn <- merge(lu_sgcn, taxagrp[c("code","taxadisplay")], by.x="TaxaGroup", by.y="code")

#### FIRST WE WILL LOAD IN AND FORMAT THE CURRENT SGCN DATA FROM THE ALLSGCNUSE LAYER
# load in SGCN data from current update
SGCN_curr <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb","allSGCNuse"))
SGCN_curr <- arc.select(SGCN_curr)

# report out all values in current source
print("Data sources in current SGCN list BEFORE replace:")
unique(SGCN_curr$DataSource)

# replace more specific data sources with broader data sources - if we ever have a need to track more specific data sources, we can change this
SGCN_curr[SGCN_curr=="PGC Grouse Data"] <- "PGC"
SGCN_curr[SGCN_curr=="PGC Woodcock Data"] <- "PGC"
SGCN_curr[SGCN_curr=="PGC_DougGross"] <- "PGC"
SGCN_curr[SGCN_curr=="PGC waterfowl"] <- "PGC"
SGCN_curr[SGCN_curr=="PFBC_DPF"] <- "PFBC"
SGCN_curr[SGCN_curr=="bat_EPFUabc"] <- "PGC"
SGCN_curr[SGCN_curr=="bat_EPFUcontrap"] <- "PGC"
SGCN_curr[SGCN_curr=="bat_EPFUhiber"] <- "PGC"
SGCN_curr[SGCN_curr=="bat_EPFUPGCtrap"] <- "PGC"
SGCN_curr[SGCN_curr=="bat_LANOcontrap"] <- "PGC"
SGCN_curr[SGCN_curr=="bat_LANOPGCtrap"] <- "PGC"
SGCN_curr[SGCN_curr=="PGCCon_2021-2022"] <- "PGC"
SGCN_curr[SGCN_curr=="PGC Woodcock Email Data"] <- "PGC"
SGCN_curr[SGCN_curr=="PGC_captures"] <- "PGC"
SGCN_curr[SGCN_curr=="PNHP CPP"] <- "PNHP Biotics"
SGCN_curr[SGCN_curr=="PNHP ER"] <- "PNHP Biotics"
SGCN_curr[SGCN_curr=="PGC Barn Owl Conservation Initiative"] <- "PGC"
SGCN_curr[SGCN_curr=="PGC Woodcock Data 2023"] <- "PGC"

# just double check output data sources if needed
print("Data sources in current SGCN list AFTER replace:")
unique(SGCN_curr$DataSource)

# aggregate data by SNAME and DataSource to get number of records per species per data source
SGCNrecordcount <- aggregate(LastObs~SNAME+DataSource, data=SGCN_curr, FUN=length)
# rename column so it makes more sense
colnames(SGCNrecordcount)[colnames(SGCNrecordcount)=="LastObs"] <- "RecordCount_curr"

# aggregate data by min and max LastObs by species and data source and rename columns to make more sense
SGCN_Max <- aggregate(LastObs~SNAME+DataSource, data=SGCN_curr, max)
colnames(SGCN_Max)[colnames(SGCN_Max)=="LastObs"] <- "MaxYear_curr"
SGCN_Min <- aggregate(LastObs~SNAME+DataSource, data=SGCN_curr, min)
colnames(SGCN_Min)[colnames(SGCN_Min)=="LastObs"] <- "MinYear_curr"

# merge all the values to get them in one table for the current update period
SGCNsummary_curr <- merge(SGCNrecordcount, SGCN_Max, by=c("SNAME","DataSource"))
SGCNsummary_curr <- merge(SGCNsummary_curr, SGCN_Min, by=c("SNAME","DataSource"))

#### NOW WE WILL LOAD IN AND FORMAT THE PREVIOUS SGCN DATA FROM THE ALLSGCNUSE LAYER SO WE CAN COMPARE
# load in SGCN data from previous update
SGCN_prev <- arc.open(path=here::here("_data","output",updateNameprev,"SGCN.gdb","allSGCNuse"))
SGCN_prev <- arc.select(SGCN_prev)

# report out all values in previous source
print("Data sources in previous SGCN list BEFORE replace:")
unique(SGCN_prev$DataSource)

# replace more specific data sources with broader data sources - if we ever have a need to track more specific data sources, we can change this
SGCN_prev[SGCN_prev=="PGC Grouse Data"] <- "PGC"
SGCN_prev[SGCN_prev=="PGC Woodcock Data"] <- "PGC"
SGCN_prev[SGCN_prev=="PGC_DougGross"] <- "PGC"
SGCN_prev[SGCN_prev=="PGC waterfowl"] <- "PGC"
SGCN_prev[SGCN_prev=="PFBC_DPF"] <- "PFBC"
SGCN_prev[SGCN_prev=="bat_EPFUabc"] <- "PGC"
SGCN_prev[SGCN_prev=="bat_EPFUcontrap"] <- "PGC"
SGCN_prev[SGCN_prev=="bat_EPFUhiber"] <- "PGC"
SGCN_prev[SGCN_prev=="bat_EPFUPGCtrap"] <- "PGC"
SGCN_prev[SGCN_prev=="bat_LANOcontrap"] <- "PGC"
SGCN_prev[SGCN_prev=="bat_LANOPGCtrap"] <- "PGC"
SGCN_prev[SGCN_prev=="PGCCon_2021-2022"] <- "PGC"
SGCN_prev[SGCN_prev=="PGC Woodcock Email Data"] <- "PGC"
SGCN_prev[SGCN_prev=="PGC_captures"] <- "PGC"
SGCN_prev[SGCN_prev=="PNHP CPP"] <- "PNHP Biotics"
SGCN_prev[SGCN_prev=="PNHP ER"] <- "PNHP Biotics"
SGCN_prev[SGCN_prev=="PGC Barn Owl Conservation Initiative"] <- "PGC"
SGCN_prev[SGCN_prev=="PGC Woodcock Data 2023"] <- "PGC"

# just double check output data sources if needed
print("Data sources in current SGCN list AFTER replace:")
unique(SGCN_prev$DataSource)


# aggregate data by SNAME and DataSource to get number of records per species per data source
SGCNrecordcount <- aggregate(LastObs~SNAME+DataSource, data=SGCN_prev, FUN=length)
# rename column so it makes more sense
colnames(SGCNrecordcount)[colnames(SGCNrecordcount)=="LastObs"] <- "RecordCount_prev"

# aggregate data by min and max LastObs by species and data source and rename columns to make more sense
SGCN_Max <- aggregate(LastObs~SNAME+DataSource, data=SGCN_prev, max)
colnames(SGCN_Max)[colnames(SGCN_Max)=="LastObs"] <- "MaxYear_prev"
SGCN_Min <- aggregate(LastObs~SNAME+DataSource, data=SGCN_prev, min)
colnames(SGCN_Min)[colnames(SGCN_Min)=="LastObs"] <- "MinYear_prev"

# merge all the values to get them in one table for the current update period
SGCNsummary_prev <- merge(SGCNrecordcount, SGCN_Max, by=c("SNAME","DataSource"))
SGCNsummary_prev <- merge(SGCNsummary_prev, SGCN_Min, by=c("SNAME","DataSource"))

# merge the current data with the previous data and get difference in total record count - THIS IS WHAT WE ARE MOST INTERESTED IN FOR QC PURPOSES!!!
SGCNsummary <- merge(SGCNsummary_curr, SGCNsummary_prev, by=c("SNAME","DataSource"))
SGCNsummary$RecordCount_diff <- SGCNsummary$RecordCount_curr - SGCNsummary$RecordCount_prev

# merge in sgcn info so we have taxa group and common name
SGCNsummary <- merge(SGCNsummary, lu_sgcn, by="SNAME", all.x=TRUE)

# rearrange and select the final column names
SGCNsummary <- SGCNsummary[c("taxadisplay","SCOMNAME","SNAME","DataSource","RecordCount_curr","RecordCount_prev","RecordCount_diff","MinYear_curr","MinYear_prev","MaxYear_curr","MaxYear_prev")]
# sort records by taxa group, then common name, then data source - we could change this to difference in records if desired
SGCNsummary <- SGCNsummary[order(SGCNsummary$taxadisplay,SGCNsummary$SCOMNAME,SGCNsummary$DataSource),]
# rename columns
names(SGCNsummary) <- c("Taxonomic Group","Common Name","Scientific Name","Data Source","Record Count - Current", "Record Count - Previous", "Record Count - Difference", "Min Year - Current", "Min Year - Previous", "Max Year - Current", "Max Year - Previous")

# this gets rid of records that do not match record in lu_SGCN list - we will keep these records for QC purposes - we need to check where these are coming from and if we can fix taxonomic issues
#SGCNsummary <- SGCNsummary[which(!is.na(SGCNsummary$`Taxonomic Group`)),]

# define output file path and name and write to .csv file
out_file <- here::here("_data","output",updateName,paste("SGCNsummary_DETAILED_QC",updateName,".csv",sep=""))
write.table(SGCNsummary, out_file, row.names=FALSE, col.names=TRUE, sep=",")

