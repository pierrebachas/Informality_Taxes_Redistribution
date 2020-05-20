					*************************************
					* 		MECHANICAL SIMULATIONS + 		*
					*************************************
***************************************************
**PRELIMINARIES**
***************************************************

	clear all 
	set more off
	cap log close
	
	display "$scenario"
	
*********************************************	
* 0.1 Make consumption data Wide
*********************************************		
		
	local gen_wide_data =1
	if `gen_wide_data' { 
	
	use "$main/proc/output_for_simulation_COICOP2_$scenario.dta", replace
	// keep if country_code == "CO"			// To run on one country select its acronym  
	egen group = group(country_code decile) 
	
	preserve 
	tempfile temp_data 
	duplicates drop group country_code decile, force
	keep group country_code decile
	save `temp_data' , replace 
	restore
	
	keep group exp_total exp_informal COICOP2
	reshape wide exp_total exp_informal, i(group) j(COICOP2)
	
	merge 1:1 group using `temp_data'
	
	drop group _merge 
	save "$main/waste/output_for_simulation_COICOP2_$scenario.dta", replace
	
	} 
	
	local slopes_by_coicop2 = 1
	if `slopes_by_coicop2' { 	
	
	use "$main/waste/output_for_simulation_COICOP2_$scenario.dta" , replace	
	forvalues i = 1(1)12 { 
		gen share_coicop`i' = exp_total`i' / exp_total0
		}
		
	collapse share_coicop1-share_coicop12, by(decile)
	
	local all_coicop = 0
	if `all_coicop' {
	forvalues i = 1(1)12 { 
	twoway scatter share_coicop`i' decile , name(share_coicop`i', replace)
			}	
	}		
			
	}
	

