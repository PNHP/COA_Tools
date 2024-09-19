#-------------------------------------------------------------------------------
# Name:        001_ET_Checks.r
# Purpose:     Prior to starting the COA Update process, this checks for ET changes that need to be made.
# Author:      Molly Moore
# Created:     2024-04-03
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

## Read the most current SGCN list in
SGCNlist_file <- list.files(path=here::here("_data","input"), pattern="^lu_SGCN")  # --- make sure your .csv is not open.
SGCNlist_file
#look at the output and choose which file you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 18 # this should  the "lu_SGCN.csv" from the previous quarter!
SGCNlist_file <- here::here("_data","input",SGCNlist_file[n])
SGCN <- read.csv(SGCNlist_file, stringsAsFactors=FALSE)

## 1 - QC to make sure that ELCODE and ELSEASON codes match
if(length(setdiff(SGCN$ELCODE, gsub("(.+?)(\\_.*)", "\\1", SGCN$ELSeason)))==0){
  print("ELCODEs and ELSeason strings match. You're good to go!")
} else {
  print(paste("Codes for ", setdiff(SGCN$ELCODE, gsub("(.+?)(\\_.*)", "\\1", SGCN$ELSeason)), " do not match;", sep=""))
}

# trim leading/trailing whitespace *** WOULD BE NICE TO CHANGE THIS TO A WHITESPACE CHECK SO IT CAN BE FIXED IN ORIGINAL SOURCE
SGCN$SNAME <- trimws(SGCN$SNAME, which="both")
SGCN$SCOMNAME <- trimws(SGCN$SCOMNAME, which="both")
SGCN$ELSeason <- trimws(SGCN$ELSeason, which="both")
SGCN$TaxaDisplay <- trimws(SGCN$TaxaDisplay, which="both")

# remove hidden newline characters
SGCN$SRANK <- gsub("[\r\n]", "", SGCN$SRANK)
SGCN$GRANK <- gsub("[\r\n]", "", SGCN$GRANK)

# get the most recent ET from Biotics
arc.check_portal()  # may need to update bridge to most recent version if it crashes: https://github.com/R-ArcGIS/r-bridge/issues/46
ET <- arc.open(paste(biotics_path,"ET",sep="/"))  # 5 is the number of the ET
ET <- arc.select(ET, c("ELSUBID","ELCODE","SNAME","SCOMNAME","GRANK","SRANK","EO_TRACK","SGCN","SENSITV_SP"), where_clause="SGCN='Y'") # , where_clause="SGCN='Y'"

# join lu_SGCN dataframe with ET dataframe by ELCODE
SGCNtest <- merge(SGCN[c("ELCODE","SNAME","SCOMNAME","GRANK","SRANK")], ET, by.x="ELCODE", by.y="ELCODE", all.x = TRUE)

# compare ELCODES to see if there are ELCODE updates that need to happen in lu_SGCN table
if(length(SGCNtest[which(is.na(SGCNtest$SNAME.y)),])>0){
  print("The following species in the lu_SGCN table did not find a matching ELCODE in Biotics and needs to be fixed.")
  print(SGCNtest[which(is.na(SGCNtest$SNAME.y)),"SNAME.x"])
  print(paste("A file named badELCODEs_",updateName,".csv has been saved in the output directory", sep=""))
  write.csv(SGCNtest[which(is.na(SGCNtest$SNAME.y)),], here::here("_data","output",updateName,paste("badELCODEs_",updateName,".csv")), row.names=FALSE)
} else {
  print("No mismatched ELCODES---you are good to go and hopefully there will be less trauma during this update...")
}

# reconcile ELCODES in ET and lu_SGCN
print("The following ELCODES are in the ET, but are NOT in the lu_SGCN:")
ET$ELCODE[!(ET$ELCODE %in% SGCN$ELCODE)] # this shows ELCODES in ET that are NOT in lu_SGCN
print("The following ELCODES are in the lu_SGCN, but are NOT in the ET:")
SGCN$ELCODE[!(SGCN$ELCODE %in% ET$ELCODE)] # this shows ELCODES in lu_SGCN that are NOT in ET


# check to see mismatches in SNAME and create .csv list
print("The following SNAMEs in lu_SGCN DO NOT match the SNAME in the ET:")
sname_mismatch <- setdiff(SGCNtest$SNAME.x, SGCNtest$SNAME.y)

crosswalk <- read.csv(biotics_crosswalk, stringsAsFactors=FALSE)
mismatch_crosswalk <- crosswalk[crosswalk$SGCN_NAME %in% sname_mismatch,]


## add checks for ranks and statuses



## add checks for actions elseason code mismatches and other ancilliary tables



####################################
## Check if reference links are valid
# Enter the references sheet (eg. "lu_BPreference") 
COA_actions_sheets # list the sheets
n <- 4 # enter its location in the list (first = 1, second = 2, etc)
COA_references <- read.xlsx(xlsxFile=COA_actions_file, sheet=COA_actions_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

# rename problematic fields
names(COA_references)[names(COA_references) == 'REFERENCE#'] <- 'ReferenceID'
names(COA_references)[names(COA_references) == 'REFERENCE.NAME'] <- 'REF_NAME'
COA_references$ActionCategory1 <- NULL
COA_references$ActionCategory2 <- NULL

# check if url exist
library(httr)

for(l in 1:nrow(COA_references)){
  if(is.na(COA_references$LINK[l])){
    print(paste("url for -",COA_references$REF_NAME[l],"- is NULL"), sep=" ")}
  else if(isFALSE(http_error(COA_references$LINK[l]))){
    print(paste("url for -",COA_references$REF_NAME[l],"- is valid"), sep=" ")}
  else if(isTRUE(http_error(COA_references$LINK[l]))){
    print(paste("url for -",COA_references$REF_NAME[l],"- is NOT VALID"), sep=" ")}
}


