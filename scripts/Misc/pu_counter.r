# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))


# read in SGCN data
loadSGCN()


db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
sgcnXpu <- dbReadTable(db, "lu_sgcnXpu_all") # write the table to the sqlite
dbDisconnect(db) # disconnect the db

a <- table(sgcnXpu$unique_id)
a1 <- as.data.frame(a)
a1a <- a1[which(a1$Freq==1),]

pulist <- as.character(a1a$Var1)

pu10 <- arc.open("E:/COA_Tools/_data/templates/SGCN_blank.gdb/PlanningUnit_Hex10acre")
pu10 <- arc.select(pu10) 
pu10a <- arc.data2sf(pu10)



norecords <- setdiff(as.character(sgcnXpu$unique_id), as.character(a1$Var1) )
norecords <- pu10[which(!(pu10$unique_id %in% a1$Var1)),]

paste("unique_id IN ", paste(sQuote(pulist), collapse=", "), sep="")
