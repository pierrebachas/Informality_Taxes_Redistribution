***************************************************
**PRELIMINARIES**
***************************************************

	
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
		
		Baseline		   central  1 10 0 0 1 1 0.7 1.5 1 0 0 0 
		Baseline + Savings central  1 10 0 0 1 1 0.7 1.5 1 0 0.015 0 
		Baseline + VAT	   central  1 10 0 0 1 1 0.7 1.5 1 0 0 0.07 	
		Proba			   proba 	1 10 0 0 1 1 0.7 1.5 1 0 0 0 
		Robust			   robust 	1 10 0 0 1 1 0.7 1.5 1 0 0 0	
		
		Baseline, e_c = 1 	central 1 10 0 0 1 1 0.7 1 1 0 0 0 
		Baseline, e_c = 2	central 1 10 0 0 1 1 0.7 2 1 0 0 0 
		
	*/
	****************************************************************************************************************
	
	
******************
**CONTROL CENTER**
******************


	local baseline 			= 1		// Baseline		  	  	central  1 10 0 0 1 1 0.7 1.5 1 0 0 0 
	local baseline_VAT 		= 1		// Baseline + VAT	   	central  1 10 0 0 1 1 0.7 1.5 1 0 0 0.07 	
	local baseline_savings 	= 1		// Baseline + Savings 	central  1 10 0 0 1 1 0.7 1.5 1 0 0.015 0 
	local proba				= 0     // Proba			  	proba 	1 10 0 0 1 1 0.7 1.5 1 0 0 0 
	local robust 			= 0		// Robust			  	robust 	1 10 0 0 1 1 0.7 1.5 1 0 0 0 	
	local baseline_e_c_1 	= 1		// Baseline, e_c = 1 	central 1 10 0 0 1 1 0.7 1 1 0 0 0 
	local baseline_e_c_2    = 1		// Baseline, e_c = 2	central 1 10 0 0 1 1 0.7 2 1 0 0 0 

	
	
***************************************************
**PRELIMINARIES**
***************************************************
		
	clear all 
	set more off
	cap log close
	
	display "$scenario"
	
*********************************************	
* DATA PREP
*********************************************
	foreach scenario in central proba robust { 
	
	use "$main/proc/output_for_simulation_COICOP2_$scenario.dta" , replace
	cap drop group 
	egen group = group(country_code decile)
	tempfile temp
	save `temp' , replace
	reshape wide exp_total exp_informal, i(group) j(COICOP2) 
	cap drop group 
	
	sort country_code year
		merge m:1 country_code year using "$main/data/country_information.dta"
		keep if _merge==3
		drop _merge
		gen ln_GDP = log(GDP_pc_constantUS2010)
		
	sort country
	save "$main/waste/output_for_simulation_COICOP2_$scenario_full.dta" , replace
	}
	
*********************************************	
* 1 BASELINE RESULTS (CENTRAL SCENARIO)
*********************************************
if `baseline' {

	set more off
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_program.do" 	
	qui optimal_tax central 1 10 0 0 1 1 0.7 1.5 1 0 0 0

	* magnitudes of tax rates
	
	sum t_A t_F t_A_food t_A_nf t_F_food t_F_nf
	tab country if t_F_food<0     //Chile has an actual subsidy on food

	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf
	sort country

	merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares
	gen food_share=exp_total1/exp_total0
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1*t_A_food+exp_total2*t_A_nf)/exp_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = (exp_formal0*t_F)/exp_total0
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (exp_formal1*t_F_food +exp_formal2*t_F_nf )/exp_total0

	** Tax Revenue collected in each scenario 
	forvalues i = 1(1)3 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}

	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code decile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)31 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)31 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j' =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j' = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3   if tag_country == 1		
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP>7.65
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP<7.65		
	
	save "$main/waste/cross_country/gini_central_baseline.dta", replace 
}
}
	
*********************************************	
* 2. WITH VAT ON INPUTS 
*********************************************

