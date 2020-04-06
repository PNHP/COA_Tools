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
# if (!requireNamespace("rmarkdown", quietly = TRUE)) install.packages("rmarkdown")
#   require(rmarkdown)

source(here::here("scripts","00_PathsAndSettings.r"))

# load the r data file
load(file=updateData)

# read in SGCN data
loadSGCN()


# assemble TREC data
TREC <- arc.open(here::here("_data","input","SGCN_data","TREC","SGCN_FromTREC.shp")) 
TREC <- arc.select(TREC) 
TREC <- arc.data2sf(TREC) 

TREC <- TREC[which(TREC$SNAME %in% sgcnlist),]




#TREC <- TREC[c("TaxaGroup","ELCODE","SNAME","SCOMNAME","DataSource","DataID","SeasonCode","OccProb","LastObs","ELSeason","useCOA")]

TREC$LastObs <- year(as.Date(TREC$date))
TREC$useCOA <- ifelse(TREC$LastObs>=cutoffyear&TREC$date!=" ", "y", "n")

TREC$SeasonCode <- ifelse(TREC$season==" ", "y", substr(TREC$season,1,1))

TREC$ELSeason <- paste(TREC$ELCODE,TREC$SeasonCode, sep="_")
TREC$DataSource <- "TREC"
TREC$OccProb <- "k"

TREC_sf <- TREC

# create a spatial layer
TREC_sf <- st_transform(TREC_sf, crs=customalbers) # reproject to custom albers
names(TREC_sf)[names(TREC_sf) == 'geom'] <- 'geometry'
st_geometry(TREC_sf) <- "geometry"
TREC_sf <- TREC_sf[final_fields]# field alignment
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_TREC"), TREC_sf, overwrite=TRUE) # write a feature class into the geodatabase
TREC_buffer_sf <- st_buffer(TREC_sf, 100) # buffer the points by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_TREC"), TREC_buffer_sf, overwrite=TRUE) # write a feature class to the gdb




