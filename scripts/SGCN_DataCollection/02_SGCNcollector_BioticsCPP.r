#---------------------------------------------------------------------------------------------
# Name: 1_SGCNcollector_BioticsCPP.r
# Purpose: 
# Author: Christopher Tracey
# Created: 2019-03-11
# Updated: 2022-10-10
#
# Updates:
# insert date and info
# * 2018-03-21 - CT: get list of species that are in Biotics
# * 2018-03-23 - CT: export shapefiles
# * 2022-10-10 - MMOORE: updates to include ER polygons as spatial features where available as per PGC/PFBC request
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))
arc.check_portal()

######################################################################################
# read in SGCN data
loadSGCN()

# load the Biotics ET data to get ELCODE and ELSUBID for selection - this is more stable than SNAME
sgcn_elcode <- lu_sgcn$ELCODE

ET <- arc.open(paste(biotics_path,"ET",sep="/")) 
sgcn_ET <- arc.select(ET) %>%
  filter(ELCODE %in% lu_sgcn$ELCODE)
sgcn_ELSUBID <- sgcn_ET$ELSUBID

########################################################################################
# load in ER Polygons
# CHANGE THIS EVERY TIME NEW ER DATASET IS AVAILABLE
# make sure ER dataset is in custom albers projection
er_layer <- "PA_ERPOLY_ALL_20250123_albers"
er_gdb <- "W:/Heritage/Heritage_Data/Environmental_Review/_ER_POLYS/ER_Polys.gdb"
er_poly <- arc.open(paste(er_gdb,er_layer, sep="/"))
er_poly <- arc.select(er_poly, c("SNAME","ELCODE","EOID","BUF_TYPE"), where_clause="BUF_TYPE ='I' AND EOID <> 0") 
er_sf <- arc.data2sf(er_poly)
er_sf <- er_sf[which(er_sf$ELCODE %in% unique(sgcn_ET$ELCODE)),]
names(er_sf)[names(er_sf) == 'EOID'] <- 'EO_ID'
# clean up
rm(er_poly)

########################################################################################
# load in Conservation Planning Polygons

# use this if you are not within the WPC network---caution, it may not be displaying all the records
#cpps <- "https://maps.waterlandlife.org/arcgis/rest/services/PNHP/CPP/FeatureServer/0"
#cppCore <- arc.open(cpps)
#cppCore <- arc.open(paste(serverPath,"PNHP.DBO.CPP_Core", sep=""))
# use this to hit the enterprise gdb server
cpp_url <- "https://gis.waterlandlife.org/server/rest/services/PNHP/CPP_EDIT/FeatureServer/0"
cppCore <- arc.open(cpp_url)
cppCore <- arc.select(cppCore, c("SNAME","ELSUBID","EO_ID","Status"), where_clause="Type IS NULL") 
cppCore_sf <- arc.data2sf(cppCore)
# we're using ELSUBID to select records because SNAME isn't as stable
cppCore_sf <- cppCore_sf[which(cppCore_sf$ELSUBID %in% unique(sgcn_ELSUBID)),]

# clean up
rm(cppCore)

########################################################################################
# load in Biotics Source Features

