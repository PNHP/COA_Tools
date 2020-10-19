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
# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
  require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN("AB")
lu_sgcn <- lu_sgcn[which(lu_sgcn$SeasonCode=='b'),]

birdcodes <- read.csv(here::here("_data","input","SGCN_data","bba_ptct","birdcodes.csv"), stringsAsFactors=FALSE)
birds_info <-  merge(lu_sgcn, birdcodes, by="SNAME")

# read the point count data
PtCt <- read.csv(here::here("_data","input","SGCN_data","bba_ptct","BBA_PtCt.csv"), stringsAsFactors=FALSE)
PtCt$OBJECTID <- NULL

trackfiles("SGCN bba ptct", here::here("_data","input","SGCN_data","bba_ptct","BBA_PtCt.csv")) # write to file tracker

# take out the coordinates of the point counts and put them into a new data frame for later
PtCtLocations <- PtCt[,c("BBA","GPS_N","GPS_W")]
PtCt$GPS_N <- NULL
PtCt$GPS_W <- NULL
names(PtCtLocations)[names(PtCtLocations)=='GPS_N'] <- 'Latitude'
names(PtCtLocations)[names(PtCtLocations)=='GPS_W'] <- 'Longitude'

PtCt1 <- melt(PtCt, id=c("BBA")) # reshape it to long format
names(PtCt1)[names(PtCt1)=='variable'] <- 'SpCode'
names(PtCt1)[names(PtCt1)=='value'] <- 'count'

PtCt1 <- PtCt1[PtCt1$count!=0,]
PtCt2 <- merge(PtCt1, PtCtLocations, by="BBA")
PtCt2 <- merge(PtCt2, birds_info, by="SpCode", all.x=TRUE)

PtCt2$DataID <- "BBA2 PtCt"
PtCt2$SeasonCode <- "b"
PtCt2$Environment <- "t"
PtCt2$TaxaGroup <- "AB"
PtCt2$LastObs <- "2007"
PtCt2$DataSource <- "BBA_PtCt"
PtCt2$OccProb <- "k"
PtCt2$useCOA <- "y"

# subset to SGCN
PtCt3 <- PtCt2[which(PtCt2$SNAME %in% lu_sgcn$SNAME),]

# create a spatial layer
bba_sf <- st_as_sf(PtCt3, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
bba_sf <- st_transform(bba_sf, crs=customalbers) # reproject to custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_BBAptct"), bba_sf, overwrite=TRUE) # write a feature class to the gdb
bba_buffer_sf <- st_buffer(bba_sf, 100) # buffer the points by 100m
bba_buffer_sf <- bba_buffer_sf[final_fields] 
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_BBAptct"), bba_buffer_sf, overwrite=TRUE) # write a feature class to the gdb

