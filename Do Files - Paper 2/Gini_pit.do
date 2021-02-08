
// Discuss all these issues with Anders: 

// TO discuss with Anders, many moving pieces when calculating GINI, including level of taxes, marginal cost of PF, transfers or not .
// These matter when we do the "flat" evaluation of scenario 1 vs the rest - relative results of 1 and 2, especially across development remain unchanged.
// Results when can tax everything depends a lot on levels of taxes since wide base
// think clearly what we want to come out of this: 
// (1) Informal sector can decrease GINI by around 2% points, 2.5/3 with rate dif. 
// (2) Rate differentiation helps to decrease GINI in middle income countries but not much in poorer ones. 
// (3) these results are robust to the inclusion of a PIT   

// Should the naive government be "dropped there" ? 
// since results operate through tax rates, it doesnt make a lot of sense to discuss the drop in inequality once there is no more rate dif: 
// If we want to mention this result I think we should fix the rates at the naive level and then apply the true formal tax bases ... but these rates
// are generally higher, thus leading to more redistribution ... so that is one result we had that was a bit "false"

// My suggestion discuss the naive case in the Tax rates part, this is what figure 7 is for, show that naive government does opposite
// over development in terms of rate dif. Then Just have a final figure with change in GINI over DEV:
// 																			Panel (A): Uniform rate (optimal) , Panel (B) dif rates

// Then all of our extensions can be shown in a figure like we have in appendix separating potentially low and middle income ... 
// Key extensions: PIT, Multiple rates (over 12 products), "robustness" (savings, inputs, other scenarios and elasticities), partially already discussed 
// Possibility: one figure which has the key extensions, and a table that has a lot more things ??? 


// The marginal cost of PF is crucial in the counterfactual scenario, 
// because there is much more revenue collected - does it make any sense though to compare them at this stage given all the moving pieces ... ? 
// They are not very comparable 

// The poverty averse government is interesting also, gives us a bit more redistribution.  
// Note: need to understand while some rich countries tax food more than non-food when can tax it all 
// There might be some odd income effects in the data which I need to revise. This explains in part why the rate dif with all does so little!


***************************************************
**PRELIMINARIES**
***************************************************
		
	clear all 
	set more off
	cap log close
	display "$scenario"
	
	* Control Center:
	
	local data_prep 	 	= 1
	local gini_main 	 	= 1 	// key numbers in paper, no PIT
	local gini_figure_paper = 0
	local baseline_VAT 		= 0		// Baseline + VAT	   	central  1 11 0 0 1 1 0.7 1.5 1 0 0 0.07 	
	local baseline_savings 	= 1		// Baseline + Savings 	central  1 11 0 0 1 1 0.7 1.5 1 0 0.015 0 
	local proba				= 0     // Proba			  	proba 	 1 11 0 0 1 1 0.7 1.5 1 0 0 0 
	local specific			= 0		// Country-specific		specific 1 11 0 0 1 1 0.7 1.5 1 0 0 0
	local baseline_e_c_1 	= 0		// Baseline, e_c = 1 	central  1 11 0 0 1 1 0.7 1 1 0 0 0 
	local baseline_e_c_2    = 0		// Baseline, e_c = 2	central  1 11 0 0 1 1 0.7 2 1 0 0 0 
	local gini_naive 	 	= 0  	// Applies optimal tax rates from the naive scenario 
	local gini_transfers 	= 0 	// no PIT, allow lump sum transfers
	local gini_pit  	 	= 0		// PIT 
	local gini_pit_figure  	= 0
	local baseline_VAT_pit 		= 0		// Baseline + VAT	   	central  1 11 0 0 1 1 0.7 1.5 1 0 0 0.07 	
	local baseline_savings_pit 	= 1		// Baseline + Savings 	central  1 11 0 0 1 1 0.7 1.5 1 0 0.015 0 
	local proba_pit				= 0    // Proba			  	proba 	 1 11 0 0 1 1 0.7 1.5 1 0 0 0 
	local specific_pit			= 0		// Country-specific		specific 1 11 0 0 1 1 0.7 1.5 1 0 0 0
	local baseline_e_c_1_pit	= 0		// Baseline, e_c = 1 	central  1 11 0 0 1 1 0.7 1 1 0 0 0 
	local baseline_e_c_2_pit    = 0		// Baseline, e_c = 2	central  1 11 0 0 1 1 0.7 2 1 0 0 0 

	
