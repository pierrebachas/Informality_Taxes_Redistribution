					*************************************
					* 		CROSS COUNTRY GRAPHS 		*
					*************************************
*********************************************	
// Preliminaries
*********************************************	
	
	qui include "$main/dofiles/server_header.doh" 		// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
		
	global scenario "central"    // central , proba , robust: see definition in Master.do
	
	clear all
	set more off

********************************************************************	
// 1. Linear regression Output Urban Rural: 
********************************************************************	
	
	local regressions_output_urban_rural = 1
	if `regressions_output_urban_rural'{ 
	
*********************************************	
// 1.1 Load Data 
*********************************************		
			
	* Obtain GDP_pc for the country
	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	
	rename Year year
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_constantUS2010 GDP_pc_currentUS PPP_current year	
	save `gdp_data'
	
	* Load Data of regression Output 
	use "$main/proc/tmp_regressions_output_urban_rural_$scenario.dta", replace 

	**************************************************************************	
	// Reshape the data for the iterations: this will give b`x' and se`x' 
	**************************************************************************
	keep country_code iteration b_urban b_rural se_urban se_rural year
	reshape wide b_urban b_rural se_urban se_rural , i(country_code year) j(iteration)
	
	merge 1:1 country_code year using `gdp_data'
	
	keep if _merge == 3
	drop _merge
	
	*** Replace Slopes into positive numbers 
	//forvalues i = 3(1)12 {
	//replace b_urban`i' = - b_urban`i'
	//replace b_rural`i' = - b_rural`i'
	
	
	** generate confidence intervals 
	foreach name in urban rural { 
	forvalues i = 3(1)12 {
		gen ci_low_`name'`i' = b_`name'`i' - 1.96*se_`name'`i'
		gen ci_high_`name'`i' = b_`name'`i' + 1.96*se_`name'`i'
		}
		}	
	
	** Gen GDP_pc measures
	gen log_GDP = log(GDP_pc_constantUS2010) 	
	gen log_GDP_pc_currentUS = log(GDP_pc_currentUS)	
	gen log_PPP_current 	 = log(PPP_current)				

	sum b_urban5 
	sum b_rural5 
	
	sum b_urban1 b_rural1 				// Means cited in paper p.13
	sum b_urban2 b_rural2				// Medians
	
	}
	
*********************************************	
* 1.2 Graphs
*********************************************	
	***********************************************************
	* Statistics
	***********************************************************	
	local stats = 1
	if `stats'{
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(20)100, nogrid labsize(`size')) yscale(range(0 12)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	
	// Average Urban Difference 
	#delim ;		
	
	twoway (scatter b_urban1 log_PPP_current, msize(medsmall) color(red) msymbol(smdiamond))
	(scatter b_rural1 log_PPP_current, msize(medsmall) color(blue) )	,	
	`yaxis' 
	`xaxis' `xtitle' 
	ytitle(Average Level of Informal Consumption, margin(small))
	legend(off) 	
	`graph_region_options'
	// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
	name(mean, replace) 		; 

	graph export "$main/graphs/cross_country/level_informality_urban_rural.pdf", replace	;
	
	#delim cr	
	
	* Average Urban 
	#delim ;		
	
	twoway (scatter b_urban1 log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))	,		
	`yaxis' 
	`xaxis' `xtitle' 
	ytitle("Informal Consumption Share", margin(medsmall) size(`size'))
	legend(off) 	
	`graph_region_options'
	// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
	name(mean, replace) 		; 

	graph export "$main/graphs/cross_country/level_informality_urban.pdf", replace	;
	
	#delim cr	
	
	* Average Rural 
	#delim ;		
	
	twoway (scatter b_rural1  log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))	,	
	`yaxis' 
	`xaxis' `xtitle' 
	ytitle("Informal Consumption Share", margin(medsmall) size(`size'))
	legend(off) 	
	`graph_region_options'
	// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
	name(mean, replace) 		; 

	graph export "$main/graphs/cross_country/level_informality_rural.pdf", replace	;
	
	#delim cr		

	*** Bar graph 	
	cap gen dif_urban_rural = b_rural1 - b_urban1	
	sum dif_urban_rural
	
	** SORT BASED ON INCOME LEVELS
	
	#delim ;		
	graph bar dif_urban_rural , over(country_code, sort(CountryName) label(labsize(vsmall))) intensity(60)
	yline(`r(mean)' , lwidth(medthick)) 
		`graph_region_options'	
		ytitle("Rural-Urban Difference in Share of Informal Exp.", margin(medlarge) size(med))
		name(bar_slopes, replace) 			; 
		
	graph export "$main/graphs/cross_country/bar_graph_dif_urban_rural.pdf" , replace	;		
	#delim cr	

	}

	***********************************************************
	* Coefficients from regressions
	***********************************************************		
	* Define a local with the set of variables to run this over 
	local regressions = 1
	if `regressions'{
	
	local size medium 
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local yaxis "ylabel(-25(5)5, nogrid labsize(`size')) yscale(range(-25 5)) yline(-25(5)5, lstyle(minor_grid) lcolor(gs1))" 		
	local xaxis "xlabel(5(1)10, labsize(`size'))"

	local outcome "urban8 rural8"
	foreach name of local outcome {
		#delim ;	
		
		twoway (rspike ci_low_`name' ci_high_`name' log_GDP, lstyle(ci) lcolor(gs6) ) 
		(scatter b_`name' log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)),
		`xaxis' 
		`yaxis' 
		`xtitle'		
		ytitle("Informal Consumption Slope", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(`name', replace) 		; 		
		
		graph export "$main/graphs/cross_country/slope_`name'_$scenario.pdf", replace	;
		#delim cr
		}
	}
	
	

	local outcome "ratio_b1_b2 ratio_b2_b3 ratio_b3_b4 ratio_b1_b4"
	foreach name of local outcome {
		#delim ;		
		
		twoway (scatter `name' log_PPP_current, color(red) mlabel(country_code) mlabcolor(red*1.5)) ,
		///(lfit `name' log_PPP_current, color(blue) )	
		/// ylabel(0(0.1)1) yscale(range(0 1))
		xlabel(6(1)11)
		xtitle("Log GDP per capita (PPP adjusted)", margin(medsmall))
		ytitle(Slope of informal consumption, margin(medsmall))
		legend(off) 	
		`graph_region_options'	
		// title(Slopes of Informal Consumption Across Countries, margin(medsmall))	
		name(`name', replace) 		; 		
		
		graph export "$main/graphs/cross_country/slope_`name'.pdf", replace	;
		
		#delim cr
		}

	*** Bar graph 	
	#delim ;		
	graph bar ratio_b1_b4 if country_code!= "CL", over(country_code, sort(ratio_b1_b4))
		`graph_region_options'	
		ytitle("Ratio of slopes", margin(medsmall))
		name(bar_slopes, replace) 			; 
		
		graph export "$main/graphs/cross_country/bar_graph_slopes_ratio.pdf" , replace	;		
	#delim cr	

	sum ratio_b1_b2 if country_code!= "CL"	
	sum ratio_b1_b3 if country_code!= "CL"		
	sum ratio_b1_b4 if country_code!= "CL"	
	}
	
