#---------------------------------------------------------------------------------------------
# Name: 21_SGCNmerger.r
# Purpose: 
# Author: Molly Moore
# Created: 2019-10-21
# Updates:
# 2024-07-17 - replaced rgdal functions with sf package functions because of deprecation of rgdal.
#
# To Do List/Future Ideas:
# * 
#---------------------------------------------------------------------------------------------
# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)

source(here::here("scripts","00_PathsAndSettings.r"))


columns <- c('OBJECTID','ELCODE','ELSeason','SNAME','SCOMNAME','SeasonCode','DataSource','DataID','OccProb','LastObs','useCOA','TaxaGroup')

sgcn_folder <- here::here("_data","output",updateName,"SGCN.gdb")

# list of datasets that only have final datasets and not source features. These will be used to create source polygon layer
finalList_srcpy <- c("final_Biotics", "final_cppCore", "final_er", "final_PGCwaterfowl")

# get a list of all the srcpt layers by filtering for those that have "srcpt" in name
fc_list <- st_layers(sgcn_folder)$name
finalList_srcpt <- fc_list[grepl("srcpt",fc_list)]

data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",finalList_srcpt[2]))
sgcn_srcpt <- arc.select(data,columns)
sgcn_srcpt_sf <- arc.data2sf(sgcn_srcpt)
sgcn_srcpt_sf <- sgcn_srcpt_sf[0,]

for(name in finalList_srcpt){
  print(name)
  data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",name))
  data <- arc.select(data,columns)
  data_srcpt_sf <- arc.data2sf(data)
  sgcn_srcpt_sf <- rbind(sgcn_srcpt_sf, data_srcpt_sf)
}

# get a list of all the srcln layers by filtering for those that have "srcln" in name
fc_list <- st_layers(sgcn_folder)$name
finalList_srcln <- fc_list[grepl("srcln",fc_list)]

data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",finalList_srcln[1]))
sgcn_srcln <- arc.select(data,columns)
sgcn_srcln_sf <- arc.data2sf(sgcn_srcln)
sgcn_srcln_sf <- sgcn_srcln_sf[0,]

for(name in finalList_srcln){
  print(name)
  data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",name))
  data <- arc.select(data,columns)
  data_srcln_sf <- arc.data2sf(data)
  sgcn_srcln_sf <- rbind(sgcn_srcln_sf, data_srcln_sf)
}

# get source poly layers - layers for which there were no source points or lines.
data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",finalList_srcpy[1]))
sgcn_srcpy <- arc.select(data,columns)
sgcn_srcpy_sf <- arc.data2sf(sgcn_srcpy)
sgcn_srcpy_sf <- sgcn_srcpy_sf[0,]

for(name in finalList_srcpy){
  print(name)
  data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",name))
  data <- arc.select(data,columns)
  data_srcpy_sf <- arc.data2sf(data)
  sgcn_srcpy_sf <- rbind(sgcn_srcpy_sf, data_srcpy_sf)
}

# copy to the proper names
tmp_ln <- sgcn_srcln_sf
tmp_pt <- sgcn_srcpt_sf
tmp_py <- sgcn_srcpy_sf

names(tmp_ln)
names(tmp_py)
names(tmp_pt)

# read in SGCN data
db <- dbConnect(SQLite(), dbname = databasename)
  SQLquery <- paste("SELECT ELCODE, SNAME, Agency"," FROM lu_sgcn ")
  lu_sgcn <- dbGetQuery(db, statement = SQLquery)
  lu_sgcn <- unique(lu_sgcn)
dbDisconnect(db) # disconnect the db

# merge the Agency data
tmp_ln <- merge(tmp_ln, lu_sgcn[c("ELCODE", "Agency")], by="ELCODE")
tmp_pt <- merge(tmp_pt, lu_sgcn[c("ELCODE", "Agency")], by="ELCODE")
tmp_py <- merge(tmp_py, lu_sgcn[c("ELCODE", "Agency")], by="ELCODE")

