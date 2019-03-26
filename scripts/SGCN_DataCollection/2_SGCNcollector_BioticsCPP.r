#---------------------------------------------------------------------------------------------
# Name: 1_SGCNcollector_BioticsCPP.r
# Purpose: 
# Author: Christopher Tracey
# Created: 2019-03-11
# Updated: 2018-03-23
#
# Updates:
# insert date and info
# * 2018-03-21 - get list of species that are in Biotics
# * 2018-03-23 - export shapefiles
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------

# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
require(RSQLite)


source(here("scripts","SGCN_DataCollection","0_PathsAndSettings.r"))


######################################################################################
# get SGCN data
db <- dbConnect(SQLite(), dbname = databasename)
SQLquery <- paste("SELECT ELCODE, SCOMNAME, SNAME, USESA, SPROT, PBSSTATUS, TaxaGroup"," FROM lu_sgcn ")
lu_sgcn <- dbGetQuery(db, statement = SQLquery)
dbDisconnect(db) # disconnect the db

# load the Biotics Crosswalk
biotics_crosswalk <- read.csv(biotics_crosswalk, stringsAsFactors=FALSE)
lu_sgcnBiotics <- biotics_crosswalk$SNAME

########################################################################################
# load in Conservation Planning Polygons
cppCore <- arc.open(paste(cpp_path,"CPP_Core",sep="/")) 
cppCore <- arc.select(cppCore, c("SNAME","EO_ID","Status"), where_clause="Status ='c' OR Status ='r'") 
cppCore_sf <- arc.data2sf(cppCore)
#### cppCore_sf <- cppCore_sf[which(cppCore_sf$SNAME %in% unique(lu_sgcn$SNAME)),] # bad SGCN names
cppCore_sf <- cppCore_sf[which(cppCore_sf$SNAME %in% unique(lu_sgcnBiotics)),]

# clean up
rm(cppCore)

########################################################################################
# load in Biotics Source Features

# create a vector of field names for the arc.select statement below
lu_srcfeature_names <- c("SF_ID","EO_ID","ELCODE","SNAME","SCOMNAME","ELSUBID","LU_TYPE","LU_DIST","LU_UNIT","USE_CLASS","EST_RA")

# read in source points 
srcfeat_points <- arc.open(paste(biotics_path,"eo_sourcept",sep="/")) 
srcfeat_points <- arc.select(srcfeat_points, lu_srcfeature_names)
srcfeat_points_SGCN <- srcfeat_points[which(srcfeat_points$SNAME %in% lu_sgcnBiotics),] # subset to SGCN
srcfeat_points_SGCN <- srcfeat_points_SGCN[which(!is.na(srcfeat_points_SGCN$EO_ID)),] # drop independent source features
# read in source lines 
srcfeat_lines <- arc.open(paste(biotics_path,"eo_sourceln",sep="/")) 
srcfeat_lines <- arc.select(srcfeat_lines, lu_srcfeature_names)
srcfeat_lines_SGCN <- srcfeat_lines[which(srcfeat_lines$SNAME %in% lu_sgcnBiotics),] # subset to SGCN
srcfeat_lines_SGCN <- srcfeat_lines_SGCN[which(!is.na(srcfeat_lines_SGCN$EO_ID)),] # drop independent source features
# read in source polygons 
srcfeat_polygons <- arc.open(paste(biotics_path,"eo_sourcepy",sep="/"))  
srcfeat_polygons <- arc.select(srcfeat_polygons, lu_srcfeature_names)
srcfeat_polygons_SGCN <- srcfeat_polygons[which(srcfeat_polygons$SNAME %in% lu_sgcnBiotics),] # subset to SGCN
srcfeat_polygons_SGCN <- srcfeat_polygons_SGCN[which(!is.na(srcfeat_polygons_SGCN$EO_ID)),] # drop independent source features

# clean up
rm(srcfeat_points,srcfeat_lines,srcfeat_polygons,lu_srcfeature_names)

# get a combined list of EO_IDs from the three source feature layers above
lu_EOID <- unique(c(srcfeat_points_SGCN$EO_ID, srcfeat_lines_SGCN$EO_ID, srcfeat_polygons_SGCN$EO_ID))