*********************************************	
* DATA PREP
*********************************************
	
	if `data_prep' { 
	
	*use "$main/proc/output_for_simulation_COICOP2_$scenario.dta" , replace

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
* 1 NO PIT, BUT NEW DATA (CENTRAL SCENARIO)
*********************************************
	if `gini_main'	{

	set more off
	matrix redist = J(4,3,.) 	
	 do "$main/dofiles/Optimal_tax_pit_program.do" 
	//do "$main/dofiles/test_countryspecific_incomeelasticities.do"  
	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_central_baseline_newdata.dta", replace 
}

}	


	if `gini_figure_paper' {

	use "$main/waste/cross_country/gini_central_baseline_newdata.dta", replace 
	
		keep if tag_country == 1	
		
		forvalues i = 1(1)3 {
			twoway (scatter pct_dif_gini_`i' ln_GDP) (lfit pct_dif_gini_`i' ln_GDP), name(G`i', replace) 
			}
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local ytitle "ytitle("Percentage Change in Gini" , margin(medsmall) size(`size'))"
	local yaxis "ylabel(-6(1)0, nogrid labsize(`size')) yscale(range(-6.2 0)) yline(-6(1)0, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
	
	#delim ; 
	
	twoway (scatter pct_dif_gini_2 ln_GDP,  `dots') (lfit pct_dif_gini_2 ln_GDP, lc(red)), 
	`yaxis' `ytitle' 
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_uniform, replace)  ; 
	graph export "$main/graphs/Gini_uniform.eps" , replace 	 ; 
	
	#delim cr		
	
	#delim ; 
	
	twoway (scatter pct_dif_gini_3 ln_GDP, `dots' ) (lfit pct_dif_gini_3 ln_GDP, lc(orange)), 
	`yaxis' `ytitle'
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_dif, replace)  ; 
	graph export "$main/graphs/Gini_ratedif.eps" , replace 	 ; 
	
	#delim cr		
			
	}	

******************************************************************		
* 1.2 NO PIT, BUT NEW DATA (CENTRAL SCENARIO) WITH VAT ON INPUTS *
******************************************************************	
	if `baseline_VAT'	{
	global vat_inputs = 0.1


	set more off
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 
	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 $vat_inputs 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_central_baseline_vat_newdata.dta", replace 
}

}	


*********************************************	
* 1.3 NO PIT, BUT NEW DATA (CENTRAL SCENARIO) WITH SAVINGS
*********************************************
	if `baseline_savings'	{

	set more off
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 
	local savings_rate = 0.015   // Note this is the gap in savings rate across deciles, ranging from 0 to savings_rate * 10

	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 `savings_rate' 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf  decile
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	* Country specific saving rates
	merge m:1 country_code decile using "$main/proc/saving_rates.dta"
	gen inc_total0 = exp_total0  / (1-saving_rate_country_decile)
	
			
	*Useful shares
	gen food_share=exp_total1/inc_total0
	
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = (exp_total1*t_A_food+exp_total2*t_A_nf)/inc_total0
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = (exp_formal0*t_F)/inc_total0
		
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = (exp_formal1*t_F_food +exp_formal2*t_F_nf )/inc_total0
	
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_central_baseline_savings_newdata.dta", replace 
}

}	

*********************************************	
* 1.4 PROBA SCENARIO , NO PIT BUT NEW DATA 
*********************************************
	if `proba'	{

	set more off
	matrix redist = J(4,3,.) 	
	 do "$main/dofiles/Optimal_tax_pit_program.do" 
	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit proba 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	

	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_proba_reshaped.dta" 
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_proba_baseline_newdata.dta", replace 
}

}	

*********************************************	
* 1.5 SPECIFIC SCENARIO , NO PIT BUT NEW DATA 
*********************************************
	if `specific'	{

	set more off
	matrix redist = J(4,3,.) 	
	 do "$main/dofiles/Optimal_tax_pit_program.do" 
	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit specific 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_specific_reshaped.dta" 
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_specific_baseline_newdata.dta", replace 
}

}	

*********************************************	
* 1.6 BASELINE RESULTS (CENTRAL SCENARIO)" e_c = 1  , NO PIT BUT NEW DATA 
*********************************************
	if `baseline_e_c_1'	{

	set more off
	matrix redist = J(4,3,.) 	
	 do "$main/dofiles/Optimal_tax_pit_program.do" 
	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1 1 0 0 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_central_e_c_1_baseline_newdata.dta", replace 
}

}	

*********************************************	
* 1.7 BASELINE RESULTS (CENTRAL SCENARIO)" e_c = 2 , NO PIT BUT NEW DATA 
*********************************************
	if `baseline_e_c_2'	{

	set more off
	matrix redist = J(4,3,.) 	
	 do "$main/dofiles/Optimal_tax_pit_program.do" 
	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 2 1 0 0 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_central_e_c_2_baseline_newdata.dta", replace 
}

}	
	

***********************************************************	
* 1.8 NO PIT, BUT USING NAIVE GOVERNMENT's TAX RATES 
***********************************************************
	if `gini_naive'	{

	set more off
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 
	// do "$main/dofiles/test_countryspecific_incomeelasticities.do"  
	
	// qui optimal_tax_pit central 2 10 3 7 1 1 0.7 1.5 1 0 0 0 0 0
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country
	sum t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	
		* Option to prevent food being more taxed than non food
		local blocked = 1
		if `blocked' {
			replace t_F_food = t_F_nf if t_F_food > t_F_nf
			replace t_A_food = t_A_nf if t_A_food > t_A_nf
		}	
	
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
	drop _merge 

	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
	
	** Use ratio to adjust rate, forcing the same "average tax rates": 
	gen ratio_temp = t_A_food / t_A_nf 
	
	replace t_F 	= 0.18	
	replace t_A_nf  = 0.18 
	replace t_F_nf  = 0.18 

	replace t_A_food = ratio_temp * t_A_nf
	replace t_F_food = ratio_temp * t_F_nf
	
	
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	
}

}		
	
	
	
	
	
	
*************************************************************	
* 1.9 NO PIT, BUT LUMP SUM REDISTRIBUTION 
*************************************************************
	if `gini_transfers'	{
	
	set more off
	use "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" , clear	
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf 
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
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
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_total0 + tax_rev`j' / 100
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j'_pit = . 
		forvalues i = 1(1)32 { 
		replace gini_`j'=  `r(gini_`i')' if group_country == `i' 
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
	
	save "$main/waste/cross_country/gini_central_baseline_newdata.dta", replace 
}

}		
	

	

