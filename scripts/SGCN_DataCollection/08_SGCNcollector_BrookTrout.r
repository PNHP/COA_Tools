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
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
  require(arcgisbinding)
require(sf)
arc.check_product()

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN("AF")

# read in Brook trout data
#trout_file <- list.files(path=here::here("_data","input","SGCN_data","PFBC_BrookTrout"), pattern=".shp$")  # --- make sure your excel file is not open.
#trout_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
#n <- 4
#trout <- here::here("_data/input/SGCN_data/PFBC_BrookTrout", trout_file[n])

# using this trout file because needed to remove m values
trout_file <- here::here("_data","input","SGCN_data","PFBC_BrookTrout","BrookTrout.gdb","Wild_BrookTrout_post_1993")

# write to file tracker
trackfiles("SGCN Brook Trout", trout_file)

# open file and do stuff
brooktrout <- arc.open(trout_file)
brooktrout <- arc.select(brooktrout, c("Year_sampl"))
brooktrout <- arc.data2sf(brooktrout)
#st_crs(brooktrout) <- 4269 #set coordinate system to NAD83 which matches input.

brooktrout$SNAME <- "Salvelinus fontinalis"
# brooktrout$SSB <- NULL

brooktrout <- merge(brooktrout, lu_sgcn[c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","TaxaGroup")], by="SNAME", all.x=TRUE)

brooktrout$DataSource <- "PFBC"
brooktrout$DataID <- rownames(brooktrout)
brooktrout$LastObs <- as.integer(brooktrout$Year_sampl)
brooktrout$OccProb <- with(brooktrout, ifelse(brooktrout$LastObs>=cutoffyearK , "k", ifelse(brooktrout$LastObs<cutoffyearK & brooktrout$LastObs>=cutoffyearL, "l", "u")))
brooktrout$useCOA <- "y"

brooktrout <- brooktrout[final_fields]

# create a spatial layer
brooktrout_sf <- st_transform(brooktrout, crs=customalbers) # reproject to custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcln_brooktrout_sf"), brooktrout_sf, overwrite=TRUE, validate=TRUE) # write a feature class to the gdb
brooktrout_buffer_sf <- st_buffer(brooktrout_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_brooktrout"), brooktrout_buffer_sf, overwrite=TRUE, validate=TRUE) # write a feature class to the gdb

