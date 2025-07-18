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
lu_sgcn <- lu_sgcn[which(substr(lu_sgcn$ELSeason,1,4)=="IILE"),]

# sgcnLepBiotics <- setdiff(lu_sgcn$SNAME, SGCN_bioticsCPP)


# read in BAMONA data
bamona_file <- list.files(path=here::here("_data","input","SGCN_data","bamona"), pattern=".csv$")  # --- make sure your excel file is not open.
bamona_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 1
bamona_file <- here::here("_data","input","SGCN_data","bamona", bamona_file[n])

# write to file tracker
trackfiles("SGCN BAMONA", bamona_file)

# read in the file

bamona <- read.csv(bamona_file, stringsAsFactors=FALSE)
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
bamona1$useCOA <- NA
cutoffYear <- year(Sys.Date())-25
bamona1$useCOA <- with(bamona1, ifelse(bamona1$LastObs >= cutoffYear, "y", "n"))

# add additonal fields 
bamona1$DataSource <- "BAMONA"
bamona1$SeasonCode <- "y"
bamona1$OccProb <- "k"

# delete the colums we don't need from the BAMONA dataset
bamona1 <- bamona1[c("DataSource","DataID","SNAME","Longitude","Latitude","OccProb","LastObs","SeasonCode","useCOA")]

#add in the SGCN fields
bamona1 <- merge(bamona1, lu_sgcn[c("SNAME","ELCODE","ELSeason","SCOMNAME","TaxaGroup")], by="SNAME", all.x=TRUE)

# create a spatial layer
bamona_sf <- st_as_sf(bamona1, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
bamona_sf <- bamona_sf[final_fields]
bamona_sf <- st_transform(bamona_sf, crs=customalbers) # reproject to the custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_BAMONA"), bamona_sf, overwrite=TRUE) # write a feature class into the geodatabase
bamona_buffer <- st_buffer(bamona_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_BAMONA"), bamona_buffer, overwrite=TRUE) # write a feature class into the geodatabase

# clean up
rm(bamona, bamona1, lu_sgcn, SGCN_bioticsCPP)


#render(here("scripts","SGCN_DataCollection","markdown_BAMONA.rmd"))