**********************************************************************************		
* 2.1 GINI PIT :BASELINE RESULTS WITH PIT & NEW DATA (CENTRAL SCENARIO)
**********************************************************************************	

	local gini_pit = 1
	if `gini_pit'	{
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 1
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf size_pit mtr
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
	drop _merge 
	
	*USEFUL INTERMEDIARY VARIABLES
	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares (pre PIT)
	gen share_A_food=exp_total1/exp_total0
	gen share_A_nf=exp_total2/exp_total0
	gen share_F=exp_formal0/exp_total0
	gen share_F_food=exp_formal1/exp_total0
	gen share_F_nf=exp_formal2/exp_total0

	*CONSTRUCT INCOME EFFECTS
	{	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_${scenario}.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	
	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	

		*Construct income effects
		foreach name in "F" "A_food" "A_nf" "F_food" "F_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}
	
	}
	
	*CHANGES BECAUSE OF PIT
	*Amount of PIT paid
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=exp_total0 if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	cap drop pit_share
	gen pit_share=0
	replace pit_share=(mtr*(exp_total0-y_bar)/100)/exp_total0 if percentile>=size_pit
	
	*Income post PIT
	gen exp_post_pit=exp_total0*(1-pit_share)
	
	*Shares post PIT
	gen dy_pit=(exp_post_pit-exp_total0)/exp_total0 		//income change because of PIT
	
	foreach var in F  A_food A_nf F_food F_nf {
	gen share_`var'_post_pit= share_`var'*(1+dy_pit*(eta_`var'-1))
	}
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = t_A_food*share_A_food_post_pit+t_A_nf*share_A_nf_post_pit
	gen taxed_share1_pit = taxed_share1+pit_share
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F*share_F_post_pit
	gen taxed_share2_pit = taxed_share2+pit_share
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = t_F_food*share_F_food_post_pit +t_F_nf*share_F_nf_post_pit 
	gen taxed_share3_pit = taxed_share3+pit_share
	
	*Scenario 4: just PIT
	gen taxed_share4_pit = pit_share
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	ineqdeco exp_post_pit , bygroup(group_country)
	gen gini_post_pit = . 
	forvalues i = 1(1)32 { 
		replace gini_post_pit =  `r(gini_`i')' if group_country == `i' 
		}
		
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_post_pit // this is the income left after all the taxes
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3{ 
		gen dif_gini_`j'_all =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j'_all = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	sort gini_post_pit
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j'_cons_only =  gini_`j'- gini_post_pit  
		gen pct_dif_gini_`j'_cons_only  = 100 *( gini_`j'- gini_post_pit) / gini_post_pit
		}		
	
	*Gini effect of PIT only
	gen dif_gini_pit_only =  gini_post_pit- gini_pre
	gen pct_dif_gini_pit_only  = 100 *( gini_post_pit- gini_pre) / gini_pre
	
	sum gini_pre dif_gini_pit_only pct_dif_gini_pit_only 		// huge effect - 5.5%. twice as large as Lustig.	

	** Country by country changes in GINI coefficients: total effects PIT + comsumption taxes
	sum gini_pre dif_gini_1_all pct_dif_gini_1_all dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all
	// list country_code gini_pre dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all   if tag_country == 1		
		
	*new results, 'consumption tax only'
	*Use Gini post pit as starting point (lower inequality to start with)
	sum gini_post_pit dif_gini_1_cons_only pct_dif_gini_1_cons_only dif_gini_2_cons_only pct_dif_gini_2_cons_only dif_gini_3_cons_only pct_dif_gini_3_cons_only
		
	save "$main/waste/cross_country/gini_${scenario}_baseline_pit.dta", replace 
}

}	
	local gini_pit_figure = 1
	if `gini_pit_figure' {

	use "$main/waste/cross_country/gini_${scenario}_baseline_pit.dta", replace  
		
	keep if tag_country == 1	
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local ytitle "ytitle("Percentage Change in Gini" , margin(medsmall) size(`size'))"
	local yaxis "ylabel(-6(1)0, nogrid labsize(`size')) yscale(range(-6.2 0)) yline(-6(1)0, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
	
	#delim ; 
	
	twoway (scatter pct_dif_gini_2_cons_only ln_GDP,  `dots') (lfit pct_dif_gini_2_cons_only ln_GDP, lc(red)), 
	`yaxis' `ytitle' 
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_uniform, replace)  ; 
	graph export "$main/graphs/Gini_uniform_PIT.eps" , replace 	 ; 
	
	#delim cr		
	
	#delim ; 
	
	twoway (scatter pct_dif_gini_3_cons_only ln_GDP, `dots' ) (lfit pct_dif_gini_3_cons_only ln_GDP, lc(orange)), 
	`yaxis' `ytitle'
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_dif, replace)  ; 
	graph export "$main/graphs/Gini_ratedif_PIT.eps" , replace 	 ; 
	
	#delim cr		
			
	}	
	
	
		

