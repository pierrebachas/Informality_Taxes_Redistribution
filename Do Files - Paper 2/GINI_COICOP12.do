	
	
	/* OPTIMAL TAX 
	
		1: scenario used to construct the dataset (central/robust/proba)
		
		*** Government Preferences:
		
		2: government preferences 1=welfarist (baseline), 2=poverty-averse
		3: government preference, if welfarist relative weight on bottom decile compared to top (Decreases by linear steps across deciles)
		4: government preferences, if poverty averse: decile above which household is considered non-poor (baseline - set to 0)
		5: government preferences, if povery averse: welfare weight of poor relative to non-poor (default is 2) (baseline - set to 0)
		6: value of public funds, set mu=`5' times the average welfare weight (baseline is 1)
		
		*** Structural Parameters: 
		7: Fix uncompensated price elasticites endogeneously (0,1). If 1: need to determine 8 and 9. if 0: need to determine 10
		8: value of price compensated own price elasticity (baseline = 0.5)	
		9: value of elasticity of compensated elasticity of substitution formal vs informal (baseline = 1.5)						
		10: Value chosen for all uncompensated elasticities if fixed exogenously (baseline needs to be set to baseline of 8 for consistency)
		
		*** Extensions:  	
		[For Removing Inequality] 
		11: =1 if remove inequalities in total expenditure (baseline), 0 otherwise	
		[for varying saving rates]
		12: savings_rate drops by that amount between decile  (baseline=0, when include savings =0.01)
		[for VAT on inputs]
		13: passthrough of taxes on informal prices (baseline =0, when include VAT on inputs for now 0.07)*
		14: of this program is not linked to the PIT but the rescaling of elasticities of goods for comparability
		
		Baseline		   central  1 10 0 0 1 1 0.7 1.5 1 0 0 0 1
		Baseline + Savings central  1 10 0 0 1 1 0.7 1.5 1 0 0.015 0 1
		Baseline + VAT	   central  1 10 0 0 1 1 0.7 1.5 1 0 0 0.07 1	
		Proba			   proba 	1 10 0 0 1 1 0.7 1.5 1 0 0 0 1
		Robust			   robust 	1 10 0 0 1 1 0.7 1.5 1 0 0 0 1	
		
		Baseline, e_c = 1 	central 1 10 0 0 1 1 0.7 1 1 0 0 0 1
		Baseline, e_c = 2	central 1 10 0 0 1 1 0.7 2 1 0 0 0 1
		
	*/
		


******************
**CONTROL CENTER**
******************

	local baseline 			= 0		// Baseline		  	  	central  1 10 0 0 1 1 0.7 1.5 1 0 0 0 1
	local baseline_VAT 		= 0		// Baseline + VAT	   	central  1 10 0 0 1 1 0.7 1.5 1 0 0 0.07 1	
	local baseline_savings 	= 1		// Baseline + Savings 	central  1 10 0 0 1 1 0.7 1.5 1 0 0.015 0 1
	local proba				= 0     // Proba			  	proba 	1 10 0 0 1 1 0.7 1.5 1 0 0 0 1
	local specific 			= 0		// Robust			   	robust 	1 10 0 0 1 1 0.7 1.5 1 0 0 0 1	
	local baseline_e_c_1 	= 0		// Baseline, e_c = 1 	central 1 10 0 0 1 1 0.7 1 1 0 0 0 1
	local baseline_e_c_2    = 0		// Baseline, e_c = 2	central 1 10 0 0 1 1 0.7 2 1 0 0 0 1

***************************************************
**PRELIMINARIES**
***************************************************
	set more off
	clear all 

	cap log close
	global scenario = "central"			// Choose scenario to be run: central, proba, robust, specific	

	display "$scenario"
	