##############################################################################
#make the PFBC data
sgcn_pfbc_ln <- tmp_ln[which(tmp_ln$Agency=="PFBC"|tmp_ln$Agency==""),]
sgcn_pfbc_py <- tmp_py[which(tmp_py$Agency=="PFBC"|tmp_py$Agency==""),]
sgcn_pfbc_pt <- tmp_pt[which(tmp_pt$Agency=="PFBC"|tmp_pt$Agency==""),]
# copy the blankSGCN directory from the base folder to the output directory
current_folder <- here::here("_data/templates/SGCN_blank.gdb") 
new_folder <- here::here("_data","output",updateName,"SGCN_PFBC.gdb") 
list_of_files <- list.files(path=current_folder, full.names=TRUE) 
dir.create(new_folder)
file.copy(from=file.path(list_of_files), to=new_folder,  overwrite=TRUE, recursive=FALSE, copy.mode=TRUE)
# write the datasets
arc.write(path=here::here("_data","output",updateName,"SGCN_PFBC.gdb","sgcn_pfbc_ln"), sgcn_pfbc_ln, overwrite=TRUE)
arc.write(path=here::here("_data","output",updateName,"SGCN_PFBC.gdb","sgcn_pfbc_pt"), sgcn_pfbc_pt, overwrite=TRUE, validate=TRUE)
arc.write(path=here::here("_data","output",updateName,"SGCN_PFBC.gdb","sgcn_pfbc_py"), sgcn_pfbc_py, overwrite=TRUE, validate=TRUE)


##############################################################################
#make the PGC data
sgcn_pgc_ln <- tmp_ln[which(tmp_ln$Agency=="PGC"|tmp_ln$Agency==""),]
sgcn_pgc_py <- tmp_py[which(tmp_py$Agency=="PGC"|tmp_py$Agency==""),]
sgcn_pgc_pt <- tmp_pt[which(tmp_pt$Agency=="PGC"|tmp_pt$Agency==""),]
# copy the blankSGCN directory from the base folder to the output directory
current_folder <- here::here("_data/templates/SGCN_blank.gdb") 
new_folder <- here::here("_data","output",updateName,"SGCN_PGC.gdb") 
list_of_files <- list.files(path=current_folder, full.names=TRUE) 
dir.create(new_folder)
file.copy(from=file.path(list_of_files), to=new_folder,  overwrite=TRUE, recursive=FALSE, copy.mode=TRUE)
# write the datasets
arc.write(path=here::here("_data","output",updateName,"SGCN_PGC.gdb","sgcn_pgc_pt"), sgcn_pgc_pt, overwrite=TRUE, validate=TRUE)  
if(nrow(sgcn_pgc_ln)>0){
  arc.write(path=here::here("_data","output",updateName,"SGCN_PGC.gdb","sgcn_pgc_ln"), sgcn_pgc_ln, overwrite=TRUE, validate=TRUE)
} else {
  print("empty ln feature class, skipping")
}

arc.write(path=here::here("_data","output",updateName,"SGCN_PGC.gdb","sgcn_pgc_py"), sgcn_pgc_py, overwrite=TRUE, validate=TRUE)

##########################

# get a list of all the srcln layers by filtering for those that have "srcln" in name
fc_list <- st_layers(sgcn_folder)$name
final_list <- fc_list[grepl("final",fc_list)]

data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",final_list[1]))
sgcn <- arc.select(data,columns)
sgcn_sf <- arc.data2sf(sgcn)
sgcn_sf <- sgcn_sf[0,]

# there used to be an issue with empty geometry in bat data, this seems to have been solved... proceed with caution
for(name in final_list){
  print(name)
  data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",name))
  data <- arc.select(data,columns)
  data_sf <- arc.data2sf(data)
  sgcn_sf <- rbind(sgcn_sf,data_sf)
}

# load in county buff layer and intersect with sgcn data to keep only PA records for final dataset
sgcn_final <- sgcn_sf[which(sgcn_sf$useCOA=='y'),]

#county_buff <- here::here("_data","output",updateName,"SGCN.gdb","CountyBuffer")
#data <- arc.open(county_buff)
#county_buff <- arc.select(data)
#county_buff_sf <- arc.data2sf(county_buff)

#sgcn_final1 <- st_make_valid(sgcn_final)
#county_buff_sf <- st_make_valid(county_buff_sf)
#sgcn_final1 <- st_crop(sgcn_final, county_buff_sf)

arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","allSGCNuse"), sgcn_final, overwrite=TRUE, validate=TRUE)
print("We're done here")

