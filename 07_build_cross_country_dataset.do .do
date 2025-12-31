/****************************************************************************************
* PHASE 7 — BUILD CROSS-COUNTRY DHS MENOPAUSE DATASET (ROBUST VERSION)

* Input: Raw DHS IR files (DHS-7 where available)
* Output: IR_multicountry_menopause_harmonized.dta
*
* Notes:
* - Country-specific variables (e.g. caste, religion) retained where available
* - Core biological and socioeconomic variables harmonised across countries
* - Sri Lanka excluded (no DHS-7)
* - Tajikistan pending DHS approval
****************************************************************************************/

clear all
set more off
set maxvar 32767
version 18.0

*============================
* GLOBAL PATHS
*============================

global ROOT "/Users/winstonlingga/Desktop/RA with Gabriella Conti/DHS Data"
global RAW   "$ROOT/raw"
global CLEAN "$ROOT/clean"
global LOGS  "$ROOT/logs"

cap mkdir "$CLEAN"
cap mkdir "$LOGS"

*============================
* LOGGING 
*============================
capture log close
log using "$LOGS/07_phase7_build.log", replace text

*============================
* MASTER FILE 
*============================

global MASTER "$CLEAN/_master_multicountry_build.dta"
capture erase "$MASTER"
clear
save "$MASTER", emptyok replace



*============================
* DEFINE COUNTRY MAPPING
*============================

// Store countries in locals first (before any data operations)
local iso1 "IN"
local iso2 "NP" 
local iso3 "BD"
local iso4 "PK"
local iso5 "AF"
local iso6 "ID"
local iso7 "KH"
local iso8 "MM"
local iso9 "TL"
local iso10 "TR"

local file1 "IAIR7EFL.DTA"
local file2 "NPIR7HFL.DTA"
local file3 "BDIR72FL.DTA"
local file4 "PKIR71FL.DTA"
local file5 "AFIR71FL.DTA"
local file6 "IDIR71FL.DTA"
local file7 "KHIR73FL.DTA"
local file8 "MMIR71FL.DTA"
local file9 "TLIR71FL.DTA"
local file10 "TRIR71FL.DTA"

local n_countries 10

*============================
* LOOP OVER COUNTRIES
*============================

forvalues i = 1/`n_countries' {
    
    local iso "`iso`i''"
    local file "`file`i''"
    
    di "========================================"
    di "Processing country: `iso'"
    di "Looking for file: $RAW/`file'"
    
    capture confirm file "$RAW/`file'"
    if _rc {
        di as error "FILE NOT FOUND: $RAW/`file'"
        continue
    }

    use "$RAW/`file'", clear
    di "Loaded `iso' with " _N " observations"

    gen str3 ctry = "`iso'"
    
    *==================================================
    * PHASE 2 — OUTCOMES
    *==================================================

    * Hysterectomy
    capture drop hysterectomy
    capture confirm variable s253
    if !_rc gen byte hysterectomy = (s253 == 1)
    if _rc  gen byte hysterectomy = .
    label var hysterectomy "Hysterectomy"

    * Any menopause
    capture drop menopause_any
    gen byte menopause_any = .

    capture confirm variable v226
    if !_rc {
        replace menopause_any = 1 if inrange(v226,12,95)
        replace menopause_any = 0 if inrange(v226,0,11)
    }

    * Amenorrheic fallback
    capture confirm variable v405
    capture confirm variable v213
    if !_rc {
        replace menopause_any = 1 if v405==1 & (v213!=1 | missing(v213)) ///
            & missing(menopause_any)
    }

    * Natural menopause
    capture drop menopause_nat
    gen byte menopause_nat = menopause_any
    replace menopause_nat = . if hysterectomy==1


    *==================================================
    * PHASE 3 — CORE COVARIATES
    *==================================================

    * Education
    capture drop educ4
    gen byte educ4 = .
    capture confirm variable v107
    if !_rc {
        replace educ4 = 0 if v107==0
        replace educ4 = 1 if inrange(v107,1,5)
        replace educ4 = 2 if inrange(v107,6,11)
        replace educ4 = 3 if v107>=12
    }

    * Urban
    capture drop urban
    gen byte urban = .
    capture confirm variable v025
    if !_rc {
        replace urban = 1 if v025==1
        replace urban = 0 if v025==2
    }

    * BMI
    capture drop bmi
    capture confirm variable v445
    if !_rc gen double bmi = v445/100 if v445<9990

    * Wealth (within-country z-score)
    capture drop z_wealth
    capture confirm variable v191
    if !_rc egen double z_wealth = std(v191)

    * Tobacco
    capture drop tobacco_any
    gen byte tobacco_any = .
    capture confirm variable v463z
    if !_rc {
        replace tobacco_any = 1 if v463z==1
        replace tobacco_any = 0 if v463z==0
    }


    *==================================================
    * PHASE 4 — ANALYSIS SAMPLE FLAG
    *==================================================

    capture drop sample_analysis
    capture confirm variable v012
    if !_rc gen byte sample_analysis = inrange(v012,35,49) & !missing(menopause_nat)
    if _rc  gen byte sample_analysis = 0


    *==================================================
    * APPEND TO MASTER
    *==================================================

    append using "$MASTER"
    save "$MASTER", replace
}


*============================
* FINAL SAVE
*============================

use "$MASTER", clear

* Sanity check
describe
tab ctry

encode ctry, gen(country_id)
label var country_id "Country identifier"

save "$CLEAN/IR_multicountry_menopause_harmonized.dta", replace

log close

