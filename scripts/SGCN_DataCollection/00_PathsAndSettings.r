

# load the arcgis license
arc.check_product() 

# update name
updateName <- "Fall2019"
# rdata  file
updateData <- here::here("_data","output",paste(updateName, "RData", sep="."))

# output database name
databasename <- here::here("_data","output","coa_bridgetest.sqlite")

# rdata file name

# paths to biotics shapefiles
biotics_path <- "W:/Heritage/Heritage_Data/Biotics_datasets.gdb"
biotics_crosswalk <- here::here("_data","input","crosswalk_BioticsSWAP.csv") # note that nine species are not in Biotics at all

# paths to cpp shapefiles
cpp_path <- "W:/Heritage/Heritage_Projects/CPP/CPP_Pittsburgh.gdb"

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
  SQLquery <- paste("SELECT ELCODE, SNAME, SCOMNAME, TaxaGroup, ELSeason"," FROM lu_sgcn ")
  lu_sgcn <- dbGetQuery(db, statement = SQLquery)
  if(missing(taxagroup)){
    lu_sgcn <<- lu_sgcn
  } else {
    lu_sgcn <<- lu_sgcn[which(lu_sgcn$TaxaGroup==taxagroup),] # limit by taxagroup code
  }
  dbDisconnect(db) # disconnect the db
  sgcnlist <<- unique(lu_sgcn$SNAME)
}

