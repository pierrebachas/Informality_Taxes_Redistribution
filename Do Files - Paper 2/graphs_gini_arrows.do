
*****************
**PRELIMINARIES**
*****************
		
	clear all 
	set more off
	cap log close
	display "$scenario"
	
	* Control Center:
	
	local food_diff_to_full 	 	= 1
	local uni_to_uni_pit			= 1
	local food_diff_to_food_dif_pit	= 1

	
	
********************************************************************************
** Graph - From differentiated food-non food to further rate differentiation  **
********************************************************************************

	if `food_diff_to_full' {
		
	use "$main/waste/cross_country/gini_central_baseline_coicop12.dta", clear 
	keep if tag_country == 1

	tempfile gini_central_baseline_coicop12
	save `gini_central_baseline_coicop12'
	
	use "$main/waste/cross_country/gini_central_baseline_newdata.dta", replace 
	keep if tag_country == 1	
	merge 1:1 country_code using `gini_central_baseline_coicop12'

		
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local ytitle "ytitle("Percentage Change in Gini" , margin(medsmall) size(`size'))"
	local yaxis "ylabel(-7(1)0, nogrid labsize(`size')) yscale(range(-7.2 0)) yline(-7(1)0, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
	
	#delim ; 
	
	twoway (scatter pct_dif_gini_3 ln_GDP,  `dots')  (pcarrow pct_dif_gini_3 ln_GDP pct_dif_gini_F ln_GDP, color(gs10) ), 
	`yaxis' `ytitle' 
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_arrow1, replace)  ; 
	graph export "$main/graphs/gini_arrow_food_diff_to_full.eps" , replace 	 ; 
	
	#delim cr		
		
			
	}	


	
*********************************************************
** Graph - From Uniform rate to Uniform rate with PIT  **
*********************************************************
	if `uni_to_uni_pit' {
	use "$main/waste/cross_country/gini_central_baseline_pit.dta", clear 
	keep if tag_country == 1

	tempfile gini_central_baseline_pit
	save `gini_central_baseline_pit'
	
	use "$main/waste/cross_country/gini_central_baseline_newdata.dta", replace 
	keep if tag_country == 1	
	merge 1:1 country_code using `gini_central_baseline_pit'

		
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local ytitle "ytitle("Percentage Change in Gini" , margin(medsmall) size(`size'))"
	local yaxis "ylabel(-4(1)0, nogrid labsize(`size')) yscale(range(-4.5 0)) yline(-4(1)0, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
	
	#delim ; 
	
	twoway (scatter pct_dif_gini_2 ln_GDP,  `dots')  (pcarrow pct_dif_gini_2 ln_GDP pct_dif_gini_2_cons_only ln_GDP if country_code!="BI", color(gs10) ), 
	`yaxis' `ytitle' 
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_arrow2, replace)  ; 
	graph export "$main/graphs/gini_arrow_uni_to_uni_pit.eps" , replace 	 ; 
	
	#delim cr		
		
	}
***************************************************************************************************
** Graph - From differentiated food-non food rate to differentiated food-non food rate with PIT  **
***************************************************************************************************
	if `food_diff_to_food_dif_pit' {
	use "$main/waste/cross_country/gini_central_baseline_pit.dta", clear 
	keep if tag_country == 1

	tempfile gini_central_baseline_pit
	save `gini_central_baseline_pit'
	
	use "$main/waste/cross_country/gini_central_baseline_newdata.dta", replace 
	keep if tag_country == 1	
	merge 1:1 country_code using `gini_central_baseline_pit'

		
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local ytitle "ytitle("Percentage Change in Gini" , margin(medsmall) size(`size'))"
	local yaxis "ylabel(-7(1)0, nogrid labsize(`size')) yscale(range(-7.2 0)) yline(-7(1)0, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
	
	#delim ; 
	
	twoway (scatter pct_dif_gini_3 ln_GDP,  `dots')  (pcarrow pct_dif_gini_3 ln_GDP pct_dif_gini_3_cons_only ln_GDP, color(gs10) ), 
	`yaxis' `ytitle' 
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_arrow3, replace)  ; 
	graph export "$main/graphs/gini_arrow_food_diff_to_food_dif_pit.eps" , replace 	 ; 
	
	#delim cr		
		
	}
