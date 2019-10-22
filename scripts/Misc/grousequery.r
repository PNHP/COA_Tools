if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
  require(here)
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
  require(RSQLite)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
  require(arcgisbinding)

# Set input paths ----
databasename <- "coa_bridgetest.sqlite" 
databasename <- here::here("_data","output",databasename)

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
#pu_grouse <- dbReadTable(db, )
  focalspdata <- dbGetQuery(db, "SELECT DISTINCT unique_id FROM lu_sgcnXpu_all WHERE ELSeason='ABNLC11010_b' ")
  pudata <- dbGetQuery(db, "SELECT ELSeason, unique_id, OccProb FROM lu_sgcnXpu_all WHERE unique_id IN (SELECT DISTINCT unique_id FROM lu_sgcnXpu_all WHERE ELSeason='ABNLC11010_b')")
  sgcn <-  dbGetQuery(db, "SELECT ELSeason, SNAME, SCOMNAME FROM lu_sgcn WHERE TaxaGroup='AB'")
dbDisconnect(db) # disconnect the db
                     

pudata <- pudata[which(pudata$ELSeason!="ABNLC11010_b"),]

pudata_unique <- unique(pudata)

sgcn <- sgcn[which(substr(sgcn$ELSeason,12,12)=="b"),]
                     
AssocSpData <- merge(pudata, sgcn, by="ELSeason")
                     
AssocSpData_Counts <- as.data.frame.matrix(table(AssocSpData$SCOMNAME,AssocSpData$OccProb))
                     
                     
# INTO OUTFILE 
write.csv(AssocSpData_Counts, "GrouseAssocSpecies1.csv") # , row.names=FALSE 

# GIS
arc.check_product()
# open the NHA feature class and select and NHA
serverPath <- paste("C:/Users/",Sys.getenv("USERNAME"),"/AppData/Roaming/ESRI/ArcGISPro/Favorites/COA.PGH-GIS0.sde/",sep="")

pu <- arc.open(paste(serverPath,"COA.DBO.PlanningUnit_Hex10acre", sep=""))

selected_pu <- arc.select(pu)  #nha, where_clause="SITE_NAME='Hogback Barrens' AND STATUS='C'" Carnahan Run at Stitts Run Road  AND STATUS ='NP'
#WHERE FIPS_COUNT IN (", paste(toString(sQuote(county_FIPS)), collapse = ", "), ")")

selected_pu1 <- selected_pu[which(selected_pu$unique_id %in% focalspdata$unique_id),] 

a <- arc.data2sf(selected_pu1)

library(sf)
st_write(a, "grouse_pu.shp")