*********************************************	
* 0.2 Prepare Data for Analysis 
*********************************************			
	
	{
	** READ THE WIDE DATA 
	use "$main/waste/output_for_simulation_COICOP2_$scenario.dta" , replace
	// keep if country_code == "CM"			// To run on one country select its acronym  
	sort country_code 
	merge m:1 country_code using "$main/data/country_information.dta"
	keep if _merge==3
	drop _merge
	gen ln_GDP = log(GDP_pc_constantUS2010)	
	
	** For simplicity: just generate food and non food
	
	order exp_total* 
	egen tmp_exp_total2 = rowtotal(exp_total2-exp_total12)
	order exp_informal* 
	egen tmp_exp_informal2 = rowtotal(exp_informal2-exp_informal12)	
	
	drop exp_total2 exp_informal2
	gen exp_total2 = tmp_exp_total2
	gen exp_informal2 = tmp_exp_informal2
	
	drop tmp_exp_total2 tmp_exp_informal2
			
	forvalues i = 0(1)2 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
	
	keep decile country_code exp_total0 exp_informal0 exp_formal0 exp_total1 exp_informal1 exp_formal1 exp_total2 exp_informal2 exp_formal2 ln_GDP

	label var exp_total0 "Expenditure on all goods" 
	label var exp_total1 "Expenditure on food" 	
	label var exp_total2 "Expenditure on non food" 
	
	label var exp_informal0 "Informal Expenditure on all goods" 
	label var exp_informal1 "Informal Expenditure on food" 
	label var exp_informal2 "Informal Expenditure on non food" 

	label var exp_formal0 "Formal Expenditure on all goods" 
	label var exp_formal1 "Formal Expenditure on food" 
	label var exp_formal2 "Formal Expenditure on non food" 		

	foreach x in "total" "informal" "formal" { 
		forvalues i = 0(1)2 { 
			bysort country: egen exp_`x'`i'_alldeciles = total(exp_`x'`i') 
			}
		}	
	}	

********************************************************************************************			
* 1. Ratio of Taxable Budget Shares of Top to Bottom Quintile: FIGURE 6 in the PAPER 
********************************************************************************************							
	local no_budgetconstraint = 1
	if `no_budgetconstraint' {
	
	preserve 
	
	gen budget_share_nf =  exp_total2 / exp_total0
	gen budget_share_for = exp_formal0 / exp_total0
	gen budget_share_for_nf = exp_formal2 / exp_total0
 	
	keep ln_GDP decile country_code  budget_share_nf budget_share_for budget_share_for_nf
	
	reshape wide budget_share_nf budget_share_for budget_share_for_nf, i(country_code) j(decile)		
	
	foreach var in "_nf" "_for" "_for_nf" { 
		gen ratio20`var' = (budget_share`var'10+budget_share`var'9) / (budget_share`var'2+budget_share`var'1)
		gen ratio10`var' = budget_share`var'10 / budget_share`var'1
		sum ratio10`var' ratio20`var'	
		} 

	****** LOCALS FOR FIGURE
	local size medsmall
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "b1title("Countries, poorest to richest", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(1)5, labsize(`size') nogrid) yscale(range(0 5)) yline(1, lcolor(black) lw(medthick)) yline(0(1)5, lstyle(minor_grid) lcolor(gs1))" 
	local ytitle "ytitle(Taxed Consumption Share: Ratio top 20-bottom 20, size(`size') margin(medsmall))"
	
	*********************************	
	#delim ; 

	graph bar ratio20_nf ratio20_for ratio20_for_nf , over(country, gap(*1.5) sort(ln_GDP)
	label(labsize(small) angle(45)))
	bar(1, color(gray)) bar(2, color(red)) bar(3, color(green))	
	`xtitle'
	`yaxis'
	`ytitle' 
	legend(title(Optimal Tax Scenarios, size(small)) 
	order(1 "Food subsidy, modern & traditional taxed" 2 "Uniform rate, only modern taxed" 3 "Food subsidy, only modern taxed") pos(1) ring(0) col(1) size(small) symxsize(*.2) symysize(*.5) )	
	`graph_region_options' ; 	
	
	// gr export "$main/graphs/calibration/redist3_sigma2.pdf", replace as(pdf) ; 	 
	#delim cr			
	
	****** LOCALS FOR FIGURE
	local size large
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local yaxis "ylabel(0(1)5, labsize(`size') nogrid) yscale(range(0 5)) yline(1, lcolor(black) lw(medthick)) yline(0(1)7, lstyle(minor_grid) lcolor(gs1))" 
	local ytitle "ytitle(Budget Share Ratio Top 20-Bottom 20, size(`size') margin(medsmall))"	
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local xaxis "xlabel(5(1)10, labsize(`size'))"	


	*** Fig1: Only Non-Food Taxed 
	
	#delim ;
	twoway (scatter ratio20_nf ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
	(lfit ratio20_nf ln_GDP, color(green)), 
	`xtitle'
	`xaxis'
	`yaxis'
	//`ytitle' 
	`graph_region_options' 
	legend(off) 
	//legend(title(Optimal Tax Scenarios, size(vsmall)) 
	// order(1 "Food Exemption, No Informal sector" ) pos(1) ring(0) col(1) size(vsmall) symxsize(*.2) symysize(*.4) )
	name(G1, replace);	
	gr export "$main/graphs/calibration/bs_nf.pdf", replace as(pdf) 	; 
	
	#delim cr	
	
	*** Fig2: Only Formal Taxed 
	
	#delim ;
	twoway (scatter ratio20_for ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
	(lfit ratio20_for ln_GDP, color(red)), 
	`xtitle'
	`xaxis'
	`yaxis'
	`ytitle' 
	`graph_region_options' 
	legend(off)
	name(G2, replace);
	gr export "$main/graphs/calibration/bs_for.pdf", replace as(pdf) 	; 
	
	#delim cr
	
	*** Fig3: Only Formal non-food taxed
	
	#delim ;
	twoway (scatter ratio20_for_nf ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
	(lfit ratio20_for_nf ln_GDP, color(orange)), 
	`xtitle'
	`xaxis'
	`yaxis'
	//`ytitle' 
	`graph_region_options' 
	legend(off) 
	name(G3, replace);	
	gr export "$main/graphs/calibration/bs_for_nf.pdf", replace as(pdf) 	; 
	
	#delim cr	
	
	restore
	
	} 
	
	
	
************************************************************************************
* 2. Generate the different scenarios for BALANCED BUDGET: Figure 5 in the PAPER
************************************************************************************
	************************************************************************************
	/* General Formula: 
		Sum across Deciles: Sum (Total_consumption * t_target) = Sum (Taxable_Consumption * t_statutory) 
	*/ 
	************************************************************************************

	local budgetconstraint_prep = 1	
	if `budgetconstraint_prep' { 
	
	***** PARAMETERS *********
	* Targetted consumption share to be raised
	local t_target = 0.10
	gen t_target = `t_target'
	
	* EXTRAS  
	* Savings Rates now let's assume the following functional form
	gen s_rate    = (1 * (decile-1.5))  / 100
	gen inc_total_sim =  exp_total0 / (1 - s_rate)
	
	** Savings Rates based on US data (To be added later) 

	*** Gen share of inputs paying taxes in informal sector
	local inputs_VAT = 		0.1
	gen inputs_VAT   = 		`inputs_VAT' 
	
	* Statutory tax rate used on VAT 
	local t_stat = 0.16
	gen t_stat = `t_stat'	
	
	* Adjust tax bases for VAT on inputs 
	*tax base is now: gen x=share_formal*decile_consumption+(1-share_formal)*decile_consumption*mu
	
	**************** Gen the t_statutory ********************************
	** Defined such that the tax collects the targetted Consumption Share
	** Food taxed 0,1 ; Informal sector taxed 0,1 	 
	
	gen t_stat_food1_inf1_vat0 = t_target * exp_total0_alldeciles / exp_total0_alldeciles			// All taxed
	gen t_stat_food0_inf1_vat0 = t_target * exp_total0_alldeciles / exp_total2_alldeciles			// Informal Taxed, Food Untaxed
	
	gen t_stat_food1_inf0_vat0 = t_target   * exp_total0_alldeciles / exp_formal0_alldeciles		// Informal UnTaxed, Food taxed
	gen t_stat_food0_inf0_vat0 = t_target   * exp_total0_alldeciles / exp_formal2_alldeciles		// Informal UnTaxed, Food Untaxed
	
	gen t_stat_food1_inf0_vat1 = t_target   * exp_total0_alldeciles / (exp_formal0_alldeciles + inputs_VAT*exp_informal0_alldeciles)	// Informal UnTaxed, Food taxed, VAT on inputs
	gen t_stat_food0_inf0_vat1 = t_target   * exp_total0_alldeciles / (exp_formal2_alldeciles + inputs_VAT*exp_informal2_alldeciles)	// Informal UnTaxed, Food Untaxed, VAT on inputs 
	
	** Gen the t_effective for the different scenarios S`i', with a Balanced budget:	
	local i = 0
	
	foreach var in "exp_total0" "inc_total_sim"  {   				// "inc_total_US"
		local i = `i' + 1
		gen t_eff_food1_inf1_vat0_B`i' = t_stat_food1_inf1_vat0 * exp_total0  / `var'
		gen t_eff_food0_inf1_vat0_B`i' = t_stat_food0_inf1_vat0 * exp_total2  / `var'
		gen t_eff_food1_inf0_vat0_B`i' = t_stat_food1_inf0_vat0 * exp_formal0  / `var'
		gen t_eff_food0_inf0_vat0_B`i' = t_stat_food0_inf0_vat0 * exp_formal2  / `var'
		gen t_eff_food1_inf0_vat1_B`i' = t_stat_food1_inf0_vat1 * (exp_formal0 + inputs_VAT*exp_informal0)  / `var'
		gen t_eff_food0_inf0_vat1_B`i' = t_stat_food0_inf0_vat1 * (exp_formal2 + inputs_VAT*exp_informal2) / `var'		
		} 
		
	** Gen the t_effective without a balanced budget (UNBALANCED), but assuming all countries use the same tax policy 	
	local i = 0
	
	foreach var in "exp_total0" "inc_total_sim"  { 					// "inc_total_US"
		local i = `i' + 1
		gen t_eff_food1_inf1_vat0_U`i' = t_stat * exp_total0  / `var'
		gen t_eff_food0_inf1_vat0_U`i' = t_stat * exp_total2  / `var'
		gen t_eff_food1_inf0_vat0_U`i' = t_stat * exp_formal0  / `var'
		gen t_eff_food0_inf0_vat0_U`i' = t_stat * exp_formal2  / `var'
		gen t_eff_food1_inf0_vat1_U`i' = t_stat * (exp_formal0 + inputs_VAT*exp_informal0)  / `var'
		gen t_eff_food0_inf0_vat1_U`i' = t_stat * (exp_formal2 + inputs_VAT*exp_informal2)  / `var'		
		} 

	************ GEN THE Redistribution Metrics *************************	

	cap drop redist*
	*Only food taxed
	cap drop x*
	gen x=t_eff_food0_inf1_vat0_B1 if decile==1 | decile == 2
	bys country:egen x2=mean(x)	
	gen x3=t_eff_food0_inf1_vat0_B1 if decile==10 | decile == 9
	bys country:egen x4=mean(x3)	
	gen redist1=x4/x2
	
	*Only formal taxed
	cap drop x*
	gen x=t_eff_food1_inf0_vat0_B1 if decile==1 | decile == 2
	bys country:egen x2=mean(x)	
	gen x3=t_eff_food1_inf0_vat0_B1 if decile==10 | decile == 9
	bys country:egen x4=mean(x3)	
	gen redist2=x4/x2
	
	*Only formal food taxed
	cap drop x*
	gen x=t_eff_food0_inf0_vat0_B1 if decile==1 | decile == 2
	bys country :egen x2=mean(x)	
	gen x3=t_eff_food0_inf0_vat0_B1 if decile==10 | decile == 9
	bys country:egen x4=mean(x3)	
	gen redist3=x4/x2
	
	gen share_for=exp_formal0/exp_total0
	cap drop x*
	gen x=share_for if decile==1
	bys country:egen x2=max(x)	
	gen x3=share_for if decile==10
	bys country:egen x4=max(x3)	
	gen redist0=x4/x2
 
	
	save "$main/waste/mechanical_simulations_$scenario.dta" , replace	

	} 
	
	
*********************************************	
* 	2.1. FIGURE for REPRESENTATIVE COUNTRY 
*********************************************		
	*** Collapse the data at the decile level to obtain a representativie country 
	

	use "$main/waste/mechanical_simulations_$scenario.dta" , replace		
	
	collapse t_eff* , by(decile)
	
	****************************************************************************************************
	** CENTRAL SCENARIO: Balanced Budget, Consumption used as denominator, No Savings, VAT on inputs  
	****************************************************************************************************	
	local central = 1
	if `central' {
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Budget Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.02)0.16, nogrid labsize(`size')) yline(0.04(0.02)0.16, lstyle(minor_grid) lcolor(gs1)) " 
		
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	local yline yline(0.1, lcolor(black))
	#delim ;	

	#delim ;
	tw 
	connected t_eff_food1_inf0_vat0_B1 decile, lcolor(red) msymbol(o) mcolor(red) || 
	connected t_eff_food0_inf1_vat0_B1 decile, lcolor(green) msymbol(X) mcolor(green)  ||
	connected t_eff_food0_inf0_vat0_B1 decile, lcolor(orange) msymbol(s) mcolor(orange)  , 
	legend(order(1 "Uniform rate, only formal taxed" 2 "Food exempt, formal & informal taxed" 3 "Food exempt, only formal taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G, replace) ; 
	 gr export "$main/graphs/cross_country/simulations/effective_rates_decile_$scenario.pdf", replace ; 

	#delim cr
	
	}
	
	
	local savings = 1
	if `savings' {

	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Expenditure Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.02)0.16, nogrid labsize(`size')) yline(0.04(0.02)0.16, lstyle(minor_grid) lcolor(gs1)) " 
		
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	local yline yline(0.1, lcolor(black))
	#delim ;	

	#delim ;
	tw 
	connected t_eff_food1_inf0_vat0_B2 decile, lcolor(red) msymbol(o) mcolor(red) || 
	connected t_eff_food0_inf1_vat0_B2 decile, lcolor(green) msymbol(X) mcolor(green)  ||
	connected t_eff_food0_inf0_vat0_B2 decile, lcolor(orange) msymbol(s) mcolor(orange)  , 
	legend(order(1 "Uniform rate, only formal taxed" 2 "Food exempt, formal & informal taxed" 3 "Food exempt, only formal taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G_sav, replace) ; 
	 gr export "$main/graphs/cross_country/simulations/effective_rates_decile_savings_$scenario.pdf", replace ; 

	#delim cr	
		
	}
	
	local VAT_inputs = 1
	if `VAT_inputs' {

	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Expenditure Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.02)0.16, nogrid labsize(`size')) yline(0.04(0.02)0.16, lstyle(minor_grid) lcolor(gs1)) " 
		
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	local yline yline(0.1, lcolor(black))
	#delim ;	

	#delim ;
	tw 
	connected t_eff_food1_inf0_vat1_B1 decile, lcolor(red) msymbol(o) mcolor(red) || 
	connected t_eff_food0_inf1_vat0_B1 decile, lcolor(green) msymbol(X) mcolor(green)  || // Here should be vat1 no ? Will put one but need to ask pierre
	connected t_eff_food0_inf0_vat1_B1 decile, lcolor(orange) msymbol(s) mcolor(orange)  , 
	legend(order(1 "Uniform rate, only formal taxed" 2 "Food exempt, formal & informal taxed" 3 "Food exempt, only formal taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G_sav, replace) ; 
	 gr export "$main/graphs/cross_country/simulations/effective_rates_decile_inputvat_$scenario.pdf", replace ; 

	#delim cr	
		
	}	
	
	local ratio2080 = 1
	if `ratio2080' {
	
	foreach var in t_eff_food1_inf0_vat0_B1 t_eff_food0_inf1_vat0_B1 t_eff_food0_inf0_vat0_B1 t_eff_food1_inf0_vat0_B2 t_eff_food0_inf1_vat0_B2 t_eff_food0_inf0_vat0_B2 t_eff_food1_inf0_vat1_B1  t_eff_food0_inf0_vat1_B1 {
	egen `var'_1_2= mean(`var') if decile==1 | decile==2
	egen `var'_9_10=mean(`var') if decile==9 | decile==10
	
	xfill `var'_1_2, i(t_eff_food1_inf1_vat0_B1)
	xfill `var'_9_10, i(t_eff_food1_inf1_vat0_B1)
	
	gen `var'_r2080= `var'_9_10/`var'_1_2
	}
	
	save "$main/waste/cross_country/effective_rates_decile_inputvat_$scenario.dta", replace 

}
	
	
	local table_A6 = 1
	if `table_A6' {
	matrix results = J(3,5,.)

	use "$main/waste/cross_country/effective_rates_decile_inputvat_central.dta", clear 


	sum  t_eff_food1_inf0_vat0_B1_r2080
	matrix results[1,1] = `r(mean)' 
	sum t_eff_food0_inf1_vat0_B1_r2080
	matrix results[2,1] = `r(mean)' 
	sum t_eff_food0_inf0_vat0_B1_r2080
	matrix results[3,1] = `r(mean)' 
	sum  t_eff_food1_inf0_vat1_B1_r2080
	matrix results[1,2] = `r(mean)' 
	sum t_eff_food0_inf1_vat0_B1_r2080
	matrix results[2,2] = `r(mean)' 
	sum t_eff_food0_inf0_vat1_B1_r2080
	matrix results[3,2] = `r(mean)' 
	sum  t_eff_food1_inf0_vat0_B2_r2080
	matrix results[1,3] = `r(mean)' 
	sum t_eff_food0_inf1_vat0_B2_r2080
	matrix results[2,3] = `r(mean)' 
	sum t_eff_food0_inf0_vat0_B2_r2080
	matrix results[3,3] = `r(mean)' 
	
	
	use "$main/waste/cross_country/effective_rates_decile_inputvat_proba.dta", clear

	sum  t_eff_food1_inf0_vat0_B1_r2080
	matrix results[1,4] = `r(mean)' 
	sum t_eff_food0_inf1_vat0_B1_r2080
	matrix results[2,4] = `r(mean)' 
	sum t_eff_food0_inf0_vat0_B1_r2080
	matrix results[3,4] = `r(mean)' 
	
	use "$main/waste/cross_country/effective_rates_decile_inputvat_robust.dta", clear

	sum  t_eff_food1_inf0_vat0_B1_r2080
	matrix results[1,5] = `r(mean)' 
	sum t_eff_food0_inf1_vat0_B1_r2080
	matrix results[2,5] = `r(mean)' 
	sum t_eff_food0_inf0_vat0_B1_r2080
	matrix results[3,5] = `r(mean)' 
	
	mat list results
		
	// Generate an automatic table of results 
	global writeto "$main/tables/cross_country/tableA6.tex"
	cap erase $writeto
	local u using $writeto
	latexify results[1,1...] `u', title("Uniform rate, only formal taxed") format(%4.2f) append
	latexify results[2,1...] `u', title("Food exempt, formal and informal taxed") format(%4.2f) append
	latexify results[3,1...] `u', title("Food exempt, only formal taxed") format(%4.2f) append		
	}	
	
	*****************************************
	** HERE GENERATE ANY OF THE GRAPHS 
	*****************************************
	
	local any_graph= 0
	if `any_graph' { 
	local food_tax = 1
	local inf_tax  = 0
	local vat_inputs = 1 
	local budget   = "B"    // B or U for balanced Unbalanced
	local base     = 1 		// 1 "exp_total0" 2 "inc_total_sim"  3 "inc_total_US"
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Expenditure Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(0.02)0.24, nogrid labsize(`size')) " 
	local xaxis "xlabel(1(1)10, labsize(`size'))"		
	
	#delim ;	

	tw connected t_eff_food`food_tax'_inf`inf_tax'_vat`vat_inputs'_`budget'`base' decile, lcolor(black) msymbol(o) mcolor(black) ,  		
	legend(order(1 "Taxed Budget shares") size(small) pos(11) ring(0))
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'  ; 
	

	
	#delim cr	
	} 	
	
	
	***********************
	* ADDING SAVINGS 
	***********************

	local savings = 0
	if `savings' {
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed income Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.02)0.16,  labsize(`size'))"
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	
	#delim ;	

	
	tw (connected t_eff_food1_inf0_vat0_B1 decile, lcolor(black) msymbol(o) mcolor(black) )
	(connected t_eff_food1_inf0_vat0_B2 decile, lcolor(blue) msymbol(o) mcolor(blue))  , 		
	legend(order(1 "No savings" 2 "With savings") pos(12) ring(0) col(1) size(small)) title("Uniform rate, only modern taxed")
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G2, replace) note("Savings rate 0 for d1, 0.1 for d10, linear in between", size(small)); 
	 gr export "$main/graphs/cross_country/simulations/fig_redist_savings.pdf", replace ; 
	#delim cr 
	} 
	
	***********************
	* UNBALANCED BUDGET 
	***********************	
	local unbalanced = 0	
	if `unbalanced' {

	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed income Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(0.02)0.20, nogrid labsize(`size')) " 
	local xaxis "xlabel(1(1)10, labsize(`size'))"		
	
	#delim ; 
	
	tw (connected t_eff_food1_inf0_vat0_U1 decile, lcolor(red) msymbol(o) mcolor(red))  , 		
	legend(order(1 "Uniform rate, all taxed" 2 "Uniform rate, only formal taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G1, replace) ; 

	tw (connected t_eff_food0_inf1_vat0_U1 decile, lcolor(black) msymbol(o) mcolor(black) lpattern(dash))  , 
	legend(order(1 "Uniform rate, all taxed" 2  "Food exempt, all taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G2, replace) ; 

	tw  (connected t_eff_food1_inf0_vat0_U1 decile, lcolor(red) msymbol(o) mcolor(red) )
	(connected t_eff_food0_inf0_vat0_U1 decile, msymbol(o) lcolor(red)  mcolor (red) lpattern(dash)) , 
	legend(order(1 "Uniform rate, only formal taxed" 2  "Food exempt, only formal taxed") pos(12) ring(0) col(1) size(small)) 
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G3, replace) ; 
	
	tw  (connected t_eff_food1_inf0_vat0_U1 decile, lcolor(red) msymbol(o) mcolor(red) )
	(connected t_eff_food1_inf0_vat1_U1 decile, msymbol(o) lcolor(red)  mcolor (blue) lpattern(dash)) , 
	legend(order(1 "Food exempt, only formal taxed" 2  "Food exempt, only formal taxed, VAT on inputs") pos(12) ring(0) col(1) size(small)) 
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G4, replace) ; 	

	#delim cr
	}
	
	
	
	***********************
	* 	VAT on INPUTS
	***********************	

	local vatinputs = 0
	if `vatinputs' {
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Expenditure Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.01)0.16,  labsize(`size'))" 
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	local yline yline(0.1, lcolor(black))
	#delim ;	

	tw  (connected t_eff_food1_inf0_vat0_B1 decile,  color(red) msymbol(o) ) 
		(connected t_eff_food1_inf0_vat1_B1 decile, lpattern(dash) color(red) msymbol(o)) ,  yline(0.1, lcolor(gray))		
	legend(order(1 "No VAT on inputs" 2 "With VAT on inputs") size(small) pos(11) ring(0)) 
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G1, replace) ; 
	gr export "$main/graphs/cross_country/simulations/taxed_shares_vatinputs.pdf", replace ; 


	tw  (connected t_eff_food0_inf0_vat0_B1 decile, lcolor(black) msymbol(o) mcolor(black)) 
		(connected t_eff_food0_inf0_vat1_B1 decile, lcolor(blue) msymbol(o) mcolor(blue)) ,  		
	legend(order(1 "Food exempt, only formal taxed" 2 "Food exempt, only formal taxed, Input VAT") size(small) pos(11) ring(0))
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G2, replace) ; 

	#delim cr
	
	}	
	
	
