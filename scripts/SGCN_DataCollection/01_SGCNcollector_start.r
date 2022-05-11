# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

# copy the blankSGCN directory from the base folder to the output directory
current_folder <- here::here("_data","templates","SGCN_blank.gdb") 
new_folder <- here::here("_data","output",updateName,"SGCN.gdb") 
list_of_files <- list.files(path=current_folder, full.names=TRUE) 
dir.create(new_folder)
file.copy(from=file.path(list_of_files), to=new_folder,  overwrite=TRUE, recursive=FALSE, copy.mode=TRUE)