**********************************************************************************		
* 2.2 GINI PIT :BASELINE RESULTS WITH PIT & NEW DATA (CENTRAL SCENARIO)  WITH VAT ON INPUTS 
**********************************************************************************	

	if `baseline_VAT_pit'	{
	global vat_inputs = 0.07

	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 $vat_inputs 1
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf size_pit mtr
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
	drop _merge 
	
	*USEFUL INTERMEDIARY VARIABLES
	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares (pre PIT)
	gen share_A_food=exp_total1/exp_total0
	gen share_A_nf=exp_total2/exp_total0
	gen share_F=exp_formal0/exp_total0
	gen share_F_food=exp_formal1/exp_total0
	gen share_F_nf=exp_formal2/exp_total0
	gen share_I=exp_informal0/exp_total0
	gen share_I_food=exp_informal1/exp_total0
	gen share_I_nf=exp_informal2/exp_total0
	
	*CONSTRUCT INCOME EFFECTS
	{	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_${scenario}.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	gen b_I_food = b_I_COICOP1

	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	

		*Construct income effects
		foreach name in "F" "I" "A_food" "A_nf" "F_food" "F_nf" "I_food" "I_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}
	
	}
	
	*CHANGES BECAUSE OF PIT
	*Amount of PIT paid
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=exp_total0 if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	cap drop pit_share
	gen pit_share=0
	replace pit_share=(mtr*(exp_total0-y_bar)/100)/exp_total0 if percentile>=size_pit
	
	*Income post PIT
	gen exp_post_pit=exp_total0*(1-pit_share)
	
	*Shares post PIT
	gen dy_pit=(exp_post_pit-exp_total0)/exp_total0 		//income change because of PIT
	
	foreach var in F I  A_food A_nf F_food F_nf I_food I_nf {
	gen share_`var'_post_pit= share_`var'*(1+dy_pit*(eta_`var'-1))
	}
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = t_A_food*share_A_food_post_pit+t_A_nf*share_A_nf_post_pit
	gen taxed_share1_pit = taxed_share1+pit_share
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F*(share_F_post_pit + share_I_post_pit* $vat_inputs ) // not sure
	gen taxed_share2_pit = taxed_share2+pit_share
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = t_F_food*(share_F_food_post_pit+ share_I_food_post_pit* $vat_inputs ) +t_F_nf*(share_F_nf_post_pit + share_I_nf_post_pit * $vat_inputs )
	gen taxed_share3_pit = taxed_share3+pit_share
	
	*Scenario 4: just PIT
	gen taxed_share4_pit = pit_share
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	ineqdeco exp_post_pit , bygroup(group_country)
	gen gini_post_pit = . 
	forvalues i = 1(1)32 { 
		replace gini_post_pit =  `r(gini_`i')' if group_country == `i' 
		}
		
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_post_pit // this is the income left after all the taxes
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3{ 
		gen dif_gini_`j'_all =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j'_all = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	sort gini_post_pit
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j'_cons_only =  gini_`j'- gini_post_pit  
		gen pct_dif_gini_`j'_cons_only  = 100 *( gini_`j'- gini_post_pit) / gini_post_pit
		}		
	
	*Gini effect of PIT only
	gen dif_gini_pit_only =  gini_post_pit- gini_pre
	gen pct_dif_gini_pit_only  = 100 *( gini_post_pit- gini_pre) / gini_pre
	
	sum gini_pre dif_gini_pit_only pct_dif_gini_pit_only 		// huge effect - 5.5%. twice as large as Lustig.	

	** Country by country changes in GINI coefficients: total effects PIT + comsumption taxes
	sum gini_pre dif_gini_1_all pct_dif_gini_1_all dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all
	// list country_code gini_pre dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all   if tag_country == 1		
		
	*new results, 'consumption tax only'
	*Use Gini post pit as starting point (lower inequality to start with)
	sum gini_post_pit dif_gini_1_cons_only pct_dif_gini_1_cons_only dif_gini_2_cons_only pct_dif_gini_2_cons_only dif_gini_3_cons_only pct_dif_gini_3_cons_only
		
	save "$main/waste/cross_country/gini_central_baseline_vat_pit.dta", replace 
}
	}
	