# read in the point reps layer to get last obs dates and such
ptreps <- arc.open(paste(biotics_path,"eo_ptreps",sep="/"))  
ptreps <- arc.select(ptreps, c("EO_ID","EST_RA","PREC_BCD","LASTOBS_YR")) # , lu_srcfeature_names
ptreps_SGCN <- ptreps[which(ptreps$EO_ID %in% lu_EOID),]
ptreps_SGCN <- as.data.frame(ptreps_SGCN) # drop the spatial part

# convert to simple features
srcf_pt_sf <- arc.data2sf(srcfeat_points_SGCN)
srcf_ln_sf <- arc.data2sf(srcfeat_lines_SGCN)
srcf_py_sf <- arc.data2sf(srcfeat_polygons_SGCN)

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
srcf_pt_sf$OccProb <- "K"
srcf_pt_sf$LastObs <- srcf_pt_sf$LASTOBS_YR
srcf_pt_sf$useCOA <- NA
### Do this for the lines as well
srcf_ln_sf$DataID <- srcf_ln_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_ln_sf$DataSource <- "PNHP Biotics"
srcf_ln_sf$OccProb <- "K"
srcf_ln_sf$LastObs <- srcf_ln_sf$LASTOBS_YR
srcf_ln_sf$useCOA <- NA
### Do this for the polygons as well
srcf_py_sf$DataID <- srcf_py_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_py_sf$DataSource <- "PNHP Biotics"
srcf_py_sf$OccProb <- "K"
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
srcf_combined$useCOA <- ifelse(srcf_combined$LASTOBS_YR>=cutoffyear & srcf_combined$buffer<1000, "y", "n")
srcf_combined$ELSeason <- paste(srcf_combined$ELCODE,srcf_combined$SeasonCode,sep="_")

# clean up
rm(srcf_pt_sf1buf,srcf_ln_sf1buf,srcf_py_sf1buf)

# remove the source features for which CPPs have been created
final_srcf_combined <- srcf_combined[which(!srcf_combined$EO_ID %in% cppCore_sf$EO_ID),] 

# get attributes for the CPPs
att_for_cpp <- srcf_combined[which(srcf_combined$EO_ID %in% cppCore_sf$EO_ID),] 

# clean up
rm(srcf_combined)

# clean up attributes to prep to join to the CPPs
st_geometry(att_for_cpp) <- NULL
att_for_cpp$SF_ID <- NULL
att_for_cpp$SNAME <- NULL
att_for_cpp$LU_DIST <- NULL
att_for_cpp$LU_DIST <- NULL
att_for_cpp$buffer <- NULL
att_for_cpp$USE_CLASS <- NULL
att_for_cpp$LU_UNIT <- NULL
att_for_cpp$LU_TYPE <- NULL
att_for_cpp$EST_RA <-NULL

att_for_cpp <- unique(att_for_cpp)

cppCore_sf_final <- merge(cppCore_sf, att_for_cpp, by="EO_ID", all.x=TRUE)
cppCore_sf_final <- cppCore_sf_final[which(!is.na(cppCore_sf_final$LastObs)),]

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

# add in TaxaGroup
cppCore_sf_final <- merge(cppCore_sf_final, unique(lu_sgcn[c("SNAME","TaxaGroup")]), all.x=TRUE)
final_srcf_combined <- merge(final_srcf_combined, unique(lu_sgcn[c("SNAME","TaxaGroup")]), all.x=TRUE)


# field alignment
cppCore_sf_final <- cppCore_sf_final[final_fields]
final_srcf_combined <- final_srcf_combined[final_fields] 

# write a feature class to the gdb
arc.write(path=here("_data/output/SGCN.gdb","final_cppCore"), final_cppCore_sf, overwrite=TRUE)
arc.write(path=here("_data/output/SGCN.gdb","final_Biotics"), final_srcf_combined, overwrite=TRUE)

# get a vector of species that are in Biotics/CPP so we can use it to filter other datasets
SGCN_biotics <- unique(final_srcf_combined[which(final_srcf_combined$useCOA=="y"),]$SNAME)
SGCN_cpp <- unique(final_cppCore_sf[which(final_cppCore_sf$useCOA=="y"),]$SNAME)

SGCN_bioticsCPP <- unique(c(SGCN_biotics, SGCN_cpp))
rm(SGCN_biotics, SGCN_cpp)

write.csv(SGCN_bioticsCPP, "SGCN_bioticsCPP.csv", row.names=FALSE)
