#---------------------------------------------------------------------------------------------
# Name: 4_SGCNcollector_PFBCfish.r
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

arc.check_product() # load the arcgis license

# read in SGCN data
sgcn <- arc.open(here("COA_Update.gdb","lu_sgcn")) # need to figure out how to reference a server
sgcn <- arc.select(sgcn, c("ELSeason", "SNAME", "SCOMNAME", "TaxaGroup" ), where_clause="ELSeason LIKE 'IILE%'")


# get SGCN data
databasename <- here("_data","output","coa_bridgetest.sqlite")  # move to a file that reads in the list from the database
db <- dbConnect(SQLite(), dbname = databasename)
SQLquery <- paste("SELECT ELCODE, SCOMNAME, SNAME, USESA, SPROT, PBSSTATUS, TaxaDisplay"," FROM lu_sgcn ")
lu_sgcn <- dbGetQuery(db, statement = SQLquery)
dbDisconnect(db) # disconnect the db

# subset to fish only
lu_sgcn <- lu_sgcn[which(lu_sgcn$TaxaDisplay=="Fish"),]

# subset to fish that are not in Biotics
SGCN_bioticsCPP <- read.csv("SGCN_bioticsCPP.csv", stringsAsFactors=FALSE)
lu_sgcn1 <- lu_sgcn[which(!lu_sgcn$SNAME %in% SGCN_bioticsCPP$x),]


# read in SGCN data
fishdata <- read.csv(here("_data/input/SGCN_data/PFBC_FishDPF","UpdatedFishDataFromDoug.csv"), stringsAsFactors=FALSE)

# get rid of rows that are all NA
fishdata <- fishdata[rowSums(is.na(fishdata)) != ncol(fishdata),]
# various field cleanup
fishdata$X <- NULL
fishdata$SNAME <- paste(fishdata$genus,fishdata$species, sep=" ")
fishdata$DataSource <- "PFBC_DPF"
fishdata$DataID <- paste(fishdata$tsn,"_",fishdata$recordid,sep="")
fishdata$Taxonomic_Group <- "AF"

names(fishdata)[names(fishdata) == "common_name"] <- "SCOMNAME"
names(fishdata)[names(fishdata) == "long"] <- "lon"
names(fishdata)[names(fishdata) == "date"] <- "LASTOBS"

# replace the older taxonomy with updated names from the SWAP.  Need to do this before the ELCODE join
fishdata$SNAME[fishdata$SNAME=="Acipenser oxyrinchus"] <- "Acipenser oxyrhynchus"
fishdata$SNAME[fishdata$SNAME=="Cottus sp."] <- "Cottus sp. cf. cognatus"
fishdata$SNAME[fishdata$SNAME=="Notropis dorsalis"] <- "Hybopsis dorsalis"
fishdata$SNAME[fishdata$SNAME=="Lota sp."] <- "Lota sp. cf. lota"
fishdata$SNAME[fishdata$SNAME=="Lota sp. "] <- "Lota sp. cf. lota" # extra space after "sp."
fishdata$SNAME[fishdata$SNAME=="Notropis heterolepis"] <- "Notropis heterodon"







# add in the ELCODE
SGCNfish <- read.csv("SGCNfish.csv")
ELCODES <- SGCNfish[,c("ELCODE","Scientific_Name")]
setnames(ELCODES, old=c("Scientific_Name"),new=c("SNAME"))
levels(ELCODES$SNAME)[levels(fishdata$SNAME)=="Polyodon spathulaÂ"] <- "Polyodon spathula"
fishdata <- merge(x = fishdata, y = ELCODES, by = "SNAME")  # inner join of the above

# drops the unneeded columns. please modify the list.
keeps <- c("SNAME","SCOMNAME","Taxonomic_Group","ELCODE","DataSource","DataID","LASTOBS","Lat","Lon")
fishdata <- fishdata[keeps]

fishdata$ELSeason <- paste(fishdata$ELCODE,"-y",sep="")
fishdata$Lat <- as.numeric(as.character(fishdata$Lat))

fishdata <- fishdata[complete.cases(fishdata), ]

#create a shapefile
# based on http://neondataskills.org/R/csv-to-shapefile-R/
library(rgdal)  # for vector work; sp package should always load with rgdal. 
library (raster)   # for metadata/attributes- vectors or rasters
# note that the easting and northing columns are in columns 4 and 5
sgcn_fish <- SpatialPointsDataFrame(fishdata[,9:8],fishdata,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS  ,proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
plot(sgcn_fish,main="Pennsylvania SGCN fish points")
# write a shapefile
writeOGR(sgcn_fish, getwd(),"sgcn_fish", driver="ESRI Shapefile")






