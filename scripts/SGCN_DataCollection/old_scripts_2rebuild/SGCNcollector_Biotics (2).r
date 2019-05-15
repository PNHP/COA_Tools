#---------------------------------------------------------------------------------------------
# Name: SGCNcollector_Biotics.r
# Purpose: 
# Author: Christopher Tracey
# Created: 2019-03-11
# Updated: 
#
# Updates:
# insert date and info
# * 2018-09-21 
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------

# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
require(RSQLite)

arc.check_product() # load the arcgis license

biotics_path <- "W:/Heritage/Heritage_Data/Biotics_datasets.gdb"
cpp_path <- "W:/Heritage/Heritage_Projects/CPP/CPP_Pittsburgh.gdb"
databasename <- here("_data","output","coa_bridgetest.sqlite")

# get SGCN data
db <- dbConnect(SQLite(), dbname = databasename)
SQLquery <- paste("SELECT ELCODE, SCOMNAME, SNAME, USESA, SPROT, PBSSTATUS, TaxaDisplay"," FROM lu_sgcn ")
lu_sgcn <- dbGetQuery(db, statement = SQLquery)
dbDisconnect(db) # disconnect the db

# get a vector of SGCN ELCODES
lu_ELCODEs <- unique(lu_sgcn$ELCODE)

# create a vector of field names for the arc.select statement below
lu_srcfeature_names <- c("SF_ID","EO_ID","ELCODE","SNAME","SCOMNAME","ELSUBID","LU_TYPE","LU_DIST","LU_UNIT","USE_CLASS","EST_RA")

# read in source points 
srcfeat_points <- arc.open(paste(biotics_path,"eo_sourcept",sep="/")) 
srcfeat_points <- arc.select(srcfeat_points, lu_srcfeature_names)
srcfeat_points_SGCN <- srcfeat_points[which(srcfeat_points$ELCODE %in% lu_ELCODEs),] # subset to SGCN
srcfeat_points_SGCN <- srcfeat_points_SGCN[which(!is.na(srcfeat_points_SGCN$EO_ID)),] # drop independent source features
# read in source lines 
srcfeat_lines <- arc.open(paste(biotics_path,"eo_sourceln",sep="/")) 
srcfeat_lines <- arc.select(srcfeat_lines, lu_srcfeature_names)
srcfeat_lines_SGCN <- srcfeat_lines[which(srcfeat_lines$ELCODE %in% lu_ELCODEs),] # subset to SGCN
srcfeat_lines_SGCN <- srcfeat_lines_SGCN[which(!is.na(srcfeat_lines_SGCN$EO_ID)),] # drop independent source features
# read in source polygons 
srcfeat_polygons <- arc.open(paste(biotics_path,"eo_sourcepy",sep="/"))  
srcfeat_polygons <- arc.select(srcfeat_polygons, lu_srcfeature_names)
srcfeat_polygons_SGCN <- srcfeat_polygons[which(srcfeat_polygons$ELCODE %in% lu_ELCODEs),] # subset to SGCN
srcfeat_polygons_SGCN <- srcfeat_polygons_SGCN[which(!is.na(srcfeat_polygons_SGCN$EO_ID)),] # drop independent source features

# get a combined list of EO_IDs from the three source feature layers above
lu_EOID <- unique(c(srcfeat_points_SGCN$EO_ID, srcfeat_lines_SGCN$EO_ID, srcfeat_polygons_SGCN$EO_ID))

# read in the point reps layer to get last obs dates and such
ptreps <- arc.open(paste(biotics_path,"eo_ptreps",sep="/"))  
ptreps <- arc.select(ptreps, c("EO_ID","EST_RA","PREC_BCD","LASTOBS_YR")) # , lu_srcfeature_names
ptreps_SGCN <- ptreps[which(ptreps$EO_ID %in% lu_EOID),]
ptreps_SGCN <- as.data.frame(ptreps_SGCN)

# convert to simple features
srcf_pt_sf <- arc.data2sf(srcfeat_points_SGCN)
srcf_ln_sf <- arc.data2sf(srcfeat_lines_SGCN)
srcf_py_sf <- arc.data2sf(srcfeat_polygons_SGCN)

