#-------------------------------------------------------------------------------
# Name:        1_insertSGCN.r
# Purpose:     Create an empty, new COA databases
# Author:      Christopher Tracey
# Created:     2019-02-14
# Updated:     2019-02-14
#
# To Do List/Future ideas:
# * modify to run off the lu_sgcn data on the arc server
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))

## NEW API BASED SCRIPTS ##
library(httr)
library(jsonlite)
library(purrr)
library(data.table)
library(dplyr)

source(here::here("scripts","00a_APIsettings.r"))

httr::set_config(config(ssl_verifypeer=0L, ssl_verifyhost=0L))
a <- POST("https://pgcapigw.beta.pa.gov:9443/oauth2/token",
          body=list(grant_type="password",
                    username=var_username,
                    password=var_password,
                    client_id=var_client_id,
                    client_secret=var_client_secret),
          encode="form")

if(a$status==200){
  cat("Connected to the API, you're good to go!")
} else(
  cat("API connection failed, try again!")
)

a.df <- as.data.frame(fromJSON(content(a, type="text")))
get_resp <- GET("http://pgcapigw.beta.pa.gov/wapapi/1.0/plan/2015-2025",
                add_headers("Content-Type"="application/json",
                            Accept="application/+json",
                            "Authorization"=paste("Bearer", as.character(a.df$access_token))
                            ))
b <- content(get_resp, "text")
parsed <- jsonlite::fromJSON(b, simplifyVector=FALSE, flatten=TRUE)
wapdata <- parsed$Plan

rm(a, a.df, b, get_resp, parsed, var_client_id, var_client_secret, var_username, var_password) # remove so they aren't hanging around 

# process into data tables
dt_list <- map(wapdata, as.data.table)
warnings()

dt <- rbindlist(dt_list, fill=TRUE, idcol=FALSE)
dt <- as.data.frame(dt)

rm(wapdata, dt_list)

dt <- dt %>% # change column names to match what we use
  dplyr::rename(
    SCOMNAME = CommonName,
    SNAME = ScientificName,
    GRANK = GRank,
    SRANK = SRank
  )

# get a vector of non list columns
nonlistcol <- names(sapply(dt, class)[!sapply(dt, class) %in% c("list")])

####
lu_sgcn <- dt[c("SpeciesId","Taxon","SubTaxon","SCOMNAME","SNAME","ELSubId","ELCode","Season","ELSeason","Sensitivity","GRANK","GRankYear","SRANK","SRankYear")]
lu_sgcn <- unique(lu_sgcn)
lu_sgcn <- dplyr::rename(lu_sgcn, ELCODE=ELCode, SeasonCode=Season, SENSITV_SP=Sensitivity)
lu_sgcn <- lu_sgcn %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(ELCODE), is.na))
# update taxa groups to deal with differences in the WAP database
taxagroups <- read.csv(here::here("_data","input","lu_SGCN_taxagroups.csv"), stringsAsFactors = FALSE)
taxagroups <- unique(taxagroups[c("ELCODE","TaxaGroup","TaxaDisplay")])
lu_sgcn <- merge(x=lu_sgcn, y=taxagroups, by="ELCODE", all.x=TRUE)
lu_sgcn <- lu_sgcn[c("ELCODE","SNAME","SCOMNAME","SeasonCode","ELSeason","GRANK","SRANK","SENSITV_SP","Taxon","SubTaxon","TaxaGroup","TaxaDisplay")]


# QC to make sure that the ELCODES match the first part of the ELSeason code.
if(length(setdiff(lu_sgcn$ELCODE, gsub("(.+?)(\\_.*)", "\\1", lu_sgcn$ELSeason)))==0){
  print("ELCODEs and ELSeason strings match. You're good to go!")
} else {
  print(paste("Codes for ", setdiff(lu_sgcn$ELCODE, gsub("(.+?)(\\_.*)", "\\1", lu_sgcn$ELSeason)), " do not match;", sep=""))
}

