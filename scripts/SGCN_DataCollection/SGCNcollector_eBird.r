#---------------------------------------------------------------------------------------------
# Name: SGCNcollector_eBird.r
# Purpose: https://www.butterfliesandmoths.org/
# Author: Christopher Tracey
# Created: 2017-07-10
# Updated: 2019-02-20
#
# Updates:
# insert date and info
# * 2018-09-21 -  
# * 2019-02-20 - rewrite and update
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------

# Instructions: Before running cleanup code, download and save eBird data in your working directory  

# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("auk", quietly = TRUE)) install.packages("auk")
require(auk)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
require(lubridate)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)

arc.check_product() # load the arcgis license

# read in SGCN data
sgcn <- arc.open(here("COA_Update.gdb","lu_sgcn")) # need to figure out how to reference a server
sgcn <- arc.select(sgcn, c("ELSeason", "SNAME", "SCOMNAME", "TaxaGroup" ), where_clause="ELSeason LIKE 'AB%'")

sgcn_clean <- unique(sgcn$SNAME)

# read in eBird data

#get a list of what's in the directory
fileList <- dir(path=here("_data","input","SGCN_data","eBird"), pattern = ".txt$")
fileList
#look at the output and choose which shapefile you want to run. enter its location in the list (first = 1, second = 2, etc)
n <- 1




# check and load required libraries  
if (!requireNamespace("rgdal", quietly = TRUE)) install.packages("rgdal")
require(rgdal)
if (!requireNamespace("raster", quietly = TRUE)) install.packages("raster")
require(raster)

# library(auk)
SGCNlist <- read.csv("Birds_eBird_Eligible.csv", stringsAsFactors = FALSE)
SGCN <- SGCNlist$CommonName
SGCN <- SGCN[-c(71,72)]
SGCN <- unique(SGCN)


f_in <- "C:/Users/dyeany/Documents/R/eBird/ebd.txt"
f_out <- "ebd_filtered_SGCN.txt"
ebd <- auk_ebd(f_in)
ebd_filters <- auk_species(ebd, species = SGCN)
ebd_filtered <- auk_filter(ebd_filters, file = f_out)
ebd_df <- read_ebd(ebd_filtered)
ebd_df_backup <- ebd_df

# gets rid of the bad data lines
ebd_df$lat <- as.numeric(as.character(ebd_df$latitude))
ebd_df$lon <- as.numeric(as.character(ebd_df$longitude))
# ebd_df <- ebd_df[!is.na(as.numeric(as.character(ebd_df$lat))),]
# ebd_df <- ebd_df[!is.na(as.numeric(as.character(ebd_df$lon))),]

### Filter out unsuitable protocols (e.g. Traveling, etc.) and keep only suitable protocols (e.g. Stationary, etc.)
ebd_df <- ebd_df[which(ebd_df$locality_type=="P"|ebd_df$locality_type=="H"),]
ebd_df <- ebd_df[which(ebd_df$protocol_type=="Incidental"|ebd_df$protocol_type=="Stationary"|ebd_df$protocol_type=="Rusty Blackbird Spring Migration Blitz"|ebd_df$protocol_type=="Banding"|ebd_df$protocol_type=="International Shorebird Survey (ISS)"),]

### Next filter out records by Focal Season for each SGCN using day-of-year
# library(lubridate)
ebd_df$dayofyear <- yday(ebd_df$observation_date) ## Add day of year to eBird dataset based on the observation date.
birdseason <- read.csv("birdseason_new.csv", stringsAsFactors = FALSE)

### assign a migration date to each ebird observation.
for(i in 1:nrow(birdseason)){
  comname<-birdseason[i,1]
  season<-birdseason[i,2]
  startdate<-birdseason[i,3]
  enddate<-birdseason[i,4]
  ebd_df$season[ebd_df$common_name==comname & ebd_df$dayofyear>startdate & ebd_df$dayofyear<enddate] <- as.character(season)
}
# Unknown or uninitialized column means that dates were outsied of SGCN seasons

# drops any species that has an NA due to be outsite the season dates
ebd_df <- ebd_df[!is.na(ebd_df$season),]
# drops the unneeded columns. please modify the list.
keeps <- c("common_name","scientific_name","lat","lon","locality_type","protocol_type","dayofyear","season", "observation_date" )
ebd_df <- ebd_df[keeps]

#create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
# library(rgdal)  # for vector work; sp package should always load with rgdal. 
# library (raster)   # for metadata/attributes- vectors or rasters
# note that the easting and northing columns are in columns 4 and 5
ebird_extract <- SpatialPointsDataFrame(ebd_df[,4:3],ebd_df,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS  ,proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature

plot(ebird_extract,main="Pennsylvania eBird points")
# write a shapefile
writeOGR(ebird_extract, getwd(),"ebird_extract", driver="ESRI Shapefile")