*********************************************	
* 	FIGURE: CROSS COUNTRY BAR GRAPHS 
*********************************************		

	local cross_country = 1
	if `cross_country' {	
	use "$main/waste/mechanical_simulations_$scenario.dta" , replace		
	
	drop if country_code == "CM" 
	
	duplicates drop country_code, force 
	keep country_code ln_GDP redist*
	
	****** LOCALS FOR FIGURE
	local size medsmall
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "b1title("Countries, poorest to richest", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(1)5, labsize(`size') nogrid) yscale(range(0 5)) yline(1, lcolor(black) lw(medthick)) yline(0(1)7, lstyle(minor_grid) lcolor(gs1))" 
	local ytitle "ytitle(Budget Shares: Ratio top 20-bottom 20, size(`size') margin(medsmall))"
	
	*********************************	
	#delim ; 

	graph bar redist1 redist2 redist3 , over(country, gap(*1.5) sort(ln_GDP)
	label(labsize(small) angle(45)))
	bar(1, color(gray)) bar(2, color(red)) bar(3, color(green))	
	`xtitle'
	`yaxis'
	`ytitle' 
	legend(title(Optimal Tax Scenarios, size(small)) 
	order(1 "Food subsidy, modern & traditional taxed" 2 "Uniform rate, only modern taxed" 3 "Food subsidy, only modern taxed") pos(1) ring(0) col(1) size(small) symxsize(*.2) symysize(*.5) )	
	`graph_region_options' ; 	
	
	gr export "$main/graphs/calibration/redist_bar_allcountries.pdf", replace as(pdf) ; 	 
	#delim cr			
	}


	
