#---------------------------------------------------------------------------------------------
# Name: SWS_unit_creator.r
# Purpose: 
# Author: Christopher Tracey
# Created: 2019-02-21
# Updated: 2019
#
# Updates:
#
# To Do List/Future Ideas:
#---------------------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

# load packages
if (!requireNamespace("stringr", quietly=TRUE)) install.packages("stringr")
  require(stringr)
if (!requireNamespace("naniar", quietly=TRUE)) install.packages("naniar")
  require(naniar)
if (!requireNamespace("reshape2", quietly=TRUE)) install.packages("reshape2")
  require(reshape2)

# load the arcgis license
arc.check_product()
 
# this script requires a geodatabase to be placed in the "" directory called "sws.gdb".  This gdb should two feature classes contained within it ("_HUC8" and "_county")

# copy the blankSGCN directory from the base folder to the output directory
current_folder <- here::here("_data","templates","sws_blank.gdb") 
new_folder <- here::here("_data","output",updateName,"sws.gdb") 
list_of_files <- list.files(path=current_folder, full.names=TRUE) 
dir.create(new_folder)
file.copy(from=file.path(list_of_files), to=new_folder,  overwrite=TRUE, recursive=FALSE, copy.mode=TRUE)

# # copy mxds
file.copy(from=here::here("_data","templates","SGCNCountyRangeMaps.mxd"), to=here::here("_data","output",updateName,"SGCNCountyRangeMaps.mxd"),  overwrite=TRUE, recursive=FALSE, copy.mode=TRUE)
file.copy(from=here::here("_data","templates","SGCNWatershedRangeMaps.mxd"), to=here::here("_data","output",updateName,"SGCNWatershedRangeMaps.mxd"),  overwrite=TRUE, recursive=FALSE, copy.mode=TRUE)

# function to grab the rightmost characters
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

# set options   
options(useFancyQuotes=FALSE)

# Set input paths ----
databasename <- here::here("_data","output",updateName,"coa_bridgetest.sqlite") 

db <- dbConnect(SQLite(), dbname=databasename)
# get the SGCN by planning unit data
SQLquery <- paste("SELECT unique_id, ELSeason, OccProb", " FROM lu_sgcnXpu_all ", " WHERE OccProb='k' OR OccProb='K' OR OccProb='l' OR OccProb='L'")
data_sgcnXpu <- dbGetQuery(db, statement = SQLquery)

# get the county data
SQLquery_county <- paste("SELECT COUNTY_NAM, FIPS_COUNT"," FROM lu_CountyName ")
data_countyname <- dbGetQuery(db, statement = SQLquery_county )
data_countyname$FIPS_COUNT <- as.character(data_countyname$FIPS_COUNT)
data_countyname$FIPS_COUNT <- str_pad(data_countyname$FIPS_COUNT, width=3, pad="0")

# get the HUC8 data
SQLquery_luNatBound <- paste("SELECT unique_id, HUC8"," FROM lu_NaturalBoundaries ")
data_NaturalBoundaries <- dbGetQuery(db, statement = SQLquery_luNatBound )

# get SGCN data
SQLquery <- paste("SELECT ELCODE, SCOMNAME, SNAME, GRANK, SRANK, USESA, SPROT, PBSSTATUS, TaxaDisplay"," FROM lu_sgcn ")
data_sgcn <- dbGetQuery(db, statement = SQLquery)
data_sgcn <- unique(data_sgcn)
data_sgcn <- replace_with_na(data_sgcn, replace=list(USESA="",SPROT="",PBSSTATUS=""))

