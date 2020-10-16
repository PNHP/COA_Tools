# load packages
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
require(RSQLite)
library(ggplot2)
library(grid)
library(scales)


#here::here("_data","output","reporting")

source(here::here("scripts","00_PathsAndSettings.r"))

# load the sgcn datasets
print(paste("We are on the",updateName, "update. Adjust your numbers below as appropiate", sep=" "))
databasename_new <- here::here("_data","output",updateName,"coa_bridgetest.sqlite")
databasename_prev <- here::here("_data","output","_update2020q1","coa_bridgetest.sqlite")
databasename_6m <- here::here("_data","output","_update2019q4","coa_bridgetest.sqlite")

# load the SGCN
loadSGCN()


######################################################################################
# get 6 MONTHS AGO lu_sgcn and lu_sgcnXpu data from sqlite database
db <- dbConnect(SQLite(), dbname=databasename_6m)
lu_sgcn_SQLquery <- "SELECT ELSeason, ELCODE, SCOMNAME, SNAME, TaxaDisplay, SeasonCode FROM lu_sgcn"
lu_sgcnXpu_SQLquery <- "SELECT unique_id, OccProb, PERCENTAGE, ELSeason FROM lu_sgcnXpu_all"
lu_sgcn_6m <- dbGetQuery(db, statement = lu_sgcn_SQLquery)
lu_sgcnXpu_6m <- dbGetQuery(db, statement = lu_sgcnXpu_SQLquery)
dbDisconnect(db) # disconnect the db
# get a count of the previous SGCN
SGCN6m <- unique(lu_sgcnXpu_6m$ELSeason)
SGCN6mNoSeason <- unique(substr(lu_sgcnXpu_6m$ELSeason,1,10))

######################################################################################
# get PREVIOUS lu_sgcn and lu_sgcnXpu data from sqlite database
db <- dbConnect(SQLite(), dbname=databasename_prev)
lu_sgcn_SQLquery <- "SELECT ELSeason, ELCODE, SCOMNAME, SNAME, TaxaDisplay, SeasonCode FROM lu_sgcn"
lu_sgcnXpu_SQLquery <- "SELECT unique_id, OccProb, PERCENTAGE, ELSeason FROM lu_sgcnXpu_all"
lu_sgcn_prev <- dbGetQuery(db, statement = lu_sgcn_SQLquery)
lu_sgcnXpu_prev <- dbGetQuery(db, statement = lu_sgcnXpu_SQLquery)
dbDisconnect(db) # disconnect the db
# get a count of the previous SGCN
SGCNprev <- unique(lu_sgcnXpu_prev$ELSeason)
SGCNprevNoSeason <- unique(substr(lu_sgcnXpu_prev$ELSeason,1,10))

######################################################################################
# get NEW lu_sgcn and lu_sgcnXpu data from sqlite database
db <- dbConnect(SQLite(), dbname=databasename_new)
lu_sgcn_SQLquery <- "SELECT ELSeason, ELCODE, SCOMNAME, SNAME, TaxaDisplay, SeasonCode FROM lu_sgcn"
lu_sgcnXpu_SQLquery <- "SELECT unique_id, OccProb, PERCENTAGE, ELSeason FROM lu_sgcnXpu_all"
lu_sgcn_new <- dbGetQuery(db, statement = lu_sgcn_SQLquery)
lu_sgcnXpu_new <- dbGetQuery(db, statement = lu_sgcnXpu_SQLquery)
dbDisconnect(db) # disconnect the db

SGCNnew <- unique(lu_sgcnXpu_new$ELSeason)
SGCNnewNoSeason <- unique(substr(lu_sgcnXpu_new$ELSeason,1,10))

#######################
# compare records between years

SGCNadded <- setdiff(SGCNnewNoSeason, SGCNprevNoSeason)
SGCNadded <- lu_sgcn_new[lu_sgcn_new$ELCODE %in% SGCNadded,]
SGCNlost <- setdiff(SGCNprevNoSeason,SGCNnewNoSeason)
SGCNlost <- lu_sgcn_prev[lu_sgcn_prev$ELCODE %in% SGCNlost,]

SGCNadded6m <- setdiff(SGCNnewNoSeason, SGCN6mNoSeason)
SGCNadded6m <- lu_sgcn_new[lu_sgcn_new$ELCODE %in% SGCNadded6m,]
SGCNlost6m <- setdiff(SGCN6mNoSeason,SGCNnewNoSeason)
SGCNlost6m <- lu_sgcn_6m[lu_sgcn_6m$ELCODE %in% SGCNlost6m,]


