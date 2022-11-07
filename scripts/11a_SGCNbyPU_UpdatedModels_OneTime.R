#---------------------------------------------------------------------------------------------
# Name: 11a_SGCNbyPU_UpdatedModels_OneTime.r
# Purpose: Update SGCNxPU table with updated models to be done when needed.
# Author: Molly Moore
# Created: 2022-10-11
# Updates:
#---------------------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)

source(here::here("scripts","00_PathsAndSettings.r"))

shapefile_folder <- "D:/COA_2022_SHMrevision/SHMrevision"

# connect to lu_sgcnXpu table
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
sgcnXpu <- dbReadTable(db, "lu_sgcnXpu_all") # write the table to the sqlite
dbDisconnect(db) # disconnect the db

# list of species whose models were updated
model_updates <- c("ABNKD06020_b", "ABPAE33040_b", "ABPAU08010_b", "ABPBA01010_b", "ABPBJ19010_b", "ABPBK01010_b", "ABPBX01020_b", "ABPBX01060_b", "ABPBX03050_b", "ABPBX03240_b", "ABPBX10030_b", "ABPBX16030_b", "ABPBX24010_b", "ABPBX45040_b", "ABPBX94050_b", "ABPBXA0020_b", "ABPBXA9010_b", "IILEP66080_y", "IILEP77030_y", "IILEPC1070_y", "IILEPC1110_y", "IILEPJ9150_y", "IILEPK4060_y", "IILEPN0010_y")

# create empty dataframe with column 
df <- data.frame(matrix(ncol = 4, nrow = 0))
x <- c("uniqu_d", "OccProb", "PERCENT", "ELSeasn")
colnames(df) <- x

# loop through shapefiles and rbind applicable columns into empty df
for(elseason in model_updates){
  print(elseason)
  shape <- read_sf(paste(shapefile_folder,paste0("pu_",elseason,"_new.shp"), sep="/"))
  df <- rbind(df,shape[,x])
}

model_df <- st_drop_geometry(df)
colnames(model_df) <- c("unique_id","OccProb","PERCENTAGE","ELSeason")

`%notin%` <- Negate(`%in%`)

# delete records of previous models for which there are updated models
sgcnXpu_minus_elcodes <- sgcnXpu[which(sgcnXpu$ELSeason %notin% model_updates),]

# get known records for elcodes of updated models to put back in
elcode_knowns <- sgcnXpu[which(sgcnXpu$ELSeason %in% model_updates & sgcnXpu$OccProb=="k"),]

# rbind the sgcnXpu without model elcodes, sgcnXpu with known elcode occurrences, and sgcnXpu for updated models
sgcnXpu_final <- do.call(rbind, list(sgcnXpu_minus_elcodes, elcode_knowns, model_df))

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_sgcnXpu_all", sgcnXpu_final, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
