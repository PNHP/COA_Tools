# Name: 
# Purpose: 
# Author: Christopher Tracey
# Created: 2016-08-11
#
# Updates:
# 2022-10-14 - MMOORE updated to include 3 woodcock email records sent by PGC.
#---------------------------------------------------------------------------------------------
# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr")
require(stringr)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN("AB")

############THIS IS FOR SHAPEFILE FORMAT########################################
# read in the grouse data 
#get the threats template
# grouse_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_Grouse"), pattern=".shp$")  # --- make sure your excel file is not open.
# grouse_file
# #look at the output and choose which shapefile you want to run
# #enter its location in the list (first = 1, second = 2, etc)
# n <- 6
# grouse_file <- here::here("_data/input/SGCN_data/PGC_Grouse", grouse_file[n])
# 
# trackfiles("SGCN grouse", here::here("_data/input/SGCN_data/PGC_Grouse", grouse_file[n])) # write to file tracker
# 
# grouse_file <- arc.open(grouse_file)
# grouse_file <- arc.select(grouse_file)
# grouse_sf <- arc.data2sf(grouse_file)
# st_crs(grouse_sf) <- 4326

#############END SHAPEFILE FORMAT###############################################

#############THIS IS FOR CSV FORMAT#############################################
# read in the grouse data 
#get the threats template
grouse_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_Grouse"), pattern=".csv$")  # --- make sure your excel file is not open.
grouse_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 3
grouse_file <- here::here("_data/input/SGCN_data/PGC_Grouse", grouse_file[n])

trackfiles("SGCN grouse", here::here("_data/input/SGCN_data/PGC_Grouse", grouse_file[n])) # write to file tracker