ChangeSummary <- data.frame(SGCNcount=c(length(SGCN6m),length(SGCNprev),length(SGCNnew)),SGCNcountNoSeason=c(length(SGCN6mNoSeason),length(SGCNprevNoSeason),length(SGCNnewNoSeason)), row.names = c("6 months ago","Previous Update","Update"))

# which planning units showed the greatest change
PUcount_6m <- lu_sgcnXpu_6m %>% group_by(unique_id) %>% tally()
PUcount_prev <- lu_sgcnXpu_prev %>% group_by(unique_id) %>% tally()
PUcount_new <- lu_sgcnXpu_new %>% group_by(unique_id) %>% tally()

PUcount_compare <- merge(PUcount_prev, PUcount_new, by="unique_id", all=TRUE)
names(PUcount_compare) <- c("unique_id","n_old", "n_new")
PUcount_compare$diff <- PUcount_compare$n_new-PUcount_compare$n_old

nrow(PUcount_compare[which(PUcount_compare$diff==0),]) # number of zero values
nrow(PUcount_compare[which(PUcount_compare$diff==1),]) # number of zero values
nrow(PUcount_compare[which(PUcount_compare$diff==15),]) # number of zero values
nrow(PUcount_compare[which(PUcount_compare$diff>=1),]) # number of zero values
nrow(PUcount_compare[which(PUcount_compare$diff<=-1),]) # number of zero values
nrow(PUcount_compare[which(PUcount_compare$diff==-1),]) # number of zero values
nrow(PUcount_compare[which(PUcount_compare$diff==-4),]) # number of zero values

PUcount_compare6m <- merge(PUcount_6m, PUcount_new, by="unique_id", all=TRUE)
names(PUcount_compare6m) <- c("unique_id","n_old", "n_new")
PUcount_compare6m$diff <- PUcount_compare6m$n_new-PUcount_compare6m$n_old

summary(PUcount_compare6m)

nrow(PUcount_compare6m[which(PUcount_compare6m$diff==0),]) # number of zero values
nrow(PUcount_compare6m[which(PUcount_compare6m$diff==1),]) # number of zero values
max(PUcount_compare6m$diff, na.rm=TRUE)
nrow(PUcount_compare6m[which(PUcount_compare6m$diff==max(PUcount_compare6m$diff, na.rm=TRUE)),]) # number of zero values
nrow(PUcount_compare6m[which(PUcount_compare6m$diff>=1),]) # number of zero values
nrow(PUcount_compare6m[which(PUcount_compare6m$diff<=-1),]) # number of zero values
nrow(PUcount_compare6m[which(PUcount_compare6m$diff==-1),]) # number of zero values
min(PUcount_compare6m$diff, na.rm=TRUE)
nrow(PUcount_compare6m[which(PUcount_compare6m$diff==min(PUcount_compare6m$diff, na.rm=TRUE)),]) # number of zero values





library(ggplot2)
library(scales)
ggplot(data=PUcount_compare6m, aes(PUcount_compare6m$diff)) +
  geom_histogram(binwidth=1) +
  scale_y_continuous(trans='log10', breaks=trans_breaks('log10', function(x) 10^x), labels=trans_format('log10', math_format(10^.x))) +
labs(title="Change in SGCN Richness of Attributed Planning Units", x ="Difference between the number of SGCN between two data updates", y = "log of count") +
  theme_minimal()

# number of occupied planning units
sgcnCount_6m <- aggregate(unique_id~ELSeason, data=lu_sgcnXpu_6m, FUN=length)
names(sgcnCount_6m) <- c("ELSeason","a6mCount")
sgcnCount_prev <- aggregate(unique_id~ELSeason, data=lu_sgcnXpu_prev, FUN=length)
names(sgcnCount_prev) <- c("ELSeason","PrevCount")
sgcnCount_new <- aggregate(unique_id~ELSeason, data=lu_sgcnXpu_new, FUN=length)
names(sgcnCount_new) <- c("ELSeason","NewCount")

sgcnCount <- merge(sgcnCount_prev, sgcnCount_new, all=TRUE)
sgcnCount$diff <- sgcnCount$NewCount - sgcnCount$PrevCount

sgcnCount6m <- merge(sgcnCount_6m, sgcnCount_new, all=TRUE)
sgcnCount6m$diff <- sgcnCount6m$NewCount - sgcnCount6m$a6mCount



print(paste(nrow(sgcnCount[which(sgcnCount$diff==0),]), " SGCN had no change in the number of records.", sep=""))
print(paste(nrow(sgcnCount6m[which(sgcnCount6m$diff==0),]), " SGCN had no change in the number of records in the 6 month comparison.", sep=""))



sgcnCount <- merge(sgcnCount, lu_sgcn, by="ELSeason")
sgcnCount6m <- merge(sgcnCount6m, lu_sgcn, by="ELSeason")


