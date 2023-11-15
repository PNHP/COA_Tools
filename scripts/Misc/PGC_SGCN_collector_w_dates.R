# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
require(lubridate)
if (!requireNamespace("reshape", quietly = TRUE)) install.packages("reshape")
require(reshape)
if (!requireNamespace("plyr", quietly = TRUE)) install.packages("plyr")
require(plyr)
if (!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr")
require(stringr)
if (!requireNamespace("auk", quietly = TRUE)) install.packages("auk")
require(auk)

# load the arcgis license
arc.check_product() 

# update name
updateName <- "PGC_SGCN_20230913"
updateNameprev <- "_update2023q2"

# create a directory for this update unless it already exists
ifelse(!dir.exists(here::here("_data","output",updateName)), dir.create(here::here("_data","output",updateName)), FALSE)

# rdata  file
updateData <- here::here("_data","output",updateName,paste(updateName, "RData", sep="."))

# output database name
databasename <- here::here("_data","output",updateName,"coa_bridgetest.sqlite")

# paths to biotics shapefiles
biotics_path <- "W:/Heritage/Heritage_Data/Biotics_datasets.gdb"
bioticsFeatServ_path <- "https://maps.waterlandlife.org/arcgis/rest/services/PNHP/Biotics/FeatureServer"
biotics_crosswalk <- here::here("_data","input","crosswalk_BioticsSWAP.csv") # note that nine species are not in Biotics at all

# paths to to server path to access cpp shapefiles, we connect to the cpp file in '02_SGCNcollector_BioticsCPP.r'
serverPath <- paste("C:/Users/",Sys.getenv("USERNAME"),"/AppData/Roaming/ESRI/ArcGISPro/Favorites/PNHP_Working_PGH-gis0.sde/",sep="")

# cutoff year for records
cutoffyear <- as.integer(substr(updateName, 8, 11)) - 25  # keep data that's only within 25 years
cutoffyearK <- cutoffyear # keep data that's only within 25 years for known records
cutoffyearL <- 1980  # 

# final fields for arcgis
final_fields <- c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","DataSource","DataID","OccProb","Date","LastObs","useCOA","TaxaGroup", "geometry") 

# custom albers projection
customalbers <- "+proj=aea +lat_1=40 +lat_2=42 +lat_0=39 +lon_0=-78 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs "

# function to load SGCN species list
loadSGCN <- function(taxagroup) {
  if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)
  db <- dbConnect(SQLite(), dbname = databasename)
  SQLquery <- paste("SELECT ELCODE, SNAME, SCOMNAME, TaxaGroup, SeasonCode, ELSeason"," FROM lu_sgcn ")
  lu_sgcn <- dbGetQuery(db, statement = SQLquery)
  if(missing(taxagroup)){
    lu_sgcn <<- lu_sgcn
    sgcnlist <<- unique(lu_sgcn$SNAME)
  } else {
    lu_sgcn <<- lu_sgcn[which(lu_sgcn$TaxaGroup==taxagroup),] # limit by taxagroup code
    sgcnlist <<- unique(lu_sgcn$SNAME)
  }
  dbDisconnect(db) # disconnect the db
}



# read in SGCN data
loadSGCN("AB")
sgcnlist <- unique(lu_sgcn$SNAME)

# create a list with the changes for the ebird taxonomy
sgcnlistcrosswalk <- sgcnlist
sgcnlistcrosswalk[sgcnlistcrosswalk=="Anas discors"] <- "Spatula discors"
sgcnlistcrosswalk[sgcnlistcrosswalk=="Oreothlypis ruficapilla"] <- "Leiothlypis ruficapilla"
sgcnlistcrosswalk[sgcnlistcrosswalk=="Ammodramus henslowii"] <- "Centronyx henslowii"

# set the auk path
auk_set_ebd_path(here::here("_data","input","SGCN_data","eBird"), overwrite=TRUE)

# eBird data ##############################################
#get a list of what's in the directory
fileList <- dir(path=here::here("_data","input","SGCN_data","eBird"), pattern = ".txt$")
fileList
#look at the output and choose which text file you want to run. enter its location in the list (first = 1, second = 2, etc)

n <- 8

# # read in the file using auk
## Note: it's good to run each of these in turn, as it can fail if you do all of them at once.
f_in <- here::here("_data","input","SGCN_data","eBird",fileList[[n]]) #"C:/Users/dyeany/Documents/R/eBird/ebd.txt"
f_out <- "ebd_filtered_SGCN.txt"
ebd <- auk_ebd(f_in)
ebd_filters <- auk_species(ebd, species=sgcnlistcrosswalk, taxonomy_version=2022)
ebd_filtered <- auk_filter(ebd_filters, file=f_out, overwrite=TRUE)
ebd_df <- read_ebd(ebd_filtered)