grouse_csv <- read.csv(grouse_file, stringsAsFactors=FALSE)
grouse_sf <- st_as_sf(grouse_csv, coords=c("Long","Lat"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

grouse_sf$LastObs <- year(as.Date(grouse_sf$Date,format="%m/%d/%Y"))
grouse_sf$dayofyear <- yday(as.Date(grouse_sf$Date,format="%m/%d/%Y"))

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

#grouse_sf$DataID <- grouse_sf$globalid # use with Shapefile input
grouse_sf$DataID <- NA

#grouse_sf <- grouse_sf[c("SNAME","LastObs","season","geom","DataID")] # use this for shapefile input

#add in the SGCN fields
grouse_sf$SCOMNAME <- NULL
grouse_sf <- merge(grouse_sf, lu_sgcn, by.x=c("SNAME","season"), by.y=c("SNAME","SeasonCode"),  all.x=TRUE)


grouse_sf$ELSeason <- paste(grouse_sf$ELCODE, grouse_sf$season, sep="_")

# add additonal fields 
grouse_sf$DataSource <- "PGC Grouse Data"
grouse_sf$OccProb <- "k"
grouse_sf$useCOA <- "y"
colnames(grouse_sf)[colnames(grouse_sf)=="season"] <- "SeasonCode"

grouse_sf <- subset(grouse_sf, select = final_fields)

##################
# read in grouse covert observation data from PGC feature service
grouse_covert_obs_url <- "https://gis.waterlandlife.org/server/rest/services/Hosted/Grouse_Covert_Observations_View_COA/FeatureServer/0"
grouse_obs <- arc.open(grouse_covert_obs_url)
grouse_obs <- arc.select(grouse_obs)
grouse_obs_sf <- arc.data2sf(grouse_obs)

grouse_obs_sf <- grouse_obs_sf[grouse_obs_sf$total_grouse > 0,]

grouse_obs_sf$LastObs <- year(as.Date(grouse_obs_sf$observation_date,format="%m/%d/%Y"))
grouse_obs_sf$dayofyear <- yday(as.Date(grouse_obs_sf$observation_date,format="%m/%d/%Y"))

grouse_obs_sf$SNAME <- "Bonasa umbellus"
grouse_obs_sf$SCOMNAME <- "Ruffed Grouse"

grouse_obs_sf$season <- NA
for(i in 1:nrow(birdseason)){
  comname <- birdseason[i,1]
  season <- birdseason[i,2]
  startdate <- birdseason[i,3]
  enddate <- birdseason[i,4]
  grouse_obs_sf$season[grouse_obs_sf$SCOMNAME==comname & grouse_obs_sf$dayofyear>=startdate & grouse_obs_sf$dayofyear<=enddate] <- substr(as.character(season), 1, 1)
}
grouse_obs_sf <- grouse_obs_sf[which(!is.na(grouse_obs_sf$season)),]

grouse_obs_sf$DataID <- NA

#add in the SGCN fields
grouse_obs_sf$SCOMNAME <- NULL
grouse_obs_sf <- merge(grouse_obs_sf, lu_sgcn, by.x=c("SNAME","season"), by.y=c("SNAME","SeasonCode"),  all.x=TRUE)


grouse_obs_sf$ELSeason <- paste(grouse_obs_sf$ELCODE, grouse_obs_sf$season, sep="_")

# add additonal fields 
grouse_obs_sf$DataSource <- "PGC Grouse Data"
grouse_obs_sf$OccProb <- "k"
grouse_obs_sf$useCOA <- "y"
colnames(grouse_obs_sf)[colnames(grouse_obs_sf)=="season"] <- "SeasonCode"

grouse_obs_sf <- subset(grouse_obs_sf, select = final_fields)

# merge grouse spreadsheet records with grouse covert observations records
grouse_sf <- rbind(grouse_sf,grouse_obs_sf)

# remove duplicates
grouse_sf <- grouse_sf %>% distinct()

# create a spatial layer
grouse_sf <- st_transform(grouse_sf, crs=customalbers) # reproject to the custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_PGCgrouse"), grouse_sf, overwrite=TRUE) # write a feature class into the geodatabase
grouse_buffer <- st_buffer(grouse_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PGCgrouse"), grouse_buffer, overwrite=TRUE) # write a feature class into the geodatabase

####################################################################################
## Process and load woodcock data into SGCN geodatabase
####################################################################################
#################################
#### New Woodcock data

library(readxl)    
read_excel_allsheets <- function(filename, tibble = FALSE) {
  # I prefer straight data.frames
  # but if you like tidyverse tibbles (the default with read_excel)
  # then just pass tibble = TRUE
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X, col_types="text"))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}


WoodcockResearch_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_Woodcock"), pattern=".xlsx$")  # --- make sure your excel file is not open.
WoodcockResearch_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
WoodcockResearch_file <- here::here("_data/input/SGCN_data/PGC_Woodcock", WoodcockResearch_file[n])

# write to file tracker
trackfiles("Woodcock Research Data", WoodcockResearch_file)


mysheets <- read_excel_allsheets(WoodcockResearch_file)

names(mysheets)
lapply(mysheets, colnames)
colnames(mysheets[["SCR"]])

changedRoute <- mysheets[["SCR"]][c("...9","...10","...11","...12","...13","2018","2019","2020","2021")] # "REGION","SGL","...3","STOP","LAT","LONG","2016","2017","2018","2019","2020","2021"
changedRoute <- changedRoute[which(complete.cases(changedRoute)),]
changedRoute <- cbind(c("SW"),changedRoute)
names(changedRoute)
names(changedRoute) <- c("REGION","SGL","...3","STOP","LAT","LONG","2018","2019","2020","2021")


mysheets[["SCR"]] <- mysheets[["SCR"]][c("REGION","SGL","...3","STOP","LAT","LONG","2016","2017","2018","2019","2020","2021" )]


a <- dplyr::bind_rows(mysheets)

a1 <- dplyr::bind_rows(a, changedRoute)

a2 <- a1 %>%
  tidyr::pivot_longer(
    cols = starts_with("20"),
    names_to = "year",
    #names_prefix = "20",
    values_to = "countyear",
    values_drop_na = TRUE
  )

a2 <- a2[which(!is.na(a2$LAT)&!is.na(a2$LONG)),]
a3 <- a2[which(stringr::str_detect(a2$LAT, " ", negate=FALSE)),]  #grepl("^\\s*$", )
a2 <- a2[which(stringr::str_detect(a2$LAT, " ", negate=TRUE)),] 

a3col <- names(a3)

a3$latD <- as.numeric(stringr::word(a3$LAT, 1))
a3$latM <- as.numeric(stringr::word(a3$LAT, 2))
a3$LAT <- a3$latD + a3$latM/60
a3$lonD <- as.numeric(stringr::word(a3$LONG, 1))
a3$lonM <- as.numeric(stringr::word(a3$LONG, 2))
a3$LONG <- (a3$lonD + a3$lonM/60) * -1

a3 <- a3[a3col]
rm(a3col)

a2 <- rbind(a2, a3)
rm(a3)

a2 <- a2[which(a2$countyear!="NA" & a2$countyear>0),]
a2$countyear <- as.numeric(a2$countyear)

woodcockResearch <- a2 %>% 
  group_by(REGION, SGL, ...3, STOP, LAT, LONG) %>% 
  summarise_if(is.numeric, sum)

woodcockResearch$DataID <- paste(woodcockResearch$REGION,"-",woodcockResearch$SGL,woodcockResearch$...3,"-Stop: ",woodcockResearch$STOP," | Count=",woodcockResearch$countyear, sep="")

#create fields and populate with SGCN data
woodcockResearch$SNAME <- "Scolopax minor"
woodcockResearch$SCOMNAME <- "American Woodcock"
woodcockResearch$ELCODE <- "ABNNF19020"
woodcockResearch$SeasonCode <- "b"
woodcockResearch$ELSeason <- paste(woodcockResearch$ELCODE, woodcockResearch$SeasonCode, sep = "_")
woodcockResearch$DataSource <- "PGC Woodcock Data"
woodcockResearch$LastObs <- "2021"
#names(woodcockResearch)[names(woodcockResearch)=='Year'] <- 'LastObs'
woodcockResearch$TaxaGroup <- "AB"
woodcockResearch$useCOA <- "y"
woodcockResearch$OccProb <- "k"

colnames(woodcockResearch)[colnames(woodcockResearch)=="LAT"] <- "Latitude"
colnames(woodcockResearch)[colnames(woodcockResearch)=="LONG"] <- "Longitude"

#keep SGCN fields, exclude all others
woodcockResearch <- woodcockResearch[c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","DataSource","DataID","OccProb","LastObs","useCOA","TaxaGroup","Longitude","Latitude")]

woodcockResearch <- woodcockResearch[which(woodcockResearch$Latitude!="missing"),]

woodcockResearch$Longitude <- abs(as.numeric(woodcockResearch$Longitude)) * -1

# create a spatial layer
woodcockResearch_sf <- st_as_sf(woodcockResearch, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
library(lwgeom)
woodcockResearch_sf <- st_make_valid(woodcockResearch_sf)

#project sf object to custom albers CRS
woodcockResearch_sf <- st_transform(woodcockResearch_sf, crs=customalbers) # reproject to custom albers
#keep only final fields and write source point and final feature classes to SGCN GDB
woodcockResearch_sf <- woodcockResearch_sf[final_fields]
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_PGCwoodcockRes"), woodcockResearch_sf, overwrite=TRUE) # write a feature class to the gdb
woodcockResearch_buffer_sf <- st_buffer(woodcockResearch_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PGCwoodcockRes"), woodcockResearch_buffer_sf, overwrite=TRUE) # write a feature class to the gdb

########################
### NEW WOODCOCK DATA

# read in the woodcock data 
woodcock_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_Woodcock"), pattern=".csv$")  # --- make sure your excel file is not open.
woodcock_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 4
woodcock_file <- here::here("_data/input/SGCN_data/PGC_Woodcock", woodcock_file[n])

trackfiles("PGC woodcock data", here::here("_data/input/SGCN_data/PGC_Woodcock", woodcock_file[n])) # write to file tracker

woodcock_csv <- read.csv(woodcock_file, stringsAsFactors=FALSE)
woodcock_sf <- st_as_sf(woodcock_csv, coords=c("Long","Lat"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

woodcock_sf$LastObs <- year(as.Date(woodcock_sf$Date,format="%m/%d/%Y"))
woodcock_sf$dayofyear <- yday(as.Date(woodcock_sf$Date,format="%m/%d/%Y"))

woodcock_sf$SNAME <- "Scolopax minor"
woodcock_sf$SCOMNAME <- "American Woodcock"
woodcock_sf$ELCODE <- "ABNNF19020"

### assign a migration date to each ebird observation.
birdseason <- read.csv(here::here("scripts","SGCN_DataCollection","lu_eBird_birdseason.csv"), colClasses = c("character","character","integer","integer"),stringsAsFactors=FALSE)

woodcock_sf$season <- NA
for(i in 1:nrow(birdseason)){
  comname <- birdseason[i,1]
  season <- birdseason[i,2]
  startdate <- birdseason[i,3]
  enddate <- birdseason[i,4]
  woodcock_sf$season[woodcock_sf$SCOMNAME==comname & woodcock_sf$dayofyear>=startdate & woodcock_sf$dayofyear<=enddate] <- substr(as.character(season), 1, 1)
}
woodcock_sf <- woodcock_sf[which(!is.na(woodcock_sf$season)),]

#grouse_sf$DataID <- grouse_sf$globalid # use with Shapefile input
woodcock_sf$DataID <- NA
woodcock_sf$ELSeason <- paste(woodcock_sf$ELCODE, woodcock_sf$season, sep="_")

# add additonal fields 
woodcock_sf$DataSource <- "PGC Woodcock Data"
woodcock_sf$OccProb <- "k"
woodcock_sf$useCOA <- "y"
woodcock_sf$TaxaGroup <- "AB"
colnames(woodcock_sf)[colnames(woodcock_sf)=="season"] <- "SeasonCode"

woodcock_sf <- subset(woodcock_sf, select = final_fields)
woodcock_sf <- woodcock_sf[which(!is.na(woodcock_sf$ELCODE)),]

# create a spatial layer
woodcock_sf <- st_transform(woodcock_sf, crs=customalbers) # reproject to the custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_PGCwoodcock_db"), woodcock_sf, overwrite=TRUE) # write a feature class into the geodatabase
woodcock_buffer <- st_buffer(woodcock_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PGCwoodcock_db"), woodcock_buffer, overwrite=TRUE) # write a feature class into the geodatabase

