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
loadSGCN("AF")

brooktrout <- arc.open(here("_data","input","SGCN_data","PFBC_BrookTrout","PA_WildTrout_BrookTroutOnly_NR_Mar2016Export.shp")) 
brooktrout <- arc.select(brooktrout, c("SSB"))
brooktrout <- arc.data2sf(brooktrout)

brooktrout$SNAME <- "Salvelinus fontinalis"
brooktrout$SSB <- NULL

brooktrout <- merge(brooktrout, lu_sgcn[c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","TaxaGroup")], by="SNAME", all.x=TRUE)

brooktrout$DataSource <- "PFBC"
brooktrout$DataID <- rownames(brooktrout)
brooktrout$OccProb <- "k"
brooktrout$LastObs <- 2017
brooktrout$useCOA <- "y"

brooktrout <- brooktrout[final_fields]

# create a spatial layer
brooktrout_sf <- st_transform(brooktrout, crs=customalbers) # reproject to custom albers
arc.write(path=here("_data/output/SGCN.gdb","srcln_brooktrout_sf"), brooktrout_sf, overwrite=TRUE) # write a feature class to the gdb
brooktrout_buffer_sf <- st_buffer(brooktrout_sf, 100) # buffer the points by 100m
arc.write(path=here("_data/output/SGCN.gdb","final_BBAptct"), brooktrout_buffer_sf, overwrite=TRUE) # write a feature class to the gdb

# write a feature class to the gdb
arc.write(path=here("_data/output/SGCN.gdb","final_brooktrout"), brooktrout, overwrite=TRUE)