if `baseline_VAT' {
	global vat_inputs = 0.07
	
	set more off
	do "$main/dofiles/Optimal_tax_program.do" 	
	qui optimal_tax central 1 10 0 0 1 1 0.7 1.5 1 0 0 $vat_inputs
	matrix redist = J(4,3,.) 	
	
	* Magnitudes of tax rates
	sum t_*
	tab country if t_F_food<0     //Chile has an actual subsidy on food

	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf
	sort country

	merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares
	gen food_share = exp_total1/exp_total0
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1*t_A_food + exp_total2*t_A_nf ) / exp_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F * (exp_formal0 +  exp_informal0 * $vat_inputs ) / exp_total0
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (t_F_food * (exp_formal1 + exp_informal1* $vat_inputs ) +  t_F_nf * (exp_formal2 + exp_informal2 * $vat_inputs ))/exp_total0

	** Tax Revenue collected in each scenario 
	forvalues i = 1(1)3 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}

	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code decile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)31 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)31 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j' =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j' = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3   if tag_country == 1		
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP>7.65
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP<7.65		
	
	save "$main/waste/cross_country/gini_central_baseline_vat.dta", replace 
}
}
*********************************************	
* 3 RESULTS With SAVINGS
*********************************************


local baseline_savings = 1

if `baseline_savings' {


	set more off
	do "$main/dofiles/Optimal_tax_program.do" 	
	local savings_rate = 0.015   // Note this is the gap in savings rate across deciles, ranging from 0 to savings_rate * 10
	optimal_tax central 1 10 0 0 1 1 0.7 1.5 1 0 `savings_rate' 0	

	* magnitudes of tax rates
	
	sum t_A t_F t_A_food t_A_nf t_F_food t_F_nf
	tab country if t_F_food<0     //Chile has an actual subsidy on food

	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf
	sort country

	merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
		
	gen inc_total0 = 	.
	forvalues i = 1(1)10 { 		
		replace inc_total0 = exp_total0 / (1-`savings_rate'*`i')	if decile == `i'
		}
			
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1 * t_A_food + exp_total2 * t_A_nf) / inc_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = (exp_formal0 * t_F) / inc_total0
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (exp_formal1 * t_F_food + exp_formal2*t_F_nf ) / inc_total0

	** Tax Revenue collected in each scenario 
	forvalues i = 1(1)3 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}

	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code decile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country) 			

	gen gini_pre = . 
	forvalues i = 1(1)31 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0  
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)31 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j' =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j' = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3   if tag_country == 1		
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP>7.65
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP<7.65		

	save "$main/waste/cross_country/gini_central_baseline_savings.dta", replace 

}		
}		
		
*********************************************	
* 4. PROBA SCENARIO 
*********************************************


if `proba' {

	set more off
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_program.do" 	
	

	qui optimal_tax proba 1 10 0 0 1 1 0.7 1.5 1 0 0 0

	* magnitudes of tax rates
	
	sum t_A t_F t_A_food t_A_nf t_F_food t_F_nf
	tab country if t_F_food<0     //Chile has an actual subsidy on food

	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf
	sort country

	merge 1:m country using "$main/waste/output_for_simulation_COICOP2_proba.dta"
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares
	gen food_share=exp_total1/exp_total0
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1*t_A_food+exp_total2*t_A_nf)/exp_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = (exp_formal0*t_F)/exp_total0
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (exp_formal1*t_F_food +exp_formal2*t_F_nf )/exp_total0

	** Tax Revenue collected in each scenario 
	forvalues i = 1(1)3 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}

	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code decile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)31 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)31 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j' =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j' = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3   if tag_country == 1		
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3	
	
	save "$main/waste/cross_country/gini_proba.dta", replace 
}
}

*********************************************	
* 5. ROBUST  SCENARIO 
*********************************************
if `robust' {

	set more off
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_program.do" 	
	

	qui optimal_tax robust 1 10 0 0 1 1 0.7 1.5 1 0 0 0

	* magnitudes of tax rates
	
	sum t_A t_F t_A_food t_A_nf t_F_food t_F_nf
	tab country if t_F_food<0     //Chile has an actual subsidy on food

	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf
	sort country

	merge 1:m country using "$main/waste/output_for_simulation_COICOP2_robust.dta"
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares
	gen food_share=exp_total1/exp_total0
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1*t_A_food+exp_total2*t_A_nf)/exp_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = (exp_formal0*t_F)/exp_total0
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (exp_formal1*t_F_food +exp_formal2*t_F_nf )/exp_total0

	** Tax Revenue collected in each scenario 
	forvalues i = 1(1)3 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}

	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code decile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)31 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)31 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j' =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j' = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3   if tag_country == 1		
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3	
	
	save "$main/waste/cross_country/gini_robust.dta", replace 
}
}
****************************************************	
* 6. BASELINE RESULTS (CENTRAL SCENARIO)" e_c = 1  
*****************************************************
if `baseline_e_c_1' {

	set more off
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_program.do" 	
	

	qui optimal_tax central 1 10 0 0 1 1 0.7 1 1 0 0 0

	* magnitudes of tax rates
	
	sum t_A t_F t_A_food t_A_nf t_F_food t_F_nf
	tab country if t_F_food<0     //Chile has an actual subsidy on food

	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf
	sort country

	merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares
	gen food_share=exp_total1/exp_total0
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1*t_A_food+exp_total2*t_A_nf)/exp_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = (exp_formal0*t_F)/exp_total0
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (exp_formal1*t_F_food +exp_formal2*t_F_nf )/exp_total0

	** Tax Revenue collected in each scenario 
	forvalues i = 1(1)3 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}

	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code decile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)31 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)31 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j' =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j' = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3   if tag_country == 1		
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP>7.65
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP<7.65		
	
	save "$main/waste/cross_country/gini_central_e_c_1.dta", replace 
}
}
***************************************************	
* 7. BASELINE RESULTS (CENTRAL SCENARIO) E_c = 2 
***************************************************
if `baseline_e_c_2' {

	set more off
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_program.do" 	
	

	qui optimal_tax central 1 10 0 0 1 1 0.7 2 1 0 0 0

	* magnitudes of tax rates
	
	sum t_A t_F t_A_food t_A_nf t_F_food t_F_nf
	tab country if t_F_food<0     //Chile has an actual subsidy on food

	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf
	sort country

	merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares
	gen food_share=exp_total1/exp_total0
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1*t_A_food+exp_total2*t_A_nf)/exp_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = (exp_formal0*t_F)/exp_total0
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (exp_formal1*t_F_food +exp_formal2*t_F_nf )/exp_total0

	** Tax Revenue collected in each scenario 
	forvalues i = 1(1)3 {
		gen tmp_tax_rev_`i' =  taxed_share`i' * exp_total0
		bysort country: egen tax_rev`i' = total(tmp_tax_rev_`i')
		gen exp_total0_post_redist`i' = (1-taxed_share`i') * exp_total0 + (tax_rev`i' / 10)		
		drop tmp_tax_rev_`i' 
		}

	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code decile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)31 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)31 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j' =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j' = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	** Country by country changes in GINI coefficients 
	list country_code gini_pre dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3   if tag_country == 1		
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP>7.65
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 if ln_GDP<7.65		
	
	save "$main/waste/cross_country/gini_central_e_c_2.dta", replace 
}
}


		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
