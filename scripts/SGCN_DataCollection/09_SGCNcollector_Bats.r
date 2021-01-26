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
loadSGCN()

# read in the bat data 

bat_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_bats"), pattern=".xlsx$")  # --- make sure your excel file is not open.
bat_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
bat_file <- here::here("_data/input/SGCN_data/PGC_bats",bat_file[n])

# write to file tracker
trackfiles("Bat Data", bat_file)

#get a list of the sheets in the file
bat_sheets <- getSheetNames(bat_file)
#look at the output and choose which excel sheet you want to load
# Enter the actions sheet (eg. "lu_actionsLevel2") 
bat_sheets # list the sheets

#EPFUABC
n <- 1 # enter its location in the list (first = 1, second = 2, etc)
bat_EPFUabc <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#EPFU Hiber
n <- 2 # enter its location in the list (first = 1, second = 2, etc)
bat_EPFUhiber <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#EPFU PGCtrap
n <- 3 # enter its location in the list (first = 1, second = 2, etc)
bat_EPFUPGCtrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#EPFU PGCtrap
n <- 4 # enter its location in the list (first = 1, second = 2, etc)
bat_LANOPGCtrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#EPFU PGCtrap
n <- 5 # enter its location in the list (first = 1, second = 2, etc)
bat_EPFUcontrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#EPFU PGCtrap
n <- 6 # enter its location in the list (first = 1, second = 2, etc)
bat_LANOcontrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)




names(bat_EPFUabc)
bat_EPFUabc$SNAME <- "Eptesicus fuscus"
bat_EPFUabc$year <- year(mdy(bat_EPFUabc$DATE))
bat_EPFUabc$DataSource <- "bat_EPFUabc"
bat_EPFUabc$SeasonCode <- "b"
bat_EPFUabc <- bat_EPFUabc[c("SNAME","LAT","LON","year","DataSource","SeasonCode")]

names(bat_EPFUhiber)
bat_EPFUhiber$SNAME <- "Eptesicus fuscus"
bat_EPFUhiber$year <- year(ymd(openxlsx::convertToDate(bat_EPFUhiber$SURVEYDATE)))
bat_EPFUhiber$DataSource <- "bat_EPFUhiber"
bat_EPFUhiber$SeasonCode <- "w"
bat_EPFUhiber <- bat_EPFUhiber[c("SNAME","LAT","LON","year","DataSource","SeasonCode")]

names(bat_EPFUPGCtrap)
bat_EPFUPGCtrap$SNAME <- "Eptesicus fuscus"
bat_EPFUPGCtrap$year <- year(ymd(openxlsx::convertToDate(bat_EPFUPGCtrap$DATE)))
bat_EPFUPGCtrap$DataSource <- "bat_EPFUPGCtrap"
bat_EPFUPGCtrap$SeasonCode <- "b"
bat_EPFUPGCtrap <- bat_EPFUPGCtrap[c("SNAME","LAT","LON","year","DataSource","SeasonCode")]

names(bat_LANOPGCtrap)
bat_LANOPGCtrap$SNAME <- "Lasionycteris noctivagans"
bat_LANOPGCtrap$year <- year(ymd(openxlsx::convertToDate(bat_LANOPGCtrap$DATE)))
bat_LANOPGCtrap$DataSource <- "bat_LANOPGCtrap"
bat_LANOPGCtrap$SeasonCode <- "b"
bat_LANOPGCtrap <- bat_LANOPGCtrap[c("SNAME","LAT","LON","year","DataSource","SeasonCode")]
  
names(bat_EPFUcontrap)
bat_EPFUcontrap$SNAME <- "Eptesicus fuscus"
bat_EPFUcontrap$year <- year(ymd(openxlsx::convertToDate(bat_EPFUcontrap$DATE)))
bat_EPFUcontrap$DataSource <- "bat_EPFUcontrap"
bat_EPFUcontrap$SeasonCode <- "b"
bat_EPFUcontrap <- bat_EPFUcontrap[c("SNAME","LAT","LON","year","DataSource","SeasonCode")]

names(bat_LANOcontrap)
bat_LANOcontrap$SNAME <- "Lasionycteris noctivagans"
bat_LANOcontrap$year <- year(ymd(openxlsx::convertToDate(bat_LANOcontrap$DATE)))
bat_LANOcontrap$DataSource <- "bat_LANOcontrap"
bat_LANOcontrap$SeasonCode <- "b"
bat_LANOcontrap <- bat_LANOcontrap[c("SNAME","LAT","LON","year","DataSource","SeasonCode")]

# join up everything
bat_alldata <- rbind(bat_EPFUabc, bat_EPFUhiber, bat_EPFUPGCtrap, bat_LANOPGCtrap, bat_EPFUcontrap, bat_LANOcontrap)

# rename 'year' field
names(bat_alldata)[names(bat_alldata) == "year"] <- "LastObs"

# delete the data we don't need anymore
remove(bat_EPFUabc, bat_EPFUhiber, bat_EPFUPGCtrap, bat_LANOPGCtrap, bat_EPFUcontrap, bat_LANOcontrap)

# merge in the SGCN data
bats <- merge(bat_alldata, lu_sgcn, by=c("SNAME", "SeasonCode"), all.x=TRUE)

# Data Source
bats$useCOA <- with(bats, ifelse(bats$LastObs >= cutoffyear, "y", "n"))
bats$DataID <- NA

# occprob
bats$OccProb <- "k"

# check for coordinate errors
names(bats)[names(bats) == "LON"] <- "Longitude"
names(bats)[names(bats) == "LAT"] <- "Latitude"

bats$Latitude <- as.numeric(bats$Latitude)
bats$Longitude <- as.numeric(bats$Longitude)

plot(bats$Longitude, bats$Latitude)
summary(bats$Latitude)
summary(bats$Longitude)

bats <- bats[which(!is.na(bats$Latitude)|!is.na(bats$Longitude)),]

bats[which(bats$Longitude>0),"Longitude"] <- bats[which(bats$Longitude>0),"Longitude"] * -1

# create a spatial layer
bats_sf <- st_as_sf(bats, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
library(lwgeom)
bats_sf <- st_make_valid(bats_sf)

# st_dimension
bats_sf <- st_transform(bats_sf, crs=customalbers) # reproject to custom albers
bats_sf <- bats_sf[final_fields]
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_bats"), bats_sf, overwrite=TRUE, validate=TRUE) # write a feature class to the gdb
bats_buffer_sf <- st_buffer(bats_sf, 100) # buffer the points by 100m
bats_buffer_sf <- st_make_valid(bats_buffer_sf)
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_bats"), bats_buffer_sf, overwrite=TRUE, validate=TRUE) # write a feature class to the gdb
