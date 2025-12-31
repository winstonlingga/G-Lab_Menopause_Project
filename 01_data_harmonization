/********************************************************************************************
* Project: DHS Early Menopause Analysis
* Phase: 1-4 Dataset Merging and Harmonization


---------------------------------------------------------------------------------------------
 OVERVIEW OF PIPELINE
--------------------------------------------------------------------------------------------
 This file performs PHASES 1–4 of the project workflow:

 The aim of this script is to build a reproducible data pipeline that:
   1) standardises basic identifiers and menopause outcomes across DHS countries, and
   2) prepares a flexible structure where the final covariate list can be plugged in once agreed.
   
    PHASE 1 — Import and Stack Raw Data
        - Import the IR (women's) files for each country (e.g. India, Nepal)
        - Create a standard country identifier and keep all original DHS variables
        - Append country files into one master file for subsequent harmonisation

    PHASE 2 — Outcome Construction (core, non-controversial)
        - Construct `menopause_any`: any menopause based on months since last period and/or explicit "in menopause" labels (country-specific DHS coding)
        - Construct `hysterectomy` flag from the relevant textual labels
        - Construct `menopause_nat`: natural menopause derived from `menopause_any`, excluding women with hysterectomy
        - Keep all original DHS variables used to build these outcomes so that coding choices remain fully transparent and revisable

    PHASE 3 — Draft Covariate Harmonization (to be refined)
        - Create a small, modular set of draft harmonised covariates that can be
          easily expanded or modified after discussion, for example:
              • Basic demographics: age (v012, v013), parity (v201), marital status (v501)
              • Education: v107 → `educ4` (none/primary/secondary/higher)
              • Residence: v025 → `urban`
              • Wealth: v191, v190 → `z_wealth` and wealth quintiles
              • Health / behaviour: BMI (v445 → `bmi`), tobacco use (v463z / v463b–x)
              • Contraceptive use: v313
        - IMPORTANT: this phase is a working draft.
          The variable list and coding will be reviewed and adjusted with Karan
          before any large-scale merging or final analysis.

    PHASE 4 — Survey Design & Analysis Sample Definition
        - Apply DHS survey settings:
              svyset [pw = v005], strata(v022), psu(v021)
        - Define an initial analysis sample flag (e.g. `sample_analysis`) for women
          aged 35–49 with non-missing menopause outcomes, to be used in
          exploratory checks and models
        - Save:
              (a) country-level harmonised files
              (b) pooled stacked file (e.g. India + Nepal) as inputs for the separate analysis script (Phase 5–6)

 Output (paths to be adjusted to the project folder structure):
    - Country-level harmonised dataset(s): data_clean/IR_<country>_harmonized.dta
    - Pooled harmonised dataset for pilot countries (e.g. India + Nepal): data_clean/IR_IN_NP_menopause_stack_harmonized.dta

 Note:
    - All covariate construction is kept modular and can be edited in a single
      block once the final variable list is agreed with Karan.
    - No irreversible filtering or dropping of original DHS variables occurs here.
--------------------------------------------------------------------------------------------\
********************************************************************************************/ 
*============================
* 0. INITIAL SETUP
*============================

clear all
set more off
set linesize 120
version 18.0


global ROOT "/Users/winstonlingga/Desktop/RA with Gabriella Conti/DHS Data"

* ---- Country folders (current structure: india / nepal) ----
global INDIR  "$ROOT/IAIR7EDT"
global NPDIR  "$ROOT/NPIR82DT"

* ---- Centralised outputs ----
global CLEAN  "$ROOT/clean"
global FINAL  "$ROOT/final"
global LOGS   "$ROOT/logs"

cap mkdir "$CLEAN"
cap mkdir "$FINAL"
cap mkdir "$LOGS"

log using "$LOGS/01_data_harmonization.log", replace text