**********************************************************************************		
* 2.3 GINI PIT :BASELINE RESULTS WITH PIT & NEW DATA (CENTRAL SCENARIO) With SAVINGS
**********************************************************************************	

	if `baseline_savings_pit'	{
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 
	local savings_rate = 0.015   // Note this is the gap in savings rate across deciles, ranging from 0 to savings_rate * 10

	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 `savings_rate' 0 1
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf size_pit mtr decile
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
	drop _merge 
	
	*USEFUL INTERMEDIARY VARIABLES
	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
	
	merge m:1 country_code decile using "$main/proc/saving_rates.dta"
	drop _merge
	gen inc_total0 = exp_total0  / (1-saving_rate_country_decile)

			
	
	*CONSTRUCT INCOME EFFECTS
	{	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_${scenario}.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	gen b_I_food = b_I_COICOP1

	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	

		*Construct income effects
		foreach name in "F" "I" "A_food" "A_nf" "F_food" "F_nf" "I_food" "I_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}
	
	}
	
	*CHANGES BECAUSE OF PIT
	*Amount of PIT paid
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=inc_total0 if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	cap drop pit_share
	gen pit_share=0
	replace pit_share=(mtr*(inc_total0-y_bar)/100)/inc_total0 if percentile>=size_pit
	
	*Income post PIT
	gen exp_post_pit=exp_total0*(1-pit_share)
	
	*Shares post PIT
	gen dy_pit=(exp_post_pit-exp_total0)/exp_total0 		//income change because of PIT
	
	*Useful shares (pre PIT)
	gen share_A_food=exp_total1/inc_total0
	gen share_A_nf=exp_total2/inc_total0
	gen share_F=exp_formal0/inc_total0
	gen share_F_food=exp_formal1/inc_total0
	gen share_F_nf=exp_formal2/inc_total0
	gen share_I=exp_informal0/inc_total0
	gen share_I_food=exp_informal1/inc_total0
	gen share_I_nf=exp_informal2/inc_total0
	
	foreach var in F I  A_food A_nf F_food F_nf I_food I_nf {
	gen share_`var'_post_pit= share_`var'*(1+dy_pit*(eta_`var'-1))
	}
		
		
	
	
	
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = t_A_food*share_A_food_post_pit+t_A_nf*share_A_nf_post_pit
	gen taxed_share1_pit = taxed_share1+pit_share
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F*share_F_post_pit
	gen taxed_share2_pit = taxed_share2+pit_share
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = t_F_food*share_F_food_post_pit +t_F_nf*share_F_nf_post_pit 
	gen taxed_share3_pit = taxed_share3+pit_share
	
	*Scenario 4: just PIT
	gen taxed_share4_pit = pit_share
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	ineqdeco exp_post_pit , bygroup(group_country)
	gen gini_post_pit = . 
	forvalues i = 1(1)32 { 
		replace gini_post_pit =  `r(gini_`i')' if group_country == `i' 
		}
		
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_post_pit // this is the income left after all the taxes
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3{ 
		gen dif_gini_`j'_all =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j'_all = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	sort gini_post_pit
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j'_cons_only =  gini_`j'- gini_post_pit  
		gen pct_dif_gini_`j'_cons_only  = 100 *( gini_`j'- gini_post_pit) / gini_post_pit
		}		
	
	*Gini effect of PIT only
	gen dif_gini_pit_only =  gini_post_pit- gini_pre
	gen pct_dif_gini_pit_only  = 100 *( gini_post_pit- gini_pre) / gini_pre
	
	sum gini_pre dif_gini_pit_only pct_dif_gini_pit_only 		// huge effect - 5.5%. twice as large as Lustig.	

	** Country by country changes in GINI coefficients: total effects PIT + comsumption taxes
	sum gini_pre dif_gini_1_all pct_dif_gini_1_all dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all
	// list country_code gini_pre dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all   if tag_country == 1		
		
	*new results, 'consumption tax only'
	*Use Gini post pit as starting point (lower inequality to start with)
	sum gini_post_pit dif_gini_1_cons_only pct_dif_gini_1_cons_only dif_gini_2_cons_only pct_dif_gini_2_cons_only dif_gini_3_cons_only pct_dif_gini_3_cons_only
		
	save "$main/waste/cross_country/gini_${scenario}_baseline_savings_pit.dta", replace 
}

}		
	

