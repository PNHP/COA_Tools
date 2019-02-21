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


### Building Indexes
Indexes have to be created the sqlite db for performance reasons.  Execute the following SQL in the database.   NEED to build an R script to do this.

CREATE INDEX habitat ON lu_HabTerr (unique_id, Code);
CREATE INDEX habitataq ON lu_LoticData (unique_id, SUM_23);
CREATE INDEX maindex ON lu_sgcnXpu_all (unique_id,ELSeason);
CREATE INDEX muni ON lu_muni (unique_id);
CREATE INDEX natbound ON lu_NaturalBoundaries (unique_id);
CREATE INDEX proland ON lu_ProtectedLands_25 (unique_id);
CREATE INDEX threats ON lu_threats (unique_id)

## State Wide Species

## Misc Tools

ActionsCleanup.r
