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
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
  require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()

# Bombus Data #################################################################################
bombus <- arc.open(here::here("_data","input","SGCN_data","PA_Bombus","PA_Bombus.shp")) 
bombus <- arc.select(bombus) 

bombus$SNAME <- paste("Bombus",bombus$species, sep=" ")
bombus$DataID <- bombus$LR_BBNA_co
bombus$DataSource <- "Xerces"
bombus$OccProb <- "k"
bombus$SeasonCode <- "y"
bombus$useCOA <- NA
bombus$LastObs <- bombus$year_
bombus$useCOA <- ifelse(bombus$LastObs>=cutoffyear, "y", "n")
bombus <- merge(bombus, lu_sgcn[c("SNAME","ELCODE","ELSeason","SCOMNAME","TaxaGroup")], by="SNAME")
# subset to SGCN
bombus <- bombus[which(bombus$SNAME %in% lu_sgcn$SNAME),]
# kill the ones with no coordinates
bombus <- bombus[which(bombus$longitude<0),]

# field alignment
bombus <- bombus[final_fields] 

# create a spatial layer
bombus_sf <- st_as_sf(bombus, coords=c("longitude","latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
bombus_sf <- st_transform(bombus_sf, crs=customalbers) # reproject to custom albers
# field alignment
bombus_sf <- bombus_sf[final_fields] 
arc.write(path=here::here("_data/output/SGCN.gdb","srcpt_Bombus"), bombus_sf, overwrite=TRUE) # write a feature class into the geodatabase
bombus_buffer_sf <- st_buffer(bombus_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data/output/SGCN.gdb","final_Bombus"), bombus_buffer_sf, overwrite=TRUE) # write a feature class to the gdb

#############################################################################################################################
# One Time Data from PSU, DougGross, and ANF #################################################################################
birdsplus <- arc.open(here::here("_data","input","SGCN_data","birdsplus","birdsplus.shp")) 
birdsplus <- arc.select(birdsplus) 
birdsplus <- arc.data2sf(birdsplus) 

birdsplus <- birdsplus[which(birdsplus$SNAME %in% sgcnlist),]
birdsplus[which(birdsplus$SNAME=="Gallinula galeata"),]$ELCODE <- "ABNME13030"
birdsplus[which(birdsplus$SNAME=="Gallinula galeata"),]$ELSeason <- "ABNME13030"


#birdsplus <- birdsplus[c("TaxaGroup","ELCODE","SNAME","SCOMNAME","DataSource","DataID","SeasonCode","OccProb","LastObs","ELSeason","useCOA")]

birdsplus$LastObs <- year(as.Date(birdsplus$LastObs))
birdsplus$useCOA <- ifelse(birdsplus$LastObs>=cutoffyear, "y", "n")


birdsplus_sf <- birdsplus

# create a spatial layer
birdsplus_sf <- st_transform(birdsplus_sf, crs=customalbers) # reproject to custom albers
names(birdsplus_sf)[names(birdsplus_sf) == 'geom'] <- 'geometry'
st_geometry(birdsplus_sf) <- "geometry"
birdsplus_sf <- birdsplus_sf[final_fields]# field alignment
arc.write(path=here::here("_data/output/SGCN.gdb","srcpt_BirdsPlus"), birdsplus_sf, overwrite=TRUE) # write a feature class into the geodatabase
birdsplus_buffer_sf <- st_buffer(birdsplus_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data/output/SGCN.gdb","final_BirdsPlus"), birdsplus_buffer_sf, overwrite=TRUE) # write a feature class to the gdb



