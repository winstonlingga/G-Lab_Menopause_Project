/****************************************************************************************
* PHASE 8 —  Core pooled analysis dataset
* Purpose: Lean extract for pooled regressions (drops country-specific variables)
****************************************************************************************/

clear all
set more off
version 18.0
set maxvar 36000
* ----------------------------
* Paths 
* ----------------------------
global ROOT  "/Users/winstonlingga/Desktop/RA with Gabriella Conti/DHS Data"
global CLEAN "$ROOT/clean"

* ----------------------------
* Load full pooled dataset
* ----------------------------
use "$CLEAN/IR_multicountry_menopause_harmonized.dta", clear

* ----------------------------
* Keep core variables only
* ----------------------------
keep ///
    ctry country_id ///
    v001 v002 v003 v005 v021 v022 ///
    v012 v013 ///
    menopause_any menopause_nat hysterectomy ///
    educ4 urban z_wealth bmi tobacco_any ///
    v201 v212 v222 ///
    v157 v158 v159 ///
    sample_analysis

* ----------------------------
* Optimise size
* ----------------------------
compress

* ----------------------------
* Save core pooled dataset
* ----------------------------
save "$CLEAN/IR_multicountry_menopause_core.dta", replace

display "Core pooled dataset created successfully."
exit

use "$CLEAN/IR_multicountry_menopause_core.dta", clear
describe
tab ctry
