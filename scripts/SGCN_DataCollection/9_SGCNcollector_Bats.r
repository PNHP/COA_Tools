# Name: 
# Purpose: 
# Author: Christopher Tracey
# Created: 2016-08-11
# Updated: 2016-08-17
#
# Updates:
# insert date and info
# * 2016-08-17 - 
#
# To Do List/Future Ideas:
# * 
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

source(here::here("scripts","SGCN_DataCollection","0_PathsAndSettings.r"))

# read in SGCN data
sgcn <- arc.open(here("COA_Update.gdb","lu_sgcn")) # need to figure out how to reference a server
sgcn <- arc.select(sgcn, c("ELCODE", "SNAME", "SCOMNAME", "TaxaGroup", "Environment","SeasonCode","ELSeason" ))

# read in the bat data 
# note that this is partially processed bat data, and not raw bat data from PGC
eptefusc <- read.csv(here("_data","input","SGCN_data","PGC_bats","EptesicusFuscus","BigBrownBat.csv"), stringsAsFactors=FALSE)
tricollb <- read.csv(here("_data","input","SGCN_data","PGC_bats","TriColoredLittleBrownBats","TriColored_LittleBrownBats.csv"), stringsAsFactors=FALSE)

names(eptefusc)
names(tricollb)

names(eptefusc)[names(eptefusc)=='sname'] <- 'SNAME'
names(eptefusc)[names(eptefusc)=='scomname'] <- 'SCOMNAME'
names(eptefusc)[names(eptefusc)=='SOURCE'] <- 'DataSource'
names(tricollb)[names(tricollb)=='sname'] <- 'SNAME'
names(tricollb)[names(tricollb)=='scomname'] <- 'SCOMNAME'
tricollb$DataSource  <- "PGC"

# dates
eptefusc$LastObs <- year(ymd(eptefusc$Date))
tricollb$LastObs <- year(mdy(tricollb$SURVEYDATE))

# data ID
eptefusc$DataID <- rownames(eptefusc)
tricollb$DataID <- rownames(tricollb) 

# seasons
names(eptefusc)[names(eptefusc)=='season'] <- 'SeasonCode'
names(tricollb)[names(tricollb)=='season'] <- 'SeasonCode'
eptefusc$SeasonCode <- substr(eptefusc$SeasonCode,1,1)

#taxa groups
eptefusc$TaxaGroup <- "AM"
tricollb$TaxaGroup <- "AM"

# Data Source
eptefusc$useCOA <- with(eptefusc, ifelse(eptefusc$LastObs >= cutoffyear, "y", "n"))
tricollb$useCOA <- with(tricollb, ifelse(tricollb$LastObs >= cutoffyear, "y", "n"))

# ELCODE
eptefusc <- merge(eptefusc, unique(sgcn[c("SNAME", "ELCODE")]), by="SNAME", all.x=TRUE)
tricollb <- merge(tricollb, unique(sgcn[c("SNAME", "ELCODE")]), by="SNAME", all.x=TRUE)
eptefusc$ELSeason <- paste(eptefusc$ELCODE, eptefusc$SeasonCode, sep="_")
tricollb$ELSeason <- paste(tricollb$ELCODE, tricollb$SeasonCode, sep="_")

# create a spatial layer
eptefusc_sf <- st_as_sf(eptefusc, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
tricollb_sf <- st_as_sf(tricollb, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# reproject to custom albers
eptefusc_sf1 <- st_transform(eptefusc_sf, crs=customalbers)
tricollb_sf1 <- st_transform(tricollb_sf, crs=customalbers)

# buffer the points by 100m
eptefusc_buffer_sf <- st_buffer(eptefusc_sf1, 100)
tricollb_buffer_sf <- st_buffer(tricollb_sf1, 100)

eptefusc_buffer_sf$OccProb <- "k"
tricollb_buffer_sf$OccProb <- "k"


eptefusc_buffer_sf <- eptefusc_buffer_sf[final_fields]
tricollb_buffer_sf <- tricollb_buffer_sf[final_fields]


bats <- rbind(eptefusc_buffer_sf, tricollb_buffer_sf)

# write a feature class to the gdb
arc.write(path=here("_data/output/SGCN.gdb","final_PGCbats"), bats, overwrite=TRUE)
