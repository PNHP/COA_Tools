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

# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)

source(here::here("scripts","00_PathsAndSettings.r"))

######################################################################################
# read in SGCN data
loadSGCN()

# get a list of bird codes to join to the list
birdcodes <- read.csv(here::here("_data","input","PA_BreedingBirds_Species_2018.csv"), stringsAsFactors=FALSE)
birdcodes <- birdcodes[c("SPEC","SCOMMON","SNAME")]
birdcodes <- birdcodes %>% add_row(SPEC="LESC", SCOMMON="Lesser Scaup", SNAME="Aythya affinis")
birdcodes <- birdcodes %>% add_row(SPEC="AGWT", SCOMMON="Green-winged Teal", SNAME="Anas carolinensis")

# read the waterfowl data in
waterfowl <- read.csv(here::here("_data","input","SGCN_data","PGC_Waterfowl","PA_speciessubset_2003_2020.csv"), stringsAsFactors=FALSE)
unique(waterfowl$species_id)
waterfowl <- merge(waterfowl, birdcodes, by.x="species_id", by.y="SPEC", all.x = TRUE)

waterfowl$state_plot_number <- stringr::str_pad(waterfowl$state_plot_number, width=3, side="left", pad="0") # pad the missing zeros for the plot number

# 2020 waterfall data
waterfowl2020 <- read.csv(here::here("_data","input","SGCN_data","PGC_Waterfowl","2020 AFBWS SGCN.csv"), stringsAsFactors=FALSE)
unique(waterfowl2020$Species)
waterfowl2020 <- merge(waterfowl2020, birdcodes, by.x="Species", by.y="SPEC", all.x = TRUE)

names(waterfowl2020)[which(names(waterfowl2020)=="Year")] <- "year"
names(waterfowl2020)[which(names(waterfowl2020)=="Stratum")] <- "stratum_id"
names(waterfowl2020)[which(names(waterfowl2020)=="Plot")] <- "state_plot_number"

waterfowl2020$state_plot_number <- stringr::str_pad(waterfowl2020$state_plot_number, width=3, side="left", pad="0") 

waterfowl2020[which(waterfowl2020$Stratum==241),"Stratum"] <- 24
waterfowl2020[which(waterfowl2020$Stratum==242),"Stratum"] <- 24
waterfowl2020[which(waterfowl2020$Stratum==243),"Stratum"] <- 24

# join up the two datasets
intersect(names(waterfowl), names(waterfowl2020))

waterfowl <- waterfowl[intersect(names(waterfowl), names(waterfowl2020))]
waterfowl2020 <- waterfowl2020[intersect(names(waterfowl), names(waterfowl2020))]

waterfowl <- rbind(waterfowl, waterfowl2020)

# filter by the most recent observation within each plot
waterfowl1 <- waterfowl %>%
  group_by(SNAME, state_plot_number) %>%
  filter(year==max(year)) #%>%

waterfowl1 <- waterfowl1[!duplicated(waterfowl1[c('SNAME', 'stratum_id', 'state_plot_number')]),] 

plotlist <- unique(waterfowl1$state_plot_number)
  
# get the plot locations
plots <- arc.open(here::here("_data","input","SGCN_data","PGC_Waterfowl","Waterfowl_Plots.shp"))
plots <- arc.select(plots)
plots <- arc.data2sf(plots)

plotsSubset <- plots[which(plots$Plot_Num %in% plotlist),]

# make the joins
birdplots <- merge(plotsSubset, waterfowl1, by.x=c("Statum","Plot_Num"), by.y=c("stratum_id","state_plot_number"), all.y=TRUE)
birdplots <- birdplots[which(!is.na(birdplots$NW_Lat)),]  # why is there not '24' stratum

# wetlands
nwi_url <- "H://Scripts/COA_Tools/_data/misc/PA_geodatabase_wetlands.gdb/PA_Wetlands"
nwi <- arc.open(nwi_url)
nwi <- arc.select(nwi)
nwi <- arc.data2sf(nwi)
nwi <- st_buffer(nwi, dist=0)
nwi <- st_transform(nwi, customalbers)

# spatial work
birdplots_new <- st_transform(birdplots, customalbers)
birdplots_new <- st_buffer(birdplots_new, dist=0)

waterfowlSGCN <- st_intersection(birdplots_new, nwi)

waterfowlSGCN$DataID <- "PGCwaterfowl"
waterfowlSGCN$SeasonCode <- "b"
waterfowlSGCN$Environment <- "t"
waterfowlSGCN$LastObs <- waterfowlSGCN$year
waterfowlSGCN$DataSource <- "PGC waterfowl"
waterfowlSGCN$OccProb <- "k"
waterfowlSGCN$useCOA <- "y"

waterfowlSGCN <- merge(waterfowlSGCN, lu_sgcn, by=c("SNAME","SeasonCode"), all.x=TRUE)

#keep only final fields and write source point and final feature classes to SGCN GDB
waterfowlSGCN <- waterfowlSGCN[final_fields]
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_PGCwaterfowl"), waterfowlSGCN, overwrite=TRUE, validate = TRUE) # write a feature class to the gdb