# add in the lastobs date to the source features
srcf_pt_sf <- merge(srcf_pt_sf,ptreps_SGCN[c("EO_ID","LASTOBS_YR")],by="EO_ID", all.x=TRUE)
srcf_pt_sf$LASTOBS_YR <- as.numeric(srcf_pt_sf$LASTOBS_YR)
srcf_ln_sf <- merge(srcf_ln_sf,ptreps_SGCN[c("EO_ID","LASTOBS_YR")],by="EO_ID", all.x=TRUE)
srcf_ln_sf$LASTOBS_YR <- as.numeric(srcf_ln_sf$LASTOBS_YR)
srcf_py_sf <- merge(srcf_py_sf,ptreps_SGCN[c("EO_ID","LASTOBS_YR")],by="EO_ID", all.x=TRUE)
srcf_py_sf$LASTOBS_YR <- as.numeric(srcf_py_sf$LASTOBS_YR)

# add a buffer distance field (in meters)
srcf_pt_sf$buffer <- ifelse(!is.na(srcf_pt_sf$LU_DIST), srcf_pt_sf$LU_DIST, 50)
srcf_ln_sf$buffer <- ifelse(!is.na(srcf_ln_sf$LU_DIST), srcf_ln_sf$LU_DIST, 50)
srcf_py_sf$buffer <- ifelse(!is.na(srcf_py_sf$LU_DIST), srcf_py_sf$LU_DIST, 50)

# rename or develop the SGCN_database fields
srcf_pt_sf$DataID <- srcf_pt_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_pt_sf$DataSource <- "PNHP Biotics"
srcf_pt_sf$OccProb <- "K"
srcf_pt_sf$LastObs <- srcf_pt_sf$LASTOBS_YR
### Do this for the lines as well
srcf_ln_sf$DataID <- srcf_ln_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_ln_sf$DataSource <- "PNHP Biotics"
srcf_ln_sf$OccProb <- "K"
srcf_ln_sf$LastObs <- srcf_ln_sf$LASTOBS_YR
### Do this for the polygons as well
srcf_py_sf$DataID <- srcf_py_sf$EO_ID # this sets the COA dataID field to the EO_ID
srcf_py_sf$DataSource <- "PNHP Biotics"
srcf_py_sf$OccProb <- "K"
srcf_py_sf$LastObs <- srcf_py_sf$LASTOBS_YR

# set up the Use classes as it relates to season
lu_UseClass <- data.frame("USE_CLASS"=c("Undetermined","Not applicable","Hibernaculum","Breeding","Nonbreeding","Maternity colony","Bachelor colony","Freshwater"),"SeasonCode"=c("y","y","w","b","y","b","b","y"), stringsAsFactors=FALSE)

srcf_pt_sf1 <- merge(srcf_pt_sf,lu_UseClass, by="USE_CLASS", all.x=TRUE)
srcf_ln_sf1 <- merge(srcf_ln_sf,lu_UseClass, by="USE_CLASS", all.x=TRUE)
srcf_py_sf1 <- merge(srcf_py_sf,lu_UseClass, by="USE_CLASS", all.x=TRUE)

# calculate the buffers
srcf_pt_sf1buf <- st_buffer(srcf_pt_sf1, dist=srcf_pt_sf1$buffer)   
srcf_ln_sf1buf <- st_buffer(srcf_ln_sf1, dist=srcf_ln_sf1$buffer)
 
# combined source feature
srcf_combined <- rbind(srcf_pt_sf1buf,srcf_ln_sf1buf)
srcf_combined <- rbind(srcf_combined,srcf_py_sf1)


# load in Conservation Planning Polygons
cppCore <- arc.open(paste(cpp_path,"CPP_Core",sep="/")) 
cppCore <- arc.select(cppCore, c("SNAME","EO_ID","Status"), where_clause="Status ='c'") 
cppCore_sf <- arc.data2sf(cppCore)
cppCore_sf <- merge(cppCore_sf,lu_sgcn[c("SNAME", "ELCODE")], by="SNAME") # limit to SGCN
cppCore_sf <- cppCore_sf[c("EO_ID")]
cppCore_sf1 <- cppCore_sf[which(cppCore_sf$EO_ID %in% lu_EOID),]




