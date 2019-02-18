#-------------------------------------------------------------------------------
# Name:        5_BoundaryData.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-02-15
# Updated:     2019-02-15
#
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)

# Set input paths ----
databasename <- "coa_bridgetest.sqlite" 
databasename <- here("_data","output",databasename)