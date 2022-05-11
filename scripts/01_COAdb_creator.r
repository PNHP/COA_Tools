#-------------------------------------------------------------------------------
# Name:        0_COAdb_creator.r
# Purpose:     Create an empty, new COA databases
# Author:      Christopher Tracey
# Created:     2019-02-14
# Updated:     2019-02-20
#
# Updates:
# * 2019-02-20 - minor cleanup and documentation
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------
# clear the environments
rm(list=ls())

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
source(here::here("scripts", "00_PathsAndSettings.r"))

# create an empty sqlite db
db <- dbConnect(SQLite(), dbname=databasename) # creates an empty COA database
dbDisconnect(db) # disconnect the db

# create an empty sqlite db for tracking
dbTrack <- dbConnect(SQLite(), dbname=trackingdatabasename) # creates an empty COA database
# create rank changes tracker
a <- c("TEXT", "TEXT", "TEXT", "TEXT", "TEXT", "TEXT", "TEXT", "TEXT", "TEXT", "REAL", "REAL", "TEXT", "TEXT", "TEXT")
names(a) <- c("ELCODE","SGCN_SNAME","SGCN_SCOMNAME","SGCN_GRANK","SGCN_SRANK", "ET_SNAME", "ET_SCOMNAME", "ET_GRANK", "ET_SRANK", "ET_SRANK.CHANGE.DATE", "ET_SRANK.REVIEW.DATE", "matchGRANK", "matchSRANK", "Name")
dbCreateTable(dbTrack, "changed_ranks", a)  # , "item"=TEXT, "filename"=TEXT, "lastmoddate"=REAL
# create file tracker
b <- c("TEXT","TEXT","TEXT","REAL")
names(b) <- c("NameUpdate","item","filename","lastmoddate")
dbCreateTable(dbTrack, "filetracker", b)  # , "item"=TEXT, "filename"=TEXT, "lastmoddate"=REAL
dbDisconnect(dbTrack) # disconnect the db


