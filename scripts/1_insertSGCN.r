#-------------------------------------------------------------------------------
# Name:        1_insertSGCN.r
# Purpose:     Create an empty, new COA databases
# Author:      Christopher Tracey
# Created:     2019-02-14
# Updated:     2019-02-14
#
# To Do List/Future ideas:
# * modify to run off the lu_sgcn data on the arc server
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())


if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

## Read SGCN list in
SGCNlist <- here::here("_data","input","lu_SGCNnew.csv")
SGCN <- read.csv(SGCNlist, stringsAsFactors=FALSE) # read in the SGCN list

file.info(SGCNlist)$mtime



# QC to make sure that the ELCODES match the first part of the ELSeason code.
if(length(setdiff(SGCN$ELCODE, gsub("(.+?)(\\_.*)", "\\1", SGCN$ELSeason)))==0){
  print("ELCODEs and ELSeason strings match. You're good to go!")
} else {
  print(paste("Codes for ", setdiff(SGCN$ELCODE, gsub("(.+?)(\\_.*)", "\\1", SGCN$ELSeason)), " do not match;", sep=""))
}

# check for leading/trailing whitespace
SGCN$SNAME <- trimws(SGCN$SNAME, which="both")
SGCN$SCOMNAME <- trimws(SGCN$SCOMNAME, which="both")
SGCN$ELSeason <- trimws(SGCN$ELSeason, which="both")
SGCN$TaxaDisplay <- trimws(SGCN$TaxaDisplay, which="both")

# remove hidden newline characters
SGCN$SRANK <- gsub("[\r\n]", "", SGCN$SRANK)
SGCN$GRANK <- gsub("[\r\n]", "", SGCN$GRANK)


# compare to the ET
#get the most recent ET
ET_file <- list.files(path="P:/Conservation Programs/Natural Heritage Program/Data Management/Biotics Database Areas/Element Tracking/current element lists", pattern=".xlsx$")  # --- make sure your excel file is not open.
ET_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 3
ET_file <- file.path("P:/Conservation Programs/Natural Heritage Program/Data Management/Biotics Database Areas/Element Tracking/current element lists",ET_file[n])


file.info(ET_file)$mtime

#get a list of the sheets in the file
ET_sheets <- getSheetNames(ET_file)
#look at the output and choose which excel sheet you want to load
# Enter the actions sheet (eg. "lu_actionsLevel2") 
ET_sheets # list the sheets
n <- 1 # enter its location in the list (first = 1, second = 2, etc)
ET <- read.xlsx(xlsxFile=ET_file, sheet=ET_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

ET <- ET[c("ELCODE","SCIENTIFIC.NAME","COMMON.NAME","G.RANK","S.RANK","SRANK.CHANGE.DATE","SRANK.REVIEW.DATE","TRACKING.STATUS")] # which(ET$SGCN.STATUS=="Y"),

SGCNtest <- merge(SGCN[c("ELCODE","SNAME","SCOMNAME","GRANK","SRANK")], ET, by.x="ELCODE", by.y="ELCODE", all.x = TRUE)

SGCNtest$matchGRANK <- ifelse(SGCNtest$GRANK==SGCNtest$G.RANK,"yes","no")
SGCNtest$matchSRANK <- ifelse(SGCNtest$SRANK==SGCNtest$S.RANK,"yes","no")

SGCNtest[which(SGCNtest$matchGRANK=="no"),]$SNAME
SGCNtest[which(SGCNtest$matchSRANK=="no"),]$SNAME

SGCN1 <- merge(SGCN, ET[c("ELCODE","G.RANK","S.RANK")], by="ELCODE", all.x = TRUE )
SGCN1$GRANK <- SGCN1$G.RANK
SGCN1$G.RANK <- NULL
SGCN1$SRANK <- SGCN1$S.RANK
SGCN1$S.RANK <- NULL

SGCN <- SGCN1

###########################################
# write the lu_sgcn table to the database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SGCN", SGCN, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(SGCN)

## Taxa Group import
taxagrp <- read.csv(here::here("_data","input","lu_taxagrp.csv"), stringsAsFactors=FALSE)
taxagrp$OID <- NULL

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_taxagrp", taxagrp, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(taxagrp)