# get the primary macrogroup
SQLquery_luPriMacrogroup <- paste("SELECT *"," FROM lu_PrimaryMacrogroup ")
data_luPriMacrogroup <- dbGetQuery(db, statement = SQLquery_luPriMacrogroup )
data_luPriMacrogroup$ELCODE <- substr(data_luPriMacrogroup$ELSeason, 1,10)
data_luPriMacrogroup$season <- substrRight(data_luPriMacrogroup$ELSeason, 1)
data_luPriMacrogroup <- data_luPriMacrogroup[c("PrimMacro","ELCODE","season")] 
library(tidyr)
data_luPriMacrogroup <- aggregate(data=data_luPriMacrogroup, PrimMacro~ELCODE+season, FUN=paste, collapse=", ")
data_luPriMacrogroup <- data_luPriMacrogroup %>% spread(season, PrimMacro)
data_luPriMacrogroup$b <- ifelse(is.na(data_luPriMacrogroup$b), NA, paste("B:",data_luPriMacrogroup$b, sep=" "))
data_luPriMacrogroup$m <- ifelse(is.na(data_luPriMacrogroup$m), NA, paste("M:",data_luPriMacrogroup$m, sep=" "))
data_luPriMacrogroup$w <- ifelse(is.na(data_luPriMacrogroup$w), NA, paste("W:",data_luPriMacrogroup$w, sep=" "))
data_luPriMacrogroup1 <- data_luPriMacrogroup %>% unite("PrimMacro", b,m,w,y, na.rm=TRUE, sep="; ")

# disconnect the db
dbDisconnect(db)

# merge the data into a single dataframe
sws <- merge(data_sgcnXpu,data_NaturalBoundaries,by="unique_id",all.x=TRUE)
#rm(data_NaturalBoundaries)

# get the county FIPS code and join the county names from the other table
sws$county_FIPS <- substr(sws$unique_id,1,3)
sws <- merge(sws,data_countyname,by.x="county_FIPS",by.y="FIPS_COUNT", all.x=TRUE)
#rm(data_countyname, data_sgcnXpu)

# extract the season code from the ELSeason
sws$season <- substrRight(sws$ELSeason, 1)

# extract the ELCODE from ELSeason and rname ELSeason to ELCODE
sws$ELSeason <- substr(sws$ELSeason,1,10)
names(sws)[names(sws)=='ELSeason'] <- 'ELCODE'

sws$HUC8 <- as.character(sws$HUC8)
sws$HUC8 <- str_pad(sws$HUC8, width=8, pad="0")

# rearrange into a more sensible list
sws <- sws[c("unique_id","HUC8","COUNTY_NAM","ELCODE","season","OccProb")]

# make a table of the count of PUs by HUC8/county just for informational purposes
PU_HUC8 <- as.data.frame(table(sws$HUC8))
PU_county <- as.data.frame(table(sws$COUNTY_NAM))

#table(sws$ELCODE,sws$OccProb,sws$HUC8)

####
# summarize by HUC8
sws_HUC8agg <- aggregate(unique_id ~ ELCODE+OccProb+HUC8+season, sws, function(x) length(x))

# generate HUC8 occurrence summary
a <- aggregate(unique_id ~ ELCODE+OccProb+HUC8, sws, function(x) length(x))
b <- dcast(a, ELCODE+HUC8~OccProb, sum, value.var="unique_id")
b$Occurrence <- NA
b$Occurrence <- ifelse(b$k>0, "Known","Likely")


sws_HUC8agg_cast <- dcast(sws_HUC8agg, ELCODE+HUC8~season, sum, value.var="unique_id")  
sws_HUC8agg_cast <- merge(sws_HUC8agg_cast, PU_HUC8 , by.x="HUC8", by.y="Var1")
sws_HUC8agg_cast$b <- sws_HUC8agg_cast$b / sws_HUC8agg_cast$Freq
sws_HUC8agg_cast$m <- sws_HUC8agg_cast$m / sws_HUC8agg_cast$Freq
sws_HUC8agg_cast$w <- sws_HUC8agg_cast$w / sws_HUC8agg_cast$Freq
sws_HUC8agg_cast$y <- sws_HUC8agg_cast$y / sws_HUC8agg_cast$Freq
sws_HUC8agg_cast$Freq <- NULL
names(sws_HUC8agg_cast)[names(sws_HUC8agg_cast)=='b'] <- 'b_prop'
names(sws_HUC8agg_cast)[names(sws_HUC8agg_cast)=='m'] <- 'm_prop'
names(sws_HUC8agg_cast)[names(sws_HUC8agg_cast)=='w'] <- 'w_prop'
names(sws_HUC8agg_cast)[names(sws_HUC8agg_cast)=='y'] <- 'y_prop'
sws_HUC8agg_cast$b <- ifelse(sws_HUC8agg_cast$b_prop>0, "yes", NA)
sws_HUC8agg_cast$m <- ifelse(sws_HUC8agg_cast$m_prop>0, "yes", NA)
sws_HUC8agg_cast$w <- ifelse(sws_HUC8agg_cast$w_prop>0, "yes", NA)
sws_HUC8agg_cast$y <- ifelse(sws_HUC8agg_cast$y_prop>0, "yes", NA)
# remove the proportions since they are not to be displayed anymore
sws_HUC8agg_cast$b_prop <- NULL
sws_HUC8agg_cast$m_prop <- NULL
sws_HUC8agg_cast$w_prop <- NULL
sws_HUC8agg_cast$y_prop <- NULL

