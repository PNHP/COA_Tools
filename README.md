# COA_Tools
This is a collection of tools for developing the SQLite database that drives the Pennsylvania COA Tool.

## SGCN Data Collection


## Building and Populating the COA SQLite database

### Create and Empty COA database
The first step is to run '0_COAdb_creator.r' to create an empty SQLite database in the output directory.
### Create the SGCN tables
Next, run '1_insertSGCN.r' to create the 'lu_sgcn' table as the master list of SGCN. This script also creates the 'lu_taxagrp' table.
### County and Muncipal Boundaries
'2_insertCountyMuni.r'

## State Wide Species

## Misc Tools

ActionsCleanup.r
