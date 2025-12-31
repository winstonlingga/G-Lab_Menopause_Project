/*******************************************************************************************
 Project:  Determinants of Early Menopause — DHS Multi-Country Study
 Author:   Winston Lingga Ho
 File:     02_analysis_phase5_6.do
 Purpose:  Use the harmonised dataset produced in 01_data_harmonization.do and carry out all descriptive statistics and regression modelling for the pilot countries (India and Nepal).
		   
Overview of workflow:
 --------------------------------------------------------------------------------------------
 PHASE 5 – Descriptive Statistics
     - Load the harmonised DHS dataset for India and Nepal.
     - Reapply the DHS survey design settings (svyset).
     - Produce the key descriptive tabulations:
           • Any and natural menopause by country
           • Natural menopause by age (v013), education (educ4), and urban residence
           • Mean wealth and BMI by menopause status
     - These checks confirm that menopause outcomes and covariates have been
       constructed correctly in Phases 1–4.

 PHASE 6 – Survey-Weighted Logistic Regression
     - Estimate survey-weighted logistic regressions for:
           (1) Any menopause (including surgical cases)
           (2) Natural menopause (excluding hysterectomy)
     - Restrict analysis to women aged 35–49 with valid outcome information
       (sample_analysis == 1).
     - Store regression results for documentation and later comparison.
     - Compute marginal effects (margins) and generate:
           • Predicted probability of natural menopause by age group
           • Predicted probability of natural menopause by education level
     - Export margins plots for presentation.

 Next Steps – PHASE 7 (to be run after covariate list is approved)
     - Automate the analysis for multiple DHS countries:
           • Loop over each country's IR file
           • Apply Phases 1–4 harmonisation to each country
           • Run the same descriptive statistics and regression models
           • Save harmonised country-level datasets and regression output
           • Build a cross-country summary table of coefficients
           • Optionally combine all harmonised datasets into one multi-country file
    

 
    The code is modular: covariates and models can be adjusted.		   
********************************************************************************************/

clear all
set more off
set linesize 120
version 18.0

* ---- EDIT THIS: keep ROOT consistent with 01_data_harmonization.do ----
global ROOT "/Users/winstonlingga/Desktop/RA with Gabriella Conti/DHS Data"
global CLEAN "$ROOT/clean"
global GRAPHS "$ROOT/graphs"
global LOGS   "$ROOT/logs"

cap mkdir "$GRAPHS"
cap mkdir "$LOGS"

log using "$LOGS/02_analysis_phase5_6.log", replace text

display "------------------------------------------------------------"
display "Starting Phase 5–6 analysis"
display "Data: $CLEAN/IR_IN_NP_menopause_stack_harmonized.dta"
display "------------------------------------------------------------"

*============================
* 1. LOAD HARMONISED DATA
*============================

use "/Users/winstonlingga/Desktop/RA with Gabriella Conti/DHS Data/clean/IR_IN_NP_menopause_stack_harmonized.dta", clear

* Re-apply survey design (svyset is not stored inside .dta)
svyset [pw=v005], strata(v022) psu(v021) singleunit(centered)

* Quick sanity: key variables should already exist from Phase 1–4
describe menopause_any menopause_nat hysterectomy educ4 urban bmi z_wealth ///
         tobacco_use v012 v013 v201 v501 v313 ctry country_id sample_analysis

********************************************************************************
* PHASE 5 — DESCRIPTIVE STATISTICS (using harmonised vars)
********************************************************************************

* 5.1 Basic distribution by country
svy: tab menopause_any ctry, col
svy: tab menopause_nat  ctry, col

* 5.2 Age gradient (all 15–49, then analysis sample 35–49)
svy: tab menopause_nat v013, col
svy: tab menopause_nat v013 if sample_analysis==1, col

* 5.3 Education and urban–rural differences (analysis sample)
svy: tab menopause_nat educ4 if sample_analysis==1, col
svy: tab menopause_nat urban  if sample_analysis==1, col

* 5.4 Means of continuous covariates by natural menopause status
svy: mean bmi z_wealth if sample_analysis==1 & menopause_nat==1
svy: mean bmi z_wealth if sample_analysis==1 & menopause_nat==0

