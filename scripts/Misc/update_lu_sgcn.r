if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)

source(here::here("scripts", "00_PathsAndSettings.r"))


# compare the two most recent ETs
ET_path <- "P:/Conservation Programs/Natural Heritage Program/Data Management/Biotics Database Areas/Element Tracking/current element lists" # this is the path to the element tracking list folder on the p-drive in Pittsburgh.

# get the ET files
ET_file <- list.files(path=ET_path, pattern=".xlsx$")  # --- make sure your excel file is not open.
ET_file
# look at the output and choose which shapefile you want to run
# enter its location in the list (first = 1, second = 2, etc)

n_old <- 2  # number of the older ET
n_new <- 3  # number of the newer ET
ET_old <- ET_file[n_old]
ET_new <- ET_file[n_new]

# read the ET spreadsheet into a data frame
ET_old <- read.xlsx(xlsxFile=paste(ET_path,ET_old, sep="/"), skipEmptyRows=FALSE, rowNames=FALSE)  #, sheet=COA_actions_sheets[n]
ET_new <- read.xlsx(xlsxFile=paste(ET_path,ET_new, sep="/"), skipEmptyRows=FALSE, rowNames=FALSE)  #, sheet=COA_actions_sheets[n]

# cleanup
rm(n_old, n_new)


setdiff(names(ET_old), names(ET_new))
setdiff(names(ET_new), names(ET_old))

ET_new$`InER?` <- NULL


ET_new <- ET_new[which(ET_new$SGCN.STATUS=="Y"),]
ET_old <- ET_old[which(ET_old$SGCN.STATUS=="Y"),]

library(htmlTable)
library(compareDF)


a <- compare_df(ET_new, ET_old, group=c("SCIENTIFIC.NAME"))


create_output_table(a, output_type="html", file_name = "ETcompare.html")






####################################################


# make a backup
file.copy(here::here("_data","input","lu_sgcn.csv"), here::here("_data","input","lu_sgcn_old.csv"))


# load the lu_sgcn file
lu_sgcn <- read.csv(here::here("_data","input","lu_sgcn.csv"), stringsAsFactors = FALSE)

#get the ET
ET_path <- "P:/Conservation Programs/Natural Heritage Program/Data Management/Biotics Database Areas/Element Tracking/current element lists"
ET_file <- list.files(path=ET_path, pattern=".xlsx$")  # --- make sure your excel file is not open.
ET_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 6
ET_file <- paste(ET_path,ET_file[n], sep="/")

#get a list of the sheets in the file
ET_sheets <- getSheetNames(ET_file)
#look at the output and choose which excel sheet you want to load
# Enter the actions sheet (eg. "lu_actionsLevel2") 
ET_sheets # list the sheets
n <- 1 # enter its location in the list (first = 1, second = 2, etc)
ET <- read.xlsx(xlsxFile=ET_file, sheet=ET_sheets[n], skipEmptyRows=FALSE, rowNames=FALSE)

# subset by SGCN 
ET <- ET[which(ET$SGCN.STATUS=="Y"),] 

colnames(ET)[colnames(ET)=="SCIENTIFIC.NAME"] <- "SNAME"
colnames(ET)[colnames(ET)=="COMMON.NAME"] <- "SCOMNAME"
colnames(ET)[colnames(ET)=="G.RANK"] <- "GRANK"
colnames(ET)[colnames(ET)=="S.RANK"] <- "SRANK"
colnames(ET)[colnames(ET)=="PA.FED.STATUS"] <- "USESA"
colnames(ET)[colnames(ET)=="PA.STATUS"] <- "PA.STATUS"
colnames(ET)[colnames(ET)=="PBS.STATUS"] <- "PBS.STATUS"

setdiff(ET$ELCODE, lu_sgcn$ELCODE)


#################### 






