library(here)
library(tidyr)

habitat <- read.csv(here("PNHP_HabitatQ.csv"), stringsAsFactors=FALSE)

habitat <- habitat[c("SWAPCommonName","SWAPScientificName","PrimMacro","ELCODE","Season")]
# export to csv for manual editing
write.csv(habitat,"habitat.csv")

habitat <- read.csv(here("habitat.csv"), stringsAsFactors=FALSE)


habitat$New.Season <- gsub("^$","year-round", habitat$New.Season)

habitat$ELCODE[habitat$SWAPScientificName=="Geolycosa turricola"] <- "ILARA28010"
habitat$ELCODE[habitat$SWAPScientificName=="Limnophila alleni"] <- "IIDIPL0010"
habitat$ELCODE[habitat$SWAPScientificName=="Limnophila marchandi"] <- "IIDIPL0020"
habitat$ELCODE[habitat$SWAPScientificName=="Tipula williamsiana"] <- "IIDIP25100"
habitat$ELCODE[habitat$SWAPScientificName=="Tethida barda"] <- "IICOL03010x"
habitat$ELCODE[habitat$SWAPScientificName=="Gammarus cohabitus"] <- "ICMAL10120"
habitat$ELCODE[habitat$SWAPScientificName=="Pseudanophthalmus sp. nov."] <- "IICOL4EY90"
habitat$ELCODE[habitat$SWAPScientificName=="Oreonetides beattyi"] <- "ILARA10030"
habitat$ELCODE[habitat$SWAPScientificName=="Lymnaea catascopium"] <- "IMGASL5050"
habitat$ELCODE[habitat$SWAPScientificName=="Aplexa hypnorum"] <- "IMGASL8010"

habitat$PrimMacro[habitat$SWAPScientificName=="Podiceps grisegena"] <- "Lakes"
habitat$PrimMacro[habitat$SWAPScientificName=="Glyptemys muhlenbergii"] <- "Emergent Marsh"

habitat$PrimMacro <- gsub("Lakes", "Lakes and Ponds",habitat$PrimMacro)
habitat$PrimMacro <- gsub("Lakes and Ponds and Ponds", "Lakes and Ponds",habitat$PrimMacro)

# calculate ELSEason
habitat$ELSeason <- paste(habitat$ELCODE,tolower(substr(habitat$New.Season,1,1)),sep="_")

habitat <- habitat[c("ELSeason","PrimMacro")]
habitat <- habitat[which(habitat$PrimMacro!="--"),]

write.csv(habitat,"lu_PrimaryMacrogroup.csv", row.names=FALSE)
