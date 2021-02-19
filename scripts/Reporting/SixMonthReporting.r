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
if (!requireNamespace("knitr", quietly = TRUE)) install.packages("knitr")
require(knitr)
if (!requireNamespace("tinytex", quietly = TRUE)) install.packages("tinytex")
require(tinytex)
if (!requireNamespace("english", quietly = TRUE)) install.packages("english")
require(english)

source(here::here("scripts","00_PathsAndSettings.r"))

# function to generate the pdf
#knit2pdf(here::here("scripts","template_Formatted_NHA_PDF.rnw"), output=paste(pdf_filename, ".tex", sep=""))
makePDF <- function(rnw_template, pdf_filename) {
  knit(here::here("scripts","Reporting", rnw_template), output=paste(pdf_filename, ".tex",sep=""))
  call <- paste0("xelatex -interaction=nonstopmode ", pdf_filename , ".tex")
  system(call)
  system(paste0("biber ",pdf_filename))
  system(call) # 2nd run to apply citation numbers
}

# function to delete .txt, .log etc if pdf is created successfully.
deletepdfjunk <- function(pdf_filename){
  fn_ext <- c(".aux",".out",".run.xml",".bcf",".blg",".tex",".log",".bbl",".toc") #
  if (file.exists(paste(pdf_filename, ".pdf",sep=""))){
    for(i in 1:NROW(fn_ext)){
      fn <- paste(pdf_filename, fn_ext[i],sep="")
      if (file.exists(fn)){
        file.remove(fn)
      }
    }
  }
}

`%nin%` <- Negate(`%in%`)

######################################################################################
# load the current SGCN list
loadSGCN()

# assign the database names for the updates
databasename_now <- here::here("_data","output",updateName,"coa_bridgetest.sqlite") # most recent update
databasename_6m <- here::here("_data","output",updateName6m,"coa_bridgetest.sqlite") # update from six months ago

# various variables
lu_sgcn_SQLquery <- "SELECT ELSeason, ELCODE, SCOMNAME, SNAME, TaxaDisplay, SeasonCode FROM lu_sgcn"
lu_sgcnXpu_SQLquery <- "SELECT unique_id, OccProb, PERCENTAGE, ELSeason FROM lu_sgcnXpu_all"

######################################################################################
# get 6 MONTHS AGO lu_sgcn and lu_sgcnXpu data from sqlite database
db <- dbConnect(SQLite(), dbname=databasename_6m)
lu_sgcn_6m <- dbGetQuery(db, statement=lu_sgcn_SQLquery)
lu_sgcnXpu_6m <- dbGetQuery(db, statement=lu_sgcnXpu_SQLquery)
dbDisconnect(db) # disconnect the db
# get a count of the previous SGCN
cnt_SGCN6m <- unique(lu_sgcnXpu_6m$ELSeason)
cnt_SGCN6mNoSeason <- unique(substr(lu_sgcnXpu_6m$ELSeason,1,10))
# check for missing SGCN in the SGCNxPU table
missingSGCN_6m <- setdiff(lu_sgcn_6m$ELSeason, cnt_SGCN6m)
cat(paste("The following ",length(missingSGCN_6m)," ELSeason codes are not found within the SGCNxPU table:", sep=""))
cat(paste(missingSGCN_6m, collapse = ", "))
# check for SGCN in the SGCNxPU table that are missing in the lu_sgcn table
extraSGCN_6m <- setdiff(cnt_SGCN6m, lu_sgcn_6m$ELSeason)
cat(paste("The following ",length(extraSGCN_6m)," ELSeason codes from the SGCNxPU table are not in the lu_sgcn table:", sep=""))
cat(paste(extraSGCN_6m, collapse = ", "))
cat("we're going to delete these so they don't interfere with the reporting.")
lu_sgcnXpu_6mA <- lu_sgcnXpu_6m[which(lu_sgcnXpu_6m$ELSeason %nin% extraSGCN_6m),]
cat(paste("This removes ",nrow(lu_sgcnXpu_6m)-nrow(lu_sgcnXpu_6mA)," bad records.", sep=""))
lu_sgcnXpu_6m <- lu_sgcnXpu_6mA
rm(lu_sgcnXpu_6mA)
# rerun the counts about 15 lines above to reflect the new data
cnt_SGCN6m <- unique(lu_sgcnXpu_6m$ELSeason)
cnt_SGCN6mNoSeason <- unique(substr(lu_sgcnXpu_6m$ELSeason,1,10))