# 
# library("openxlsx")
# 
# files <- list.files(path=here::here("_data","input","SGCN_data","TREC"), pattern = "\\.(xls|xlsx)$")
# files <- files[-c(1,2)]
# data_names<- gsub("[.]xlsx", "", files) 
# 
# dbo_Amphibians <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Amphibians.xlsx"), colNames=TRUE, skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Birds <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Birds.xlsx"), skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Fishes <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Fishes.xlsx"), skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Insects <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Insects.xlsx"), skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Mammals <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Mammals.xlsx"), skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Mollusks <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Mollusks.xlsx"), skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Plants <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Plants.xlsx"), skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Reptiles <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","dbo_Reptiles.xlsx"), skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Invertebrate1 <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","_TREC NHM Misc Invertebrate Database.xlsx"), sheet=1, skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Invertebrate2 <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","_TREC NHM Misc Invertebrate Database.xlsx"), sheet=2, skipEmptyRows=FALSE, rowNames=FALSE)
# dbo_Spiders <- read.xlsx(xlsxFile=here::here("_data","input","SGCN_data","TREC","_TREC NHM Spider Database.xlsx"), skipEmptyRows=TRUE, rowNames=FALSE)
# dbo_Spiders <- dbo_Spiders[,1:55]
# 
# # merge frames together
# library(gtools)
# test <- smartbind(dbo_Reptiles, dbo_Mammals)
# test <- smartbind(test, dbo_Amphibians)
# test <- smartbind(test, dbo_Birds)
# test <- smartbind(test, dbo_Mollusks)
# test <- smartbind(test, dbo_Insects)
# test <- smartbind(test, dbo_Fishes)
# test <- smartbind(test, dbo_Invertebrate1)
# test <- smartbind(test, dbo_Invertebrate2)
# test <- smartbind(test, dbo_Spiders)
# 
# testpa <- test[test$State=="PA"|test$State=="N/A",]
# testpa$Curatorial_Notes <- NULL
# testpa$Cabinet <- NULL
# testpa$NA. <- NULL
# testpa$Freezer_Dry_Number <- NULL
# testpa$Other_Property <- NULL
# testpa$Federal_Property <- NULL
# testpa$State_Forest <- NULL
# testpa$State_Park <- NULL
# testpa$PFBC_Access <- NULL
# testpa$SGL <- NULL
# testpa$Subfamily <- NULL
# testpa$Superfamily <- NULL
# testpa$Subfamily <- NULL
# testpa$Drawer <- NULL
# testpa$Lot_Number <- NULL
# testpa$Field_Number <- NULL
# testpa$Superclass <- NULL
# testpa$Subclass <-NULL
# testpa$PGC_FWS_Accession_Number <-NULL
# testpa$Collection_Method <-NULL
# testpa$Received_By <-NULL
# testpa$Collector.s.Field.Number <-NULL
# testpa$Images <- NULL
# testpa$Preservation_Method <- NULL
#   testpa$Shelf <- NULL
# testpa$Family_Common_Name <- NULL
# testpa$Reports_and_Citations <- NULL
# testpa$Collectors_Address <- NULL
# 
# write.csv(test,"compiledoutput.csv")
# 
# test1 <- testpa
# 
# sgcn <- read.csv("sgcn.csv")
# 
# library('plyr')
# library('dplyr')
# library('data.table')
# setnames(sgcn, "Scientific_Name", "SNAME")
# setnames(test1,"Species","SNAME")
# TRECdata <-  inner_join(test1,sgcn)
# 
# TRECdata$date <- ifelse(!is.na(TRECdata$Date), TRECdata$Date, TRECdata$Date_Found)
# 
# keeps <- c("TSN","SNAME","date","State","Latitude","Longitude","Taxonomic_Group","ELCODE","Common_Name")
# TRECdata1 <- TRECdata[keeps]
# 
# TaxaGrp <- read.csv("TaxaGroup.csv")
# TRECdata1 <-  join(TRECdata1,TaxaGrp)
# TRECdata1$Taxonomic_Group <- NULL
# 
# setnames(TRECdata1,"TSN","DataID")
# setnames(TRECdata1,"Common_Name","SCOMNAME")
# 
# # bird safe dates
# library(lubridate)
# TRECdata1$dayofyear <- yday(TRECdata1$date) 
# 
# birdseason <- read.csv("birdseason_new.csv") #updated filename
# birdseason <- birdseason[!is.na(birdseason$SGCN),] # drops any species that is not an SGCN 
# birdseason$Common.name <- droplevels(birdseason$Common.name)
# 
# TRECdata1$SCOMNAME <- droplevels(TRECdata1$SCOMNAME)
# 
# TRECbirds <- TRECdata1[TRECdata1$TaxaGroup=="AB",]
# TRECbirds <- TRECbirds[TRECbirds$SCOMNAME!="Piping Plover",]
# TRECbirds$SCOMNAME <- droplevels(TRECbirds$SCOMNAME)
# levels(TRECbirds$SCOMNAME)
# 
# birdlist <- unique(TRECbirds$SCOMNAME)
# #birdlist <- droplevels(birdlist[-13])
# levels(birdlist)
# 
# birdseasonclean <- birdseason[birdseason$Common.name %in% birdlist, ]
# birdseasonclean$Common.name <- droplevels(birdseasonclean$Common.name)
# levels(birdseasonclean$Common.name)
# ### assign a migration date to each ebird observation.
# for(i in 1:nrow(birdseasonclean)){
#   comname<-birdseasonclean[i,1]
#   season<-birdseasonclean[i,2]
#   startdate<-birdseasonclean[i,3]
#   enddate<-birdseasonclean[i,4]
#   TRECbirds$SeasonCode[TRECbirds$SCOMNAME==comname & TRECbirds$dayofyear>startdate & TRECbirds$dayofyear<enddate] <- substr(as.character(season), 1, 1)
# }
# 
# 
# TRECdatasansBirds <- TRECdata1[TRECdata1$TaxaGroup!="AB",]
# TRECdataFinal <- rbind.fill(TRECdatasansBirds,TRECbirds)
# TRECdataFinal <- TRECdataFinal[!is.na(TRECdataFinal$Latitude),] 
# TRECdataFinal <- TRECdataFinal[TRECdataFinal$State=="PA"|TRECdataFinal$State=="N/A",]
# TRECdataFinal$DataSource <- "TREC Museum Collection"
# 
# 
# 
# # fix missing '-' in Longitudes
# TRECdataFinal$Longitude <- ifelse(TRECdataFinal$Longitude>0, TRECdataFinal$Longitude*-1,TRECdataFinal$Longitude)
# 
# # note that the easting and northing columns are in columns 4 and 5
# SGCN_TREC <- SpatialPointsDataFrame(TRECdataFinal[,6:5],TRECdataFinal,,proj4string <- CRS("+init=epsg:4326"))   # assign a CRS  ,proj4string = utm18nCR  #https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf; the two commas in a row are important due to the slots feature
# plot(SGCN_TREC,main="Map of SGCN Locations")
# # write a shapefile
# writeOGR(SGCN_TREC, getwd(),"SGCN_FromTREC", driver="ESRI Shapefile")
