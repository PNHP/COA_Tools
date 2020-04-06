
# load packages
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
require(lubridate)
if (!requireNamespace("auk", quietly = TRUE)) install.packages("auk")
require(auk)
if (!requireNamespace("reshape", quietly = TRUE)) install.packages("reshape")
require(reshape)
if (!requireNamespace("plyr", quietly = TRUE)) install.packages("plyr")
require(plyr)
if (!requireNamespace("dplyr", quietly=TRUE)) install.packages("dplyr")
require(dplyr)

# load the arcgis license
arc.check_product() 

# update name
updateName <- "_update202004"

# create a directory for this update unless it already exists
ifelse(!dir.exists(here::here("_data","output",updateName)), dir.create(here::here("_data","output",updateName)), FALSE)

# rdata  file
updateData <- here::here("_data","output",updateName,paste(updateName, "RData", sep="."))

# output database name
databasename <- here::here("_data","output",updateName,"coa_bridgetest.sqlite")

# paths to biotics shapefiles
biotics_path <- "W:/Heritage/Heritage_Data/Biotics_datasets.gdb"
biotics_crosswalk <- here::here("_data","input","crosswalk_BioticsSWAP.csv") # note that nine species are not in Biotics at all

# paths to to server path to access cpp shapefiles, we connect to the cpp file in '02_SGCNcollector_BioticsCPP.r'
serverPath <- paste("C:/Users/",Sys.getenv("USERNAME"),"/AppData/Roaming/ESRI/ArcGISPro/Favorites/PNHP.PGH-gis0.sde/",sep="")

# cutoff year for records
cutoffyear <- as.integer(format(Sys.Date(), "%Y")) - 25  # keep data that's only within 25 years
cutoffyearK <- as.integer(format(Sys.Date(), "%Y")) - 25  # keep data that's only within 25 years
cutoffyearL <- 1980  # keep data that's only within 25 years

# final fields for arcgis
final_fields <- c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","DataSource","DataID","OccProb","LastObs","useCOA","TaxaGroup","geometry") 

# custom albers projection
customalbers <- "+proj=aea +lat_1=40 +lat_2=42 +lat_0=39 +lon_0=-78 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs "

# function to load SGCN species list
loadSGCN <- function(taxagroup) {
  if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
    require(RSQLite)
  db <- dbConnect(SQLite(), dbname = databasename)
  SQLquery <- paste("SELECT ELCODE, SNAME, SCOMNAME, TaxaGroup, SeasonCode, ELSeason"," FROM lu_sgcn ")
  lu_sgcn <- dbGetQuery(db, statement = SQLquery)
  if(missing(taxagroup)){
    lu_sgcn <<- lu_sgcn
    sgcnlist <<- unique(lu_sgcn$SNAME)
  } else {
    lu_sgcn <<- lu_sgcn[which(lu_sgcn$TaxaGroup==taxagroup),] # limit by taxagroup code
    sgcnlist <<- unique(lu_sgcn$SNAME)
  }
  dbDisconnect(db) # disconnect the db
}