**********************************************************************************		
* 2.4 GINI PIT :BASELINE RESULTS WITH PIT & NEW DATA (PROBA SCENARIO)
**********************************************************************************	

	if `proba_pit'	{
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 	
	qui optimal_tax_pit proba 1 11 0 0 1 1 0.7 1.5 1 0 0 0 1
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf size_pit mtr
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_proba_reshaped.dta" 
	drop _merge 
	
	*USEFUL INTERMEDIARY VARIABLES
	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares (pre PIT)
	gen share_A_food=exp_total1/exp_total0
	gen share_A_nf=exp_total2/exp_total0
	gen share_F=exp_formal0/exp_total0
	gen share_F_food=exp_formal1/exp_total0
	gen share_F_nf=exp_formal2/exp_total0

	*CONSTRUCT INCOME EFFECTS
	{	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_proba.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_proba.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_proba.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	
	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	

		*Construct income effects
		foreach name in "F" "A_food" "A_nf" "F_food" "F_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}
	
	}
	
	*CHANGES BECAUSE OF PIT
	*Amount of PIT paid
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=exp_total0 if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	cap drop pit_share
	gen pit_share=0
	replace pit_share=(mtr*(exp_total0-y_bar)/100)/exp_total0 if percentile>=size_pit
	
	*Income post PIT
	gen exp_post_pit=exp_total0*(1-pit_share)
	
	*Shares post PIT
	gen dy_pit=(exp_post_pit-exp_total0)/exp_total0 		//income change because of PIT
	
	foreach var in F  A_food A_nf F_food F_nf {
	gen share_`var'_post_pit= share_`var'*(1+dy_pit*(eta_`var'-1))
	}
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = t_A_food*share_A_food_post_pit+t_A_nf*share_A_nf_post_pit
	gen taxed_share1_pit = taxed_share1+pit_share
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F*share_F_post_pit
	gen taxed_share2_pit = taxed_share2+pit_share
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = t_F_food*share_F_food_post_pit +t_F_nf*share_F_nf_post_pit 
	gen taxed_share3_pit = taxed_share3+pit_share
	
	*Scenario 4: just PIT
	gen taxed_share4_pit = pit_share
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	ineqdeco exp_post_pit , bygroup(group_country)
	gen gini_post_pit = . 
	forvalues i = 1(1)32 { 
		replace gini_post_pit =  `r(gini_`i')' if group_country == `i' 
		}
		
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_post_pit // this is the income left after all the taxes
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3{ 
		gen dif_gini_`j'_all =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j'_all = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	sort gini_post_pit
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j'_cons_only =  gini_`j'- gini_post_pit  
		gen pct_dif_gini_`j'_cons_only  = 100 *( gini_`j'- gini_post_pit) / gini_post_pit
		}		
	
	*Gini effect of PIT only
	gen dif_gini_pit_only =  gini_post_pit- gini_pre
	gen pct_dif_gini_pit_only  = 100 *( gini_post_pit- gini_pre) / gini_pre
	
	sum gini_pre dif_gini_pit_only pct_dif_gini_pit_only 		// huge effect - 5.5%. twice as large as Lustig.	

	** Country by country changes in GINI coefficients: total effects PIT + comsumption taxes
	sum gini_pre dif_gini_1_all pct_dif_gini_1_all dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all
	// list country_code gini_pre dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all   if tag_country == 1		
		
	*new results, 'consumption tax only'
	*Use Gini post pit as starting point (lower inequality to start with)
	sum gini_post_pit dif_gini_1_cons_only pct_dif_gini_1_cons_only dif_gini_2_cons_only pct_dif_gini_2_cons_only dif_gini_3_cons_only pct_dif_gini_3_cons_only
		
	save "$main/waste/cross_country/gini_proba_baseline_pit.dta", replace 
}

}	

	
**********************************************************************************		
* 2.5 GINI PIT :BASELINE RESULTS WITH PIT & NEW DATA (COUNTRY SPECIFIC SCENARIO)
**********************************************************************************	

	if `specific_pit'	{
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 	
	qui optimal_tax_pit specific 1 11 0 0 1 1 0.7 1.5 1 0 0 0 1
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf size_pit mtr
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_specific_reshaped.dta" 
	drop _merge 
	
	*USEFUL INTERMEDIARY VARIABLES
	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares (pre PIT)
	gen share_A_food=exp_total1/exp_total0
	gen share_A_nf=exp_total2/exp_total0
	gen share_F=exp_formal0/exp_total0
	gen share_F_food=exp_formal1/exp_total0
	gen share_F_nf=exp_formal2/exp_total0

	*CONSTRUCT INCOME EFFECTS
	{	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_specific.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_specific.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_specific.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	
	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	

		*Construct income effects
		foreach name in "F" "A_food" "A_nf" "F_food" "F_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}
	
	}
	
	*CHANGES BECAUSE OF PIT
	*Amount of PIT paid
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=exp_total0 if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	cap drop pit_share
	gen pit_share=0
	replace pit_share=(mtr*(exp_total0-y_bar)/100)/exp_total0 if percentile>=size_pit
	
	*Income post PIT
	gen exp_post_pit=exp_total0*(1-pit_share)
	
	*Shares post PIT
	gen dy_pit=(exp_post_pit-exp_total0)/exp_total0 		//income change because of PIT
	
	foreach var in F  A_food A_nf F_food F_nf {
	gen share_`var'_post_pit= share_`var'*(1+dy_pit*(eta_`var'-1))
	}
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = t_A_food*share_A_food_post_pit+t_A_nf*share_A_nf_post_pit
	gen taxed_share1_pit = taxed_share1+pit_share
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F*share_F_post_pit
	gen taxed_share2_pit = taxed_share2+pit_share
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = t_F_food*share_F_food_post_pit +t_F_nf*share_F_nf_post_pit 
	gen taxed_share3_pit = taxed_share3+pit_share
	
	*Scenario 4: just PIT
	gen taxed_share4_pit = pit_share
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	ineqdeco exp_post_pit , bygroup(group_country)
	gen gini_post_pit = . 
	forvalues i = 1(1)32 { 
		replace gini_post_pit =  `r(gini_`i')' if group_country == `i' 
		}
		
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_post_pit // this is the income left after all the taxes
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3{ 
		gen dif_gini_`j'_all =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j'_all = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	sort gini_post_pit
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j'_cons_only =  gini_`j'- gini_post_pit  
		gen pct_dif_gini_`j'_cons_only  = 100 *( gini_`j'- gini_post_pit) / gini_post_pit
		}		
	
	*Gini effect of PIT only
	gen dif_gini_pit_only =  gini_post_pit- gini_pre
	gen pct_dif_gini_pit_only  = 100 *( gini_post_pit- gini_pre) / gini_pre
	
	sum gini_pre dif_gini_pit_only pct_dif_gini_pit_only 		// huge effect - 5.5%. twice as large as Lustig.	

	** Country by country changes in GINI coefficients: total effects PIT + comsumption taxes
	sum gini_pre dif_gini_1_all pct_dif_gini_1_all dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all
	// list country_code gini_pre dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all   if tag_country == 1		
		
	*new results, 'consumption tax only'
	*Use Gini post pit as starting point (lower inequality to start with)
	sum gini_post_pit dif_gini_1_cons_only pct_dif_gini_1_cons_only dif_gini_2_cons_only pct_dif_gini_2_cons_only dif_gini_3_cons_only pct_dif_gini_3_cons_only
		
	save "$main/waste/cross_country/gini_specific_baseline_pit.dta", replace 
}

}	
	