# check for leading/trailing whitespace
lu_sgcn$SNAME <- trimws(lu_sgcn$SNAME, which="both")
lu_sgcn$SCOMNAME <- trimws(lu_sgcn$SCOMNAME, which="both")
lu_sgcn$ELSeason <- trimws(lu_sgcn$ELSeason, which="both")

################################################################
# TESTING PURPOSES!!!!!!########################################
################################################################
lu_sgcn_2022q1 <- "E:/COA/COA_Tools/_data/input/lu_SGCN_update2022q1.csv"
lu_sgcn_2022q1 <- read.csv(lu_sgcn_2022q1)

sgcn_compare <- merge(lu_sgcn, lu_sgcn_2022q1, by = "ELSeason", all = TRUE, suffixes = c("","_2022"))
sgcn_compare <- sgcn_compare %>%
  mutate(sname_match  = if_else(SNAME==SNAME_2022, "y", "n"),
         scomname_match = if_else(SCOMNAME==SCOMNAME_2022, "y", "n"),
         grank_match = if_else(GRANK==GRANK_2022,"y","n"),
         srank_match = if_else(SRANK==SRANK_2022,"y","n"))


write.csv(sgcn_compare,'H:/Scripts/COA_Tools/scripts/COA_API_PlaySpace/lu_sgcn_API_compare.csv',row.names=TRUE)

################################################################
# DONE WITH TESTING!!!!!########################################
################################################################

writeSQLite(lu_sgcn, "lu_sgcn") # write to the database


#########################################################################################
# actions
lu_actions <- dt[c(nonlistcol,'Actions')]
lu_actions_unlisted <- rbindlist(lu_actions$Actions, fill=TRUE, idcol="id")
lu_actions$id <- seq.int(nrow(lu_actions))
lu_actions <- left_join(lu_actions, lu_actions_unlisted, by="id")
lu_actions$Actions <- NULL # delete unneeded columns
lu_actions$id <- NULL # delete unneeded columns
rm(lu_actions_unlisted) # delete temporary data frame

# clean up some things from the actions
lu_actionsLevel2 <- lu_actions[,c("SpeciesId","ELSeason","SNAME","ActionId","IUCNThreatLv1","ThreatCategory","EditedThreat","ActionLv1","ActionCategory1",  "ActionLv2","ActionCategory2","COATool_ActionsFINAL","AgencySpecific","ActionPriority","CombActLocs","RefIds")]
lu_actionsLevel2 <- lu_actionsLevel2 %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(IUCNThreatLv1,ThreatCategory,EditedThreat,ActionLv1,ActionCategory1,ActionLv2,ActionCategory2,COATool_ActionsFINAL), is.na))
lu_actionsLevel2 <- unique(lu_actionsLevel2)
lu_actionsLevel2 <- dplyr::rename(lu_actionsLevel2, RefID = RefIds)
lu_actionsLevel2 <- dplyr::rename(lu_actionsLevel2, ActionLv1 = ActionLv1)
lu_actionsLevel2 <- dplyr::rename(lu_actionsLevel2, ActionLV2 = ActionLv2)
writeSQLite(lu_actionsLevel2, "lu_actionsLevel2") # write to the database

# action locations
lu_actions_loc <- lu_actions[,c("SpeciesId","ActionId","ELSeason","Locations")]
lu_actions_loc_unlisted <- rbindlist(lu_actions_loc$Locations, fill = T, idcol = "id") # unlist nested list with id
lu_actions_loc$id <- seq.int(nrow(lu_actions_loc)) # create same id in remaining data frame
lu_actions_loc <- left_join(lu_actions_loc, lu_actions_loc_unlisted, by = "id") # join data frame with unlisted list
lu_actions_loc$id <- NULL # get rid of unnecessary columns
lu_actions_loc$Locations <- NULL # get rid of unnecessary columns
rm(lu_actions_loc_unlisted)
lu_actions_loc <- unique(lu_actions_loc)
lu_actions_loc <- lu_actions_loc %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(PhysiographicProvince,PhysiographicSection,HUC4Watershed,HUC8Watershed,HUC10Watershed), is.na))
writeSQLite(lu_actions_loc, "lu_ActionLocations") # write to the database
rm(lu_actions)

