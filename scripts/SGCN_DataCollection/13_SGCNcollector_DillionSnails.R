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

# clear the environments
rm(list=ls())


# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()
lu_sgcn <- lu_sgcn[which(lu_sgcn$TaxaGroup=="inv_snailf"),]

#snails <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","Snails","PA-data-from_Dillon-14Jan14.xlsx"), sheet="Sheet1", skipEmptyRows=FALSE, rowNames=FALSE)
snails <- read.csv(file=here::here("_data","input","SGCN_data","Snails","PA-data-from_Dillon-14Jan14.csv"))

trackfiles("SGCN AquaticSnails", here::here("_data","input","SGCN_data","Snails","PA-data-from_Dillon-14Jan14.xlsx")) # write to file tracker

# subset to the species group one wants to query
snails <- snails[which(snails$SCI_NAME %in% lu_sgcn$SNAME),]

snails$LastObs <- year(parse_date_time(snails$DATE, c("%m/%d/%y","ymd","%mdy","d%by")))
snails$LastObs[is.na(snails$LastObs)] <- "NO DATE"

snails$DataSource <- "DillionSnails"
snails$SeasonCode <- "y"
snails$OccProb <- "k"
names(snails)[names(snails)=='SCI_NAME'] <- 'SNAME'
names(snails)[names(snails)=='REF_SITE_NO'] <- 'DataID'
names(snails)[names(snails)=='LONGITUDE'] <- 'Longitude'
names(snails)[names(snails)=='LATITUDE'] <- 'Latitude'

# delete the colums we don't need from the BAMONA dataset
snails <- snails[c("SNAME","DataID","DataSource","Longitude","Latitude","LastObs","OccProb")]


#add in the SGCN fields
snails <- merge(snails, lu_sgcn, by="SNAME", all.x=TRUE)

# add in and calculate useCOA based on lastobs date
snails$useCOA <- with(snails, ifelse(snails$LastObs >= cutoffyear & snails$LastObs != "NO DATE", "y", "n"))

# create a spatial layer
snails_sf <- st_as_sf(snails, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
snails_sf <- st_transform(snails_sf, crs=customalbers)
snails_sf <- snails_sf %>%
  select(final_fields)
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_snails"), snails_sf, overwrite=TRUE) # write a feature class into the geodatabase
snails_buffer_sf <- st_buffer(snails_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_snails"), snails_buffer_sf, overwrite=TRUE) # write a feature class into the geodatabase