#setdiff(unique(lu_sgcn_6m$ELCODE), cnt_SGCN6mNoSeason)

######################################################################################
# get NOW lu_sgcn and lu_sgcnXpu data from sqlite database
db <- dbConnect(SQLite(), dbname=databasename_now)
lu_sgcn_now <- dbGetQuery(db, statement=lu_sgcn_SQLquery)
lu_sgcnXpu_now <- dbGetQuery(db, statement=lu_sgcnXpu_SQLquery)
dbDisconnect(db) # disconnect the db
# get a count of the current SGCN
cnt_SGCNnow <- unique(lu_sgcnXpu_now$ELSeason)
cnt_SGCNnowNoSeason <- unique(substr(lu_sgcnXpu_now$ELSeason,1,10))
# check for missing SGCN in the SGCNxPU table
missingSGCN_now <- setdiff(lu_sgcn_now$ELSeason, cnt_SGCNnow)
cat(paste("The following ",length(missingSGCN_now)," ELSeason codes are not found within the SGCNxPU table:", sep=""))
cat(paste(missingSGCN_now, collapse = ", "))
# check for SGCN in the SGCNxPU table that are missing in the lu_sgcn table
extraSGCN_now <- setdiff(cnt_SGCNnow, lu_sgcn_now$ELSeason)
cat(paste("The following ",length(extraSGCN_now)," ELSeason codes from the SGCNxPU table are not in the lu_sgcn table:", sep=""))
cat(paste(extraSGCN_now, collapse = ", "))
cat("we're going to delete these so they don't interfere with the reporting.")
lu_sgcnXpu_nowA <- lu_sgcnXpu_now[which(lu_sgcnXpu_now$ELSeason %nin% extraSGCN_now),]
cat(paste("This removes ",nrow(lu_sgcnXpu_now)-nrow(lu_sgcnXpu_nowA)," bad records.", sep=""))
lu_sgcnXpu_now <- lu_sgcnXpu_nowA
rm(lu_sgcnXpu_nowA)
# rerun the counts about 15 lines above to reflect the new data
cnt_SGCNnow <- unique(lu_sgcnXpu_now$ELSeason)
cnt_SGCNnowNoSeason <- unique(substr(lu_sgcnXpu_now$ELSeason,1,10))
# save.image(file = "my_work_space.RData")
# load(file = "my_work_space.RData")

######################################################################################
# compare records between 6 month reporting periods
SGCNadded6m <- setdiff(cnt_SGCNnowNoSeason, cnt_SGCN6mNoSeason)
SGCNadded6m <- lu_sgcn_now[lu_sgcn_now$ELCODE %in% SGCNadded6m,]
SGCNlost6m <- setdiff(cnt_SGCN6mNoSeason, cnt_SGCNnowNoSeason)
SGCNlost6m <- lu_sgcn_6m[lu_sgcn_6m$ELCODE %in% SGCNlost6m,]

ChangeSummary <- data.frame(SGCNcount=c(length(cnt_SGCN6m),length(cnt_SGCNnow)),SGCNcountNoSeason=c(length(cnt_SGCN6mNoSeason),length(cnt_SGCNnowNoSeason)), row.names = c("6 months ago","Update"))

# which planning units showed the greatest change
PUcount_6m <- lu_sgcnXpu_6m %>% group_by(unique_id) %>% tally()
PUcount_now <- lu_sgcnXpu_now %>% group_by(unique_id) %>% tally()

PUcount_compare6m <- merge(PUcount_6m, PUcount_now, by="unique_id", all=TRUE)
names(PUcount_compare6m) <- c("unique_id","n_6m", "n_now")
PUcount_compare6m$diff <- PUcount_compare6m$n_now-PUcount_compare6m$n_6m

summary(PUcount_compare6m)

PUchng <- nrow(PUcount_6m)-nrow(PUcount_now)

PUchng_max <- max(PUcount_compare6m$diff, na.rm=TRUE)
PUchng_min <- min(PUcount_compare6m$diff, na.rm=TRUE)

