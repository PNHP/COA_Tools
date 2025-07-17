# Name: 06a_SGCNcollector_BarnOwls.r
# Purpose: Created to incorporate PGC Barn Owl records sent by PGC
# Author: Molly Moore
# Created: 2024-10-16
#
# Updates:
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

#############THIS IS FOR CSV FORMAT#############################################
# check for barn owl .csv files and allow user to select current .csv file for inclusion
BAOW_file <- list.files(path=here::here("_data/input/SGCN_data/PGC_Owls"), pattern=".csv$")
BAOW_file
#look at the output and choose which .csv you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
BAOW_file <- here::here("_data/input/SGCN_data/PGC_Owls", BAOW_file[n])

trackfiles("SGCN", here::here("_data/input/SGCN_data/PGC_Owls", BAOW_file[n])) # write to file tracker

# load .csv file and convert to SF
BAOW_csv <- read.csv(BAOW_file, stringsAsFactors=FALSE)
BAOW_sf <- st_as_sf(BAOW_csv, coords=c("Long","Lat"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# add COA fields
BAOW_sf$LastObs <- BAOW_sf$Last_Confirmed_Breeding
BAOW_sf$SNAME <- "Tyto alba"
BAOW_sf$SCOMNAME <- "Barn Owl"
BAOW_sf$ELCODE <- "ABNSA01010"
BAOW_sf$SeasonCode <- "b"
BAOW_sf$ELSeason <- paste0(BAOW_sf$ELCODE,"_",BAOW_sf$SeasonCode)
BAOW_sf$TaxaGroup <- "AB"
BAOW_sf$DataSource <- "PGC Barn Owl Conservation Initiative"
BAOW_sf$DataID <- NA
BAOW_sf$OccProb <- "k"
BAOW_sf$useCOA <- with(BAOW_sf, ifelse(BAOW_sf$LastObs >= cutoffyear, "y", "n"))

# limit to final COA fields
BAOW_sf <- subset(BAOW_sf, select = final_fields)

# write the spatial layer to AGOL .gdb, buffer srcpts and write to .gdb
BAOW_sf <- st_transform(BAOW_sf, crs=customalbers) # reproject to the custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_PGCBAOW"), BAOW_sf, overwrite=TRUE) # write a feature class into the geodatabase
BAOW_buffer <- st_buffer(BAOW_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PGCBAOW"), BAOW_buffer, overwrite=TRUE) # write a feature class into the geodatabase

