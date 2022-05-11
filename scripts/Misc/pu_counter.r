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
a1a <- merge(a1a, sgcnXpu, by.x="Var1", by.y="unique_id", all.x=TRUE)
a1a <- merge(a1a, lu_sgcn, by.x="ELSeason", all.x=TRUE)
a1a <- merge(a1a, ET[c("SCIENTIFIC.NAME", "SENSITIVE.SPECIES")], by.x="SNAME", by.y="SCIENTIFIC.NAME", all.x=TRUE)
a1a <- a1a[which(a1a$SENSITIVE.SPECIES=="Y"),]

pulist <- as.character(a1a$Var1)

pu10 <- arc.open("E:/COA_Tools/_data/templates/SGCN_blank.gdb/PlanningUnit_Hex10acre")
pu10 <- arc.select(pu10) 
pu10a <- arc.data2sf(pu10)


# sensitive species
sensalone <- pu10[which(pu10$unique_id %in% a1a$Var1),]
arc.write(path=here::here("PU_Sens1record.shp"), sensalone, overwrite=TRUE)

#####
norecords <- setdiff(as.character(sgcnXpu$unique_id), as.character(a1$Var1) )
norecords <- pu10[which(!(pu10$unique_id %in% a1$Var1)),]

arc.write(path=here::here("PU_norecords.shp"), norecords, overwrite=TRUE)