********************************************************************************
* PHASE 6 — SURVEY-WEIGHTED REGRESSION MODELS (UPDATED FOR KARAN'S VARIABLES)
********************************************************************************
/*
display "Running survey-weighted regressions (Phase 6)..."

* Survey design (from Phase 4)
svyset [pw = v005], psu(v021) strata(v022) singleunit(centered)


********************************************************************************
* 6.1 MAIN MODEL — Natural menopause as outcome
********************************************************************************

* Reduced multicollinearity version (recommended first pass)
* Start with essential demographic, SES, reproductive & health variables

svy: logistic menopause_nat ///
    i.v013 /// Age groups 35-39, 40-44, 45-49
    educ4 /// Your clean 4-level education variable
    urban /// Uses v025; consistent across DHS
    c.z_wealth /// Within-country SES
    c.bmi /// Body Mass Index
    tobacco_any /// Simplified tobacco variable
    pregnant amenorrheic ///
    num_children ///
    age_first_birth ///
    last_birth_months ///
    contra_intent ///
    religion ///
    insurance ///
    i.country_id ///
    if sample_analysis==1

estimates store model_red



	
svy: logistic menopause_nat ///
    i.v013 ///
    educ4 ///
    urban ///
    z_wealth ///
    bmi ///
    tobacco_any ///
    pregnant amenorrheic ///
    age_first_birth num_children ///
    contra_intent ///
    religion ///
    insurance ///
    preg_loss ///
    haemoglobin ///
    i.country_id ///
    if sample_analysis==1

********************************************************************************
* 6.2 FULL MODEL — Karan's complete variable list
********************************************************************************

* WARNING: may cause more collinearity drops; this is expected

*svy: logistic menopause_nat ///
    i.v013 ///
    educ4 ///
    urban ///
    c.z_wealth ///
    c.bmi ///
    tobacco_any ///
    pregnant amenorrheic ///
    months_last_period ///
    hysterectomy ///
    age_first_birth ///
    num_children ///
    last_birth_months ///
    contra_intent ///
    haemoglobin ///
    preg_loss ///
    religion caste ///
    read_news listen_radio watch_tv ///
    wealth_quintile ///
    insurance ///
    state ///
    i.country_id ///
    if sample_analysis==1*

*Trimmed variable list since the full list shows perfect prediction or empty categories
svy: logistic menopause_nat ///
    i.v013 ///
    educ4 ///
    urban ///
    z_wealth ///
    bmi ///
    tobacco_any ///
    pregnant amenorrheic ///
    age_first_birth num_children ///
    contra_intent ///
    religion ///
    insurance ///
    preg_loss ///
    haemoglobin ///
    i.country_id ///
    if sample_analysis==1

estimates store model_full


********************************************************************************
* 6.3 Average marginal effects (AMEs)
********************************************************************************

* Use reduced model to avoid multi-collinearity noise

estimates restore model_red

margins, dydx( ///
    v013 ///
    educ4 ///
    urban ///
    z_wealth ///
    bmi ///
    tobacco_any ///
    pregnant ///
    amenorrheic ///
    num_children ///
    )

estimates store ame_red


********************************************************************************
* 6.4 MARGINS PLOTS
* Age gradient

margins v013
marginsplot, ///
    title("Predicted Probability of Natural Menopause by Age Group") ///
    name(plot_age, replace)

* Education gradient
margins educ4
marginsplot, ///
    title("Predicted Probability of Natural Menopause by Education") ///
    name(plot_educ, replace)


display "Phase 6 complete."
*/
********************************************************************************
* PHASE 6 (simple mode)— CORE VALIDATION MODELS 
********************************************************************************

use "$CLEAN/IR_IN_NP_menopause_stack_harmonized.dta", clear
svyset [pw=v005], psu(v021) strata(v022) singleunit(centered)

* Restrict to analysis sample
keep if sample_analysis == 1

* -------------------------------
* 6.1 Descriptive age gradient
* -------------------------------
svy: tab menopause_nat v013, col

* -------------------------------
* 6.2 Core cross-country model
* -------------------------------
svy: logistic menopause_nat ///
    i.v013 ///
    educ4 ///
    urban ///
    z_wealth ///
    bmi ///
    tobacco_any ///
    i.country_id

est store core_model

* -------------------------------
* 6.3 Marginal effects (optional)
* -------------------------------
margins v013
margins educ4


********************************************************************************
* 7. SAVE ESTIMATION RESULTS & CLOSE LOG
********************************************************************************

est save "$CLEAN/phase6_models_IN_NP.ster", replace

log close
exit