display "------------------------------------------------------------"
display "Starting DHS harmonization pipeline (Phases 1–4)"
display "Root:  $ROOT"
display "Time: " c(current_time) "  Date: " c(current_date)
display "------------------------------------------------------------"


********************************************************************************
* PHASE 1 — IMPORT AND STACK RAW INDIA + NEPAL IR DATA
********************************************************************************
set maxvar 32767

*------------- 1.1 INDIA -------------
local india_file  "IAIR7EFL.DTA"
display "Loading India IR file: `india_file'"
use "$INDIR/`india_file'", clear

* Create country tag (3-letter or 2-letter code; here "IN")
capture drop ctry
gen str3 ctry = "IN"
label var ctry "Country code (India)"

* Save a raw India-only copy
save "$CLEAN/IR_IN_raw.dta", replace

*------------- 1.2 NEPAL -------------
local nepal_file  "NPIR82FL.DTA"
display "Loading Nepal IR file: `nepal_file'"
use "$NPDIR/`nepal_file'", clear

capture drop ctry
gen str3 ctry = "NP"
label var ctry "Country code (Nepal)"

* Save a raw Nepal-only copy
save "$CLEAN/IR_NP_raw.dta", replace


*------------- 1.3 STACK INDIA + NEPAL -------------
display "Appending India + Nepal raw files..."

use "$CLEAN/IR_IN_raw.dta", clear
append using "$CLEAN/IR_NP_raw.dta"

compress
save "$CLEAN/IR_IN_NP_raw_stack.dta", replace

********************************************************************************
* PHASE 2 — MENOPAUSE OUTCOME CONSTRUCTION (ROBUST VERSION)
********************************************************************************

display "Constructing menopause outcomes (robust version)..."

*------------------------------------------------------------------*
* 2.1 HYSTERECTOMY INDICATOR (India only, safe elsewhere)
*------------------------------------------------------------------*

capture drop hysterectomy
capture confirm variable s253
if !_rc {
    gen byte hysterectomy = (s253 == 1) if !missing(s253)
    label var hysterectomy "Hysterectomy (s253)"
}
else {
    gen byte hysterectomy = .
    label var hysterectomy "Hysterectomy (not collected)"
}

label define hysto 0 "No" 1 "Yes"
label values hysterectomy hysto


*------------------------------------------------------------------*
* 2.2 ANY MENOPAUSE (inclusive definition)
*------------------------------------------------------------------*

capture drop menopause_any
gen byte menopause_any = .

* --- Rule A: Months since last period (preferred, if available) ---
capture confirm variable v226
if !_rc {
    replace menopause_any = 1 if inrange(v226, 12, 95)
    replace menopause_any = 0 if inrange(v226, 0, 11)
}

* --- Rule B: Amenorrheic but not pregnant (fallback) ---
* If v226 missing, use amenorrhea status
capture confirm variable v405
capture confirm variable v213
if !_rc {
    replace menopause_any = 1 if v405 == 1 & (v213 != 1 | missing(v213)) ///
        & missing(menopause_any)
}

label define menop 0 "Not menopausal" 1 "Menopausal"
label values menopause_any menop
label var menopause_any "Any menopause (inclusive)"


*------------------------------------------------------------------*
* 2.3 NATURAL MENOPAUSE (exclude hysterectomy)
*------------------------------------------------------------------*

capture drop menopause_nat
gen byte menopause_nat = menopause_any

* Exclude hysterectomy cases
replace menopause_nat = . if hysterectomy == 1

label var menopause_nat "Natural menopause (excl. hysterectomy)"

********************************************************************************
* PHASE 3 — DRAFT COVARIATE HARMONIZATION (to be refined)
********************************************************************************

*display "Constructing draft harmonised covariates..."

* ---- Age variables (keep original, add helper if needed) ----
*label var v012 "Age (years)"
*label var v013 "Age in 5-year groups"