ebd_df_backup <- ebd_df

# change the species we had to change for the 2020 ebird taxomon back to our SGCN names
ebd_df[which(ebd_df$scientific_name=="Spatula discors"),]$scientific_name <- "Anas discors"
ebd_df[which(ebd_df$scientific_name=="Anas discors"),]
ebd_df[which(ebd_df$scientific_name=="Leiothlypis ruficapilla"),]$scientific_name <- "Oreothlypis ruficapilla" 
ebd_df[which(ebd_df$scientific_name=="Oreothlypis ruficapilla"),] 
ebd_df[which(ebd_df$scientific_name=="Centronyx henslowii"),]$scientific_name <- "Ammodramus henslowii" 
ebd_df[which(ebd_df$scientific_name=="Ammodramus henslowii"),]

# gets rid of the bad data lines
ebd_df$latitude <- as.numeric(as.character(ebd_df$latitude))
ebd_df$longitude <- as.numeric(as.character(ebd_df$longitude))
ebd_df <- ebd_df[!is.na(as.numeric(as.character(ebd_df$latitude))),]
ebd_df <- ebd_df[!is.na(as.numeric(as.character(ebd_df$longitude))),]

### Filter out unsuitable protocols (e.g. Traveling, etc.) and keep only suitable protocols (e.g. Stationary, etc.)
ebd_df <- ebd_df[which(ebd_df$locality_type=="P"|ebd_df$locality_type=="H"),]
ebd_df <- ebd_df[which(ebd_df$protocol_type=="Banding"|
                         ebd_df$protocol_type=="Stationary"|
                         ebd_df$protocol_type=="eBird - Stationary Count"|
                         ebd_df$protocol_type=="Incidental"|
                         ebd_df$protocol_type=="eBird - Casual Observation"|
                         ebd_df$protocol_type=="eBird--Rusty Blackbird Blitz"|
                         ebd_df$protocol_type=="Rusty Blackbird Spring Migration Blitz"|
                         ebd_df$protocol_type=="International Shorebird Survey (ISS)"|
                         ebd_df$protocol_type=="eBird--Heron Stationary Count"|
                         ebd_df$protocol_type=="Random"|
                         ebd_df$protocol_type=="eBird Random Location Count"|
                         ebd_df$protocol_type=="Historical"),]
### Next filter out records by Focal Season for each SGCN using day-of-year
# library(lubridate)
ebd_df$dayofyear <- yday(ebd_df$observation_date) ## Add day of year to eBird dataset based on the observation date.
birdseason <- read.csv(here::here("scripts","SGCN_DataCollection","lu_eBird_birdseason.csv"), colClasses = c("character","character","integer","integer"),stringsAsFactors=FALSE)

### assign a migration date to each ebird observation.
ebd_df$season <- NA
for(i in 1:nrow(birdseason)){
  comname<-birdseason[i,1]
  season<-birdseason[i,2]
  startdate<-birdseason[i,3]
  enddate<-birdseason[i,4]
  ebd_df$season[ebd_df$common_name==comname & ebd_df$dayofyear>startdate & ebd_df$dayofyear<enddate] <- as.character(season)
}

# drops any species that has an NA due to be outside the season dates
ebd_df <- ebd_df[!is.na(ebd_df$season),]

# add additonal fields 
ebd_df$DataSource <- "eBird"
ebd_df$OccProb <- "k"
names(ebd_df)[names(ebd_df)=='scientific_name'] <- 'SNAME'
names(ebd_df)[names(ebd_df)=='common_name'] <- 'SCOMNAME'
names(ebd_df)[names(ebd_df)=='global_unique_identifier'] <- 'DataID'
names(ebd_df)[names(ebd_df)=='lon'] <- 'longitude'
names(ebd_df)[names(ebd_df)=='lat'] <- 'latitude'
names(ebd_df)[names(ebd_df)=='observation_date'] <- 'Date'
ebd_df$LastObs <- year(parse_date_time(ebd_df$Date, orders=c("ymd","mdy")))
ebd_df <- ebd_df[which(!is.na(ebd_df$Date)),] # deletes one without a date

ebd_df$useCOA <- NA
ebd_df$useCOA <- with(ebd_df, ifelse(ebd_df$LastObs >= cutoffyear, "y", "n"))

# drops the unneeded columns. 
ebd_df <- ebd_df[c("SNAME","DataID","longitude","latitude","Date","useCOA","DataSource","OccProb","season")]

ebd_df$season <- substr(ebd_df$season, 1, 1)

#add in the SGCN fields
ebd_df <- merge(ebd_df, lu_sgcn, by="SNAME", all.x=TRUE)

ebd_df$ELSeason <- paste(ebd_df$ELCODE, ebd_df$season, sep="_")

# create a list of ebird SGCN elseason codes
sgcnfinal <- lu_sgcn$ELSeason

