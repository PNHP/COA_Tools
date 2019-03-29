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
sgcn <- arc.select(sgcn, c("ELCODE", "SNAME", "SCOMNAME", "TaxaGroup", "Environment","SeasonCode","ELSeason" ))

# read in the bat data 
# note that this is partially processed bat data, and not raw bat data from PGC

brooktrout <- arc.open(here("_data","input","SGCN_data","PFBC_BrookTrout","PA_WildTrout_BrookTroutOnly_NR_Mar2016Export.shp")) 
brooktrout <- arc.select(brooktrout, c("SSB"))

brooktrout <- arc.data2sf(brooktrout)

brooktrout$SNAME <- "Salvelinus fontinalis"
brooktrout$SSB <- NULL

brooktrout <- merge(brooktrout, sgcn[c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","TaxaGroup")], by="SNAME", all.x=TRUE)

brooktrout$DataSource <- "PFBC"
brooktrout$DataID <- rownames(brooktrout)
brooktrout$OccProb <- "k"
brooktrout$LastObs <- 2017
brooktrout$useCOA <- "y"

brooktrout <- brooktrout[final_fields]

brooktrout <- st_transform(brooktrout, crs=customalbers)

brooktrout <- st_buffer(brooktrout, 50)

# write a feature class to the gdb
arc.write(path=here("_data/output/SGCN.gdb","final_brooktrout"), brooktrout, overwrite=TRUE)