*********************************************	
* DATA PREP
*********************************************

	foreach scenario in central proba specific { 
	* prep GDP data 
	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	
	rename Year year
	
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	save `gdp_data'	
		
	use "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}.dta", clear
	cap drop group 
	egen group = group(country_code percentile)
	tempfile temp
	save `temp' , replace
	reshape wide exp_total exp_informal, i(group) j(COICOP2) 
	cap drop group 
	
	sort country_code year
		merge m:1 country_code year using `gdp_data'	
		keep if _merge==3
		drop _merge
		gen ln_GDP = log(GDP_pc_constantUS2010)
		
	sort country
	save "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" , replace
	}

*********************************************	
* 1 BASELINE RESULTS (CENTRAL SCENARIO) 
*********************************************

if `baseline' {

	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12_new.do" 	
	optimal_tax_COICOP12 central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 1
	matrix redist = J(4,3,.) 	

	bys country: keep if _n==1
	sort country	
	
	*** Tax rates: weighted sum
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_A`i' = t_A_COICOP`i' *  s_A_COICOP`i'
	 }
	egen tax_weighted_A= rowtotal(tmp_tax_weighted_A*)
	sum tax_weighted_A
	
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_F`i' = t_F_COICOP`i' *  s_F_COICOP`i' 		// same weights as before maybe that odd ?
	 }
	egen tax_weighted_F= rowtotal(tmp_tax_weighted_F*)
	sum tax_weighted_F	
	
	* Save only needed info
	keep country t_A* t_F* decile

	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta"
	drop _merge 

	** Exp formal 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
			
	* Generate Taxed Shares
	
	forvalues i = 1(1)12 { 
		gen tax_A_`i' = (exp_total`i'* t_A_COICOP`i')
		gen tax_F_`i' = (exp_formal`i'* t_F_COICOP`i')
		}
		
	order tax_A*	
	egen taxed_share_A = rowtotal(tax_A_1-tax_A_12)
	replace taxed_share_A = taxed_share_A / exp_total0

	order tax_F*	
	egen taxed_share_F = rowtotal(tax_F_1-tax_F_12)
	replace taxed_share_F = taxed_share_F / exp_total0	
	
	** Tax Revenue collected in each scenario 
	
	/*
	forvalues i = 1(1)2 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}
	*/ 
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	foreach name in "A" "F" { 
		gen exp_total_post_tax`name' = (1-taxed_share_`name') * exp_total0
		ineqdeco exp_total_post_tax`name' , bygroup(group_country)
		gen gini_`name' = . 
		forvalues i = 1(1)32 { 
		replace gini_`name' =  `r(gini_`i')' if group_country == `i' 
		}
	}
		
	sort gini_pre
	
	foreach name in "A" "F" { 
		gen dif_gini_`name' =  gini_`name'- gini_pre  
		gen pct_dif_gini_`name' = 100 *( gini_`name' - gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if tag_country == 1		
	sum gini_pre  dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F 
	
	/*
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F  if ln_GDP>7.65
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if ln_GDP<7.65	
	*/ 
	
	save "$main/waste/cross_country/gini_${scenario}_baseline_coicop12.dta", replace 

}

	
*********************************************	
* 2. WITH VAT ON INPUTS 
*********************************************



if `baseline_VAT' {

	global vat_inputs = 0.07

	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12_new.do" 	
	optimal_tax_COICOP12 central 1 10 0 0 1 1 0.7 1.5 1 0 0 $vat_inputs 1
	matrix redist = J(4,3,.) 	

	bys country: keep if _n==1
	sort country	
	
	*** Tax rates: weighted sum
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_A`i' = t_A_COICOP`i' *  s_A_COICOP`i'
	 }
	egen tax_weighted_A= rowtotal(tmp_tax_weighted_A*)
	sum tax_weighted_A
	
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_F`i' = t_F_COICOP`i' *  s_F_COICOP`i' 		// same weights as before maybe that odd ?
	 }
	egen tax_weighted_F= rowtotal(tmp_tax_weighted_F*)
	sum tax_weighted_F	
	
	* Save only needed info
	keep country t_A* t_F*
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta"
	drop _merge 

	
	** Exp formal 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
			
	* Generate Taxed Shares
		
	forvalues i = 1(1)12 { 
		gen tax_A_`i' = (exp_total`i'* t_A_COICOP`i')
		gen tax_F_`i' = (exp_formal`i'* t_F_COICOP`i' + $vat_inputs * exp_informal`i'* t_F_COICOP`i')
		}
		
	order tax_A*	
	egen taxed_share_A = rowtotal(tax_A_1-tax_A_12)
	replace taxed_share_A = taxed_share_A / exp_total0

	order tax_F*	
	egen taxed_share_F = rowtotal(tax_F_1-tax_F_12)
	replace taxed_share_F = taxed_share_F / exp_total0	
	
	** Tax Revenue collected in each scenario 
	
	/*
	forvalues i = 1(1)2 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}
	*/ 
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	foreach name in "A" "F" { 
		gen exp_total_post_tax`name' = (1-taxed_share_`name') * exp_total0
		ineqdeco exp_total_post_tax`name' , bygroup(group_country)
		gen gini_`name' = . 
		forvalues i = 1(1)32 { 
		replace gini_`name' =  `r(gini_`i')' if group_country == `i' 
		}
	}
		
	sort gini_pre
	
	foreach name in "A" "F" { 
		gen dif_gini_`name' =  gini_`name'- gini_pre  
		gen pct_dif_gini_`name' = 100 *( gini_`name' - gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if tag_country == 1		
	sum gini_pre  dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F 
	
	save "$main/waste/cross_country/gini_central_baseline_vat_coicop12.dta", replace 

 }
	
***************************************************	
* 3 BASELINE RESULTS (CENTRAL SCENARIO) + SAVINGS 
***************************************************
if `baseline_savings' {

	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12_new.do" 	
	local savings_rate = 0.015   // Note this is the gap in savings rate across deciles, ranging from 0 to savings_rate * 10
	optimal_tax_COICOP12 central 1 10 0 0 1 1 0.7 1.5 1 0 `savings_rate' 0 1
	matrix redist = J(4,3,.) 	
	
	bys country: keep if _n==1
	sort country	

	*** Tax rates: weighted sum
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_A`i' = t_A_COICOP`i' *  s_A_COICOP`i'
	 }
	egen tax_weighted_A= rowtotal(tmp_tax_weighted_A*)
	sum tax_weighted_A
	
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_F`i' = t_F_COICOP`i' *  s_F_COICOP`i' 		// same weights as before maybe that odd ?
	 }
	egen tax_weighted_F= rowtotal(tmp_tax_weighted_F*)
	sum tax_weighted_F	
	
	* Save only needed info
	keep country t_A* t_F* decile
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta"
	drop _merge 
	
	** Exp formal 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
			
	merge m:1 country_code decile using "$main/proc/saving_rates.dta"
	drop _merge
	gen inc_total0 = exp_total0  / (1-saving_rate_country_decile)

		
	* Generate Taxed Shares
	
	forvalues i = 1(1)12 { 
		gen tax_A_`i' = (exp_total`i'* t_A_COICOP`i')
		gen tax_F_`i' = (exp_formal`i'* t_F_COICOP`i')
		}
		
	order tax_A*	
	egen taxed_share_A = rowtotal(tax_A_1-tax_A_12)
	replace taxed_share_A = taxed_share_A / inc_total0

	order tax_F*	
	egen taxed_share_F= rowtotal(tax_F_1-tax_F_12)
	replace taxed_share_F = taxed_share_F / inc_total0	
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	

	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	

	*************** TAX SCENARIOS ***************
	

	foreach name in "A" "F" { 
		gen exp_total_post_tax`name' = (1-taxed_share_`name') * exp_total0
		ineqdeco exp_total_post_tax`name' , bygroup(group_country)
		gen gini_`name' = . 
		forvalues i = 1(1)32 { 
		replace gini_`name' =  `r(gini_`i')' if group_country == `i' 
		}
	}
		
	sort gini_pre

	foreach name in "A" "F" { 
		gen dif_gini_`name' =  gini_`name'- gini_pre
		gen pct_dif_gini_`name' = 100 *( gini_`name' - gini_pre) / gini_pre
		}
	
	sum dif_gini_A dif_gini_F pct_dif_gini_A pct_dif_gini_F
	
	save "$main/waste/cross_country/gini_${scenario}_baseline_savings_coicop12.dta", replace 

	
}
*********************************************	
* 4. PROBA SCENARIO 
*********************************************
if `proba' {

	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12_new.do" 	
	optimal_tax_COICOP12 proba 1 10 0 0 1 1 0.7 1.5 1 0 0 0 1	
	matrix redist = J(4,3,.) 	

	bys country: keep if _n==1
	sort country	
	
	*** Tax rates: weighted sum
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_A`i' = t_A_COICOP`i' *  s_A_COICOP`i'
	 }
	egen tax_weighted_A= rowtotal(tmp_tax_weighted_A*)
	sum tax_weighted_A
	
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_F`i' = t_F_COICOP`i' *  s_F_COICOP`i' 		// same weights as before maybe that odd ?
	 }
	egen tax_weighted_F= rowtotal(tmp_tax_weighted_F*)
	sum tax_weighted_F	
	
	* Save only needed info
	keep country t_A* t_F*

	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_proba_reshaped.dta"
	drop _merge 


	** Exp formal 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
			
	* Generate Taxed Shares
	
	forvalues i = 1(1)12 { 
		gen tax_A_`i' = (exp_total`i'* t_A_COICOP`i')
		gen tax_F_`i' = (exp_formal`i'* t_F_COICOP`i')
		}
		
	order tax_A*	
	egen taxed_share_A = rowtotal(tax_A_1-tax_A_12)
	replace taxed_share_A = taxed_share_A / exp_total0

	order tax_F*	
	egen taxed_share_F = rowtotal(tax_F_1-tax_F_12)
	replace taxed_share_F = taxed_share_F / exp_total0	
	
	** Tax Revenue collected in each scenario 
	
	/*
	forvalues i = 1(1)2 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}
	*/ 
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	foreach name in "A" "F" { 
		gen exp_total_post_tax`name' = (1-taxed_share_`name') * exp_total0
		ineqdeco exp_total_post_tax`name' , bygroup(group_country)
		gen gini_`name' = . 
		forvalues i = 1(1)32 { 
		replace gini_`name' =  `r(gini_`i')' if group_country == `i' 
		}
	}
		
	sort gini_pre
	
	foreach name in "A" "F" { 
		gen dif_gini_`name' =  gini_`name'- gini_pre  
		gen pct_dif_gini_`name' = 100 *( gini_`name' - gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if tag_country == 1		
	sum gini_pre  dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F 
	
	/*
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F  if ln_GDP>7.65
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if ln_GDP<7.65
	*/ 
	
	save "$main/waste/cross_country/gini_proba_coicop12.dta", replace 

	}
