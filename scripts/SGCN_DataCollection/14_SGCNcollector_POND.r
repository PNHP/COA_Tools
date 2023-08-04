#---------------------------------------------------------------------------------------------
# Name: 14_SGCNcollector_POND.r
# Purpose: 
# Author: Molly Moore
# Created: 2019-10-01
# Updated: 
#
# Updates:
#
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

#load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

#get paths listed in paths and settings script
source(here::here("scripts","00_PathsAndSettings.r"))

arc.check_portal()

# read in SGCN data
loadSGCN()

#paths to POND feature service layers
pond_sde <- "C://Users//mmoore//AppData//Roaming//Esri//ArcGISPro//Favorites//PNHP_Working_pgh-gis0.sde"
pond_pts <- paste(pond_sde,"PNHP.DBO.POND//PNHP.DBO.pools",sep="/")
pond_species <- paste(pond_sde,"PNHP.DBO.species",sep="/")
pond_surveys <- paste(pond_sde,"PNHP.DBO.surveys",sep="/")

#import all species records from POND
species_fields <- c('refcode','species_type','sname','species_found')
s <- arc.open(pond_species)
species <- arc.select(s,species_fields) #add code to load only sgcn species from lu_sgcn list

#limit POND species records to SGCN species
sgcn_species <- species[species$sname %in% lu_sgcn$ELCODE,]

#join sgcn data fields
sgcn_species <- merge(x=sgcn_species, y=lu_sgcn, by.x='sname', by.y='ELCODE', all.x=TRUE)
#exclude records where species was NOT found
sgcn_species <- sgcn_species[sgcn_species$species_found=='Y',]

#import all survey records from POND
survey_fields <- c('pool_id','refcode','start_date')
su <- arc.open(pond_surveys)
surveys <- arc.select(su,survey_fields)
surveys$start_date <- strtrim(surveys$start_date,4)

#limit surveys to only those where SGCN species were found
sgcn_surveys <- merge(x=surveys, y=sgcn_species, by='refcode', all.y=TRUE)

#import all vernal pool points from POND
point_fields <- c('pool_id','pool_name','Shape')
p <- arc.open(pond_pts)
pond_points <- arc.select(p,point_fields)
pond_sf <- arc.data2sf(pond_points)
st_crs(pond_sf) <- 3857 #set to web mercator

#limit POND points to those with SGCN species in them
sgcn_points <- merge(x=pond_sf, y=sgcn_surveys, by='pool_id', all.y=TRUE)

#change column names to match schema
names(sgcn_points)[names(sgcn_points) %in% c('pool_id','start_date','sname')] <- c('DataID','LastObs','ELCODE')

#add SGCN columns and fill with info to match schema
sgcn_points$DataSource <- 'PNHP POND'
sgcn_points$OccProb <- 'k'
sgcn_points$useCOA <- ifelse(sgcn_points$LastObs>=cutoffyearK ,"y","n")

#rearrange columns and subset to only needed columns to match scheuma of SGCN data
sgcn_pond <- sgcn_points[,c('ELCODE','ELSeason','SNAME','SCOMNAME','SeasonCode','DataSource','DataID','OccProb','LastObs','useCOA','TaxaGroup')]
sgcn_pond <- st_transform(sgcn_pond, crs=customalbers) # reproject to custom albers

#write POND point to feature class in SGCN gdb
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_POND"), sgcn_pond, overwrite=TRUE)
sgcn_pond_buff <- st_buffer(sgcn_pond, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_POND"), sgcn_pond_buff, overwrite=TRUE)