* ---- Education: v107 (years) → educ4 ----
*capture drop educ4
*gen byte educ4 = .
*replace educ4 = 0 if v107 == 0
*replace educ4 = 1 if inrange(v107, 1, 5)
*replace educ4 = 2 if inrange(v107, 6, 11)
*replace educ4 = 3 if v107 >= 12

*label define educ4 0 "None" 1 "Primary" 2 "Secondary" 3 "Higher"
*label values educ4 educ4
*label var educ4 "Education level (4 categories from v107)"

* ---- Urban / rural: v025 → urban ----
*capture drop urban
*gen byte urban = .

*capture confirm numeric variable v025
*if !_rc {
 *   replace urban = 1 if v025 == 1   /* Urban */
  *  replace urban = 0 if v025 == 2   /* Rural */
}

*capture confirm string variable v025
*if !_rc {
*    replace urban = 1 if strpos(lower(v025), "urban") > 0
*    replace urban = 0 if strpos(lower(v025), "rural") > 0
}

*label define urb 0 "Rural" 1 "Urban"
*label values urban urb
*label var urban "Urban residence (v025)"

* ---- Wealth: v191 (factor score) → z_wealth; keep v190 as quintiles ----
*capture drop z_wealth
*capture confirm variable v191
*if !_rc {
  *  bysort ctry: egen double z_wealth = std(v191)
 *   label var z_wealth "Wealth factor score (standardised within country)"
}
*label var v190 "Wealth quintile (v190)"   // if present

* ---- BMI: v445 (two implied decimals) → bmi ----
*capture drop bmi
*gen double bmi = v445/100 if v445 < 9990
*label var bmi "Body Mass Index (kg/m^2)"

* ---- Tobacco use: v463z primary, fallback to v463b/c/i/ab ----
*capture drop tobacco_use
*gen byte tobacco_use = .

*capture confirm variable v463z
*if !_rc {
*    replace tobacco_use = 1 if v463z == 1    /* does not use tobacco */
*    replace tobacco_use = 0 if v463z == 0    /* uses tobacco */
}

*quietly ds v463b v463c v463i v463ab, has(type numeric)
*local specv `r(varlist)'
*if "`specv'" != "" {
 *   tempvar any_yes n_obs
  *  egen `any_yes' = rowmax(`specv')
   * egen `n_obs'   = rownonmiss(`specv')
    *replace tobacco_use = 0 if missing(tobacco_use) & `any_yes' == 1
    *replace tobacco_use = 1 if missing(tobacco_use) & `n_obs' > 0 & `any_yes' == 0
}

*label define tob 0 "Uses tobacco" 1 "Does not use tobacco"
*label values tobacco_use tob
*label var tobacco_use "Tobacco use (1 = does not use, 0 = uses)"

* ---- Reproductive & marital covariates ----
*label var v201 "Number of children ever born (v201)"
*label var v501 "Current marital status (v501)"
*label var v313 "Current contraceptive method type (v313)"

* ---- Country numeric id for factor vars later ----
*capture drop country_id
*encode ctry, gen(country_id)
*label var country_id "Country ID (encoded from ctry)"



********************************************************************************
* PHASE 3 — HARMONISED COVARIATES (CORE + KARAN LIST)
********************************************************************************

display "Constructing harmonised covariates..."

set maxvar 32676
use "/Users/winstonlingga/Desktop/RA with Gabriella Conti/DHS Data/clean/IR_IN_NP_raw_stack.dta"
capture confirm variable ctry
if _rc {
    di as error "ERROR: ctry not found. Did you load the stacked dataset?"
    exit 198
}
*---------------------------------------------*
* 0. COUNTRY IDENTIFIER
*---------------------------------------------*
capture drop country_id
encode ctry, gen(country_id)
label var country_id "Country ID (encoded)"


*---------------------------------------------*
* 1. CORE BASE VARIABLES (KEEP THESE!)
*---------------------------------------------*