*********************************************	
* 5. Country Specific  SCENARIO 
*********************************************
if `specific' {
	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12_new.do" 	
	optimal_tax_COICOP12 specific 1 10 0 0 1 1 0.7 1.5 1 0 0 0 1	
	matrix redist = J(4,3,.) 	

	bys country: keep if _n==1
	sort country	
	
	*** Tax rates: weighted sum
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_A`i' = t_A_COICOP`i' *  s_A_COICOP`i'
	 }
	egen tax_weighted_A= rowtotal(tmp_tax_weighted_A*)
	sum tax_weighted_A
	
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_F`i' = t_F_COICOP`i' *  s_F_COICOP`i' 		// same weights as before maybe that odd ?
	 }
	egen tax_weighted_F= rowtotal(tmp_tax_weighted_F*)
	sum tax_weighted_F	
	
	* Save only needed info
	keep country t_A* t_F*

	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_specific_reshaped.dta"
	drop _merge 


	
	** Exp formal 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
			
	* Generate Taxed Shares
	
	forvalues i = 1(1)12 { 
		gen tax_A_`i' = (exp_total`i'* t_A_COICOP`i')
		gen tax_F_`i' = (exp_formal`i'* t_F_COICOP`i')
		}
		
	order tax_A*	
	egen taxed_share_A = rowtotal(tax_A_1-tax_A_12)
	replace taxed_share_A = taxed_share_A / exp_total0

	order tax_F*	
	egen taxed_share_F = rowtotal(tax_F_1-tax_F_12)
	replace taxed_share_F = taxed_share_F / exp_total0	
	
	** Tax Revenue collected in each scenario 
	
	/*
	forvalues i = 1(1)2 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}
	*/ 
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	foreach name in "A" "F" { 
		gen exp_total_post_tax`name' = (1-taxed_share_`name') * exp_total0
		ineqdeco exp_total_post_tax`name' , bygroup(group_country)
		gen gini_`name' = . 
		forvalues i = 1(1)32 { 
		replace gini_`name' =  `r(gini_`i')' if group_country == `i' 
		}
	}
		
	sort gini_pre
	
	foreach name in "A" "F" { 
		gen dif_gini_`name' =  gini_`name'- gini_pre  
		gen pct_dif_gini_`name' = 100 *( gini_`name' - gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if tag_country == 1		
	sum gini_pre  dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F 
	
	/*
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F  if ln_GDP>7.65
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if ln_GDP<7.65		
	*/ 	
	
	save "$main/waste/cross_country/gini_specific_coicop12.dta", replace 

	}
