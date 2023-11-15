# #---------------------------------------------------------------------------------------------
# # Name: 1_SGCNcollector_BioticsCPP.r
# # Purpose: 
# # Author: Christopher Tracey
# # Created: 2019-03-11
# # Updated: 2018-03-23
# #
# # Updates:
# # insert date and info
# # * 2018-03-21 - get list of species that are in Biotics
# # * 2018-03-23 - export shapefiles
# #
# # To Do List/Future Ideas:
# # * 
# #---------------------------------------------------------------------------------------------
# 
# clear the environments
rm(list=ls())

# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("rinat", quietly = TRUE)) install.packages("rinat")
require(rinat)

source(here::here("scripts","00_PathsAndSettings.r"))

# load the r data file
load(file=updateData)

# read in SGCN data
loadSGCN()
# 
# a <- list()
# for(i in 1:length(sgcnlist[1:2])) {
#   a[i] <- get_inat_obs(taxon_name=sgcnlist[i], year = 2019)
# }
# 
# 
SGCNinat <- sgcnlist
SGCNinat <- sgcnlist[which(!sgcnlist %in% SGCN_bioticsCPP)]
SGCNinat <- SGCNinat[order(SGCNinat)]

a <- list()
k <- NULL
for(x in 1:length(SGCNinat)){
  #get metadata on the number of occurrences
  print(paste("getting metadata from iNaturalist for ",SGCNinat[x],".", sep="") )
  try(k <- get_inat_obs(taxon_name=SGCNinat[x], bounds=c(39.7198, -80.519891, 42.26986,	-74.689516) , geo=TRUE, meta=TRUE) ) # this step first queries iNat to see if there are any records present, if there are it actually downloads them.
  Sys.sleep(10) # this is too throttle our requests so we don't overload their servers
  if(is.list(k)){
    print(paste("There are ", k$meta$found, " records on iNaturalist", sep=""))
    if(k$meta$found>0){
      a[[x]] <- get_inat_obs(taxon_name=SGCNinat[x], bounds=c(39.7198, -80.519891, 42.26986,	-74.689516) , geo=TRUE, maxresults = k$meta$found) 
      k <- NULL
    } else {}
  } else {
    print("No records found")
  }
}

# convert to a data frame
inatrecs <- ldply(a)

# make a backup
write.csv(inatrecs, here::here("_data","input","SGCN_data","iNat",paste0("inatrecs_",format(Sys.Date(),"%Y%m%d"),".csv")), row.names = FALSE)
##### ONLY USE if you need to read in backup data
#inatrecs <- read.csv(here::here("_data","input","SGCN_data","iNat",paste0("inatrecsq2_2022.csv")), stringsAsFactors = FALSE)

# how many species did we get records for?
unique(inatrecs$scientific_name)
table(inatrecs$scientific_name,inatrecs$captive_cultivated)

# ones that match the sgcn
SGCNinat <- as.data.frame(SGCNinat)
names(SGCNinat) <- "SNAME"
SGCNinat$match <- "yes"


speciesmatch <- as.data.frame(unique(inatrecs$scientific_name)) 
names(speciesmatch) <- "SNAME"
speciesmatch <- merge(speciesmatch, SGCNinat, all.x=TRUE)
speciesmatch$SNAME <- as.character(speciesmatch$SNAME)

print("The following species do not match the original SGCN list:")
speciesmatch[which(is.na(speciesmatch$match)),]$SNAME

# REALLY NEED TO MAKE THIS AN "IF" CHECK!
inatrecs[which(inatrecs$scientific_name=="Apterodela unipunctata"),]$scientific_name <- "Cicindela unipunctata"
inatrecs[which(inatrecs$scientific_name=="Bonasa umbellus umbellus"),]$scientific_name <- "Bonasa umbellus"
inatrecs[which(inatrecs$scientific_name=="Buteo platypterus platypterus"),]$scientific_name <- "Buteo platypterus"
inatrecs[which(inatrecs$scientific_name=="Callophrys gryneus gryneus"),]$scientific_name <- "Callophrys gryneus"
inatrecs[which(inatrecs$scientific_name=="Certhia americana americana"),]$scientific_name <- "Certhia americana"
inatrecs[which(inatrecs$scientific_name=="Cicindela scutellaris rugifrons"),]$scientific_name <- "Cicindela scutellaris"
inatrecs[which(inatrecs$scientific_name=="Cygnus columbianus columbianus"),]$scientific_name <- "Cygnus columbianus"
inatrecs[which(inatrecs$scientific_name=="Danaus plexippus plexippus"),]$scientific_name <- "Danaus plexippus"
inatrecs[which(inatrecs$scientific_name=="Opheodrys aestivus aestivus"),]$scientific_name <- "Opheodrys aestivus"
inatrecs[which(inatrecs$scientific_name=="Pipilo erythrophthalmus erythrophthalmus"),]$scientific_name <- "Pipilo erythrophthalmus"
inatrecs[which(inatrecs$scientific_name=="Podiceps auritus cornutus"),]$scientific_name <- "Podiceps auritus"
inatrecs[which(inatrecs$scientific_name=="Salvelinus fontinalis fontinalis"),]$scientific_name <- "Salvelinus fontinalis"
inatrecs[which(inatrecs$scientific_name=="Satyrium favonius ontario"),]$scientific_name <- "Satyrium favonius"
inatrecs[which(inatrecs$scientific_name=="Spatula discors"),]$scientific_name <- "Anas discors"
inatrecs[which(inatrecs$scientific_name=="Spizella pusilla pusilla"),]$scientific_name <- "Spizella pusilla"
inatrecs[which(inatrecs$scientific_name=="Faxonius limosus"),]$scientific_name <- "Orconectes limosus"
inatrecs[which(inatrecs$scientific_name=="Phanogomphus borealis"),]$scientific_name <- "Gomphus borealis"
inatrecs[which(inatrecs$scientific_name=="Sthenopis pretiosus"),]$scientific_name <- "Sthenopis auratus"
inatrecs[which(inatrecs$scientific_name=="Spinus pinus pinus"),]$scientific_name <- "Spinus pinus"

