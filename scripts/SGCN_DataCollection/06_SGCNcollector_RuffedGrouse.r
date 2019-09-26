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

source(here::here("scripts","SGCN_DataCollection","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN("AB")

# read in the grouse data 
#get the threats template
grouse_file <- list.files(path=here("_data/input/SGCN_data/PGC_Grouse"), pattern=".shp$")  # --- make sure your excel file is not open.
grouse_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
grouse_file <- here("_data/input/SGCN_data/PGC_Grouse", grouse_file[n])

grouse_file <- arc.open(grouse_file)
grouse_file <- arc.select(grouse_file)
grouse_sf <- arc.data2sf(grouse_file)

grouse_sf$LastObs <- year(grouse_sf$date_of_ob)
grouse_sf$dayofyear <- yday(grouse_sf$date_of_ob)

grouse_sf$SNAME <- "Bonasa umbellus"
grouse_sf$SCOMNAME <- "Ruffed Grouse"

### assign a migration date to each ebird observation.
birdseason <- read.csv(here("scripts","SGCN_DataCollection","lu_eBird_birdseason.csv"), colClasses = c("character","character","integer","integer"),stringsAsFactors=FALSE)

grouse_sf$season <- NA
for(i in 1:nrow(birdseason)){
  comname <- birdseason[i,1]
  season <- birdseason[i,2]
  startdate <- birdseason[i,3]
  enddate <- birdseason[i,4]
  grouse_sf$season[grouse_sf$SCOMNAME==comname & grouse_sf$dayofyear>startdate & grouse_sf$dayofyear<enddate] <- substr(as.character(season), 1, 1)
}
grouse_sf <- grouse_sf[which(!is.na(grouse_sf$season)),]
grouse_sf$SCOMNAME <- NULL

grouse_sf$ELSeason <- paste(grouse_sf$ELCODE, grouse_sf$season, sep="_")

grouse_sf$DataID <- grouse_sf$globalid

grouse_sf <- grouse_sf[c("SNAME","LastObs","SNAME","season","geom","DataID")]

#add in the SGCN fields
grouse_sf <- merge(grouse_sf, lu_sgcn, by.x=c("SNAME","season"), by.y=c("SNAME","SeasonCode"),  all.x=TRUE)

# add additonal fields 
grouse_sf$DataSource <- "PGC Grouse Data"
grouse_sf$OccProb <- "k"
grouse_sf$useCOA <- "y"

#grouse_sf <- grouse_sf[final_fields,]

grouse_sf <- st_transform(grouse_sf, crs=customalbers)
# buffer by 100m
grouse_sf <- st_buffer(grouse_sf, dist=100)

# write a feature class into the geodatabase
arc.write(path=here("_data/output/SGCN.gdb","final_PGCgrouse"), grouse_sf, overwrite=TRUE)