****************************************************	
* 6. BASELINE RESULTS (CENTRAL SCENARIO)" e_c = 1  
*****************************************************
if `baseline_e_c_1' {
	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12_new.do" 	
	optimal_tax_COICOP12 central 1 10 0 0 1 1 0.7 1 1 0 0 0 1	
	matrix redist = J(4,3,.) 	

	bys country: keep if _n==1
	sort country	
	
	*** Tax rates: weighted sum
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_A`i' = t_A_COICOP`i' *  s_A_COICOP`i'
	 }
	egen tax_weighted_A= rowtotal(tmp_tax_weighted_A*)
	sum tax_weighted_A
	
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_F`i' = t_F_COICOP`i' *  s_F_COICOP`i' 		// same weights as before maybe that odd ?
	 }
	egen tax_weighted_F= rowtotal(tmp_tax_weighted_F*)
	sum tax_weighted_F	
	
	* Save only needed info
	keep country t_A* t_F*

	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta"
	drop _merge 


	
	** Exp formal 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
			
	* Generate Taxed Shares
	
	forvalues i = 1(1)12 { 
		gen tax_A_`i' = (exp_total`i'* t_A_COICOP`i')
		gen tax_F_`i' = (exp_formal`i'* t_F_COICOP`i')
		}
		
	order tax_A*	
	egen taxed_share_A = rowtotal(tax_A_1-tax_A_12)
	replace taxed_share_A = taxed_share_A / exp_total0

	order tax_F*	
	egen taxed_share_F = rowtotal(tax_F_1-tax_F_12)
	replace taxed_share_F = taxed_share_F / exp_total0	
	
	** Tax Revenue collected in each scenario 
	
	/*
	forvalues i = 1(1)2 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}
	*/ 
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	foreach name in "A" "F" { 
		gen exp_total_post_tax`name' = (1-taxed_share_`name') * exp_total0
		ineqdeco exp_total_post_tax`name' , bygroup(group_country)
		gen gini_`name' = . 
		forvalues i = 1(1)32 { 
		replace gini_`name' =  `r(gini_`i')' if group_country == `i' 
		}
	}
		
	sort gini_pre
	
	foreach name in "A" "F" { 
		gen dif_gini_`name' =  gini_`name'- gini_pre  
		gen pct_dif_gini_`name' = 100 *( gini_`name' - gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if tag_country == 1		
	sum gini_pre  dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F 
	
	/*
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F  if ln_GDP>7.65
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if ln_GDP<7.65		
	*/ 
	
	save "$main/waste/cross_country/gini_central_e_c_1_coicop12.dta", replace 

	}
