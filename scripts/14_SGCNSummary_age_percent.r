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

# clear the environments
rm(list=ls())

source(here::here("scripts","00_PathsAndSettings.r"))


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
SGCN[SGCN=="PGCCon_2021-2022"] <- "PGC"
SGCN[SGCN=="PGC Woodcock Email Data"] <- "PGC"
SGCN[SGCN=="PGC_captures"] <- "PGC"
SGCN[SGCN=="PNHP CPP"] <- "PNHP Biotics"
SGCN[SGCN=="PNHP ER"] <- "PNHP Biotics"
SGCN[SGCN=="PGC Barn Owl Conservation Initiative"] <- "PGC"
SGCN[SGCN=="PGC Woodcock Data 2023"] <- "PGC"
           
unique(SGCN$DataSource)


# aggregate data by min/max year
SGCNrecordcount <- aggregate(LastObs~SNAME+DataSource, data=SGCN, FUN=length)
colnames(SGCNrecordcount)[colnames(SGCNrecordcount)=="LastObs"] <- "RecordCount"
SGCN_Max <- aggregate(LastObs~SNAME+DataSource, data=SGCN, max)
colnames(SGCN_Max)[colnames(SGCN_Max)=="LastObs"] <- "MaxYear"
SGCN_Min <- aggregate(LastObs~SNAME+DataSource, data=SGCN, min)
colnames(SGCN_Min)[colnames(SGCN_Min)=="LastObs"] <- "MinYear"


age_out_5 <- SGCN %>%
  dplyr::group_by(SNAME, DataSource) %>%  # Replace "grouping_variable" with the column you want to group by
  dplyr::reframe(count_in_range = count(LastObs >= cutoffyear & LastObs <= cutoffyear+5)) %>%
  tidyr::unnest(c(count_in_range),keep_empty=TRUE)
age_out_5 <- age_out_5[which(age_out_5$x == TRUE),]
colnames(age_out_5)[colnames(age_out_5)=="freq"] <- "year5cutoff"

age_out_10 <- SGCN %>%
  dplyr::group_by(SNAME, DataSource) %>%  # Replace "grouping_variable" with the column you want to group by
  dplyr::reframe(count_in_range = count(LastObs >= cutoffyear & LastObs <= cutoffyear+10)) %>%
  tidyr::unnest(c(count_in_range),keep_empty=TRUE)
age_out_10 <- age_out_10[which(age_out_10$x == TRUE),]
colnames(age_out_10)[colnames(age_out_10)=="freq"] <- "year10cutoff"


SGCNsummary <- merge(SGCNrecordcount, SGCN_Max, by=c("SNAME","DataSource"))
SGCNsummary <- merge(SGCNsummary, SGCN_Min, by=c("SNAME","DataSource"))
SGCNsummary <- merge(SGCNsummary, lu_sgcn, by="SNAME", all.x=TRUE)
SGCNsummary <- merge(SGCNsummary, age_out_5, by=c("SNAME","DataSource"))
SGCNsummary <- merge(SGCNsummary, age_out_10, by=c("SNAME","DataSource"))

SGCNsummary$year5percent <- round((SGCNsummary$year5cutoff/SGCNsummary$RecordCount)*100,2)
SGCNsummary$year10percent <- round((SGCNsummary$year10cutoff/SGCNsummary$RecordCount)*100,2)

# rearrange the column names
SGCNsummary <- SGCNsummary[c("taxadisplay","SCOMNAME","SNAME","DataSource","RecordCount","MinYear","MaxYear","year5cutoff","year5percent","year10cutoff","year10percent")]
# sort
SGCNsummary <- SGCNsummary[order(SGCNsummary$taxadisplay,SGCNsummary$SCOMNAME,SGCNsummary$DataSource),]
# rename columns
names(SGCNsummary) <- c("Taxonomic Group","Common Name","Scientific Name","Data Source","Record Count","MinYear","MaxYear","Records aging out in 5 years","Percent records aging out in 5 years","Records aging out in 10 years","Percent records aging out in 10 years")

SGCNsummary <- SGCNsummary[which(!is.na(SGCNsummary$`Taxonomic Group`)),]


a1 <- "The following information regarding Wildlife Action Plan Conservation Opportunity Area Tool data sources, number of records for each data source, and the record dates is provided by the Pennsylvania Natural Heritage Program (PNHP) for reference purposes. Please contact Pennsylvania Game Commission (birds, mammals, terrestrial invertebrates; PGCSWAP@pa.gov) or Pennsylvania Fish & Boat Commission (fish, amphibians, reptiles, aquatic or terrestrial invertebrates; RA-FBSWAP@pa.gov) for more information."
b1 <- "KEY: BAMONA = Butterflies and Moths of North America; BBA_PtCt = Pennsylvania Breeding Bird Atlas point counts (Wilson et al. 2012); DillonSnails = aquatic snail records contributed by an expert in the field; eBird = free bird sighting database administered by Cornell Lab of Ornithology (ebird.org); GBIF = Global Biodiversity Information Facility, an open access index of species occurrence records (more information can be found at https://www.gbif.org/en/what-is-gbif); iNaturalist = (www.inaturalist.org); PFBC = Pennsylvania Fish & Boat Commission data; PGC = Pennsylvania Game Commission data; PNHP Biotics = Pennsylvania Natural Heritage Program database of unique, threatened or endangered species that is linked with NatureServe, a global biodiversity conservation organization (more information can be found at http://www.natureserve.org/conservation-tools/biotics-5); PNHP POND = Poool Observation Networked Database, a database of vernal pool data; PSU-Brittingham-Miller = bird data from a Pennsylvania State University research lab; TREC = Tom Ridge Environmental Center in Erie, PA; USFS-NRS = SGNC data contributed by the Allegheny National Forest; Xerces = Xerces Society, an invertebrate conservation organization (more information can be found at https://xerces.org/)." 


options(useFancyQuotes = FALSE)
sink(here::here("_data","output",updateName,paste("SGCNsummary_internal_",updateName,".csv",sep="")))
cat(paste(dQuote(a1),"\n" , sep=" "))
cat(paste(dQuote(b1),"\n" , sep=" "))
cat("\n")
write.table(SGCNsummary, row.names=FALSE, col.names=TRUE, sep=",")
sink()                      
options(useFancyQuotes = TRUE)