*******************************************************************************		
* 	FIGURES REPRESENTATIVE COUNTRIES BY GROUPS OF INCOME LEVELS 
*******************************************************************************			
	*** Collapse the data at the decile level for x groups of GDP pc levels to obtain a representative country 
	
	local rep_country_inclevels = 1
	if `rep_country_inclevels' { 
	use "$main/waste/mechanical_simulations_$scenario.dta" , replace	
	tab ln_GDP
	
	gen income_level = 0
	replace income_level  = 1 if ln_GDP >= 7.9	
	
	* Three groups
	/*
	gen income_level = 0
	replace income_level  = 1 if ln_GDP >= 7
	replace income_level  = 2 if ln_GDP >= 8.6
	*/ 
	collapse t_eff* , by(decile income_level)	

	* By INCOME LEVELS 
	forvalues i = 0(1)1 {
	

	preserve
	
	keep if income_level == `i' 
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Expenditure Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.02)0.16, nogrid labsize(`size')) yscale(range(0.03 0.17)) yline(0.04(0.02)0.16, lstyle(minor_grid) lcolor(gs1)) " 	
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	local yline yline(0.1, lcolor(black))	
	
	#delim ;
	tw 
	connected t_eff_food0_inf1_vat0_B1 decile, lcolor(gray) msymbol(o) mcolor(gray) lpattern(dash) ||
	connected t_eff_food1_inf0_vat0_B1 decile, lcolor(red) msymbol(o) mcolor(red) || 
	connected t_eff_food0_inf0_vat0_B1 decile, lcolor(green) msymbol(o) mcolor(green)  lpattern(dash)  , 
	legend(order(1  "Food exempt, modern & traditional taxed" 2 "Uniform rate, only modern taxed" 3 "Food exempt, only modern taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G`i', replace) ; 
	 gr export "$main/graphs/cross_country/simulations/fig_redist_slides4_incomeG`i'_$scenario.pdf", replace ; 

	#delim cr
	
	restore  
	
	}		
	}
		
	** SAME FIGURE AS ABOVE BUT FOR PAPER: Split sample of countries 
	local rep_country_inclevels_paper_even = 1
	if `rep_country_inclevels_paper_even' { 
	use "$main/waste/mechanical_simulations_$scenario.dta" , replace	
	tab ln_GDP
	
	gen income_level = 0
	replace income_level  = 1 if ln_GDP >= 7.8	
	
	* Three groups
	/*
	gen income_level = 0
	replace income_level  = 1 if ln_GDP >= 7
	replace income_level  = 2 if ln_GDP >= 8.6
	*/ 
	collapse t_eff* , by(decile income_level)	
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Expenditure Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.02)0.16, nogrid labsize(`size')) yscale(range(0.03 0.17)) yline(0.04(0.02)0.16, lstyle(minor_grid) lcolor(gs1)) " 	
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	local yline yline(0.1, lcolor(black))	
	
	#delim ;
	tw 
	connected t_eff_food0_inf1_vat0_B1 decile if income_level == 0 , lcolor(gray) msymbol(o) mcolor(gray) lpattern(dash)  ||
	connected t_eff_food1_inf0_vat0_B1 decile if income_level == 0 , lcolor(red) msymbol(o) mcolor(red)  || 
	connected t_eff_food0_inf0_vat0_B1 decile if income_level == 0 , lcolor(green) msymbol(o) mcolor(green)  lpattern(dash)  , 
	legend(order(1  "Food exempt, modern & traditional taxed" 2 "Uniform rate, only modern taxed" 3 "Food exempt, only modern taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G1, replace) ; 
	 gr export "$main/graphs/cross_country/simulations/fig_redist_incomeG1_splitEven_$scenario.pdf", replace ; 

	#delim cr
	
	
	#delim ;
	tw 
	connected t_eff_food0_inf1_vat0_B1 decile if income_level == 1 , lcolor(gray) msymbol(o) mcolor(gray) lpattern(dash)  ||
	connected t_eff_food1_inf0_vat0_B1 decile if income_level == 1 , lcolor(red) msymbol(o) mcolor(red)  || 
	connected t_eff_food0_inf0_vat0_B1 decile if income_level == 1 , lcolor(green) msymbol(o) mcolor(green)  lpattern(dash)  , 
	legend(off)
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	ytitle("") 
	`graph_region_options'
	name(G2, replace) ; 
	 gr export "$main/graphs/cross_country/simulations/fig_redist_incomeG2_splitEven_$scenario.pdf", replace ; 

	#delim cr	
	
	}		
		
	
	*** CURRENT FIGURE 5 in PAPER 	
	** SAME FIGURE AS ABOVE BUT FOR PAPER: Split sample based on World Bank Income Classification 
	local rep_country_inclevels_paper_wb = 1
	if `rep_country_inclevels_paper' { 
	use "$main/waste/mechanical_simulations_$scenario.dta" , replace	
	tab ln_GDP
	
	gen income_level = 0
	replace income_level  = 1 if ln_GDP >= ln(3995) 
	
	* Three groups
	/*
	gen income_level = 0
	replace income_level  = 1 if ln_GDP >= 7
	replace income_level  = 2 if ln_GDP >= 8.6
	*/ 
	collapse t_eff* , by(decile income_level)	
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local size med
	local xtitle "xtitle(Decile of Expenditure Distribution, margin(medsmall) size(`size'))"
	local ytitle "ytitle(Taxed Expenditure Share, margin(medsmall) size(`size'))"
	local yaxis "ylabel(0.04(0.02)0.16, nogrid labsize(`size')) yscale(range(0.03 0.17)) yline(0.04(0.02)0.16, lstyle(minor_grid) lcolor(gs1)) " 	
	local xaxis "xlabel(1(1)10, labsize(`size'))"	
	local yline yline(0.1, lcolor(black))	
	
	#delim ;
	tw 
	connected t_eff_food0_inf1_vat0_B1 decile if income_level == 0 , lcolor(gray) msymbol(o) mcolor(gray) lpattern(dash)  ||
	connected t_eff_food1_inf0_vat0_B1 decile if income_level == 0 , lcolor(red) msymbol(o) mcolor(red)  || 
	connected t_eff_food0_inf0_vat0_B1 decile if income_level == 0 , lcolor(green) msymbol(o) mcolor(green)  lpattern(dash)  , 
	legend(order(1  "Food exempt, modern & traditional taxed" 2 "Uniform rate, only modern taxed" 3 "Food exempt, only modern taxed") pos(12) ring(0) col(1) size(small))
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	`ytitle' 
	`graph_region_options'
	name(G1, replace) ; 
	 gr export "$main/graphs/cross_country/simulations/fig_redist_incomeG1_splitWB_$scenario.pdf", replace ; 

	#delim cr
	
	
	#delim ;
	tw 
	connected t_eff_food0_inf1_vat0_B1 decile if income_level == 1 , lcolor(gray) msymbol(o) mcolor(gray) lpattern(dash)  ||
	connected t_eff_food1_inf0_vat0_B1 decile if income_level == 1 , lcolor(red) msymbol(o) mcolor(red)  || 
	connected t_eff_food0_inf0_vat0_B1 decile if income_level == 1 , lcolor(green) msymbol(o) mcolor(green)  lpattern(dash)  , 
	legend(off)
	`yline'
	`xaxis' 
	`yaxis' 
	`xtitle' 
	ytitle("") 
	`graph_region_options'
	name(G2, replace) ; 
	 gr export "$main/graphs/cross_country/simulations/fig_redist_incomeG2_splitWB_$scenario.pdf", replace ; 

	#delim cr	
	
	}		
		
	
	

	
	
	
	
	
	
	
	
	