***************************************************	
* 7. BASELINE RESULTS (CENTRAL SCENARIO) E_c = 2 
***************************************************
if `baseline_e_c_2' {
	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12_new.do" 	
	optimal_tax_COICOP12 central 1 10 0 0 1 1 0.7 2 1 0 0 0 1	
	matrix redist = J(4,3,.) 	

	bys country: keep if _n==1
	sort country	
	
	*** Tax rates: weighted sum
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_A`i' = t_A_COICOP`i' *  s_A_COICOP`i'
	 }
	egen tax_weighted_A= rowtotal(tmp_tax_weighted_A*)
	sum tax_weighted_A
	
	forvalues i = 1(1)12 {  
	 gen tmp_tax_weighted_F`i' = t_F_COICOP`i' *  s_F_COICOP`i' 		// same weights as before maybe that odd ?
	 }
	egen tax_weighted_F= rowtotal(tmp_tax_weighted_F*)
	sum tax_weighted_F	
	
	* Save only needed info
	keep country t_A* t_F*

	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta"
	drop _merge 


	
	** Exp formal 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
			
	* Generate Taxed Shares
	
	forvalues i = 1(1)12 { 
		gen tax_A_`i' = (exp_total`i'* t_A_COICOP`i')
		gen tax_F_`i' = (exp_formal`i'* t_F_COICOP`i')
		}
		
	order tax_A*	
	egen taxed_share_A = rowtotal(tax_A_1-tax_A_12)
	replace taxed_share_A = taxed_share_A / exp_total0

	order tax_F*	
	egen taxed_share_F = rowtotal(tax_F_1-tax_F_12)
	replace taxed_share_F = taxed_share_F / exp_total0	
	
	** Tax Revenue collected in each scenario 
	
	/*
	forvalues i = 1(1)2 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}
	*/ 
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	foreach name in "A" "F" { 
		gen exp_total_post_tax`name' = (1-taxed_share_`name') * exp_total0
		ineqdeco exp_total_post_tax`name' , bygroup(group_country)
		gen gini_`name' = . 
		forvalues i = 1(1)32 { 
		replace gini_`name' =  `r(gini_`i')' if group_country == `i' 
		}
	}
		
	sort gini_pre
	
	foreach name in "A" "F" { 
		gen dif_gini_`name' =  gini_`name'- gini_pre  
		gen pct_dif_gini_`name' = 100 *( gini_`name' - gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if tag_country == 1		
	sum gini_pre  dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F 
	
	/*
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F  if ln_GDP>7.65
	sum gini_pre dif_gini_A pct_dif_gini_A dif_gini_F pct_dif_gini_F   if ln_GDP<7.65		
	*/ 	
	save "$main/waste/cross_country/gini_${scenario}_e_c_2_coicop12.dta", replace 

	}
	
	
	
	
	
