# Name: 
# Purpose: 
# Author: Christopher Tracey
# Created: 2016-08-11
# Updates:
# 2022-10-18 - MMOORE updated to accommodate new 2021-2022 PGC contractor data delivered by PGC
#---------------------------------------------------------------------------------------------
# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()

# function to convert excel to date
dateswap <- function(fld){
  
}
openxlsx::convertToDate(42705)

# read in the bat data 
bat_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_bats"), pattern=".xlsx$")  # --- make sure your excel file is not open.
bat_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 2
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
bat_EPFUabc <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE, detectDates=TRUE)

#EPFU Hiber
n <- 2 # enter its location in the list (first = 1, second = 2, etc)
bat_EPFUhiber <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#EPFU PGCtrap
n <- 3 # enter its location in the list (first = 1, second = 2, etc)
bat_EPFUPGCtrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#LANO PGCtrap
n <- 4 # enter its location in the list (first = 1, second = 2, etc)
bat_LANOPGCtrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#EPFU PGCtrap
n <- 5 # enter its location in the list (first = 1, second = 2, etc)
bat_EPFUcontrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

#LANO PGCtrap
n <- 6 # enter its location in the list (first = 1, second = 2, etc)
bat_LANOcontrap <- read.xlsx(xlsxFile=bat_file, sheet=bat_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

names(bat_EPFUabc)
bat_EPFUabc$SNAME <- "Eptesicus fuscus"
bat_EPFUabc$LastObs <- format(as.Date(bat_EPFUabc$DATE,format = "%m/%d/%Y"),"%Y")
bat_EPFUabc$DataSource <- "bat_EPFUabc"
bat_EPFUabc$SeasonCode <- "b"
bat_EPFUabc <- bat_EPFUabc[c("SNAME","LAT","LON","LastObs","DataSource","SeasonCode")]

names(bat_EPFUhiber)
bat_EPFUhiber$SNAME <- "Eptesicus fuscus"
bat_EPFUhiber$LastObs <- format(as.Date(bat_EPFUhiber$SURVEYDATE,origin="1899-12-30"),"%Y")
bat_EPFUhiber$DataSource <- "bat_EPFUhiber"
bat_EPFUhiber$SeasonCode <- "w"
bat_EPFUhiber <- bat_EPFUhiber[c("SNAME","LAT","LON","LastObs","DataSource","SeasonCode")]

names(bat_EPFUPGCtrap)
bat_EPFUPGCtrap$SNAME <- "Eptesicus fuscus"
bat_EPFUPGCtrap$LastObs <- format(as.Date(bat_EPFUPGCtrap$DATE,origin="1899-12-30"),"%Y")
bat_EPFUPGCtrap$DataSource <- "bat_EPFUPGCtrap"
bat_EPFUPGCtrap$SeasonCode <- "b"
bat_EPFUPGCtrap <- bat_EPFUPGCtrap[c("SNAME","LAT","LON","LastObs","DataSource","SeasonCode")]

names(bat_LANOPGCtrap)
bat_LANOPGCtrap$SNAME <- "Lasionycteris noctivagans"
bat_LANOPGCtrap$LastObs <- format(as.Date(bat_LANOPGCtrap$DATE,origin="1899-12-30"),"%Y")
bat_LANOPGCtrap$DataSource <- "bat_LANOPGCtrap"
bat_LANOPGCtrap$SeasonCode <- "b"
bat_LANOPGCtrap <- bat_LANOPGCtrap[c("SNAME","LAT","LON","LastObs","DataSource","SeasonCode")]
  
names(bat_EPFUcontrap)
bat_EPFUcontrap$SNAME <- "Eptesicus fuscus"
bat_EPFUcontrap$LastObs <- format(as.Date(bat_EPFUcontrap$DATE,origin="1899-12-30"),"%Y")
bat_EPFUcontrap$DataSource <- "bat_EPFUcontrap"
bat_EPFUcontrap$SeasonCode <- "b"
bat_EPFUcontrap <- bat_EPFUcontrap[c("SNAME","LAT","LON","LastObs","DataSource","SeasonCode")]

names(bat_LANOcontrap)
bat_LANOcontrap$SNAME <- "Lasionycteris noctivagans"
bat_LANOcontrap$LastObs <- format(as.Date(bat_LANOcontrap$DATE,origin="1899-12-30"),"%Y")
bat_LANOcontrap$DataSource <- "bat_LANOcontrap"
bat_LANOcontrap$SeasonCode <- "b"
bat_LANOcontrap <- bat_LANOcontrap[c("SNAME","LAT","LON","LastObs","DataSource","SeasonCode")]

# join up everything
bat_alldata <- rbind(bat_EPFUabc, bat_EPFUhiber, bat_EPFUPGCtrap, bat_LANOPGCtrap, bat_EPFUcontrap, bat_LANOcontrap)

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

#################################################################################
# 2021-2022 bat data from PGC
#################################################################################

bat_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_bats"), pattern=".csv")  # --- make sure your excel file is not open.
bat_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
bat_file_22 <- here::here("_data/input/SGCN_data/PGC_bats",bat_file[n])
n <- 2
bat_file_23 <- here::here("_data/input/SGCN_data/PGC_bats",bat_file[n])

# load in 21-22 PGC bat data
bats1 <- read.csv(bat_file_22)
bats2 <- read.csv(bat_file_23)

# set up PGC species code to ELCODE crosswalk
PGC_crosswalk <- data.frame("PGC_code"=c("MYLU", "MYSO", "EPFU", "MYLE", "MYSE", "PESU", "LANO"),"ELCODE"=c("AMACC01010","AMACC01100","AMACC04010","AMACC01130","AMACC01150","AMACC03020","AMACC02010"), stringsAsFactors=FALSE)
species_crosswalk <- data.frame("Species"=c("Little Brown","Indiana","Big Brown","Small-footed","Northern Long-eared","Tricolored","Silver-haired"),
                                "ELCODE"=c("AMACC01010","AMACC01100","AMACC04010","AMACC01130","AMACC01150","AMACC03020","AMACC02010"))

# join ELCODE to dataset using PGC crosswalk
bats1 <- bats1 %>%
  left_join(PGC_crosswalk, by = c("Species.Code" = "PGC_code"))
bats2 <- bats2 %>%
  left_join(species_crosswalk, by = c("Species" = "Species"))


bats2$Survey.Date <- paste(bats2$Month,bats2$Day,bats2$Year, sep="/")

colnames(bats2)[colnames(bats2)=="LAT"] <- "LATITUDE"
colnames(bats2)[colnames(bats2)=="LONG"] <- "LONGITUDE"

common_cols <- intersect(colnames(bats1), colnames(bats2))

bat_cap <- rbind(
  subset(bats1, select = common_cols), 
  subset(bats2, select = common_cols)
)


# fill season code based on bat safe dates
# add day of year to bat survey date
bat_cap$dayofyear <- yday(as.Date(bat_cap$Survey.Date, format="%m/%d/%Y"))

# assign start and end dates for bat breeding (5/15 - 8/1)
start_day <- yday(as.Date("5/15/2022", format="%m/%d/%Y"))
end_day <- yday(as.Date("8/1/2022", format="%m/%d/%Y"))

# list big brown, little brown, indiana, tricolored for use in ifelse statement below
winter_bats <- c("AMACC04010", "AMACC01100", "AMACC01010", "AMACC03020", "AMACC02010")
# assign season code based on if survey day of year are between start and end days
# season codes for Big Brown, Little Brown, Indiana, and Tricolored are broken into breeding and wintering. All the rest are breeding and year round.
bat_cap$SeasonCode <- ifelse(bat_cap$ELCODE %in% winter_bats,(ifelse(bat_cap$dayofyear >= start_day & bat_cap$dayofyear <= end_day, "b", "w")), "y")
# remove wintering silver-haired bats because they are not SGCN
bat_cap <- bat_cap[which(!(bat_cap$ELCODE=="AMACC02010"&bat_cap$SeasonCode=="w")),]

# merge in the SGCN data
bat_cap <- merge(bat_cap, lu_sgcn, by=c("ELCODE", "SeasonCode"), all.x=TRUE)

# add COA fields
bat_cap$LastObs <- format(as.Date(bat_cap$Survey.Date, format="%m/%d/%Y"),"%Y")
bat_cap$useCOA <- with(bat_cap, ifelse(bat_cap$LastObs >= cutoffyear, "y", "n"))
bat_cap$DataSource <- "PGC_captures"
bat_cap$OccProb <- "k"
bat_cap$DataID <- NA
names(bat_cap)[names(bat_cap) == "LONGITUDE"] <- "Longitude"
names(bat_cap)[names(bat_cap) == "LATITUDE"] <- "Latitude"

# limit fields to those in the other bat data prepare to rbind
common_cols <- intersect(colnames(bat_cap), colnames(bats))

# rbind bat data together
bats <- rbind(
  subset(bats, select = common_cols), 
  subset(bat_cap, select = common_cols)
)

# proceed with latitude/longitude checks for accuracy
library(measurements)
x = '40-15-49'
stringr::str_detect(bats$Latitude, "([0-9]{2})[-]([0-9]{2})[-]([0-9]{2})")
x = gsub('-', ' ', x)
x = measurements::conv_unit(gsub('-', ' ', x), from='deg_min_sec', to='dec_deg')

bats[which(stringr::str_detect(bats$Latitude, "([0-9]{2})[-]([0-9]{2})[-]([0-9]{2})")),"Latitude"] <- measurements::conv_unit(gsub('-', ' ', bats[which(stringr::str_detect(bats$Latitude, "([0-9]{2})[-]([0-9]{2})[-]([0-9]{2})")),"Latitude"]), from='deg_min_sec', to='dec_deg')
bats[which(stringr::str_detect(bats$Longitude, "([0-9]{2})[-]([0-9]{2})[-]([0-9]{2})")),"Longitude"] <- measurements::conv_unit(gsub('-', ' ', bats[which(stringr::str_detect(bats$Longitude, "([0-9]{2})[-]([0-9]{2})[-]([0-9]{2})")),"Longitude"]), from='deg_min_sec', to='dec_deg')

bats$Latitude <- as.numeric(bats$Latitude)
bats$Longitude <- as.numeric(bats$Longitude)

plot(bats$Longitude, bats$Latitude)
summary(bats$Latitude)
summary(bats$Longitude)

bats[which(bats$Longitude>0),"Longitude"] <- abs(bats[which(bats$Longitude>0),"Longitude"]) * -1

bats <- bats[which(!is.na(bats$Latitude)|!is.na(bats$Longitude)),]

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

