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

# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("rgdal", quietly = TRUE)) install.packages("rgdal")
require(rgdal)

source(here::here("scripts","00_PathsAndSettings.r"))

sgcn_folder <- here::here("_data","output",updateName,"SGCN.gdb")
subset(ogrDrivers(), grepl("GDB", name))
fc_list <- ogrListLayers(sgcn_folder)
final_list <- fc_list[grepl("final",fc_list)]
final_list # print out the final list


columns <- c('OBJECTID','ELCODE','ELSeason','SNAME','SCOMNAME','SeasonCode','DataSource','DataID','OccProb','LastObs','useCOA','TaxaGroup')

data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",final_list[1]))
sgcn <- arc.select(data,columns)
sgcn_sf <- arc.data2sf(sgcn)
sgcn_sf <- sgcn_sf[0,]

# before doing this step, you should check to make sure there is no empty geometry in the bat data, unless that was fixed and then please delete this comment.
for(name in final_list){
  print(name)
  data <- arc.open(path=here::here("_data","output",updateName,"SGCN.gdb",name))
  data <- arc.select(data,columns)
  data_sf <- arc.data2sf(data)
  sgcn_sf <- rbind(sgcn_sf,data_sf)
}

sgcn_final <- sgcn_sf[which(sgcn_sf$useCOA=='y'),]
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","allSGCNuse"), sgcn_final, overwrite=TRUE)