* Age: keep raw (v012) and 5-year grouping (v013)
label var v012 "Age (years)"
label var v013 "Age in 5-year groups"

* Education — use your robust recode from v107
capture drop educ4
gen byte educ4 = .
replace educ4 = 0 if v107 == 0
replace educ4 = 1 if inrange(v107,1,5)
replace educ4 = 2 if inrange(v107,6,11)
replace educ4 = 3 if v107 >= 12
label define educ4 0 "None" 1 "Primary" 2 "Secondary" 3 "Higher"
label values educ4 educ4
label var educ4 "Education level (4-category recode)"

* Urban (v025 preferred over v102 for cross-country consistency)
capture drop urban
gen byte urban = .
capture confirm variable v025
if !_rc {
    replace urban = 1 if v025 == 1   // Urban
    replace urban = 0 if v025 == 2   // Rural
}
label define urb 0 "Rural" 1 "Urban"
label values urban urb
label var urban "Urban residence"

* Wealth (continuous z-score)
capture drop z_wealth
capture confirm variable v191
if !_rc {
    sort country_id
    by country_id: egen double z_wealth = std(v191)
    label var z_wealth "Wealth factor (std within country)"
}


* BMI (two implied decimals)
capture drop bmi
gen double bmi = v445/100 if v445 < 9990
label var bmi "Body Mass Index (kg/m^2)"

* Tobacco (simplified: DHS v463z)
capture drop tobacco_any
gen byte tobacco_any = .
capture confirm variable v463z
if !_rc {
    replace tobacco_any = 1 if v463z == 1   // NO tobacco
    replace tobacco_any = 0 if v463z == 0   // uses some tobacco
}
label define tob 0 "Uses tobacco" 1 "Does not use tobacco"
label values tobacco_any tob
label var tobacco_any "Any tobacco use"


*---------------------------------------------*
* 2. KARAN'S NFHS-5 VARIABLE LIST (SAFE BLOCKS)
*---------------------------------------------*

* Age (already have v012)
* Pregnancy status
capture drop pregnant
capture confirm variable v213
if !_rc gen pregnant = (v213 == 1)
if _rc  gen pregnant = .
label var pregnant "Currently pregnant (v213)"

* Amenorrheic
capture drop amenorrheic
capture confirm variable v405
if !_rc gen amenorrheic = (v405 == 1)
if _rc  gen amenorrheic = .
label var amenorrheic "Amenorrheic (v405)"

* Months since last period
capture drop months_last_period
capture confirm variable v226
if !_rc gen months_last_period = v226
if _rc  gen months_last_period = .
label var months_last_period "Months since last period (v226)"

* Hysterectomy (India only)
capture drop hyst_surg
capture confirm variable s253
if !_rc gen hyst_surg = (s253 == 1)
if _rc  gen hyst_surg = .
label var hyst_surg "Hysterectomy (s253, India only)"

* Place of hysterectomy
capture drop hyst_place
capture confirm variable s255
if !_rc gen hyst_place = s255
if _rc  gen hyst_place = .
label var hyst_place "Place hysterectomy performed (s255)"

* Area of living (v102)
capture drop area_v102
capture confirm variable v102
if !_rc gen area_v102 = v102
if _rc  gen area_v102 = .
label var area_v102 "Area of living (v102)"

* Education level (v106)
capture drop educ_level
capture confirm variable v106
if !_rc gen educ_level = v106
if _rc  gen educ_level = .
label var educ_level "Education level (v106)"

* Highest education (v107)
capture drop educ_years
capture confirm variable v107
if !_rc gen educ_years = v107
if _rc  gen educ_years = .
label var educ_years "Highest schooling years (v107)"

* Religion
capture drop religion
capture confirm variable v130
if !_rc gen religion = v130
if _rc  gen religion = .
label var religion "Religion (v130)"