#########################################################################################
# surveyNeeds
lu_surveyNeeds <- dt[,c(nonlistcol,'Surveys')]
lu_surveyNeeds_unlisted <- rbindlist(lu_surveyNeeds$Surveys , fill = T, idcol = "id") # unlist nested list with id
lu_surveyNeeds$id <- seq.int(nrow(lu_surveyNeeds)) # create same id in remaining data frame
lu_surveyNeeds <- left_join(lu_surveyNeeds, lu_surveyNeeds_unlisted, by = "id") # join data frame with unlisted list
lu_surveyNeeds <- lu_surveyNeeds[,c("SpeciesId","ELSeason","SNAME","NumSurveyQuestion_Edited","AgencySpecific","SurveyID","Priority")]
rm(lu_surveyNeeds_unlisted)
lu_surveyNeeds <- unique(lu_surveyNeeds)
lu_surveyNeeds <- lu_surveyNeeds %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(NumSurveyQuestion_Edited,AgencySpecific,SurveyID,Priority), is.na))
writeSQLite(lu_surveyNeeds, "lu_SGCNsurvey") # write to the database
trackfiles("Survey Needs", paste("downloaded from API on ", Sys.Date(), sep="")) # write to file tracker

#########################################################################################
# researchNeeds
lu_researchNeeds <- dt[,c(nonlistcol,'ResearchNeeds')]
lu_researchNeeds_unlisted <- rbindlist(lu_researchNeeds$ResearchNeeds , fill = T, idcol = "id") # unlist nested list with id
lu_researchNeeds$id <- seq.int(nrow(lu_researchNeeds)) # create same id in remaining data frame
lu_researchNeeds <- left_join(lu_researchNeeds, lu_researchNeeds_unlisted, by = "id") # join data frame with unlisted list
lu_researchNeeds <- lu_researchNeeds[,c("SpeciesId","ELSeason","SNAME","ResearchQues_Edited","AgencySpecific","ResearchID","Priority")]
rm(lu_researchNeeds_unlisted)
lu_researchNeeds <- unique(lu_researchNeeds)
lu_researchNeeds <- lu_researchNeeds %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(ResearchQues_Edited,AgencySpecific,ResearchID,Priority), is.na))
writeSQLite(lu_researchNeeds, "lu_SGCNresearch") # write to the database
trackfiles("Research Needs", paste("downloaded from API on ", Sys.Date(), sep="")) # write to file tracker

#########################################################################################
# Specific Habitat Requirements
lu_HabitatReq <- dt[,c(nonlistcol,'HabitatRequirements')] 
lu_HabitatReq_unlisted <- rbindlist(lu_HabitatReq$HabitatRequirements, fill = T, idcol = "id") # unlist nested list with id
lu_HabitatReq$id <- seq.int(nrow(lu_HabitatReq)) # create same id in remaining data frame
lu_HabitatReq <- left_join(lu_HabitatReq, lu_HabitatReq_unlisted, by = "id") # join data frame with unlisted list
lu_HabitatReq <- lu_HabitatReq[,c("ELSeason","SNAME","Formation","Macrogroup","HabitatSystem","SpecificHabitatRequirements")] # "HabitatRequirementId",
rm(lu_HabitatReq_unlisted)
lu_HabitatReq <- unique(lu_HabitatReq)

