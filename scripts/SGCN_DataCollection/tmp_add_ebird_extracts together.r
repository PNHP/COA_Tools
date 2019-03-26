ebird_old <- read.delim(here("_data","input","SGCN_data","eBird","ebd_US-PA_199101_201612_relAug-2016.txt"), stringsAsFactors=FALSE)
ebird_new <- read.delim(here("_data","input","SGCN_data","eBird","ebd_US-PA_201612_201810_relMay-2018.txt"), stringsAsFactors=FALSE)

ebird_all <- rbind(ebird_old, ebird_new)

names(ebird_old)
names(ebird_new)

setdiff(names(ebird_old), names(ebird_new))
setdiff(names(ebird_new), names(ebird_old))

names(ebird_old)[names(ebird_old)=='COUNTRY_CODE'] <- 'COUNTRY.CODE'
names(ebird_old)[names(ebird_old)=='STATE_PROVINCE'] <- 'STATE'
names(ebird_old)[names(ebird_old)=='SUBNATIONAL1_CODE'] <- 'STATE.CODE'
names(ebird_old)[names(ebird_old)=='SUBNATIONAL2_CODE'] <- 'COUNTY.CODE'
ebird_old$FIRST.NAME <- NULL
ebird_old$LAST.NAME <- NULL


ebird_new$LAST.EDITED.DATE <- NULL
ebird_new$BREEDING.BIRD.ATLAS.CATEGORY <- NULL
ebird_new$USFWS.CODE <- NULL
ebird_new$PROTOCOL.CODE <- NULL
ebird_new$HAS.MEDIA <- NULL
#delete "LAST.EDITED.DATE" "BREEDING.BIRD.ATLAS.CATEGORY" "USFWS.CODE" "PROTOCOL.CODE" "HAS.MEDIA"
#taken care of in old "COUNTRY.CODE" "STATE" 

ebird_all <- rbind(ebird_old, ebird_new)

write.csv(ebird_all, "ebird_all.csv")

#------------------------------------------------------

ebird_skim <- read.csv(here("_data","input","SGCN_data","eBird","ebird_all.txt"), stringsAsFactors=FALSE)
names(ebird_skim) <- tolower(names(ebird_skim))
write.table(ebird_skim, here("_data","input","SGCN_data","eBird","ebird_all_tab.txt"), sep="\t")
