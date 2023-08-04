
# clear the environments
rm(list=ls())

source(here::here("scripts","00_PathsAndSettings.r"))

# read in SGCN data
loadSGCN()


# load the arcgis license
arc.check_product() 

occurrences <- "H:/Scripts/COA_Tools/_data/input/SGCN_data/Snails/SymbOutput_2023-07-06_064117_DwC-A/occurrences.csv"

mollusks <- read.csv(occurrences,fileEncoding = "latin1")

sgcn_mollusks <- mollusks %>%
  filter(scientificName %in% sgcnlist)

sgcn_mollusks$LastObs <- sgcn_mollusks$year
sgcn_mollusks$LastObs[is.na(sgcn_mollusks$LastObs)] <- "NO DATE"
sgcn_mollusks$DataSource <- "InvertEBase"
sgcn_mollusks$OccProb <- "k"

names(sgcn_mollusks)[names(sgcn_mollusks)=='scientificName'] <- 'SNAME'
names(sgcn_mollusks)[names(sgcn_mollusks)=='id'] <- 'DataID'
names(sgcn_mollusks)[names(sgcn_mollusks)=='decimalLongitude'] <- 'Longitude'
names(sgcn_mollusks)[names(sgcn_mollusks)=='decimalLatitude'] <- 'Latitude'

# delete the columns we don't need from the dataset
sgcn_mollusks <- sgcn_mollusks[c("SNAME","DataID","DataSource","Longitude","Latitude","LastObs","OccProb")]

#add in the SGCN fields
sgcn_mollusks <- merge(sgcn_mollusks, lu_sgcn, by="SNAME", all.x=TRUE)

sgcn_snails <- sgcn_mollusks %>%
  filter(str_detect(ELSeason, "IMGAS"))

# add in and calculate useCOA based on lastobs date
sgcn_snails$useCOA <- with(sgcn_snails, ifelse(sgcn_snails$LastObs >= cutoffyear & sgcn_snails$LastObs != "NO DATE", "y", "n"))

sgcn_snails <- sgcn_snails %>%
  drop_na(Latitude) %>%
  drop_na(Longitude)

# create a spatial layer
sgcn_snails_sf <- st_as_sf(sgcn_snails, coords=c("Longitude","Latitude"), crs = 4326)
sgcn_snails_sf <- st_transform(sgcn_snails_sf, crs=customalbers)
sgcn_snails_sf <- sgcn_snails_sf %>%
  select(final_fields)
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_InvertEBase"), sgcn_snails_sf, overwrite=TRUE) # write a feature class into the geodatabase
sgcn_snails_buffer_sf <- st_buffer(sgcn_snails_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_InvertEBase"), sgcn_snails_buffer_sf, overwrite=TRUE) # write a feature class into the geodatabase
