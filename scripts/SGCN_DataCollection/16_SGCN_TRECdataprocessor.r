#---------------------------------------------------------------------------------------------
# Name: SGCNcollector_BAMONA.r
# Purpose: https://www.butterfliesandmoths.org/
# Author: Christopher Tracey
# Created: 2017-07-10
# Updated: 2019-02-19
#
# Updates:
# insert date and info
# * 2016-08-17 - got the code to remove NULL values from the keys to work; 
#                added the complete list of SGCN to load from a text file;
#                figured out how to remove records where no occurences we found;
#                make a shapefile of the results  
# * 2019-02-19 - rewrite and update
#
# To Do List/Future Ideas:
# * check projection
# * write bibtex
# * Migrant, Unknown, Stray, Temporary Colonist, Nonresident filter
#---------------------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# load the r data file
load(file=updateData)

# read in SGCN data
loadSGCN()

# assemble TREC data
trackfiles("SGCN TREC", here::here("_data","input","SGCN_data","TREC","SGCN_FromTREC.shp")) # write to file tracker
TREC <- arc.open(here::here("_data","input","SGCN_data","TREC","SGCN_FromTREC.shp")) 
TREC <- arc.select(TREC) 
TREC <- arc.data2sf(TREC)
st_crs(TREC) <- 4326

`%!in%` = Negate(`%in%`)
notTREC <- TREC[which(TREC$SNAME %!in% sgcnlist),]
unique(notTREC$SNAME)

TREC[which(TREC$SNAME=="Boloria selene myrina"),]$SNAME <- "Boloria selene"

TREC <- TREC[which(TREC$SNAME %in% sgcnlist),]

TREC$LastObs <- year(as.Date(TREC$date))
TREC$useCOA <- ifelse(TREC$LastObs>=cutoffyear&TREC$date!=" ", "y", "n")
TREC[which(is.na(TREC$LastObs)),]$useCOA <- "n"

TREC$SeasonCode <- ifelse(TREC$season==" ", "y", substr(TREC$season,1,1))

TREC$ELSeason <- paste(TREC$ELCODE,TREC$SeasonCode, sep="_")
TREC$DataSource <- "TREC"
TREC$OccProb <- "k"

TREC <- TREC[which(TREC$ELSeason %in% lu_sgcn$ELSeason),]

TREC_sf <- TREC

# create a spatial layer
TREC_sf <- st_transform(TREC_sf, crs=customalbers) # reproject to custom albers
names(TREC_sf)[names(TREC_sf) == 'geom'] <- 'geometry'
st_geometry(TREC_sf) <- "geometry"
TREC_sf <- TREC_sf[final_fields]# field alignment
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_TREC"), TREC_sf, overwrite=TRUE) # write a feature class into the geodatabase
TREC_buffer_sf <- st_buffer(TREC_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_TREC"), TREC_buffer_sf, overwrite=TRUE) # write a feature class to the gdb

