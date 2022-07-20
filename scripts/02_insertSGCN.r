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
#look at the output and choose which file you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 10 # this should  the "lu_SGCN.csv" from the previous quarter!!!!!!!!!!!!!!!!!!!!
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
arc.check_portal()  # may need to update bridge to most recent version if it crashes: https://github.com/R-ArcGIS/r-bridge/issues/46
ET <- arc.open(paste(biotics_path,"ET",sep="/"))  # 5 is the number of the ET
ET <- arc.select(ET, c("ELSUBID","ELCODE","SNAME","SCOMNAME","GRANK","SRANK","SRANK_CHGD","SRANK_RVWD","EO_TRACK","SGCN","SENSITV_SP")) # , where_clause="SGCN='Y'"
# write to file tracker  REMOVED for now

SGCNtest <- merge(SGCN[c("ELCODE","SNAME","SCOMNAME","GRANK","SRANK")], ET, by.x="ELCODE", by.y="ELCODE", all.x = TRUE)

# compare elcodes
if(length(SGCNtest[which(is.na(SGCNtest$SNAME.y)),])>0){
  print("The following species in the lu_SGCN table did not find a matching ELCODE in Biotics and needs to be fixed.")
  print(SGCNtest[which(is.na(SGCNtest$SNAME.y)),"SNAME.x"])
  print(paste("A file named badELCODEs_",updateName,".csv has been saved in the output directory", sep=""))
  write.csv(SGCNtest[which(is.na(SGCNtest$SNAME.y)),], here::here("_data","output",updateName,paste("badELCODEs_",updateName,".csv")), row.names=FALSE)
} else {
  print("No mismatched ELCODES---you are good to go and hopefully there will be less trauma during this update...")
}


#compare g-ranks
SGCNtest$matchGRANK <- ifelse(SGCNtest$GRANK.x==SGCNtest$GRANK.y,"yes","no")
if(all(SGCNtest$matchGRANK=="yes")){
  print("GRANK strings match. You're good to go!")
} else {
  print(paste("GRANKS for ", SGCNtest[which(SGCNtest$matchGRANK=="no"),"SNAME.x"] , " do not match;", sep=""))
}
# compare s-ranks
SGCNtest$matchSRANK <- ifelse(SGCNtest$SRANK.x==SGCNtest$SRANK.y,"yes","no")
if(all(SGCNtest$matchSRANK=="yes")){
  print("GRANK strings match. You're good to go!")
} else {
  print(paste("SRANKS for ", SGCNtest[which(SGCNtest$matchSRANK=="no"),"SNAME.x"] , " do not match;", sep=""))
}

SGCNtest <- SGCNtest[which(SGCNtest$matchGRANK=="no"|SGCNtest$matchSRANK=="no"),] # edit this down to just the changes
SGCNtest$ELSUBID <- NULL
SGCNtest$EO_TRACK <- NULL
SGCNtest$SGCN <- NULL
SGCNtest$SENSITV_SP <- NULL

names(SGCNtest) <- c("ELCODE","SGCN_SNAME","SGCN_SCOMNAME","SGCN_GRANK","SGCN_SRANK","ET_SNAME","ET_SCOMNAME","ET_GRANK","ET_SRANK","ET_SRANK.CHANGE.DATE","ET_SRANK.REVIEW.DATE","matchGRANK","matchSRANK") 

SGCNtest$Name <- sub('.', '', updateName) #insert the update name and remove the first character

dbTracking <- dbConnect(SQLite(), dbname=trackingdatabasename) # connect to the database
dbExecute(dbTracking, paste("DELETE FROM changed_ranks WHERE Name='",sub('.', '', updateName),"'", sep="")) # 
dbAppendTable(dbTracking, "changed_ranks", SGCNtest, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(dbTracking) # disconnect the db

# replace data in table
SGCN1 <- merge(SGCN, ET[c("ELCODE","GRANK","SRANK")], by="ELCODE", all.x = TRUE )
SGCN1$GRANK.x <- SGCN1$GRANK.y
SGCN1$GRANK.y <- NULL
names(SGCN1)[names(SGCN1) == "GRANK.x"] <- "GRANK"
SGCN1$SRANK.y <- SGCN1$SRANK.y
SGCN1$SRANK.y <- NULL
names(SGCN1)[names(SGCN1) == "SRANK.x"] <- "SRANK"
SGCN <- SGCN1
rm(SGCN1)
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