* Caste (India only)
capture drop caste
capture confirm variable s116
if !_rc gen caste = s116
if _rc  gen caste = .
label var caste "Caste (India only)"

* Media exposure
foreach x in v157 v158 v159 {
    capture confirm variable `x'
    if !_rc {
        capture drop `x'_media
        gen `x'_media = `x'
        label var `x'_media "`x' media exposure"
    }
}

* Wealth quintile
capture drop wealth_quintile
capture confirm variable v190
if !_rc gen wealth_quintile = v190
if _rc  gen wealth_quintile = .
label var wealth_quintile "Wealth quintile (v190)"

* Hemoglobin level
capture drop haemoglobin
capture confirm variable v456
if !_rc gen haemoglobin = v456/10
if _rc  gen haemoglobin = .
label var haemoglobin "Hemoglobin level (g/dl)"

* Pregnancy loss (India only)
capture drop preg_loss
capture confirm variable s234
if !_rc gen preg_loss = (s234 == 1)
if _rc  gen preg_loss = .
label var preg_loss "Pregnancy ended in miscarriage/abortion/stillbirth (s234)"

* Fertility history
capture drop age_first_birth
capture confirm variable v212
if !_rc gen age_first_birth = v212
if _rc  gen age_first_birth = .
label var age_first_birth "Age at first birth (v212)"

capture drop num_children
capture confirm variable v201
if !_rc gen num_children = v201
if _rc  gen num_children = .
label var num_children "Number of children ever born (v201)"

capture drop last_birth_months
capture confirm variable v222
if !_rc gen last_birth_months = v222
if _rc  gen last_birth_months = .
label var last_birth_months "Months since last birth (v222)"

* Contraceptive usage/intention
capture drop contra_intent
capture confirm variable v364
if !_rc gen contra_intent = v364
if _rc  gen contra_intent = .
label var contra_intent "Contraceptive intention (v364)"

* Health insurance
capture drop insurance
capture confirm variable v481
if !_rc gen insurance = v481
if _rc  gen insurance = .
label var insurance "Health insurance (v481)"

* State / Region
capture drop state
capture confirm variable v024
if !_rc gen state = v024
if _rc  gen state = .
label var state "State / Region (v024)"

* District (India only)
capture drop district
capture confirm variable sdist
if !_rc gen district = sdist
if _rc  gen district = .
label var district "District (India-only)"

* Tobacco alternate indicators v463*
capture drop tobacco_alt
capture confirm variable v463a
if !_rc gen tobacco_alt = (v463a==1 | v463b==1 | v463c==1)
if _rc  gen tobacco_alt = .
label var tobacco_alt "Tobacco use (smoking/chewing)"

display "Covariate harmonisation finished."

********************************************************************************
* PHASE 4 — SURVEY DESIGN & ANALYSIS SAMPLE
********************************************************************************

display "Defining survey design and analysis sample..."

* ---- DHS survey design (can be reused in analysis scripts) ----
svyset [pw = v005], strata(v022) psu(v021) singleunit(centered)

* ---- Analysis sample: women 35–49 with valid natural menopause info ----
capture drop sample_analysis
gen byte sample_analysis = 0
replace sample_analysis = 1 if inrange(v012, 35, 49) & !missing(menopause_nat)

label define samp 0 "Excluded (<35 or missing)" 1 "Analysis sample 35–49"
label values sample_analysis samp
label var sample_analysis "Analysis sample: age 35–49 with non-missing menopause_nat"

* Quick sanity check
tab sample_analysis ctry, m
svy: tab menopause_nat v013, col


* ---- Save harmonised pooled dataset ----
* compress
save "$CLEAN/IR_IN_NP_menopause_stack_harmonized.dta", replace

display "------------------------------------------------------------"
display "Harmonisation complete. Saved to:"
display "    $CLEAN/IR_IN_NP_menopause_stack_harmonized.dta"
display "------------------------------------------------------------"

log close
exit
