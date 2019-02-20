#---------------------------------------------------------------------------------------------
# Name: SGCNcollector_BAMONA.r
# Purpose: https://www.butterfliesandmoths.org/
# Author: Christopher Tracey
# Created: 2017-07-10
# Updated: 
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
# * wkt integration
# * filter the occ_search results on potential data flags -- looks like its pulling 
#   the coordinates from iNat that are obscured.  
# * might be a good idea to create seperate reports with obscured records
#-------

# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
require(lubridate)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)

arc.check_product() # load the arcgis license

# read in SGCN data
sgcn <- arc.open(here("COA_Update.gdb","lu_sgcn")) # need to figure out how to reference a server
sgcn <- arc.select(sgcn, c("ELSeason", "SNAME", "SCOMNAME", "TaxaGroup" ), where_clause="ELSeason LIKE 'IILE%'")

# read in BAMONA data
bamona <- read.csv(here("_data","input","SGCN_data","bamona_data_02_19_2019.csv"), stringsAsFactors=FALSE)
bamona_citation <- "Lotts, Kelly and Thomas Naberhaus, coordinators. 2017. Butterflies and Moths of North America. http://www.butterfliesandmoths.org/ (Version MMDDYYYY)"

# prune bad data from master BAMONA
bamona <- bamona[which(!is.na(bamona$Longitude)),]
bamona$year <- year(parse_date_time(bamona$Observation.Date,"mdy"))
bamona <- bamona[which(!is.na(bamona$year)),]
bamona <- bamona[which(bamona$year>=(year(Sys.Date())-25)),]

#subset BAMONA data by SGCN
bamona1 <- bamona[bamona$Scientific.Name %in% sgcn$SNAME,]
print(paste(length(unique(bamona1$Scientific.Name)),"of the", length(unique(sgcn$SNAME)) ,"lep SGCN were found in the BAMONA database"), sep=" ")

# get a list of SGCN not found in the bamona database
NotInBamona <- setdiff(sgcn$SNAME, bamona1$Scientific.Name)

# add additonal fields 
bamona1$DataSource <- "BAMONA"
bamona1$SeasonCode <- "y"
bamona1$OccProb <- "k"
names(bamona1)[names(bamona1)=='Scientific.Name'] <- 'SNAME'
names(bamona1)[names(bamona1)=='Common.Name'] <- 'SCOMNAME'
names(bamona1)[names(bamona1)=='Record.Number'] <- 'DataID'
names(bamona1)[names(bamona1)=='Lat.Long'] <- 'Latitude'
names(bamona1)[names(bamona1)=='Observation.Date'] <- 'LastObs'

# delete the colums we don't need from the BAMONA dataset
bamona1 <- bamona1[c("DataSource","DataID","SNAME","Longitude","Latitude","OccProb","LastObs","SeasonCode")]

#add in the SGCN fields
bamona1 <- merge(bamona1, sgcn, by="SNAME", all.x=TRUE)

# create a spatial layer
bamona_sf <- st_as_sf(bamona1, coords=c("Longitude","Latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
