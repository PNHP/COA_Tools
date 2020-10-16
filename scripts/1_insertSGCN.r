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

SGCNlist_file <- list.files(path=here::here("_data","input"), pattern="^lu_SGCN")  # --- make sure your excel file is not open.
SGCNlist_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 3
SGCNlist_file <- here::here("_data","input",SGCNlist_file[n])
SGCN <- read.csv(SGCNlist_file, stringsAsFactors=FALSE)

# write to file tracker
trackfiles("SGCN List", SGCNlist_file)

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

# write to file tracker
filetracker <- data.frame(NameUpdate=sub('.', '', updateName), item="ET File", filename=(ET_file), lastmoddate=file.info(ET_file)$mtime)
dbTracking <- dbConnect(SQLite(), dbname=trackingdatabasename) # connect to the database
dbExecute(dbTracking, paste("DELETE FROM filetracker WHERE (NameUpdate='",sub('.', '', updateName),"' AND item='ET File')", sep="")) # 
dbWriteTable(dbTracking, "filetracker", filetracker, append=TRUE, overwrite=FALSE) # write the table to the sqlite
dbDisconnect(dbTracking) # disconnect the db
rm(filetracker)

trackfiles("ET File", ET_file)

#get a list of the sheets in the file
ET_sheets <- getSheetNames(ET_file)
#look at the output and choose which excel sheet you want to load
# Enter the actions sheet (eg. "lu_actionsLevel2") 
ET_sheets # list the sheets
n <- 1 # enter its location in the list (first = 1, second = 2, etc)
ET <- read.xlsx(xlsxFile=ET_file, sheet=ET_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE,  detectDates = TRUE)
ET <- ET[c("ELCODE","SCIENTIFIC.NAME","COMMON.NAME","G.RANK","S.RANK","SRANK.CHANGE.DATE","SRANK.REVIEW.DATE")] # which(ET$SGCN.STATUS=="Y"),

SGCNtest <- merge(SGCN[c("ELCODE","SNAME","SCOMNAME","GRANK","SRANK")], ET, by.x="ELCODE", by.y="ELCODE", all.x = TRUE)

SGCNtest$matchGRANK <- ifelse(SGCNtest$GRANK==SGCNtest$G.RANK,"yes","no")
SGCNtest$matchSRANK <- ifelse(SGCNtest$SRANK==SGCNtest$S.RANK,"yes","no")

SGCNtest[which(SGCNtest$matchGRANK=="no"),]$SNAME
SGCNtest[which(SGCNtest$matchSRANK=="no"),]$SNAME

SGCNtest <- SGCNtest[which(SGCNtest$matchGRANK=="no"|SGCNtest$matchSRANK=="no"),] # edit this down to just the changes
names(SGCNtest) <- c("ELCODE","SGCN_SNAME","SGCN_SCOMNAME","SGCN_GRANK","SGCN_SRANK","ET_SNAME","ET_SCOMNAME","ET_GRANK","ET_SRANK","ET_SRANK.CHANGE.DATE","ET_SRANK.REVIEW.DATE","matchGRANK","matchSRANK") 

SGCNtest$Name <- sub('.', '', updateName) #insert the update name and remove the first character

dbTracking <- dbConnect(SQLite(), dbname=trackingdatabasename) # connect to the database
dbExecute(dbTracking, paste("DELETE FROM changed_ranks WHERE Name='",sub('.', '', updateName),"'", sep="")) # 
dbAppendTable(dbTracking, "changed_ranks", SGCNtest, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(dbTracking) # disconnect the db

# replace data in table
SGCN1 <- merge(SGCN, ET[c("ELCODE","G.RANK","S.RANK")], by="ELCODE", all.x = TRUE )
SGCN1$GRANK <- SGCN1$G.RANK
SGCN1$G.RANK <- NULL
SGCN1$SRANK <- SGCN1$S.RANK
SGCN1$S.RANK <- NULL
SGCN <- SGCN1

write.csv(SGCN, here::here("_data","input",paste("lu_SGCN",updateName,".csv", sep="")), row.names=FALSE)

###########################################
# write the lu_sgcn table to the database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_SGCN", SGCN, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(SGCN)

###########################################
## Taxa Group import
taxagrp <- read.csv(here::here("_data","input","lu_taxagrp.csv"), stringsAsFactors=FALSE)
taxagrp$OID <- NULL

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_taxagrp", taxagrp, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(taxagrp)

