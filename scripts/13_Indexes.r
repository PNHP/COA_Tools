#-------------------------------------------------------------------------------
# Name:        8_Indexes.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-04-09
# Updated:     
#
# To Do List/Future ideas:
# * 
#-------------------------------------------------------------------------------

# clear the environments
rm(list=ls())

# Run these in SQLite dbrowser

CREATE INDEX habitat ON lu_HabTerr (unique_id, Code);
CREATE INDEX habitataq ON lu_LoticData (unique_id, SUM_23);
CREATE INDEX maindex ON lu_sgcnXpu_all (unique_id, ELSeason);
CREATE INDEX muni ON lu_muni (unique_id);
CREATE INDEX natbound ON lu_NaturalBoundaries (unique_id);
CREATE INDEX proland ON lu_ProtectedLands_25 (unique_id);
CREATE INDEX threats ON lu_threats (unique_id);
CREATE INDEX lu_HabTerr_Code_index ON lu_HabTerr (Code);
CREATE INDEX lu_SpecialHabitats_unique_id_index ON lu_SpecialHabitats (unique_id);
CREATE INDEX lu_HabTerr_unique_id_index ON lu_HabTerr (unique_id);
CREATE INDEX lu_LoticData_unique_id_index ON lu_LoticData (unique_id);
CREATE INDEX lu_actionsLevel2_ELSeason_index ON lu_actionsLevel2 (ELSeason);
CREATE INDEX lu_SGCN_ELSeason_index ON lu_SGCN (ELSeason);
CREATE INDEX lu_PrimaryMacrogroup_ELSeason_index ON lu_PrimaryMacrogroup (ELSeason);
CREATE INDEX lu_SpeciesAccountPages_ELSeason_index ON lu_SpeciesAccountPages (ELCODE);



