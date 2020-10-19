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

# read in the grouse data 
#get the threats template
grouse_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_Grouse"), pattern=".shp$")  # --- make sure your excel file is not open.
grouse_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
grouse_file <- here::here("_data/input/SGCN_data/PGC_Grouse", grouse_file[n])

trackfiles("SGCN grouse", here::here("_data/input/SGCN_data/PGC_Grouse", grouse_file[n])) # write to file tracker

grouse_file <- arc.open(grouse_file)
grouse_file <- arc.select(grouse_file)
grouse_sf <- arc.data2sf(grouse_file)
st_crs(grouse_sf) <- 4326

grouse_sf$LastObs <- year(grouse_sf$date_of_ob)
grouse_sf$dayofyear <- yday(grouse_sf$date_of_ob)

grouse_sf$SNAME <- "Bonasa umbellus"
grouse_sf$SCOMNAME <- "Ruffed Grouse"

### assign a migration date to each ebird observation.
birdseason <- read.csv(here::here("scripts","SGCN_DataCollection","lu_eBird_birdseason.csv"), colClasses = c("character","character","integer","integer"),stringsAsFactors=FALSE)

grouse_sf$season <- NA
for(i in 1:nrow(birdseason)){
  comname <- birdseason[i,1]
  season <- birdseason[i,2]
  startdate <- birdseason[i,3]
  enddate <- birdseason[i,4]
  grouse_sf$season[grouse_sf$SCOMNAME==comname & grouse_sf$dayofyear>=startdate & grouse_sf$dayofyear<=enddate] <- substr(as.character(season), 1, 1)
}
grouse_sf <- grouse_sf[which(!is.na(grouse_sf$season)),]
grouse_sf$SCOMNAME <- NULL

grouse_sf$ELSeason <- paste(grouse_sf$ELCODE, grouse_sf$season, sep="_")

grouse_sf$DataID <- grouse_sf$globalid

grouse_sf <- grouse_sf[c("SNAME","LastObs","season","geom","DataID")]

#add in the SGCN fields
grouse_sf <- merge(grouse_sf, lu_sgcn, by.x=c("SNAME","season"), by.y=c("SNAME","SeasonCode"),  all.x=TRUE)

# add additonal fields 
grouse_sf$DataSource <- "PGC Grouse Data"
grouse_sf$OccProb <- "k"
grouse_sf$useCOA <- "y"
colnames(grouse_sf)[colnames(grouse_sf)=="season"] <- "SeasonCode"

grouse_sf <- grouse_sf[final_fields]

# create a spatial layer
grouse_sf <- st_transform(grouse_sf, crs=customalbers) # reproject to the custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_PGCgrouse"), grouse_sf, overwrite=TRUE) # write a feature class into the geodatabase
grouse_buffer <- st_buffer(grouse_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PGCgrouse"), grouse_buffer, overwrite=TRUE) # write a feature class into the geodatabase

####################################################################################
## Process and load woodcock data into SGCN geodatabase
####################################################################################

#read the woodcock data
woodcock_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_Woodcock"), pattern=".csv$")  # --- make sure your excel file is not open.
woodcock_file

#look at the output and choose which .csv you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
woodcock_file <- here::here("_data/input/SGCN_data/PGC_Woodcock", woodcock_file[n])

trackfiles("SGCN woodcock", woodcock_file) # write to file tracker

#read in woodcock csv
woodcock <- read.csv(woodcock_file, stringsAsFactors = FALSE, na.strings = c("", "NA"))
#keep only positive records that have lat/long values
woodcock <- woodcock[!is.na(woodcock$Value) & !is.na(woodcock$Latitude), ]

# check for bad coordinates
if(any(woodcock$Latitude==woodcock$Longitude)){
  print("Mistake in the lat/lon pairs, matching values")
} else {
  print("no duplicate pairs in the coordinates")
}

#create fields and populate with SGCN data
woodcock$SNAME <- "Scolopax minor"
woodcock$SCOMNAME <- "American Woodcock"
woodcock$ELCODE <- "ABNNF19020"
woodcock$SeasonCode <- "b"
woodcock$ELSeason <- paste(woodcock$ELCODE, woodcock$SeasonCode, sep = "_")
woodcock$DataSource <- "PGC Woodcock Data"
woodcock$DataID <- paste(gsub("\\s", "", woodcock$Route), gsub("\\s", "", woodcock$Stop), sep = "_")
names(woodcock)[names(woodcock)=='Year'] <- 'LastObs'
woodcock$TaxaGroup <- "AB"
woodcock$useCOA <- "y"
woodcock$OccProb <- "k"

#keep SGCN fields, exclude all others
woodcock <- woodcock[c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","DataSource","DataID","OccProb","LastObs","useCOA","TaxaGroup","Longitude","Latitude")]

#create sf object
woodcock_sf <- st_as_sf(woodcock, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
library(lwgeom)
woodcock_sf <- st_make_valid(woodcock_sf)

#project sf object to custom albers CRS
woodcock_sf <- st_transform(woodcock_sf, crs=customalbers) # reproject to custom albers
#keep only final fields and write source point and final feature classes to SGCN GDB
woodcock_sf <- woodcock_sf[final_fields]
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_PGCwoodcock"), woodcock_sf, overwrite=TRUE) # write a feature class to the gdb
woodcock_buffer_sf <- st_buffer(woodcock_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PGCwoodcock"), woodcock_buffer_sf, overwrite=TRUE) # write a feature class to the gdb

