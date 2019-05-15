#---------------------------------------------------------------------------------------------
# Name: SGCNcollector_BAMONA.r
# Purpose: https://www.butterfliesandmoths.org/
# Author: Christopher Tracey
# Created: 2017-07-10
# Updated: 2019-02-19
#
# Updates:
# insert date and info
# * 2016-08-17 - got the code to remove NULL values from the keys to work; 
#                added the complete list of SGCN to load from a text file;
#                figured out how to remove records where no occurences we found;
#                make a shapefile of the results  
# * 2019-02-19 - rewrite and update
#
# To Do List/Future Ideas:
# * check projection
# * write bibtex
# * Migrant, Unknown, Stray, Temporary Colonist, Nonresident filter
#---------------------------------------------------------------------------------------------

# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
require(lubridate)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)

source(here::here("scripts","SGCN_DataCollection","0_PathsAndSettings.r"))

# read in SGCN data
db <- dbConnect(SQLite(), dbname = databasename)
SQLquery <- paste("SELECT ELCODE, SNAME, SCOMNAME, TaxaGroup, ELSeason"," FROM lu_sgcn ")
lu_sgcn <- dbGetQuery(db, statement = SQLquery)
lu_sgcn <- lu_sgcn[which(lu_sgcn$TaxaGroup=="inv_snailf"),]
dbDisconnect(db) # disconnect the db



snails <- read.xlsx(xlsxFile=here("_data","input","SGCN_data","Snails","PA-data-from_Dillon-14Jan14.xlsx"), sheet="Sheet1", skipEmptyRows=FALSE, rowNames=FALSE)

# subset to the species group one wants to query
snails <- snails[which(snails$SCI_NAME %in% lu_sgcn$SNAME),]



snails$LASTOBS <- year(parse_date_time(snails$DATE, c("%m/%d/%y","ymd","%mdy","d%by")))
snails$LASTOBS[is.na(snails$LASTOBS)] <- "NO DATE"


snails$DataSource <- "DillionSnails"
snails$SeasonCode <- "y"
names(snails)[names(snails)=='SCI_NAME'] <- 'SNAME'
names(snails)[names(snails)=='REF_SITE_NO'] <- 'DataID'
names(snails)[names(snails)=='LONGITUDE'] <- 'Longitude'
names(snails)[names(snails)=='LATITUDE'] <- 'Latitude'
names(snails)[names(snails)==''] <- ''

# delete the colums we don't need from the BAMONA dataset
snails <- snails[c("SNAME","DataID","DataSource","Longitude","Latitude","LASTOBS","SeasonCode")]


#add in the SGCN fields
snails <- merge(snails, lu_sgcn, by="SNAME", all.x=TRUE)

# add in useCOA
snails$UseCOA <- NA
cutoffYear <- year(Sys.Date())-25
snails$UseCOA <- with(snails, ifelse(snails$LASTOBS >= cutoffYear, "y", "n"))

# create a spatial layer
snails_sf <- st_as_sf(snails, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
snails_sf <- st_transform(snails_sf, crs=customalbers)
# buffer by 100m
snails_sf <- st_buffer(snails_sf, dist=100)

# write a feature class into the geodatabase
arc.write(path=here("_data/output/SGCN.gdb","final_snails"), snails_sf, overwrite=TRUE)
