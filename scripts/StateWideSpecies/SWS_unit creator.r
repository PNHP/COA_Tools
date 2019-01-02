


# load packages
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
require(RSQLite)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("reshape", quietly = TRUE)) install.packages("reshape")
require(reshape)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)

# load the arcgis license
arc.check_product()

# Set input paths ----
databasename <- "E:/coa2/coa_bridgetest.sqlite" 
#working_directory <- "E:/coa2/COA/COA_WebToolDemo"   # replace with here()

# function to grab the rightmost characters
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

# set options   
options(useFancyQuotes = FALSE)

db <- dbConnect(SQLite(), dbname = databasename)

SQLquery <- paste("SELECT unique_id, ELSeason, OccProb"," FROM lu_sgcnXpu_all ")
data_sgcnXpu <- dbGetQuery(db, statement = SQLquery)

SQLquery_county <- paste("SELECT COUNTY_NAM, FIPS_COUNT"," FROM lu_CountyName ")
data_countyname <- dbGetQuery(db, statement = SQLquery_county )

SQLquery_luNatBound <- paste("SELECT unique_id, HUC08"," FROM lu_NaturalBoundaries ")
data_NaturalBoundaries <- dbGetQuery(db, statement = SQLquery_luNatBound )

sws <- merge(data_sgcnXpu,data_NaturalBoundaries,by="unique_id",all.x=TRUE)

# get the county FIPS code
sws$county_FIPS <- substr(sws$unique_id,1,3)

sws <- merge(sws,data_countyname,by.x="county_FIPS",by.y="FIPS_COUNT", all.x=TRUE)
# get the season
sws$season <- substrRight(sws$ELSeason, 1)
# get the ELCODE
sws$ELSeason <- substr(sws$ELSeason,1,10)
names(sws)[names(sws)=='ELSeason'] <- 'ELCODE'

# rearrange
sws <- sws[c("unique_id","HUC08","COUNTY_NAM","ELCODE","season","OccProb")]
# make a table of the count of PUs by HUC08
PU_huc08 <- as.data.frame(table(sws$HUC08))
PU_county <- as.data.frame(table(sws$COUNTY_NAM))

# summarize by HUC08
sws_huc08agg <- aggregate(unique_id ~ ELCODE+OccProb+HUC08+season, sws, function(x) length(x))
sws_huc08agg_cast <- dcast(sws_huc08agg, ELCODE+HUC08~season,sum, value.var="unique_id")  #OccProb+
sws_huc08agg_cast <- merge(sws_huc08agg_cast, PU_huc08 , by.x="HUC08", by.y="Var1")
sws_huc08agg_cast$b <- sws_huc08agg_cast$b / sws_huc08agg_cast$Freq
sws_huc08agg_cast$m <- sws_huc08agg_cast$m / sws_huc08agg_cast$Freq
sws_huc08agg_cast$w <- sws_huc08agg_cast$w / sws_huc08agg_cast$Freq
sws_huc08agg_cast$y <- sws_huc08agg_cast$y / sws_huc08agg_cast$Freq
sws_huc08agg_cast$Freq <- NULL
names(sws_huc08agg_cast)[names(sws_huc08agg_cast)=='b'] <- 'b_prop'
names(sws_huc08agg_cast)[names(sws_huc08agg_cast)=='m'] <- 'm_prop'
names(sws_huc08agg_cast)[names(sws_huc08agg_cast)=='w'] <- 'w_prop'
names(sws_huc08agg_cast)[names(sws_huc08agg_cast)=='y'] <- 'y_prop'
sws_huc08agg_cast$b <- ifelse(sws_huc08agg_cast$b_prop>0, "yes", NA)
sws_huc08agg_cast$m <- ifelse(sws_huc08agg_cast$m_prop>0, "yes", NA)
sws_huc08agg_cast$w <- ifelse(sws_huc08agg_cast$w_prop>0, "yes", NA)
sws_huc08agg_cast$y <- ifelse(sws_huc08agg_cast$y_prop>0, "yes", NA)
# load the huc08 basemap
huc08_shp <- arc.open("e:/coa2/StateWideSpecies/sws.gdb/_huc08")
huc08_shp <- arc.select(huc08_shp)
huc08_shp <- arc.data2sf(huc08_shp)
huc08_shp <- huc08_shp[c("OBJECTID","HUC8","NAME")]
# map it
sgcnlist <- unique(sws_huc08agg_cast$ELCODE)
sgcnlist <- gsub("\r\n","",sgcnlist)
# make the watershed maps
for(i in 1:length(sgcnlist)){
  sws_huc08_1 <- sws_huc08agg_cast[which(sws_huc08agg_cast$ELCODE==sgcnlist[i]),]
  sws_huc08_1a <- merge(huc08_shp,sws_huc08_1,by.x="HUC8",by.y="HUC08")
  arc.write(file.path("sws.gdb",paste("huc08",sgcnlist[i],sep="_")),sws_huc08_1a ,overwrite=TRUE)
}


# summarize by County
sws_countyagg <- aggregate(unique_id ~ ELCODE+OccProb+COUNTY_NAM+season, sws, function(x) length(x))
sws_countyagg_cast <- dcast(sws_countyagg, ELCODE+COUNTY_NAM~season,sum, value.var="unique_id")  #OccProb+
sws_countyagg_cast <- merge(sws_countyagg_cast, PU_county , by.x="COUNTY_NAM", by.y="Var1")
sws_countyagg_cast$b <- sws_countyagg_cast$b / sws_countyagg_cast$Freq
sws_countyagg_cast$m <- sws_countyagg_cast$m / sws_countyagg_cast$Freq
sws_countyagg_cast$w <- sws_countyagg_cast$w / sws_countyagg_cast$Freq
sws_countyagg_cast$y <- sws_countyagg_cast$y / sws_countyagg_cast$Freq
sws_countyagg_cast$Freq <- NULL
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='b'] <- 'b_prop'
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='m'] <- 'm_prop'
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='w'] <- 'w_prop'
names(sws_countyagg_cast)[names(sws_countyagg_cast)=='y'] <- 'y_prop'
sws_countyagg_cast$b <- ifelse(sws_countyagg_cast$b_prop>0, "yes", NA)
sws_countyagg_cast$m <- ifelse(sws_countyagg_cast$m_prop>0, "yes", NA)
sws_countyagg_cast$w <- ifelse(sws_countyagg_cast$w_prop>0, "yes", NA)
sws_countyagg_cast$y <- ifelse(sws_countyagg_cast$y_prop>0, "yes", NA)
# load the county basemap
county_shp <- arc.open("e:/coa2/StateWideSpecies/sws.gdb/_county")
county_shp <- arc.select(county_shp)
county_shp <- arc.data2sf(county_shp)
county_shp <- county_shp[c("OBJECTID","COUNTY_NAM","COUNTY_NUM","FIPS_COUNT")]
# map it
sgcnlist <- unique(sws_countyagg_cast$ELCODE)
sgcnlist <- gsub("\r\n","",sgcnlist)
# make the watershed maps
for(i in 1:length(sgcnlist)){
  sws_county_1 <- sws_countyagg_cast[which(sws_countyagg_cast$ELCODE==sgcnlist[i]),]
  sws_county_1a <- merge(county_shp,sws_county_1,by="COUNTY_NAM")
  arc.write(file.path("sws.gdb",paste("county",sgcnlist[i],sep="_")),sws_county_1a ,overwrite=TRUE)
}


###################################
