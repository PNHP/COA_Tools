#---------------------------------------------------------------------------------------------
# Name: 21_SGCNmerger.r
# Purpose: 
# Author: Molly Moore
# Created: 2019-10-21
# Updated: 
#
# Updates:
# 
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
if (!requireNamespace("rgdal", quietly = TRUE)) install.packages("rgdal")
require(rgdal)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)

source(here::here("scripts","SGCN_DataCollection","00_PathsAndSettings.r"))

sgcn_folder <- here::here("_data/output/SGCN.gdb")
subset(ogrDrivers(), grepl("GDB", name))
fc_list <- ogrListLayers(sgcn_folder)
final_list <- fc_list[grepl("final",fc_list)]

columns <- c('OBJECTID','ELCODE','ELSeason','SNAME','SCOMNAME','SeasonCode','DataSource','DataID','OccProb','LastObs','useCOA','TaxaGroup')

arc.check_product()
data <- arc.open(path=here::here("_data/output/SGCN.gdb",final_list[1]))
sgcn <- arc.select(data,columns)
sgcn_sf <- arc.data2sf(sgcn)
sgcn_sf <- sgcn_sf[0,]

for(name in final_list){
  print(name)
  data <- arc.open(path=here::here("_data/output/SGCN.gdb",name))
  data <- arc.select(data,columns)
  data_sf <- arc.data2sf(data)
  sgcn_sf <- rbind(sgcn_sf,data_sf)
}

sgcn_final <- sgcn_sf[grepl("y",sgcn$useCOA),]
arc.write(path=here::here("_data/output/SGCN.gdb","allSGCNuse"), sgcn_final, overwrite=TRUE)