# drop species that we don't want to use eBird data for as
drop_from_eBird <- c("ABNKC10010_b", "ABNNM10020_b", "ABNGA11010_b", "ABNNM08070_b", "ABNGA04040_b", "ABNKC12060_b", "ABNKC01010_b", "ABNKD06070_b", "ABNNB03070_b", "ABNSB13040_b", "ABNGA13010_b")
sgcnfinal <- sgcnfinal[which(!sgcnfinal %in% drop_from_eBird) ] 

# create the final layer
ebd_df1 <- ebd_df[which(ebd_df$ELSeason %in% sgcnfinal),]
# field alignment
names(ebd_df1)[names(ebd_df1)=='season'] <- 'SeasonCode'

# this 
write.csv(ebd_df1, "eBirdBACKUPOct.csv", row.names=FALSE) 
ebd_df1 <- read.csv("eBirdBACKUPOct.csv", stringsAsFactors = FALSE)

# create a spatial layer
ebird_sf <- st_as_sf(ebd_df1, coords=c("longitude","latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
ebird_sf <- st_transform(ebird_sf, crs=customalbers) # reproject to the custom albers
#ebird_sf <- st_transform(ebird_sf, crs=4326) # reproject to the custom albers
ebird_sf <- ebird_sf[final_fields]
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_eBird"), ebird_sf, overwrite=TRUE) # write a feature class into the geodatabase
ebird_buffer <- st_buffer(ebird_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_eBird"), ebird_buffer, overwrite=TRUE) # write a feature class into the geodatabase

# delete unneeded stuff
rm(birdseason, lu_sgcn, ebd, ebd_df_backup, ebd_filtered, ebd_filters)




















































################################################################################
################################################################################
################################################################################
################################################################################

# Load SGCN data from Biotics, CPPs, and ER polygons, and create centroid layer
loadSGCN()

# load the Biotics Crosswalk
biotics_crosswalk <- read.csv(biotics_crosswalk, stringsAsFactors=FALSE)
lu_sgcnBiotics <- biotics_crosswalk$SNAME
lu_sgcnBioticsELCODE <- biotics_crosswalk$ELCODE

########################################################################################
# load in ER Polygons
# CHANGE THIS EVERY TIME NEW ER DATASET IS AVAILABLE
# make sure ER dataset is in custom albers projection
er_layer <- "PA_ERPOLY_ALL_20220707_proj"
er_gdb <- "W:/Heritage/Heritage_Data/Environmental_Review/_ER_POLYS/ER_Polys.gdb"
er_poly <- arc.open(paste(er_gdb,er_layer, sep="/"))
er_poly <- arc.select(er_poly, c("SNAME","EOID","BUF_TYPE"), where_clause="BUF_TYPE ='I' AND EOID <> 0") 
er_sf <- arc.data2sf(er_poly)
er_sf <- er_sf[which(er_sf$SNAME %in% unique(lu_sgcn$SNAME)),]
names(er_sf)[names(er_sf) == 'EOID'] <- 'EO_ID'
# clean up
rm(er_poly)

########################################################################################
# load in Conservation Planning Polygons

# use this if you are not within the WPC network---caution, it may not be displaying all the records
#cpps <- "https://maps.waterlandlife.org/arcgis/rest/services/PNHP/CPP/FeatureServer/0"
#cppCore <- arc.open(cpps)
# use this to hit the enterprise gdb server
cppCore <- arc.open(paste(serverPath,"PNHP.DBO.CPP_Core", sep=""))

#cppCore <- arc.open(cpps)
cppCore <- arc.select(cppCore, c("SNAME","EO_ID","Status"), where_clause="Status ='c' OR Status ='r'") 
cppCore_sf <- arc.data2sf(cppCore)
#### cppCore_sf <- cppCore_sf[which(cppCore_sf$SNAME %in% unique(lu_sgcn$SNAME)),] # bad SGCN names
cppCore_sf <- cppCore_sf[which(cppCore_sf$SNAME %in% unique(lu_sgcn$SNAME)),]

# clean up
rm(cppCore)

########################################################################################
# load in Biotics Source Features

# create a vector of field names for the arc.select statement below
lu_srcfeature_names <- c("SF_ID","EO_ID","ELCODE","SNAME","SCOMNAME","ELSUBID","LU_TYPE","LU_DIST","LU_UNIT","USE_CLASS","EST_RA")
## arc.check_portal()  # may need to update bridge to most recent version if it crashes: https://github.com/R-ArcGIS/r-bridge/issues/46
# read in source points 
##srcfeat_points <- arc.open(paste0(bioticsFeatServ_path,"/2"))  # 2 is the number of the EO points 
srcfeat_points <- arc.open(paste(biotics_path,"eo_sourcept",sep="/")) 
srcfeat_points <- arc.select(srcfeat_points, lu_srcfeature_names)
srcfeat_points <- arc.data2sf(srcfeat_points)
srcfeat_points_SGCN <- srcfeat_points[which(srcfeat_points$ELCODE %in% lu_sgcn$ELCODE),] # subset to SGCN
srcfeat_points_SGCN <- srcfeat_points_SGCN[which(!is.na(srcfeat_points_SGCN$EO_ID)),] # drop independent source features
# read in source lines 
## srcfeat_lines <- arc.open(paste0(bioticsFeatServ_path,"/3")) # 3 is the number of the EO lines 
srcfeat_lines <- arc.open(paste(biotics_path,"eo_sourceln",sep="/")) 
srcfeat_lines <- arc.select(srcfeat_lines, lu_srcfeature_names)
srcfeat_lines <- arc.data2sf(srcfeat_lines)
srcfeat_lines_SGCN <- srcfeat_lines[which(srcfeat_lines$ELCODE %in% lu_sgcn$ELCODE),] # subset to SGCN
srcfeat_lines_SGCN <- srcfeat_lines_SGCN[which(!is.na(srcfeat_lines_SGCN$EO_ID)),] # drop independent source features
# read in source polygons 
##srcfeat_polygons <- arc.open(paste0(bioticsFeatServ_path,"/4"))  # 4 is the number of the EO polys 
srcfeat_polygons <- arc.open(paste(biotics_path,"eo_sourcepy",sep="/")) 
options(useFancyQuotes = FALSE)
ex <- paste("ELCODE IN (", paste(sQuote(lu_sgcn$ELCODE), sep=" ", collapse=", "),")", sep="")
srcfeat_polygons <- arc.select(srcfeat_polygons, lu_srcfeature_names, where_clause=ex )
srcfeat_polygons <- arc.data2sf(srcfeat_polygons)
srcfeat_polygons_SGCN <- srcfeat_polygons[which(srcfeat_polygons$ELCODE %in% lu_sgcn$ELCODE),] # subset to SGCN
srcfeat_polygons_SGCN <- srcfeat_polygons_SGCN[which(!is.na(srcfeat_polygons_SGCN$EO_ID)),] # drop independent source features

# clean up
rm(srcfeat_points, srcfeat_lines, srcfeat_polygons, lu_srcfeature_names)

# get a combined list of EO_IDs from the three source feature layers above
lu_EOID <- unique(c(srcfeat_points_SGCN$EO_ID, srcfeat_lines_SGCN$EO_ID, srcfeat_polygons_SGCN$EO_ID))

# read in the point reps layer to get last obs dates and such
## ptreps <- arc.open(paste0(bioticsFeatServ_path,"/0"))  # 0 is the pt reps
ptreps <- arc.open(paste(biotics_path,"eo_ptreps",sep="/"))  
ptreps <- arc.select(ptreps, c("EO_ID","EST_RA","PREC_BCD","LASTOBS_YR")) # , lu_srcfeature_names
ptreps_SGCN <- ptreps[which(ptreps$EO_ID %in% lu_EOID),]
ptreps_SGCN <- as.data.frame(ptreps_SGCN) # drop the spatial part

# convert to simple features
srcf_pt_sf <- srcfeat_points_SGCN
srcf_ln_sf <- srcfeat_lines_SGCN
srcf_py_sf <- srcfeat_polygons_SGCN

# clean up
rm(ptreps, srcfeat_points_SGCN, srcfeat_lines_SGCN, srcfeat_polygons_SGCN)

# add in the lastobs date to the source features
srcf_pt_sf <- merge(srcf_pt_sf,ptreps_SGCN[c("EO_ID","LASTOBS_YR")],by="EO_ID", all.x=TRUE)
srcf_pt_sf$LASTOBS_YR <- as.numeric(srcf_pt_sf$LASTOBS_YR)
srcf_ln_sf <- merge(srcf_ln_sf,ptreps_SGCN[c("EO_ID","LASTOBS_YR")],by="EO_ID", all.x=TRUE)
srcf_ln_sf$LASTOBS_YR <- as.numeric(srcf_ln_sf$LASTOBS_YR)
srcf_py_sf <- merge(srcf_py_sf,ptreps_SGCN[c("EO_ID","LASTOBS_YR")],by="EO_ID", all.x=TRUE)
srcf_py_sf$LASTOBS_YR <- as.numeric(srcf_py_sf$LASTOBS_YR)

# clean up
rm(ptreps_SGCN)

# check buffer distances and change to meters if they are not in meters
unitconv <- data.frame(unit=c("MILES","METERS",NA,"FEET"),multiplier=c(1609.34,1,NA,0.304799))
srcf_pt_sf <- merge(srcf_pt_sf, unitconv, by.x="LU_UNIT", by.y="unit")
srcf_pt_sf$LU_DIST <- srcf_pt_sf$LU_DIST * srcf_pt_sf$multiplier
srcf_pt_sf$multiplier <- NULL
srcf_ln_sf <- merge(srcf_ln_sf, unitconv, by.x="LU_UNIT", by.y="unit")
srcf_ln_sf$LU_DIST <- srcf_ln_sf$LU_DIST * srcf_ln_sf$multiplier
srcf_ln_sf$multiplier <- NULL
srcf_py_sf <- merge(srcf_py_sf, unitconv, by.x="LU_UNIT", by.y="unit")
srcf_py_sf$LU_DIST <- srcf_py_sf$LU_DIST * srcf_py_sf$multiplier
srcf_py_sf$multiplier <- NULL
# add a buffer distance field (in meters)
srcf_pt_sf$buffer <- ifelse(!is.na(srcf_pt_sf$LU_DIST), srcf_pt_sf$LU_DIST, 50)
srcf_ln_sf$buffer <- ifelse(!is.na(srcf_ln_sf$LU_DIST), srcf_ln_sf$LU_DIST, 50)
srcf_py_sf$buffer <- ifelse(!is.na(srcf_py_sf$LU_DIST), srcf_py_sf$LU_DIST, 50)
# clean up
rm(unitconv)

# rename or develop the SGCN_database fields
srcf_pt_sf$DataID <- srcf_pt_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_pt_sf$DataSource <- "PNHP Biotics"
srcf_pt_sf$OccProb <- "k"
srcf_pt_sf$LastObs <- srcf_pt_sf$LASTOBS_YR
srcf_pt_sf$useCOA <- NA
### Do this for the lines as well
srcf_ln_sf$DataID <- srcf_ln_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_ln_sf$DataSource <- "PNHP Biotics"
srcf_ln_sf$OccProb <- "k"
srcf_ln_sf$LastObs <- srcf_ln_sf$LASTOBS_YR
srcf_ln_sf$useCOA <- NA
### Do this for the polygons as well
srcf_py_sf$DataID <- srcf_py_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_py_sf$DataSource <- "PNHP Biotics"
srcf_py_sf$OccProb <- "k"
srcf_py_sf$LastObs <- srcf_py_sf$LASTOBS_YR
srcf_py_sf$useCOA <- NA

# set up the Use classes as it relates to season
lu_UseClass <- data.frame("USE_CLASS"=c("Undetermined","Not applicable","Hibernaculum","Breeding","Nonbreeding","Maternity colony","Bachelor colony","Freshwater"),"SeasonCode"=c("y","y","w","b","y","b","b","y"), stringsAsFactors=FALSE)

srcf_pt_sf1 <- merge(srcf_pt_sf,lu_UseClass, by="USE_CLASS", all.x=TRUE)
srcf_ln_sf1 <- merge(srcf_ln_sf,lu_UseClass, by="USE_CLASS", all.x=TRUE)
srcf_py_sf1 <- merge(srcf_py_sf,lu_UseClass, by="USE_CLASS", all.x=TRUE)

# clean up
rm(srcf_pt_sf, srcf_ln_sf, srcf_py_sf, lu_UseClass)

# calculate the buffers
srcf_pt_sf1buf <- st_buffer(srcf_pt_sf1, dist=srcf_pt_sf1$buffer)   
srcf_ln_sf1buf <- st_buffer(srcf_ln_sf1, dist=srcf_ln_sf1$buffer)
srcf_py_sf1buf <- st_buffer(srcf_py_sf1, dist=srcf_py_sf1$buffer)

# clean up
rm(srcf_pt_sf1,srcf_ln_sf1,srcf_py_sf1)

# merge into one
srcf_combined <- rbind(srcf_pt_sf1buf,srcf_ln_sf1buf,srcf_py_sf1buf)

# mark for coa use if lastobs > cutoffyearL and buffer is < 1000m
srcf_combined$useCOA <- with(srcf_combined, ifelse(srcf_combined$LastObs>=cutoffyearL & srcf_combined$buffer<1000, "y", "n"))
# add the occurrence probability
srcf_combined$useCOA <- with(srcf_combined, ifelse(srcf_combined$LastObs>=cutoffyearL & srcf_combined$buffer<1000, "y", "n"))
#add the occurrence probability
srcf_combined$OccProb = with(srcf_combined, ifelse(LastObs>=cutoffyearK , "k", ifelse(LastObs<cutoffyearK & LastObs>=cutoffyearL, "l", "u")))


# replace bad season codes
sf_y2b <- c("Circus hudsonius","Cistothorus stellaris","Podilymbus podiceps","Botaurus lentiginosus","Ixobrychus exilis","Ardea alba","Nycticorax nycticorax","Nyctanassa violacea","Anas crecca","Anas rubripes","Anas discors","Pandion haliaetus","Haliaeetus leucocephalus","Circus cyaneus","Accipiter striatus","Accipiter gentilis","Buteo platypterus","Falco sparverius","Falco peregrinus","Bonasa umbellus","Rallus elegans","Rallus limicola","Porzana carolina","Gallinula galeata","Fulica americana","Charadrius melodus","Actitis macularius","Bartramia longicauda","Gallinago delicata","Scolopax minor","Sterna hirundo","Chlidonias niger","Tyto alba","Asio otus","Asio flammeus","Aegolius acadicus","Chordeiles minor","Antrostomus vociferus","Chaetura pelagica","Melanerpes erythrocephalus","Contopus cooperi","Empidonax flaviventris","Empidonax traillii","Progne subis","Riparia riparia","Certhia americana","Troglodytes hiemalis","Cistothorus platensis","Cistothorus palustris","Catharus ustulatus","Hylocichla mustelina","Dumetella carolinensis","Lanius ludovicianus","Vermivora cyanoptera","Vermivora chrysoptera","Oreothlypis ruficapilla","Setophaga caerulescens","Setophaga virens","Setophaga discolor","Setophaga striata","Setophaga cerulea","Mniotilta varia","Protonotaria citrea","Parkesia noveboracensis","Parkesia motacilla","Geothlypis formosa","Cardellina canadensis","Icteria virens","Piranga rubra","Piranga olivacea","Spiza americana","Spizella pusilla","Pooecetes gramineus","Passerculus sandwichensis","Ammodramus savannarum","Ammodramus henslowii","Zonotrichia albicollis","Dolichonyx oryzivorus","Sturnella magna","Loxia curvirostra","Spinus pinus","Lanius ludovicianus","Lanius ludovicianus migrans","Lasionycteris noctivagans")  
srcf_combined[which(srcf_combined$SNAME %in% sf_y2b),]$SeasonCode <- "b"
sf_b2y <- c("Myotis leibii","Myotis septentrionalis","Sceloporus undulatus")
srcf_combined[which(srcf_combined$SNAME %in% sf_b2y),]$SeasonCode <- "y"
sf_b2w <- c("Perimyotis subflavus")
srcf_combined[which(srcf_combined$SNAME %in% sf_b2w),]$SeasonCode <- "w"
sf_w2y <- c("Lithobates pipiens","Lithobates sphenocephalus utricularius","Plestiodon anthracinus anthracinus","Virginia valeriae pulchra")
srcf_combined[which(srcf_combined$SNAME %in% sf_b2y),]$SeasonCode <- "y"


srcf_combined$ELSeason <- paste(srcf_combined$ELCODE,srcf_combined$SeasonCode,sep="_")

# clean up
rm(srcf_pt_sf1buf,srcf_ln_sf1buf,srcf_py_sf1buf)

# remove the source features for which CPPs and ER polygons have been created
final_srcf_combined <- srcf_combined[which(!srcf_combined$EO_ID %in% cppCore_sf$EO_ID & !srcf_combined$EO_ID %in% er_sf$EOID),]

# old - delete after above ER code is implemented successfully
#final_srcf_combined <- srcf_combined[which(!srcf_combined$EO_ID %in% cppCore_sf$EO_ID),]

# remove the cpp polygons for which there are ER polygons
cppCore_sf <- cppCore_sf[which(!cppCore_sf$EO_ID %in% er_sf$EO_ID),]

# get attributes for the CPPs
att_for_cpp <- srcf_combined[which(srcf_combined$EO_ID %in% cppCore_sf$EO_ID),] 

# replace bad season codes
cpp_y2b <- c("Circus hudsonius","Cistothorus stellaris","Podilymbus podiceps","Botaurus lentiginosus","Ixobrychus exilis","Ardea alba","Nycticorax nycticorax","Nyctanassa violacea","Anas crecca","Anas rubripes","Anas discors","Pandion haliaetus","Haliaeetus leucocephalus","Circus cyaneus","Accipiter striatus","Accipiter gentilis","Buteo platypterus","Falco sparverius","Falco peregrinus","Bonasa umbellus","Rallus elegans","Rallus limicola","Porzana carolina","Gallinula galeata","Fulica americana","Charadrius melodus","Actitis macularius","Bartramia longicauda","Gallinago delicata","Scolopax minor","Sterna hirundo","Chlidonias niger","Tyto alba","Asio otus","Asio flammeus","Aegolius acadicus","Chordeiles minor","Antrostomus vociferus","Chaetura pelagica","Melanerpes erythrocephalus","Contopus cooperi","Empidonax flaviventris","Empidonax traillii","Progne subis","Riparia riparia","Certhia americana","Troglodytes hiemalis","Cistothorus platensis","Cistothorus palustris","Catharus ustulatus","Hylocichla mustelina","Dumetella carolinensis","Lanius ludovicianus","Vermivora cyanoptera","Vermivora chrysoptera","Oreothlypis ruficapilla","Setophaga caerulescens","Setophaga virens","Setophaga discolor","Setophaga striata","Setophaga cerulea","Mniotilta varia","Protonotaria citrea","Parkesia noveboracensis","Parkesia motacilla","Geothlypis formosa","Cardellina canadensis","Icteria virens","Piranga rubra","Piranga olivacea","Spiza americana","Spizella pusilla","Pooecetes gramineus","Passerculus sandwichensis","Ammodramus savannarum","Ammodramus henslowii","Zonotrichia albicollis","Dolichonyx oryzivorus","Sturnella magna","Loxia curvirostra","Spinus pinus","Lanius ludovicianus","Lanius ludovicianus migrans","Lasionycteris noctivagans")       
att_for_cpp[which(att_for_cpp$SNAME %in% cpp_y2b),]$SeasonCode <- "b"
cpp_b2y <- c("Lithobates pipiens","Lithobates sphenocephalus utricularius","Plestiodon anthracinus anthracinus","Sorex palustris albibarbis","Virginia pulchra","Myotis leibii","Myotis septentrionalis","Sceloporus undulatus")
att_for_cpp[which(att_for_cpp$SNAME %in% cpp_b2y),]$SeasonCode <- "y"
cpp_b2w <- c("Perimyotis subflavus")
att_for_cpp[which(att_for_cpp$SNAME %in% cpp_b2y),]$SeasonCode <- "w"
cpp_w2y <- c("Lithobates pipiens","Lithobates sphenocephalus utricularius","Plestiodon anthracinus anthracinus","Virginia valeriae pulchra")
att_for_cpp[which(att_for_cpp$SNAME %in% cpp_b2y),]$SeasonCode <- "y"
att_for_cpp$ELSeason <- paste(att_for_cpp$ELCODE, att_for_cpp$SeasonCode,sep="_")

# clean up attributes to prep to join to the CPPs
st_geometry(att_for_cpp) <- NULL
att_for_cpp$SF_ID <- NULL
att_for_cpp$SNAME <- NULL
att_for_cpp$LU_DIST <- NULL
att_for_cpp$buffer <- NULL
att_for_cpp$USE_CLASS <- NULL
att_for_cpp$LU_UNIT <- NULL
att_for_cpp$LU_TYPE <- NULL
att_for_cpp$EST_RA <-NULL

att_for_cpp <- unique(att_for_cpp)

cppCore_sf_final <- merge(cppCore_sf, att_for_cpp, by="EO_ID", all.x=TRUE)
cppCore_sf_final <- cppCore_sf_final[which(!is.na(cppCore_sf_final$LastObs)),]

# get attributes for the ER polys
att_for_er <- srcf_combined[which(srcf_combined$EO_ID %in% er_sf$EO_ID),] 

# replace bad season codes
er_y2b <- c("Circus hudsonius","Cistothorus stellaris","Podilymbus podiceps","Botaurus lentiginosus","Ixobrychus exilis","Ardea alba","Nycticorax nycticorax","Nyctanassa violacea","Anas crecca","Anas rubripes","Anas discors","Pandion haliaetus","Haliaeetus leucocephalus","Circus cyaneus","Accipiter striatus","Accipiter gentilis","Buteo platypterus","Falco sparverius","Falco peregrinus","Bonasa umbellus","Rallus elegans","Rallus limicola","Porzana carolina","Gallinula galeata","Fulica americana","Charadrius melodus","Actitis macularius","Bartramia longicauda","Gallinago delicata","Scolopax minor","Sterna hirundo","Chlidonias niger","Tyto alba","Asio otus","Asio flammeus","Aegolius acadicus","Chordeiles minor","Antrostomus vociferus","Chaetura pelagica","Melanerpes erythrocephalus","Contopus cooperi","Empidonax flaviventris","Empidonax traillii","Progne subis","Riparia riparia","Certhia americana","Troglodytes hiemalis","Cistothorus platensis","Cistothorus palustris","Catharus ustulatus","Hylocichla mustelina","Dumetella carolinensis","Lanius ludovicianus","Vermivora cyanoptera","Vermivora chrysoptera","Oreothlypis ruficapilla","Setophaga caerulescens","Setophaga virens","Setophaga discolor","Setophaga striata","Setophaga cerulea","Mniotilta varia","Protonotaria citrea","Parkesia noveboracensis","Parkesia motacilla","Geothlypis formosa","Cardellina canadensis","Icteria virens","Piranga rubra","Piranga olivacea","Spiza americana","Spizella pusilla","Pooecetes gramineus","Passerculus sandwichensis","Ammodramus savannarum","Ammodramus henslowii","Zonotrichia albicollis","Dolichonyx oryzivorus","Sturnella magna","Loxia curvirostra","Spinus pinus","Lanius ludovicianus","Lanius ludovicianus migrans","Lasionycteris noctivagans")       
att_for_er[which(att_for_er$SNAME %in% er_y2b),]$SeasonCode <- "b"
er_b2y <- c("Lithobates pipiens","Lithobates sphenocephalus utricularius","Plestiodon anthracinus anthracinus","Sorex palustris albibarbis","Virginia pulchra","Myotis leibii","Myotis septentrionalis","Sceloporus undulatus")
att_for_er[which(att_for_er$SNAME %in% er_b2y),]$SeasonCode <- "y"
er_b2w <- c("Perimyotis subflavus")
att_for_er[which(att_for_er$SNAME %in% er_b2y),]$SeasonCode <- "w"
er_w2y <- c("Lithobates pipiens","Lithobates sphenocephalus utricularius","Plestiodon anthracinus anthracinus","Virginia valeriae pulchra")
att_for_er[which(att_for_er$SNAME %in% er_b2y),]$SeasonCode <- "y"

att_for_er$ELSeason <- paste(att_for_er$ELCODE, att_for_er$SeasonCode,sep="_")

# clean up attributes to prep to join to the CPPs
st_geometry(att_for_er) <- NULL
att_for_er$SF_ID <- NULL
att_for_er$SNAME <- NULL
att_for_er$LU_DIST <- NULL
att_for_er$buffer <- NULL
att_for_er$USE_CLASS <- NULL
att_for_er$LU_UNIT <- NULL
att_for_er$LU_TYPE <- NULL
att_for_er$EST_RA <-NULL

att_for_er <- unique(att_for_er)

er_sf_final <- merge(er_sf, att_for_er, by.x="EO_ID", all.x=TRUE)
er_sf_final <- er_sf_final[which(!is.na(er_sf_final$LastObs)),]

# clean up
rm(srcf_combined)

# replace the ET names with those from the SWAP
cppCore_sf_final1 <- merge(cppCore_sf_final, biotics_crosswalk[c("SNAME","SGCN_NAME")], by="SNAME")
cppCore_sf_final1$SNAME <- cppCore_sf_final1$SGCN_NAME
cppCore_sf_final1$SGCN_NAME <- NULL
final_cppCore_sf <- cppCore_sf_final1
rm(cppCore_sf_final1)

final_srcf_combined1 <- merge(final_srcf_combined, biotics_crosswalk[c("SNAME","SGCN_NAME")], by="SNAME")
final_srcf_combined1$SNAME <- final_srcf_combined1$SGCN_NAME
final_srcf_combined1$SGCN_NAME <- NULL
final_srcf_combined <- final_srcf_combined1
rm(final_srcf_combined1)

er_sf_final1 <- merge(er_sf_final, biotics_crosswalk[c("SNAME","SGCN_NAME")], by="SNAME")
er_sf_final1$SNAME <- er_sf_final1$SGCN_NAME
er_sf_final1$SGCN_NAME <- NULL
final_er_sf <- er_sf_final1
rm(er_sf_final1)

# add in TaxaGroup
final_cppCore_sf <- merge(final_cppCore_sf, unique(lu_sgcn[c("SNAME","TaxaGroup")]), all.x=TRUE)
final_srcf_combined <- merge(final_srcf_combined, unique(lu_sgcn[c("SNAME","TaxaGroup")]), all.x=TRUE)
final_er_sf <- merge(final_er_sf, unique(lu_sgcn[c("SNAME","TaxaGroup")]), all.x=TRUE)
final_cppCore_sf$DataSource <- "PNHP CPP"
final_er_sf$DataSource <- "PNHP ER"

# field alignment
final_cppCore_sf <- final_cppCore_sf[final_fields]
final_srcf_combined <- final_srcf_combined[final_fields]
final_er_sf <- final_er_sf[final_fields]

#final_srcf_combined$useCOA <- with(final_srcf_combined, ifelse(final_srcf_combined$LastObs>=cutoffyearL, "y", "n"))
#add the occurence probability
#final_srcf_combined$OccProb = with(final_srcf_combined, ifelse(LastObs>=cutoffyearK , "k", ifelse(LastObs<cutoffyearK & LastObs>=cutoffyearL, "l", "u")))

# write a feature class to the gdb
st_crs(final_cppCore_sf) <- customalbers
st_crs(final_srcf_combined) <- customalbers
st_crs(final_er_sf) <- customalbers
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_cppCore"), final_cppCore_sf, overwrite=TRUE, validate=TRUE)
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_Biotics"), final_srcf_combined, overwrite=TRUE, validate=TRUE)
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_er"), final_er_sf, overwrite=TRUE, validate=TRUE)