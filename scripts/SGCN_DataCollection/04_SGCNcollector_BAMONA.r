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

# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
  require(arcgisbinding)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
  require(lubridate)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
  require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
  require(sf)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)
if (!requireNamespace("rmarkdown", quietly = TRUE)) install.packages("rmarkdown")
  require(rmarkdown)

source(here::here("scripts","SGCN_DataCollection","00_PathsAndSettings.r"))

load(file=updateData)

# read in SGCN data
loadSGCN()
lu_sgcn <- lu_sgcn[which(substr(lu_sgcn$ELSeason,1,4)=="IILE"),]

# read in BAMONA data
bamona_file <- "bamona_data_02_19_2019.csv"
bamona <- read.csv(here("_data","input","SGCN_data","bamona", bamona_file), stringsAsFactors=FALSE)
bamona_citation <- "Lotts, Kelly and Thomas Naberhaus, coordinators. 2017. Butterflies and Moths of North America. http://www.butterfliesandmoths.org/ (Version MMDDYYYY)"

bamona_backup <- bamona

# change field names
names(bamona)[names(bamona)=='Scientific.Name'] <- 'SNAME'
names(bamona)[names(bamona)=='Common.Name'] <- 'SCOMNAME'
names(bamona)[names(bamona)=='Record.Number'] <- 'DataID'
names(bamona)[names(bamona)=='Lat.Long'] <- 'Latitude'

# prune bad data from master BAMONA
bamona <- bamona[which(!is.na(bamona$Longitude)),]
bamona$LastObs <- year(parse_date_time(bamona$Observation.Date,"mdy"))
bamona <- bamona[which(!is.na(bamona$LastObs)),]

#subset BAMONA data by SGCN
bamona1 <- bamona[bamona$SNAME %in% lu_sgcn$SNAME,]
print(paste(length(unique(bamona1$SNAME)),"of the", length(unique(lu_sgcn$SNAME)) ,"lep SGCN were found in the BAMONA database"), sep=" ")

# get a list of SGCN not found in the bamona database
NotInBamona <- setdiff(lu_sgcn$SNAME, bamona1$Scientific.Name)
NotInBamona
# subset to leps that are not in Biotics
#DELETE SGCN_bioticsCPP <- read.csv("SGCN_bioticsCPP.csv", stringsAsFactors=FALSE)
bamona1 <- bamona1[which(!bamona1$SNAME %in% SGCN_bioticsCPP),]

table(bamona1$SNAME)

# add in useCOA
bamona1$UseCOA <- NA
cutoffYear <- year(Sys.Date())-25
bamona1$UseCOA <- with(bamona1, ifelse(bamona1$year >= cutoffYear, "y", "n"))

# add additonal fields 
bamona1$DataSource <- "BAMONA"
bamona1$SeasonCode <- "y"
bamona1$OccProb <- "k"

# delete the colums we don't need from the BAMONA dataset
bamona1 <- bamona1[c("DataSource","DataID","SNAME","Longitude","Latitude","OccProb","LastObs","SeasonCode","UseCOA")]

#add in the SGCN fields
bamona1 <- merge(bamona1, lu_sgcn, by="SNAME", all.x=TRUE)

# create a spatial layer
bamona_sf <- st_as_sf(bamona1, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
bamona_sf <- st_transform(bamona_sf, crs=customalbers)
# buffer by 100m
bamona_sf <- st_buffer(bamona_sf, dist=100)

# write a feature class into the geodatabase
arc.write(path=here("_data/output/SGCN.gdb","final_BAMONA"), bamona_sf, overwrite=TRUE)

# clean up
rm(bamona, bamona1, lu_sgcn, SGCN_bioticsCPP)


#render(here("scripts","SGCN_DataCollection","markdown_BAMONA.rmd"))