db <- dbConnect(SQLite(), dbname=databasename_new)
lu_taxagrp_SQLquery <- "SELECT * FROM lu_taxagrp"
lu_taxagrp <- dbGetQuery(db, statement=lu_taxagrp_SQLquery)
dbDisconnect(db) # disconnect the db

sgcnCount <- merge(sgcnCount, lu_taxagrp, by="ELSeason", by.x="TaxaGroup", by.y="code")
sgcnCount6m <- merge(sgcnCount6m, lu_taxagrp, by="ELSeason", by.x="TaxaGroup", by.y="code")

# rename the invert
sgcnCount[which(substr(sgcnCount$taxadisplay,1,12)=="Invertebrate"),]$taxadisplay <- "Invertebrate"
sgcnCount6m[which(substr(sgcnCount6m$taxadisplay,1,12)=="Invertebrate"),]$taxadisplay <- "Invertebrate"


# find the top/bottom five values for the quarter
upvalues <- sort(sgcnCount$diff)[1:5]
downvalues <- sort(sgcnCount$diff, decreasing = TRUE)[1:5]
labvalue <- c(upvalues, downvalues)
sgcnCount$label <- NA
sgcnCount[which(sgcnCount$diff %in% labvalue),]$label <- "yes"
sgcnCount$labeltext <- paste(sgcnCount$SCOMNAME," (",sgcnCount$diff,")", sep="")
grob1 <- grobTree(textGrob("Increase in Planning Units", x=0.1,  y=0.95, just="left", gp=gpar(col="black", fontsize=16, fontface="italic")))
grob2 <- grobTree(textGrob("Decrease in Planning Units", x=0.95,  y=0.1, just="right", gp=gpar(col="black", fontsize=16, fontface="italic")))
ggplot(sgcnCount, aes(x=PrevCount, y=NewCount, color=taxadisplay)) + 
  geom_point() +
  scale_x_continuous(trans='log10', breaks=trans_breaks('log10', function(x) 10^x), labels=trans_format('log10', math_format(10^.x))) +
  scale_y_continuous(trans='log10', breaks=trans_breaks('log10', function(x) 10^x), labels=trans_format('log10', math_format(10^.x))) +
  geom_abline(intercept=0, slope=1, color="grey51", linetype = "dashed") +
  geom_text(aes(label=ifelse(label=="yes", labeltext, ""), hjust="left", vjust="top"), show.legend=FALSE ) +
  annotation_custom(grob1) + 
  annotation_custom(grob2) + 
  #annotation_logticks() +
  labs(title="Change in Attributed Planning Units", x="April 2019", y="October 2019") +
  theme_minimal()

# find the top/bottom five values for the six month period
upvalues <- sort(sgcnCount6m$diff)[1:5]
downvalues <- sort(sgcnCount6m$diff, decreasing = TRUE)[1:5]
labvalue <- c(upvalues, downvalues)
sgcnCount6m$label <- NA
sgcnCount6m[which(sgcnCount6m$diff %in% labvalue),]$label <- "yes"
sgcnCount6m$labeltext <- paste(sgcnCount6m$SCOMNAME," (",sgcnCount6m$diff,")", sep="")
grob1 <- grobTree(textGrob("Increase in Planning Units", x=0.1,  y=0.95, just="left", gp=gpar(col="black", fontsize=16, fontface="italic")))
grob2 <- grobTree(textGrob("Decrease in Planning Units", x=0.95,  y=0.1, just="right", gp=gpar(col="black", fontsize=16, fontface="italic")))
ggplot(sgcnCount6m, aes(x=a6mCount, y=NewCount, color=taxadisplay)) + 
  geom_point() +
  scale_x_continuous(trans='log10', breaks=trans_breaks('log10', function(x) 10^x), labels=trans_format('log10', math_format(10^.x))) +
  scale_y_continuous(trans='log10', breaks=trans_breaks('log10', function(x) 10^x), labels=trans_format('log10', math_format(10^.x))) +
  geom_abline(intercept=0, slope=1, color="grey51", linetype = "dashed") +
  geom_text(aes(label=ifelse(label=="yes", labeltext, ""), hjust="left", vjust="top", fontsize=12), show.legend=FALSE ) +
  annotation_custom(grob1) + 
  annotation_custom(grob2) + 
  #annotation_logticks() +
  labs(title="Change in Attributed Planning Units", x="April 2019", y="October 2019") +
  theme_minimal()




#####
# get the species that are missing from the PU data
missingSGCN <- setdiff(lu_sgcn$ELCODE, substr(SGCNnew, 1, 10))
missingSGCN <- lu_sgcn[lu_sgcn$ELCODE %in% missingSGCN,]
missingSGCN <- merge(missingSGCN, lu_taxagrp, by.x="TaxaGroup", by.y="code")

