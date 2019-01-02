
actions <- read.csv("COA_ThreatsActionsTemplate_v3.4.csv")

# rename two problematic fields

names(actions)[names(actions) == 'X'] <- 'SpeciesID'
names(actions)[names(actions) == 'Reference.'] <- 'ReferenceID'


write.csv(actions, "lu_actions.csv", row.names=FALSE)

##################################
#references

references <- read.csv("lu_BPreference.csv", stringsAsFactors=FALSE)
names(references)[names(references) == 'REFERENCE.'] <- 'ReferenceID'
names(references)[names(references) == 'REFERENCE.NAME'] <- 'REF_NAME'
references$ActionCategory1 <- NULL
references$ActionCategory2 <- NULL

write.csv(references,"lu_BPreference.csv", row.names=FALSE)


