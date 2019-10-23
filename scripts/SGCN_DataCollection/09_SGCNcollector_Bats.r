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
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()

# read in the bat data 
# note that this is partially processed bat data, and not raw bat data from PGC
eptefusc <- read.csv(here::here("_data","input","SGCN_data","PGC_bats","EptesicusFuscus","BigBrownBat.csv"), stringsAsFactors=FALSE)
tricollb <- read.csv(here::here("_data","input","SGCN_data","PGC_bats","TriColoredLittleBrownBats","TriColored_LittleBrownBats.csv"), stringsAsFactors=FALSE)

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

# occprob
eptefusc$OccProb <- "k"
tricollb$OccProb <- "k"

# ELCODE
eptefusc <- merge(eptefusc, unique(lu_sgcn[c("SNAME", "ELCODE")]), by="SNAME", all.x=TRUE)
tricollb <- merge(tricollb, unique(lu_sgcn[c("SNAME", "ELCODE")]), by="SNAME", all.x=TRUE)
eptefusc$ELSeason <- paste(eptefusc$ELCODE, eptefusc$SeasonCode, sep="_")
tricollb$ELSeason <- paste(tricollb$ELCODE, tricollb$SeasonCode, sep="_")


# field alignment
eptefusc <- eptefusc[c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","DataSource","DataID","OccProb","LastObs","useCOA","TaxaGroup","Longitude","Latitude")]
tricollb <- tricollb[c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","DataSource","DataID","OccProb","LastObs","useCOA","TaxaGroup","Longitude","Latitude")]

# join the two species together
bats <- rbind(eptefusc, tricollb)

# create a spatial layer
bats_sf <- st_as_sf(bats, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# st_dimension

bats_sf <- st_transform(bats_sf, crs=customalbers) # reproject to custom albers
bats_sf <- bats_sf[final_fields]
arc.write(path=here::here("_data/output/SGCN.gdb","srcpt_bats"), bats_sf, overwrite=TRUE) # write a feature class to the gdb
bats_buffer_sf <- st_buffer(bats_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data/output/SGCN.gdb","final_bats"), bats_buffer_sf, overwrite=TRUE) # write a feature class to the gdb