PUcnt_total <- 2908000  
PUcnt_nochange <- nrow(PUcount_compare6m[which(PUcount_compare6m$diff==0),]) # number of zero values
PUcnt_max <- nrow(PUcount_compare6m[which(PUcount_compare6m$diff==PUchng_max),]) # number of PU units with a maximum change 
PUcnt_min <- nrow(PUcount_compare6m[which(PUcount_compare6m$diff==PUchng_min),]) # number of PU units with a minimum change 
PUcnt_ge1 <- nrow(PUcount_compare6m[which(PUcount_compare6m$diff>=1),]) # number of PU where the change was more than 1
PUcnt_le1 <- nrow(PUcount_compare6m[which(PUcount_compare6m$diff<=-1),]) # number of PU where the change was less than 1
PUcnt_plus1 <- nrow(PUcount_compare6m[which(PUcount_compare6m$diff==1),]) # number of differences of 1
PUcnt_minus1 <- nrow(PUcount_compare6m[which(PUcount_compare6m$diff==-1),]) # number of differences of -1

# !!! The above is used to plot the PU_Richness fig in the .rnw !!! #

# number of occupied planning units
sgcnCount_6m <- aggregate(unique_id~ELSeason, data=lu_sgcnXpu_6m, FUN=length)
names(sgcnCount_6m) <- c("ELSeason","Count_6m")
sgcnCount_now <- aggregate(unique_id~ELSeason, data=lu_sgcnXpu_now, FUN=length)
names(sgcnCount_now) <- c("ELSeason","Count_Now")
sgcnCount6m <- merge(sgcnCount_6m, sgcnCount_now, all=TRUE)
sgcnCount6m$diff <- sgcnCount6m$Count_Now - sgcnCount6m$Count_6m

print(paste(nrow(sgcnCount6m[which(sgcnCount6m$diff==0),]), " SGCN had no change in the number of records in the 6 month comparison.", sep=""))

sgcnCount6m <- merge(sgcnCount6m, lu_sgcn, by="ELSeason")

db <- dbConnect(SQLite(), dbname=databasename_now)
lu_taxagrp_SQLquery <- "SELECT * FROM lu_taxagrp"
lu_taxagrp <- dbGetQuery(db, statement=lu_taxagrp_SQLquery)
dbDisconnect(db) # disconnect the db

sgcnCount6m <- merge(sgcnCount6m, lu_taxagrp, by="ELSeason", by.x="TaxaGroup", by.y="code")

# rename the invert
sgcnCount6m[which(substr(sgcnCount6m$taxadisplay,1,12)=="Invertebrate"),]$taxadisplay <- "Invertebrate"


# # find the top/bottom five values for the quarter
# upvalues <- sort(sgcnCount$diff)[1:5]
# downvalues <- sort(sgcnCount$diff, decreasing = TRUE)[1:5]
# labvalue <- c(upvalues, downvalues)
# sgcnCount$label <- NA
# sgcnCount[which(sgcnCount$diff %in% labvalue),]$label <- "yes"
# sgcnCount$labeltext <- paste(sgcnCount$SCOMNAME," (",sgcnCount$diff,")", sep="")
# grob1 <- grobTree(textGrob("Increase in Planning Units", x=0.1,  y=0.95, just="left", gp=gpar(col="black", fontsize=16, fontface="italic")))
# grob2 <- grobTree(textGrob("Decrease in Planning Units", x=0.95,  y=0.1, just="right", gp=gpar(col="black", fontsize=16, fontface="italic")))
# ggplot(sgcnCount, aes(x=PrevCount, y=NewCount, color=taxadisplay)) + 
#   geom_point() +
#   scale_x_continuous(trans='log10', breaks=trans_breaks('log10', function(x) 10^x), labels=trans_format('log10', math_format(10^.x))) +
#   scale_y_continuous(trans='log10', breaks=trans_breaks('log10', function(x) 10^x), labels=trans_format('log10', math_format(10^.x))) +
#   geom_abline(intercept=0, slope=1, color="grey51", linetype = "dashed") +
#   geom_text(aes(label=ifelse(label=="yes", labeltext, ""), hjust="left", vjust="top"), show.legend=FALSE ) +
#   annotation_custom(grob1) + 
#   annotation_custom(grob2) + 
#   #annotation_logticks() +
#   labs(title="Change in Attributed Planning Units", x="April 2019", y="October 2019") +
#   theme_minimal()





#####
# get the species that are missing from the PU data
missingSGCN <- setdiff(lu_sgcn$ELCODE, substr(SGCNnew, 1, 10))
missingSGCN <- lu_sgcn[lu_sgcn$ELCODE %in% missingSGCN,]
missingSGCN <- merge(missingSGCN, lu_taxagrp, by.x="TaxaGroup", by.y="code")

