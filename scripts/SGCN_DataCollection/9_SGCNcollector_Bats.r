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

source(here::here("scripts","SGCN_DataCollection","0_PathsAndSettings.r"))

# read in SGCN data
sgcn <- arc.open(here("COA_Update.gdb","lu_sgcn")) # need to figure out how to reference a server
sgcn <- arc.select(sgcn, c("ELCODE", "SNAME", "SCOMNAME", "TaxaGroup", "SeasonCode","ELSeason" ))

# read in the bat data 
# note that this is partially processed bat data, and not raw bat data from PGC
eptefusc <- read.csv(here("_data","input","SGCN_data","PGC_bats","EptesicusFuscus","BigBrownBat.csv"), stringsAsFactors=FALSE)
tricollb <- read.csv(here("_data","input","SGCN_data","PGC_bats","TriColoredLittleBrownBats","TriColored_LittleBrownBats.csv"), stringsAsFactors=FALSE)

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
