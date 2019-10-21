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
if (!requireNamespace("reshape", quietly = TRUE)) install.packages("reshape")
  require(reshape)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()
lu_sgcn <- lu_sgcn[which(lu_sgcn$TaxaGroup=="AAAA"|lu_sgcn$TaxaGroup=="AAAB"|lu_sgcn$TaxaGroup=="ARAA"|lu_sgcn$TaxaGroup=="ARAC"|lu_sgcn$TaxaGroup=="ARAD"),]
dbDisconnect(db) # disconnect the db



## need to find the data



birdcodes <- read.csv(here("_data","input","SGCN_data","bba_ptct","birdcodes.csv"), stringsAsFactors=FALSE)
birds_info <-  merge(lu_sgcn, birdcodes, by="SNAME")

# read the point count data
PtCt <- read.csv(here("_data","input","SGCN_data","bba_ptct","BBA_PtCt.csv"), stringsAsFactors=FALSE)
PtCt$OBJECTID <- NULL

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

# subset to SGCN
PtCt3 <- PtCt2[which(PtCt2$SNAME %in% lu_sgcn$SNAME),]

# create a spatial layer
bba_sf <- st_as_sf(PtCt3, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# reproject to custom albers
bba_sf1 <- st_transform(bba_sf, crs=customalbers)

# buffer the points by 100m
bba_buffer_sf <- st_buffer(bba_sf1, 100)

# field alignment
bba_buffer_sf$DataSource <- "BBA_PtCt"
bba_buffer_sf$OccProb <- "k"
bba_buffer_sf$useCOA <- "y"
bba_buffer_sf <- bba_buffer_sf[final_fields]

# write a feature class to the gdb
arc.write(path=here("_data/output/SGCN.gdb","final_BBAptct"), bba_buffer_sf, overwrite=TRUE)