missingSGCNsummary <- missingSGCN %>% group_by(taxadisplay) %>% tally()
write.csv(missingSGCNsummary,paste(here::here("_data","output","reporting"),"/missingSGCN.csv", sep="")) 

#####
# get the species that are missing from the PU data for the 6m period
missingSGCN6m <- setdiff(lu_sgcn$ELCODE, substr(SGCN6m, 1, 10))
missingSGCN6m <- lu_sgcn[lu_sgcn$ELCODE %in% missingSGCN6m,]
missingSGCN6m <- merge(missingSGCN6m, lu_taxagrp, by.x="TaxaGroup", by.y="code")

missingSGCN6msummary <- missingSGCN6m %>% group_by(taxadisplay) %>% tally()
write.csv(missingSGCN6msummary,paste(here::here("_data","output","reporting"),"/missingSGCN6m.csv", sep="")) 

# comparison of the six month to now
missingCompare <- merge(missingSGCN6msummary, missingSGCNsummary, by="taxadisplay")
names(missingCompare) <- c("taxadisplay", "n_6m", "n_now")
missingCompare$difference <- missingCompare$n_6m - missingCompare$n_now

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



# making the taxa maps ############################################################################################################
save.image(file = "my_work_space.RData")

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
  png(filename = paste(here::here("_data/output",updateName,"figuresReporting"),"/","lastobs_",taxalist[i],".png",sep=""), width=600, height=600, units = "px", )
  print(h)
  dev.off()
  
  # make the map
  SGCN_sf_sub <- st_buffer(SGCN_sf_sub, 1000)
  #counties <- us_counties(map_date = NULL, resolution = c("high"), states="PA")
  #counties <- st_transform(counties, st_crs(SGCN_sf_sub))
  p <- ggplot() +
    geom_sf(data=SGCN_sf_sub, mapping=aes(fill=include), alpha=0.9, color=NA) +
    scale_fill_manual(values=c("blue","red"), drop=FALSE) +
    #geom_sf(data=counties, aes(), colour="black", fill=NA)  +
    scale_x_continuous(limits=c(-215999, 279249)) +
    scale_y_continuous(limits=c(80036, 364574)) +
    theme_void() +
    theme(legend.position="top") +
    theme(legend.title=element_blank()) +
    theme(legend.text=element_text(size=15)) +
    theme(axis.text=element_blank(), axis.title=element_text(size=15))
  png(filename = paste(here::here("_data/output",updateName,"figuresReporting"),"/","lastobsmap_",taxalist[i],".png",sep=""), width=600, height=450, units = "px", )
  print(p)
  dev.off()
  
  # # combine into two graphs
  # require(gridExtra)
  # grid.arrange(h, p, ncol=2)
}

# get old data
# get new data
SGCN_prev <- arc.open(path=here::here("_data/output/","_update2020q3","SGCN.gdb","allSGCNuse"))
SGCN_prev <- arc.select(SGCN_prev)
SGCN_prev_sf <- arc.data2sf(SGCN_prev)

# update tracking content
db <- dbConnect(SQLite(), dbname="E:/COA_Tools/_data/output/COA_QuarterlyTracking.sqlite")
updatetracker_SQLquery <- "SELECT * FROM updateMain"
updatetracker <- dbGetQuery(db, statement=updatetracker_SQLquery)
dbDisconnect(db) 

db <- dbConnect(SQLite(), dbname="E:/COA_Tools/_data/output/COA_QuarterlyTracking.sqlite")
updateNotes_SQLquery <- "SELECT * FROM updateNotes"
updatenotes <- dbGetQuery(db, statement=updateNotes_SQLquery)
dbDisconnect(db) 




##############################################################################################################
## Write the output document for the intro ###############
setwd(here::here("_data/output",updateName)) #, "countyIntros", nameCounty, sep="/")
pdf_filename <- paste(updateName,"_SixMonthReport",sep="") # ,gsub("[^0-9]", "", Sys.time() )
makePDF("SixMonthReporting.rnw", pdf_filename) # user created function
deletepdfjunk(pdf_filename) # user created function # delete .txt, .log etc if pdf is created successfully.
setwd(here::here()) # return to the main wd
beepr::beep(sound=10, expr=NULL)