# merge the HUC8 occrence summary
sws_HUC8agg_cast <- merge(sws_HUC8agg_cast, b[c("ELCODE","HUC8","Occurrence")], by=c("ELCODE","HUC8"), all.x=TRUE)

# merge the primary macrogroup info in
sws_HUC8agg_cast <- merge(sws_HUC8agg_cast, data_luPriMacrogroup1, by="ELCODE", all.x=TRUE)

# TEMP for Testing  #######################
#save.image(file=here::here("_data","output",updateName, "tempSWS.RData"))
#load(here::here("_data","output",updateName, "tempSWS.RData"))
###########################################


# load the HUC8 basemap
HUC8_shp <- arc.open(here::here("_data","output",updateName,"sws.gdb", "_huc08"))
HUC8_shpprj <- HUC8_shp
HUC8_shp <- arc.select(HUC8_shp)
HUC8_shp <- arc.data2sf(HUC8_shp)
HUC8_shp <- HUC8_shp[c("OBJECTID","HUC8","NAME")]
# map it
sgcnlist <- unique(sws_HUC8agg_cast$ELCODE)
sgcnlist <- gsub("\r\n","",sgcnlist)
sgcnlist <- sort(sgcnlist)

# make the watershed feature classes
for(i in 1:length(sgcnlist)){
  sws_HUC8_1 <- sws_HUC8agg_cast[which(sws_HUC8agg_cast$ELCODE==sgcnlist[i]),]
  print(paste(sgcnlist[i],", which is species ",i," of ",length(sgcnlist), sep=""))
  sws_HUC8_1a <- merge(HUC8_shp,sws_HUC8_1,by.x="HUC8",by.y="HUC8")
  sws_HUC8_1a <- merge(sws_HUC8_1a,data_sgcn,by="ELCODE", all.x=TRUE)
  sws_HUC8_1a <- sws_HUC8_1a[c("ELCODE","HUC8","NAME","TaxaDisplay","SCOMNAME","SNAME","PrimMacro","b","m","w","y","Occurrence","GRANK","SRANK","USESA","SPROT","PBSSTATUS","geometry")]
  arc.write(file.path(here::here("_data","output",updateName,"sws.gdb",paste("HUC8",sgcnlist[i],sep="_"))), sws_HUC8_1a ,overwrite=TRUE) #, shape_info=arc.shapeinfo(HUC8_shpprj)
}

################
# summarize by County
sws_countyagg <- aggregate(unique_id ~ ELCODE+OccProb+COUNTY_NAM+season, sws, function(x) length(x))

# generate county occurrence summary
a <- aggregate(unique_id ~ ELCODE+OccProb+COUNTY_NAM, sws, function(x) length(x))
b <- dcast(a, ELCODE+COUNTY_NAM~OccProb, sum, value.var="unique_id")
b$Occurrence <- NA
b$Occurrence <- ifelse(b$k>0, "Known","Likely")

sws_countyagg_cast <- dcast(sws_countyagg, ELCODE+COUNTY_NAM~season,sum, value.var="unique_id")  #OccProb+
sws_countyagg_cast <- merge(sws_countyagg_cast, PU_county , by.x="COUNTY_NAM", by.y="Var1")
sws_countyagg_cast$b <- sws_countyagg_cast$b / sws_countyagg_cast$Freq
sws_countyagg_cast$m <- sws_countyagg_cast$m / sws_countyagg_cast$Freq
sws_countyagg_cast$w <- sws_countyagg_cast$w / sws_countyagg_cast$Freq
sws_countyagg_cast$y <- sws_countyagg_cast$y / sws_countyagg_cast$Freq
sws_countyagg_cast$Freq <- NULL
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='b'] <- 'b_prop'
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='m'] <- 'm_prop'
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='w'] <- 'w_prop'
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='y'] <- 'y_prop'
sws_countyagg_cast$b <- ifelse(sws_countyagg_cast$b_prop>0, "yes", NA)
sws_countyagg_cast$m <- ifelse(sws_countyagg_cast$m_prop>0, "yes", NA)
sws_countyagg_cast$w <- ifelse(sws_countyagg_cast$w_prop>0, "yes", NA)
sws_countyagg_cast$y <- ifelse(sws_countyagg_cast$y_prop>0, "yes", NA)
# remove the proportions since they are not to be displayed anymore
sws_countyagg_cast$b_prop <- NULL
sws_countyagg_cast$m_prop <- NULL
sws_countyagg_cast$w_prop <- NULL
sws_countyagg_cast$y_prop <- NULL

