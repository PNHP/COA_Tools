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
# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN("AF")

# laod and assemble the fish data from the indivdual excel files
setwd("E:/COA_Tools/_data/input/SGCN_data/PFBC_FishDPF") #E:\COA_Tools\_data\input\SGCN_data\PFBC_FishDPF

# load the csv to dataframes  #### I don't think this is needed anymore....
#temp = list.files(pattern="*DPF.csv")
#for (i in 1:length(temp)) assign(temp[i], read.csv(temp[i]))

# join the individual fish dataframes into one
my_files <- list.files(pattern = "\\.csv$")
my_data <- lapply(my_files, function(i){read.csv(i,header=TRUE, stringsAsFactors=FALSE,colClasses=c("SCP_siteID"="character","Museum_Number"="character","N_vouchered"="character","SCP_PermitNumber"="character","N_Detected"="character","TSN"="character","HUC_8"="character","Lat"="character"))}) #,colClasses=c("SCP_siteID"="character","Date"="character","N_vouchered"="character","Museum_Number"="character","N_Detected"="character","TSN"="character","HUC_8"="character","SCP_PermitNumber"="character","lat"="numeric")

my_data <- lapply(my_data, function(x) {
  names(x)<-tolower(names(x))
  x})

#make a data frame
fishdata_master <- dplyr::bind_rows(my_data)

### extra fish data
# read in SGCN data
fishdata_extra <- read.csv(here::here("_data/input/SGCN_data/PFBC_FishDPF","UpdatedFishDataFromDoug.csv"), stringsAsFactors=FALSE)
fishdata_extra$X <- NULL

fishdata <- rbind(fishdata_master, fishdata_extra)

fishdata <- fishdata_master

# get rid of rows that are all NA
fishdata <- fishdata[rowSums(is.na(fishdata)) != ncol(fishdata),]
# various field cleanup
fishdata$X <- NULL
fishdata$SNAME <- paste(fishdata$genus,fishdata$species, sep=" ")
fishdata$DataSource <- "PFBC_DPF"
fishdata$DataID <- paste(fishdata$tsn,"_",fishdata$recordid,sep="")
fishdata$TaxaGroup <- "AF"

##names(fishdata)[names(fishdata) == "common_name"] <- "SCOMNAME"
names(fishdata)[names(fishdata) == "long"] <- "lon"

# replace the older taxonomy with updated names from the SWAP.  Need to do this before the ELCODE join
fishdata$SNAME[fishdata$SNAME=="Acipenser oxyrinchus"] <- "Acipenser oxyrhynchus"
fishdata$SNAME[fishdata$SNAME=="Cottus sp."] <- "Cottus sp. cf. cognatus"
fishdata$SNAME[fishdata$SNAME=="Notropis dorsalis"] <- "Hybopsis dorsalis"
fishdata$SNAME[fishdata$SNAME=="Lota sp."] <- "Lota sp. cf. lota"
fishdata$SNAME[fishdata$SNAME=="Lota sp. "] <- "Lota sp. cf. lota" # extra space after "sp."
fishdata$SNAME[fishdata$SNAME=="Notropis heterolepis"] <- "Notropis heterodon"
fishdata$SNAME[fishdata$SNAME=="Chaenobryttus gulosus"] <- "Lepomis gulosus"

# add in the ELCODE
###SGCNfish <- read.csv("SGCNfish.csv")
ELCODES <- lu_sgcn[,c("ELCODE","SNAME","SCOMNAME")]
fishdata <- merge(x=fishdata, y=ELCODES, by="SNAME")  # inner join of the above.  this elimanates some non matches

# calculate year and assign its use to the COA tool based on which side of the date it ends up on
fishdata$year <- year(parse_date_time(fishdata$date, orders=c("ymd","mdy")))
fishdata$year[fishdata$year==2104] <- 2014
fishdata$LastObs <- fishdata$year
fishdata$useCOA <- NA
fishdata$useCOA <- with(fishdata, ifelse(fishdata$year>=cutoffyearL, "y", "n"))

#add the occurence probability
fishdata$OccProb = with(fishdata, ifelse(year>=cutoffyearK , "k", ifelse(year<cutoffyearK & year>=cutoffyearL, "l", "u")))



# drops the unneeded columns. please modify the list.
fishdata <- fishdata[c("SNAME","SCOMNAME","TaxaGroup","ELCODE","DataSource","DataID","LastObs","lat","lon","OccProb","useCOA")]

fishdata$SeasonCode <- "y"
fishdata$ELSeason <- paste(fishdata$ELCODE,"_y",sep="")
fishdata$lat <- as.numeric(as.character(fishdata$lat))

fishdata <- fishdata[complete.cases(fishdata), ]


setwd(here::here())

# subset to fish that are not in Biotics
##SGCN_bioticsCPP <- read.csv("SGCN_bioticsCPP.csv", stringsAsFactors=FALSE)
##fishdata <- fishdata[which(!fishdata$SNAME %in% SGCN_bioticsCPP$x),]


# create a spatial layer
fishdata_sf <- st_as_sf(fishdata, coords=c("lon","lat"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
fishdata_sf <- st_transform(fishdata_sf, crs=customalbers) # reproject to the custom albers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_PFBC_DPF"), fishdata_sf, overwrite=TRUE) # write a feature class into the geodatabase
fishdata_buffer <- st_buffer(fishdata_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PFBC_DPF"), fishdata_buffer, overwrite=TRUE) # write a feature class into the geodatabase