# do the specific habitat requirements
lu_SpecificHabitatReq <- lu_HabitatReq[,c("ELSeason","SNAME","SpecificHabitatRequirements")] 
print('The following SGCN do not have specific habitat requirements.')
lu_SpecificHabitatReq[which(is.na(lu_SpecificHabitatReq$SpecificHabitatRequirements)),] # get a list of sgcn of species without specific habitat requirements
lu_SpecificHabitatReq <- lu_SpecificHabitatReq %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(SpecificHabitatRequirements), is.na))
writeSQLite(lu_SpecificHabitatReq, "lu_SpecificHabitatReq") # write to the database

# do the Primary Macrogroups
lu_PrimaryMacrogroup <- lu_HabitatReq[,c("ELSeason","SNAME","Formation","Macrogroup","HabitatSystem")] 
print('The following SGCN do not have specific habitat requirements.')
lu_PrimaryMacrogroup[which(is.na(lu_PrimaryMacrogroup$Macrogroup)),] # get a list of sgcn of species without specific habitat requirements
lu_PrimaryMacrogroup <- lu_PrimaryMacrogroup %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(Formation,Macrogroup,HabitatSystem), is.na))
lu_PrimaryMacrogroup$PrimMacro <- lu_PrimaryMacrogroup$Macrogroup # this adds a field to be compatible with the COA tool. It's a little redundant, but it should be ok
writeSQLite(lu_PrimaryMacrogroup, "lu_PrimaryMacrogroup") # write to the database
rm(lu_HabitatReq)

#########################################################################################
# Ref
lu_References <- dt[,c(nonlistcol,'References')]
lu_References_unlisted <- rbindlist(lu_References$References, fill = T, idcol = "id") # unlist nested list with id
lu_References$id <- seq.int(nrow(lu_References)) # create same id in remaining data frame
lu_References <- left_join(lu_References, lu_References_unlisted, by = "id") # join data frame with unlisted list
lu_References <- lu_References[,c("RefID","REF_NAME","Source","Link")] # "SpeciesId","ELSeason","SNAME",
rm(lu_References_unlisted)
lu_References <- unique(lu_References)
names(lu_References)[names(lu_References) == 'RefID'] <- 'ReferenceID' # rename problematic fields that don't match the rest of the COA tool
names(lu_References)[names(lu_References) == 'Link'] <- 'LINK' # rename problematic fields that don't match the rest of the COA tool
lu_References <- lu_References %>% # delete rows were all the reference columns are unpopulated 
  filter(!if_all(c(ReferenceID,REF_NAME,Source,LINK), is.na))
lu_References <- unique(lu_References)
for(l in 1:nrow(lu_References)){ # check if url exist 
  if(isFALSE(http_error(lu_References$LINK[l]))){
    print(paste("url for -",lu_References$REF_NAME[l],"- is valid"), sep=" ")
  } else if(isTRUE(http_error(lu_References$LINK[l]))){
    print(paste("url for -",lu_References$REF_NAME[l],"- is NOT VALID"), sep=" ")
  }
}

writeSQLite(lu_References, "lu_BPreference") # write to the database


####################################################################################################################
# write to file tracker
trackfiles("SGCN List", paste("downloaded from API on ", Sys.Date(), sep=""))

# delete the unneeded layers
rm(dt)





################################





# deal with the malformed SRANKs. I wishi this was handled differently!
lu_sgcn$SeasonAlt <- replace(lu_sgcn$Season, lu_sgcn$Season=="w", "n") 
lu_sgcn$SRANKalt <- toupper(apply(lu_sgcn[c("SRANK", "SeasonAlt")], 1, function(x) paste0(x[x!="y"], collapse=""))) #   lu_sgcn$SRANK
lu_sgcn$SeasonAlt <- NULL


# compare to the ET
#get the most recent ET
arc.check_portal()  # may need to update bridge to most recent version if it crashes: https://github.com/R-ArcGIS/r-bridge/issues/46
ET <- arc.open(paste0(bioticsFeatServ_path,"/5"))  # 5 is the number of the ET 
# NOTE YOU MAY GET AN ERROR about missing DLL's; this is fine!
ET <- arc.select(ET, c("ELSUBID","ELCODE","SNAME","SCOMNAME","GRANK","SRANK","SRANK_CHGDT","SRANK_RVWDT","EO_TRACK","SGCN","SENSITV_SP"), where_clause = "SGCN IS NOT NULL") # , where_clause="SGCN='Y'"
# write to file tracker  REMOVED for now