unique(inatrecs$scientific_name)

# remove the E. invaria records as we have no idea...
inatrecs <- inatrecs[which(inatrecs$scientific_name!="Ephemerella invaria"),]

# remove captive cultivated records
inatrecs <- inatrecs[which(inatrecs$captive_cultivated!="true"),]

# remove obscured records
inatrecs1 <- inatrecs[which(inatrecs$geoprivacy!="obscured"),]
inatrecs1 <- inatrecs1[which(inatrecs1$taxon_geoprivacy!="open"|inatrecs1$taxon_geoprivacy!=""),]
inatrecs1 <- inatrecs1[which(inatrecs1$coordinates_obscured!="true"),]

# positional accuracy
summary(inatrecs1$positional_accuracy)
inatrecs1 <- inatrecs1[which(inatrecs1$positional_accuracy<=150),]

# not research grade
#inatgraph$resgrade <- ifelse(inatgraph$quality_grade!="research", "remove", "keep")
inatrecs1 <- inatrecs1[which(inatrecs1$quality_grade=="research"),]

#unique(inatrecs1$scientific_name)

# sort just to make it cleaner

inatrecs1 <- inatrecs1[order(inatrecs1$scientific_name),]

#bird season
inatrecs1$dayofyear <- yday(inatrecs1$datetime) ## Add day of year to eBird dataset based on the observation date.
inatrecs1birds <- inatrecs1[which(inatrecs1$iconic_taxon_name=="Aves"),]
inatrecs1nobirds <- inatrecs1[which(inatrecs1$iconic_taxon_name!="Aves"),]


birdseason <- read.csv(here::here("scripts","SGCN_DataCollection","lu_eBird_birdseason.csv"), colClasses = c("character","character","integer","integer"),stringsAsFactors=FALSE)

### assign a migration date to each ebird observation.
inatrecs1birds$season <- NA
for(i in 1:nrow(birdseason)){
  comname <- birdseason[i,1]
  season <- birdseason[i,2]
  startdate <- birdseason[i,3]
  enddate <- birdseason[i,4]
  inatrecs1birds$season[inatrecs1birds$common_name==comname & inatrecs1birds$dayofyear>startdate & inatrecs1birds$dayofyear<enddate] <- as.character(season)
}

table(inatrecs1birds$scientific_name,inatrecs1birds$season)

inatrecs1birds <- inatrecs1birds[!is.na(inatrecs1birds$season),]

inatrecs1nobirds$season <- NA

inatrecs2 <- rbind(inatrecs1birds, inatrecs1nobirds)


# add additional fields 
inatrecs2$DataSource <- "iNaturalist"
inatrecs2$OccProb <- "k"
names(inatrecs2)[names(inatrecs2)=='scientific_name'] <- 'SNAME'
names(inatrecs2)[names(inatrecs2)=='common_name'] <- 'SCOMNAME'
names(inatrecs2)[names(inatrecs2)=='url'] <- 'DataID'

inatrecs2$LastObs <- year(parse_date_time(inatrecs2$observed_on, orders=c("ymd","mdy")))

inatrecs2 <- inatrecs2[which(!is.na(inatrecs2$LastObs)),] # deletes one without a year

inatrecs2$useCOA <- NA
inatrecs2$useCOA <- with(inatrecs2, ifelse(inatrecs2$LastObs >= cutoffyear, "y", "n"))

# drops the unneeded columns. 
inatrecs2 <- inatrecs2[c("SNAME","DataID","longitude","latitude","LastObs","useCOA","DataSource","OccProb","season")]

inatrecs2$season <- substr(inatrecs2$season, 1, 1)
inatrecs2$season <- tidyr::replace_na(inatrecs2$season, "y")

#add in the SGCN fields
inatrecs2 <- merge(inatrecs2, lu_sgcn, by="SNAME", all.x=TRUE)
inatrecs2$ELSeason <- paste(inatrecs2$ELCODE, inatrecs2$season, sep="_")

# limit by SGCN
inatrecs3 <- inatrecs2[which(inatrecs2$ELSeason %in% lu_sgcn$ELSeason),]

# drop species that we don't want to use Ebird data for as
drop_from_eBird <- c("ABNKC10010_b", "ABNNM10020_b", "ABNGA11010_b", "ABNNM08070_b", "ABNGA04040_b", "ABNKC12060_b", "ABNKC01010_b", "ABNKD06070_b", "ABNNB03070_b", "ABNSB13040_b", "ABNGA13010_b")
inatrecs3 <- inatrecs3[which(!inatrecs3 %in% drop_from_eBird) ] 

# field alignment
names(inatrecs3)[names(inatrecs3)=='season'] <- 'SeasonCode'

inat_sf <- st_as_sf(inatrecs3, coords=c("longitude","latitude"), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
inat_sf <- st_transform(inat_sf, crs=customalbers) # reproject to the custom albers
inat_sf <- inat_sf[final_fields]
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","srcpt_inat"), inat_sf, overwrite=TRUE) # write a feature class into the geodatabase
inat_buffer <- st_buffer(inat_sf, dist=100) # buffer by 100m
arc.write(path=here::here("_data","output",updateName,"SGCN.gdb","final_inat"), inat_buffer, overwrite=TRUE) # write a feature class into the geodatabase

unique(inatrecs3$SNAME)
table(inatrecs3$SNAME,inatrecs3$TaxaGroup)
