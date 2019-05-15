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
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)

source(here::here("scripts","SGCN_DataCollection","0_PathsAndSettings.r"))

# read in SGCN data
db <- dbConnect(SQLite(), dbname = databasename)
SQLquery <- paste("SELECT ELCODE, SNAME, SCOMNAME, TaxaGroup, SeasonCode, ELSeason"," FROM lu_sgcn ")
lu_sgcn <- dbGetQuery(db, statement = SQLquery)
dbDisconnect(db) # disconnect the db

# Bombus Data #################################################################################
bombus <- arc.open(here("_data","input","SGCN_data","PA_Bombus","PA_Bombus.shp")) 
bombus <- arc.select(bombus) 

bombus$SNAME <- paste("Bombus",bombus$species, sep=" ")
bombus$DataID <- bombus$LR_BBNA_co
bombus$DataSource <- "Xerces"
bombus$OccProb <- "k"
bombus$SeasonCode <- "y"
bombus$useCOA <- NA
bombus$LastObs <- bombus$year_
bombus$useCOA <- ifelse(bombus$LastObs>=cutoffyear, "y", "n")
bombus <- merge(bombus, lu_sgcn[c("SNAME","ELCODE","ELSeason","SCOMNAME","TaxaGroup")], by="SNAME")
# subset to SGCN
bombus <- bombus[which(bombus$SNAME %in% lu_sgcn$SNAME),]
# kill the ones with no coordinates
bombus <- bombus[which(bombus$longitude<0),]
# create a spatial layer
bombus_sf <- st_as_sf(bombus, coords=c("longitude","latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
# reproject to custom albers
bombus_sf <- st_transform(bombus_sf, crs=customalbers)
# buffer the points by 100m
bombus_buffer_sf <- st_buffer(bombus_sf, 100)
# field alignment
bombus_buffer_sf <- bombus_buffer_sf[final_fields]
# write a feature class to the gdb
arc.write(path=here("_data/output/SGCN.gdb","final_Bombus"), bombus_buffer_sf, overwrite=TRUE)


# Bombus Data #################################################################################