# create a vector of field names for the arc.select statement below
lu_srcfeature_names <- c("SF_ID","EO_ID","ELCODE","SNAME","SCOMNAME","ELSUBID","LU_TYPE","LU_DIST","LU_UNIT","USE_CLASS","EST_RA")
# read in source points 
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
sf_y2b <- c("Circus hudsonius","Cistothorus stellaris","Podilymbus podiceps","Botaurus lentiginosus","Ixobrychus exilis","Ardea alba","Nycticorax nycticorax","Nyctanassa violacea","Anas crecca","Anas rubripes","Anas discors","Pandion haliaetus","Haliaeetus leucocephalus","Circus cyaneus","Accipiter striatus","Accipiter gentilis","Accipiter atricapillus","Buteo platypterus","Falco sparverius","Falco peregrinus","Bonasa umbellus","Rallus elegans","Rallus limicola","Porzana carolina","Gallinula galeata","Fulica americana","Charadrius melodus","Actitis macularius","Bartramia longicauda","Gallinago delicata","Scolopax minor","Sterna hirundo","Chlidonias niger","Tyto alba","Asio otus","Asio flammeus","Aegolius acadicus","Chordeiles minor","Antrostomus vociferus","Chaetura pelagica","Melanerpes erythrocephalus","Contopus cooperi","Empidonax flaviventris","Empidonax traillii","Progne subis","Riparia riparia","Certhia americana","Troglodytes hiemalis","Cistothorus platensis","Cistothorus palustris","Catharus ustulatus","Hylocichla mustelina","Dumetella carolinensis","Lanius ludovicianus","Vermivora cyanoptera","Vermivora chrysoptera","Oreothlypis ruficapilla","Setophaga caerulescens","Setophaga virens","Setophaga discolor","Setophaga striata","Setophaga cerulea","Mniotilta varia","Protonotaria citrea","Parkesia noveboracensis","Parkesia motacilla","Geothlypis formosa","Cardellina canadensis","Icteria virens","Piranga rubra","Piranga olivacea","Spiza americana","Spizella pusilla","Pooecetes gramineus","Passerculus sandwichensis","Ammodramus savannarum","Ammodramus henslowii","Zonotrichia albicollis","Dolichonyx oryzivorus","Sturnella magna","Loxia curvirostra","Spinus pinus","Lanius ludovicianus","Lanius ludovicianus migrans","Lasionycteris noctivagans")  
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

# remove the cpp polygons for which there are ER polygons
cppCore_sf <- cppCore_sf[which(!cppCore_sf$EO_ID %in% er_sf$EO_ID),]

# get attributes for the CPPs
att_for_cpp <- srcf_combined[which(srcf_combined$EO_ID %in% cppCore_sf$EO_ID),] 

# replace bad season codes
cpp_y2b <- c("Circus hudsonius","Cistothorus stellaris","Podilymbus podiceps","Botaurus lentiginosus","Ixobrychus exilis","Ardea alba","Nycticorax nycticorax","Nyctanassa violacea","Anas crecca","Anas rubripes","Anas discors","Pandion haliaetus","Haliaeetus leucocephalus","Circus cyaneus","Accipiter striatus","Accipiter gentilis","Accipiter atricapillus","Buteo platypterus","Falco sparverius","Falco peregrinus","Bonasa umbellus","Rallus elegans","Rallus limicola","Porzana carolina","Gallinula galeata","Fulica americana","Charadrius melodus","Actitis macularius","Bartramia longicauda","Gallinago delicata","Scolopax minor","Sterna hirundo","Chlidonias niger","Tyto alba","Asio otus","Asio flammeus","Aegolius acadicus","Chordeiles minor","Antrostomus vociferus","Chaetura pelagica","Melanerpes erythrocephalus","Contopus cooperi","Empidonax flaviventris","Empidonax traillii","Progne subis","Riparia riparia","Certhia americana","Troglodytes hiemalis","Cistothorus platensis","Cistothorus palustris","Catharus ustulatus","Hylocichla mustelina","Dumetella carolinensis","Lanius ludovicianus","Vermivora cyanoptera","Vermivora chrysoptera","Oreothlypis ruficapilla","Setophaga caerulescens","Setophaga virens","Setophaga discolor","Setophaga striata","Setophaga cerulea","Mniotilta varia","Protonotaria citrea","Parkesia noveboracensis","Parkesia motacilla","Geothlypis formosa","Cardellina canadensis","Icteria virens","Piranga rubra","Piranga olivacea","Spiza americana","Spizella pusilla","Pooecetes gramineus","Passerculus sandwichensis","Ammodramus savannarum","Ammodramus henslowii","Zonotrichia albicollis","Dolichonyx oryzivorus","Sturnella magna","Loxia curvirostra","Spinus pinus","Lanius ludovicianus","Lanius ludovicianus migrans","Lasionycteris noctivagans")       
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
er_y2b <- c("Circus hudsonius","Cistothorus stellaris","Podilymbus podiceps","Botaurus lentiginosus","Ixobrychus exilis","Ardea alba","Nycticorax nycticorax","Nyctanassa violacea","Anas crecca","Anas rubripes","Anas discors","Pandion haliaetus","Haliaeetus leucocephalus","Circus cyaneus","Accipiter striatus","Accipiter gentilis","Accipiter atricapillus","Buteo platypterus","Falco sparverius","Falco peregrinus","Bonasa umbellus","Rallus elegans","Rallus limicola","Porzana carolina","Gallinula galeata","Fulica americana","Charadrius melodus","Actitis macularius","Bartramia longicauda","Gallinago delicata","Scolopax minor","Sterna hirundo","Chlidonias niger","Tyto alba","Asio otus","Asio flammeus","Aegolius acadicus","Chordeiles minor","Antrostomus vociferus","Chaetura pelagica","Melanerpes erythrocephalus","Contopus cooperi","Empidonax flaviventris","Empidonax traillii","Progne subis","Riparia riparia","Certhia americana","Troglodytes hiemalis","Cistothorus platensis","Cistothorus palustris","Catharus ustulatus","Hylocichla mustelina","Dumetella carolinensis","Lanius ludovicianus","Vermivora cyanoptera","Vermivora chrysoptera","Oreothlypis ruficapilla","Setophaga caerulescens","Setophaga virens","Setophaga discolor","Setophaga striata","Setophaga cerulea","Mniotilta varia","Protonotaria citrea","Parkesia noveboracensis","Parkesia motacilla","Geothlypis formosa","Cardellina canadensis","Icteria virens","Piranga rubra","Piranga olivacea","Spiza americana","Spizella pusilla","Pooecetes gramineus","Passerculus sandwichensis","Ammodramus savannarum","Ammodramus henslowii","Zonotrichia albicollis","Dolichonyx oryzivorus","Sturnella magna","Loxia curvirostra","Spinus pinus","Lanius ludovicianus","Lanius ludovicianus migrans","Lasionycteris noctivagans")       
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