**********************************************************************************		
* 2.6 GINI PIT :BASELINE RESULTS WITH PIT & NEW DATA (CENTRAL SCENARIO) E_c = 1
**********************************************************************************	

	if `baseline_e_c_1_pit'	{
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1 1 0 0 0 1
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf size_pit mtr
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
	drop _merge 
	
	*USEFUL INTERMEDIARY VARIABLES
	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares (pre PIT)
	gen share_A_food=exp_total1/exp_total0
	gen share_A_nf=exp_total2/exp_total0
	gen share_F=exp_formal0/exp_total0
	gen share_F_food=exp_formal1/exp_total0
	gen share_F_nf=exp_formal2/exp_total0

	*CONSTRUCT INCOME EFFECTS
	{	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_${scenario}.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	
	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	

		*Construct income effects
		foreach name in "F" "A_food" "A_nf" "F_food" "F_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}
	
	}
	
	*CHANGES BECAUSE OF PIT
	*Amount of PIT paid
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=exp_total0 if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	cap drop pit_share
	gen pit_share=0
	replace pit_share=(mtr*(exp_total0-y_bar)/100)/exp_total0 if percentile>=size_pit
	
	*Income post PIT
	gen exp_post_pit=exp_total0*(1-pit_share)
	
	*Shares post PIT
	gen dy_pit=(exp_post_pit-exp_total0)/exp_total0 		//income change because of PIT
	
	foreach var in F  A_food A_nf F_food F_nf {
	gen share_`var'_post_pit= share_`var'*(1+dy_pit*(eta_`var'-1))
	}
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = t_A_food*share_A_food_post_pit+t_A_nf*share_A_nf_post_pit
	gen taxed_share1_pit = taxed_share1+pit_share
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F*share_F_post_pit
	gen taxed_share2_pit = taxed_share2+pit_share
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = t_F_food*share_F_food_post_pit +t_F_nf*share_F_nf_post_pit 
	gen taxed_share3_pit = taxed_share3+pit_share
	
	*Scenario 4: just PIT
	gen taxed_share4_pit = pit_share
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	ineqdeco exp_post_pit , bygroup(group_country)
	gen gini_post_pit = . 
	forvalues i = 1(1)32 { 
		replace gini_post_pit =  `r(gini_`i')' if group_country == `i' 
		}
		
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_post_pit // this is the income left after all the taxes
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3{ 
		gen dif_gini_`j'_all =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j'_all = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	sort gini_post_pit
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j'_cons_only =  gini_`j'- gini_post_pit  
		gen pct_dif_gini_`j'_cons_only  = 100 *( gini_`j'- gini_post_pit) / gini_post_pit
		}		
	
	*Gini effect of PIT only
	gen dif_gini_pit_only =  gini_post_pit- gini_pre
	gen pct_dif_gini_pit_only  = 100 *( gini_post_pit- gini_pre) / gini_pre
	
	sum gini_pre dif_gini_pit_only pct_dif_gini_pit_only 		// huge effect - 5.5%. twice as large as Lustig.	

	** Country by country changes in GINI coefficients: total effects PIT + comsumption taxes
	sum gini_pre dif_gini_1_all pct_dif_gini_1_all dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all
	// list country_code gini_pre dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all   if tag_country == 1		
		
	*new results, 'consumption tax only'
	*Use Gini post pit as starting point (lower inequality to start with)
	sum gini_post_pit dif_gini_1_cons_only pct_dif_gini_1_cons_only dif_gini_2_cons_only pct_dif_gini_2_cons_only dif_gini_3_cons_only pct_dif_gini_3_cons_only
		
	save "$main/waste/cross_country/gini_${scenario}_e_c_1_pit.dta", replace 
}

}	

	
	
	
**********************************************************************************		
* 2.7 GINI PIT :BASELINE RESULTS WITH PIT & NEW DATA (CENTRAL SCENARIO) E_c = 2
**********************************************************************************	

	if `baseline_e_c_2_pit'	{
	
	matrix redist = J(4,3,.) 	
	do "$main/dofiles/Optimal_tax_pit_program.do" 	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 2 1 0 0 0 1
	
	bys country: keep if _n==1
	keep country t_A t_F t_A_food t_F_food t_A_nf t_F_nf size_pit mtr
	sort country

	*merge 1:m country using "$main/waste/output_for_simulation_COICOP2_central.dta"
	merge 1:m country using "$main/proc/new_output_for_simulation_pct_COICOP2_${scenario}_reshaped.dta" 
	drop _merge 
	
	*USEFUL INTERMEDIARY VARIABLES
	** For simplicity: =just generate food and non food
		forvalues i = 3(1)12 {
			replace exp_total2 = exp_total2 + exp_total`i'
			replace exp_informal2 = exp_informal2 + exp_informal`i'
			}
		
		forvalues i = 0(1)2 { 
			gen exp_formal`i' = exp_total`i' - exp_informal`i'
			}
			
	*Useful shares (pre PIT)
	gen share_A_food=exp_total1/exp_total0
	gen share_A_nf=exp_total2/exp_total0
	gen share_F=exp_formal0/exp_total0
	gen share_F_food=exp_formal1/exp_total0
	gen share_F_nf=exp_formal2/exp_total0

	*CONSTRUCT INCOME EFFECTS
	{	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_${scenario}.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_${scenario}.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	
	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	

		*Construct income effects
		foreach name in "F" "A_food" "A_nf" "F_food" "F_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}
	
	}
	
	*CHANGES BECAUSE OF PIT
	*Amount of PIT paid
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=exp_total0 if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	cap drop pit_share
	gen pit_share=0
	replace pit_share=(mtr*(exp_total0-y_bar)/100)/exp_total0 if percentile>=size_pit
	
	*Income post PIT
	gen exp_post_pit=exp_total0*(1-pit_share)
	
	*Shares post PIT
	gen dy_pit=(exp_post_pit-exp_total0)/exp_total0 		//income change because of PIT
	
	foreach var in F  A_food A_nf F_food F_nf {
	gen share_`var'_post_pit= share_`var'*(1+dy_pit*(eta_`var'-1))
	}
		
	*Scenario 1: rate differentation, no informal sector
	gen taxed_share1 = t_A_food*share_A_food_post_pit+t_A_nf*share_A_nf_post_pit
	gen taxed_share1_pit = taxed_share1+pit_share
	
	*Scenario 2: uniform rate, with informal sector
	gen taxed_share2 = t_F*share_F_post_pit
	gen taxed_share2_pit = taxed_share2+pit_share
	
	*Scenario 3: rate differentation, with informal sector
	gen taxed_share3 = t_F_food*share_F_food_post_pit +t_F_nf*share_F_nf_post_pit 
	gen taxed_share3_pit = taxed_share3+pit_share
	
	*Scenario 4: just PIT
	gen taxed_share4_pit = pit_share
	
	egen tag_country = tag(country_code)	
	
*********************************************	
* GINI CALUCLATION
*********************************************	
{	
	sort country_code percentile 
	egen group_country = group(country_code) 
	ineqdeco exp_total0 , bygroup(group_country)

	gen gini_pre = . 
	forvalues i = 1(1)32 { 
		replace gini_pre =  `r(gini_`i')' if group_country == `i' 
		}
	
	ineqdeco exp_post_pit , bygroup(group_country)
	gen gini_post_pit = . 
	forvalues i = 1(1)32 { 
		replace gini_post_pit =  `r(gini_`i')' if group_country == `i' 
		}
		
	*************** TAX SCENARIOS ***************
	
	forvalues j  = 1(1)3 { 
		gen exp_total_post_tax`j' = (1-taxed_share`j') * exp_post_pit // this is the income left after all the taxes
		ineqdeco exp_total_post_tax`j' , bygroup(group_country)
		gen gini_`j' = . 
		forvalues i = 1(1)32 { 
		replace gini_`j' =  `r(gini_`i')' if group_country == `i' 
		}
		}
		
	sort gini_pre
	
	forvalues  j  = 1(1)3{ 
		gen dif_gini_`j'_all =  gini_`j'- gini_pre  
		gen pct_dif_gini_`j'_all = 100 *( gini_`j'- gini_pre) / gini_pre
		}

	sort gini_post_pit
	
	forvalues  j  = 1(1)3 { 
		gen dif_gini_`j'_cons_only =  gini_`j'- gini_post_pit  
		gen pct_dif_gini_`j'_cons_only  = 100 *( gini_`j'- gini_post_pit) / gini_post_pit
		}		
	
	*Gini effect of PIT only
	gen dif_gini_pit_only =  gini_post_pit- gini_pre
	gen pct_dif_gini_pit_only  = 100 *( gini_post_pit- gini_pre) / gini_pre
	
	sum gini_pre dif_gini_pit_only pct_dif_gini_pit_only 		// huge effect - 5.5%. twice as large as Lustig.	

	** Country by country changes in GINI coefficients: total effects PIT + comsumption taxes
	sum gini_pre dif_gini_1_all pct_dif_gini_1_all dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all
	// list country_code gini_pre dif_gini_2_all pct_dif_gini_2_all dif_gini_3_all pct_dif_gini_3_all   if tag_country == 1		
		
	*new results, 'consumption tax only'
	*Use Gini post pit as starting point (lower inequality to start with)
	sum gini_post_pit dif_gini_1_cons_only pct_dif_gini_1_cons_only dif_gini_2_cons_only pct_dif_gini_2_cons_only dif_gini_3_cons_only pct_dif_gini_3_cons_only
		
	save "$main/waste/cross_country/gini_${scenario}_e_c_2_pit.dta", replace 
}

}	
	
		
	
	
	
	
	
	
	
	
	
	