# merge the county occurrence summary
sws_countyagg_cast <- merge(sws_countyagg_cast, b[c("ELCODE","COUNTY_NAM","Occurrence")], by=c("ELCODE","COUNTY_NAM"), all.x=TRUE)

# merge the primary macrogroup info in
sws_countyagg_cast <- merge(sws_countyagg_cast, data_luPriMacrogroup1, by="ELCODE", all.x=TRUE)

# load the county basemap
county_shp <- arc.open(here::here("_data","output",updateName,"sws.gdb", "_county")) 
county_shpprj <- county_shp
county_shp <- arc.select(county_shp)
county_shp <- arc.data2sf(county_shp)
county_shp <- county_shp[c("OBJECTID","COUNTY_NAM","COUNTY_NUM","FIPS_COUNT")]
# map it
sgcnlist <- unique(sws_countyagg_cast$ELCODE)
sgcnlist <- gsub("\r\n","",sgcnlist)
sgcnlist <- sort(sgcnlist)

# make the county feature classes
for(i in 1:length(sgcnlist)){
  sws_county_1 <- sws_countyagg_cast[which(sws_countyagg_cast$ELCODE==sgcnlist[i]),]
  print(paste(sgcnlist[i],", which is species ",i," of ",length(sgcnlist), sep=""))
  sws_county_1a <- merge(county_shp,sws_county_1,by="COUNTY_NAM")
  sws_county_1a <- merge(sws_county_1a,data_sgcn,by="ELCODE", all.x=TRUE)
  sws_county_1a <- sws_county_1a[c("ELCODE","COUNTY_NAM","TaxaDisplay","SCOMNAME","SNAME","PrimMacro","b","m","w","y","Occurrence","GRANK","SRANK","USESA","SPROT","PBSSTATUS","geometry")] # 
  arc.write(file.path(here::here("_data","output",updateName,"sws.gdb",paste("county",sgcnlist[i],sep="_"))),sws_county_1a ,overwrite=TRUE) # , shape_info=arc.shapeinfo(county_shpprj)
}

###################################
# combined data for COA tool
HUC8agg <- sws_HUC8agg_cast
HUC8agg <- merge(HUC8agg,data_sgcn,by="ELCODE", all.x=TRUE)
HUC8agg_all <- merge(HUC8_shp, HUC8agg, by.x="HUC8", by.y="HUC8")
HUC8agg_all <- HUC8agg_all[c("ELCODE","HUC8","NAME","TaxaDisplay","SCOMNAME","SNAME","PrimMacro","b","m","w","y","Occurrence","GRANK","SRANK","USESA","SPROT","PBSSTATUS")]
arc.write(here::here("_data","output",updateName,"sws.gdb","_HUC8_SGCN"), HUC8agg_all, overwrite=TRUE, validate=TRUE) #, shape_info=arc.shapeinfo(HUC8_shpprj)

countyagg <- sws_countyagg_cast
countyagg <- merge(countyagg,data_sgcn,by="ELCODE", all.x=TRUE)
countyagg <- countyagg[c("ELCODE","COUNTY_NAM","TaxaDisplay","SCOMNAME","SNAME","PrimMacro","b","m","w","y","Occurrence","GRANK","SRANK","USESA","SPROT","PBSSTATUS")]
countyagg_all <- merge(county_shp, countyagg, by="COUNTY_NAM")
arc.write(here::here("_data","output",updateName,"sws.gdb","_county_SGCN"), countyagg_all, overwrite=TRUE, validate=TRUE) # , shape_info=arc.shapeinfo(county_shpprj)

