# G-Lab_Menopause_Project
Author: Winston
Project: Determinants of early menopause (DHS)
Last updated: 22 December 2025

1. Overview
This repository contains a reproducible Stata pipeline and a pooled cross-country DHS women’s (IR) dataset constructed to study menopause outcomes across multiple countries. The current pooled dataset includes the following countries:
AF, BD, ID, IN, KH, MM, NP, PK, TL, TR
(Sri Lanka excluded: no DHS-7 women’s survey; Tajikistan pending DHS approval)
The pipeline is modular and designed to scale easily as additional countries are added.

2. Files included
Do-files
•	01_data_harmonization.do
Imports raw DHS IR files, constructs menopause outcomes, harmonises core covariates, and applies survey design.
•	07_build_cross_country_dataset.do
Loops over countries and builds the pooled cross-country dataset.
•	08_core_pooled_analysis_dataset.do
Datasets
•	IR_multicountry_menopause_harmonized.dta 
Full pooled dataset retaining all raw DHS variables alongside constructed outcomes and harmonised covariates.
•	IR_multicountry_menopause_core.dta (core extract; smaller file size)
Lean analysis-ready dataset retaining only harmonised variables used in baseline pooled analyses.

3. Outcome variables
•	menopause_any
Indicator for any menopause (natural or surgical), based on months since last period (v226) and amenorrhea/pregnancy information where applicable.
•	menopause_nat
Indicator for natural menopause, excluding women reporting hysterectomy.
•	hysterectomy
Derived from country-specific DHS variables (e.g. s253 where available).
Outcome construction follows DHS conventions and mirrors the approach in Karan Babbar (2024).

4. Core harmonised covariates (used in pooled analyses)
These variables are available across all or nearly all countries and are safe for pooled analysis:
•	Age: v012, v013
•	Education: educ4 (from v107)
•	Urban/rural residence: urban (from v025)
•	Wealth index: z_wealth (standardised within country from v191)
•	BMI: bmi (from v445)
•	Tobacco use: tobacco_any (from v463*)
•	Fertility history: v201, v212, v222
•	Media exposure: v157, v158, v159
Survey design variables (v005, v021, v022) are retained for all analyses.

5. Country-specific variables (retained but not pooled)
The following variables are retained where available but are not used in baseline pooled regressions:
•	Caste (s116) - India only
•	Religion (v130) - available in a subset of countries, with country-specific coding
•	Health insurance (v481) - available in a subset of countries
These variables are intended for country-specific or heterogeneity analyses.

6. Notes on missingness
Missing values primarily reflect DHS survey design (e.g. BMI not collected for pregnant women; outcome variables undefined for certain reproductive states). No duplicate women are present within country.

7. Reproducibility
All datasets can be rebuilt from raw DHS IR files by running the do-files in sequence. Paths and country lists are documented at the top of each script.