er_sf_final <- merge(er_sf, att_for_er, by.x="EO_ID", by.y="EO_ID", all.x=TRUE)
er_sf_final <- er_sf_final[which(!is.na(er_sf_final$LastObs)),]

# clean up
rm(srcf_combined)

# replace the ET names with those from the SWAP
biotics_crosswalk <- read.csv(biotics_crosswalk, stringsAsFactors=FALSE)
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
final_er_sf$ELCODE <- final_er_sf$ELCODE.x
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

BioticsCPP_ELSeason <- unique(c(final_cppCore_sf$ELSeason, final_srcf_combined$ELSeason, final_er_sf$ELSeason))

# get a vector of species that are in Biotics/CPP/er so we can use it to filter other datasets
SGCN_biotics <- unique(final_srcf_combined[which(final_srcf_combined$useCOA=="y"),]$SNAME)
SGCN_cpp <- unique(final_cppCore_sf[which(final_cppCore_sf$useCOA=="y"),]$SNAME)
SGCN_er <- unique(final_er_sf[which(final_er_sf$useCOA=="y"),]$SNAME)

SGCN_bioticsCPP <- unique(c(SGCN_biotics, SGCN_cpp, SGCN_er))
rm(SGCN_biotics, SGCN_cpp, SGCN_er)

#write.csv(SGCN_bioticsCPP, "SGCN_bioticsCPP.csv", row.names=FALSE)
save(SGCN_bioticsCPP, file=updateData)

a <- setdiff(unique(final_cppCore_sf$ELCODE), unique(lu_sgcn$ELCODE))
b <- setdiff(unique(lu_sgcn$ELCODE), unique(final_cppCore_sf$ELCODE))
a <- table(cppCore_sf_final$SNAME, final_cppCore_sf$SeasonCode)
b <- table(final_srcf_combined$SNAME, final_srcf_combined$SeasonCode)

# QC checks

# get ELSeason values that are in lu_sgcn table, but not spatially represented in lu_sgcnXpu table
sgcn_noDataFromBiotics <- setdiff(lu_sgcn$ELSeason, BioticsCPP_ELSeason)
print("The following ELSeason records are found in the lu_sgcn table, but are not spatially represented in the  Biotics/CPP data: ")
print(lu_sgcn[lu_sgcn$ELSeason %in% sgcn_noDataFromBiotics ,])
a <- lu_sgcn[lu_sgcn$ELSeason %in% sgcn_noDataFromBiotics ,]

# get ELSeason values that are in lu_sgcnXpu table, but do not have a matching ELSeason record in lu_sgcn
sgcn_InBioticsButNotInLuSGCN <- setdiff(BioticsCPP_ELSeason, lu_sgcn$ELSeason)
print("The following ELSeason records are found in the Biotics/CPP data, but do not have matching records in the lu_sgcn table: ")
print(sgcn_InBioticsButNotInLuSGCN)