missingSGCNsummary <- missingSGCN %>% group_by(taxadisplay) %>% tally()
write.csv(missingSGCNsummary,paste(here::here("_data","output","reporting"),"/missingSGCN.csv", sep="")) 

#####
# get the species that are missing from the PU data for the 6m period
missingSGCN6m <- setdiff(lu_sgcn$ELCODE, substr(SGCNnew, 1, 10))
missingSGCN6m <- lu_sgcn[lu_sgcn$ELCODE %in% missingSGCN6m,]
missingSGCN6m <- merge(missingSGCN6m, lu_taxagrp, by.x="TaxaGroup", by.y="code")

missingSGCN6msummary <- missingSGCN6m %>% group_by(taxadisplay) %>% tally()
write.csv(missingSGCN6msummary,paste(here::here("_data","output","reporting"),"/missingSGCN6m.csv", sep="")) 


################################################


# creation of summary table
source(here::here("scripts","00_PathsAndSettings.r"))
# read in SGCN data
loadSGCN()

# collapse sgcn down to one season
lu_sgcn <- unique(lu_sgcn[c("ELCODE","SNAME","SCOMNAME","TaxaGroup")])

# get new data
SGCN <- arc.open(path=here::here("_data/output/",updateName,"SGCN.gdb","allSGCNuse"))
SGCN <- arc.select(SGCN)
SGCN_sf <- arc.data2sf(SGCN)

# merge
SGCN_sf <- merge(SGCN_sf, lu_taxagrp, by.x="TaxaGroup", by.y="code")
SGCN_sf$LastObs <- as.numeric(SGCN_sf$LastObs)
SGCN_sf <- SGCN_sf[which(SGCN_sf$LastObs>=1980),]

taxalist <- unique(SGCN_sf$taxadisplay)

for(i in 1:length(taxalist)){
  SGCN_sf_sub <- SGCN_sf[which(SGCN_sf$taxadisplay==taxalist[i]),]
  SGCN_sf_sub$include <- factor(ifelse(SGCN_sf_sub$LastObs>=1994,"less than 25 years","older than 25 years"))
  levels(SGCN_sf_sub$include) <- c("less than 25 years","older than 25 years")
  # make the histogram
  h <- ggplot(data=SGCN_sf_sub , aes(LastObs, fill=include)) +
    geom_histogram(binwidth=1) +
    scale_fill_manual(values=c("blue","red"), drop=FALSE) +
    scale_x_continuous(breaks=seq(1980, 2020, by=5), labels=waiver(), limits=c(1980, 2020)) +
    xlab("Observation Date") +
    ylab("Number of Records") +
    theme_minimal() +
    theme(legend.position="top") +
    theme(legend.title=element_blank()) +
    theme(legend.text=element_text(size=15)) +
    theme(axis.text=element_text(size=14), axis.title=element_text(size=15)) +
    theme(axis.text.x=element_text(angle=60, hjust=1))
  png(filename = paste("lastobs_",taxalist[i],".png",sep=""), width=600, height=600, units = "px", )
  print(h)
  dev.off()
  
  # make the map
  library(USAboundaries)
  library(USAboundariesData)
  SGCN_sf_sub <- st_buffer(SGCN_sf_sub, 1000)
  counties <- us_counties(map_date = NULL, resolution = c("high"), states="PA")
  counties <- st_transform(counties, st_crs(SGCN_sf_sub))
  p <- ggplot() +
    geom_sf(data=SGCN_sf_sub, mapping=aes(fill=include), alpha=0.9, color=NA) +
    scale_fill_manual(values=c("blue","red"), drop=FALSE) +
    geom_sf(data=counties, aes(), colour="black", fill=NA)  +
    scale_x_continuous(limits=c(-215999, 279249)) +
    scale_y_continuous(limits=c(80036, 364574)) +
    theme_void() +
    theme(legend.position="top") +
    theme(legend.title=element_blank()) +
    theme(legend.text=element_text(size=15)) +
    theme(axis.text=element_blank(), axis.title=element_text(size=15))
  png(filename = paste("lastobsmap_",taxalist[i],".png",sep=""), width=600, height=450, units = "px", )
  print(p)
  dev.off()
  
  # # combine into two graphs
  # require(gridExtra)
  # grid.arrange(h, p, ncol=2)
}

# get old data
# get new data
SGCN_prev <- arc.open(path=here::here("_data/output/","_update2020q1","SGCN.gdb","allSGCNuse"))
SGCN_prev <- arc.select(SGCN_prev)
SGCN_prev_sf <- arc.data2sf(SGCN_prev)