SGCNtest <- merge(lu_sgcn[c("ELCode","SNAME","SCOMNAME","GRANK","SRANK","SRANKalt")], ET[c("ELCODE","SNAME","SCOMNAME","GRANK","SRANK")], by.x="ELCode", by.y="ELCODE", all.x=TRUE)

# compare elcodes
if(length(SGCNtest[which(is.na(SGCNtest$SNAME.y)),])>0){
  print("The following species in the lu_SGCN table did not find a matching ELCODE in Biotics and needs to be fixed.")
  print(SGCNtest[which(is.na(SGCNtest$SNAME.y)),"SNAME.x"])
  print(paste("A file named badELCODEs_",updateName,".csv has been saved in the output directory", sep=""))
  write.csv(SGCNtest[which(is.na(SGCNtest$SNAME.y)),], here::here("_data","output",updateName,paste("badELCODEs_",updateName,".csv")), row.names=FALSE)
} else {
  print("No mismatched ELCODES---you are good to go and hopefully there will be less trauma during this update...")
}

#compare g-ranks
SGCNtest$matchGRANK <- ifelse(SGCNtest$GRANK.x==SGCNtest$GRANK.y,"yes","no")
if(all(SGCNtest$matchGRANK=="yes")){
  print("GRANK strings match. You're good to go!")
} else {
  print(paste("GRANKS for ", SGCNtest[which(SGCNtest$matchGRANK=="no"),"SNAME.x"] , " do not match;", sep=""))
}

# compare s-ranks
SGCNtest <- within(SGCNtest, matchSRANK1 <- mapply(grepl, SRANKalt, SRANK.y, ignore.case=TRUE))
SGCNtest$matchSRANK <- ifelse(SGCNtest$matchSRANK1, "yes", "no")
SGCNtest$matchSRANK1 <- NULL
if(all(SGCNtest$matchSRANK=="yes")){
  print("SRANK strings match. You're good to go!")
} else {
  print(paste("SRANKS for ", SGCNtest[which(SGCNtest$matchSRANK=="no"),"SNAME.x"] , " do not match;", sep=""))
}

SGCNtest <- SGCNtest[which(SGCNtest$matchGRANK=="no"|SGCNtest$matchSRANK=="no"),] # edit this down to just the changes
SGCNtest$ELSUBID <- NULL
SGCNtest$EO_TRACK <- NULL
SGCNtest$SGCN <- NULL
SGCNtest$SENSITV_SP <- NULL

names(SGCNtest) <- c("ELCODE","SGCN_SNAME","SGCN_SCOMNAME","SGCN_GRANK","SGCN_SRANK","ET_SNAME","ET_SCOMNAME","ET_GRANK","ET_SRANK","ET_SRANK.CHANGE.DATE","ET_SRANK.REVIEW.DATE","matchGRANK","matchSRANK") 

SGCNtest$Name <- sub('.', '', updateName) #insert the update name and remove the first character

dbTracking <- dbConnect(SQLite(), dbname=trackingdatabasename) # connect to the database
dbExecute(dbTracking, paste("DELETE FROM changed_ranks WHERE Name='",sub('.', '', updateName),"'", sep="")) # 
dbAppendTable(dbTracking, "changed_ranks", SGCNtest, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(dbTracking) # disconnect the db



###########################################
## Taxa Group import
taxagrp <- read.csv(here::here("_data","input","lu_taxagrp.csv"), stringsAsFactors=FALSE)
taxagrp$OID <- NULL

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "lu_taxagrp", taxagrp, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db
rm(taxagrp)

