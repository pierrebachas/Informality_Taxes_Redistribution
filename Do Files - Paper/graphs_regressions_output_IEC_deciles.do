
					*************************************
					* 	CROSS COUNTRY GRAPHS by DECILES	*
					*************************************
					
*************************************
/* 		
	
	*/
*************************************										

	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"

*********************************************	
// Preliminaries
*********************************************	
	
	clear all
	set more off
	
	display "$scenario"	
	
**************************************************************	
// 1. Graph combining deciles: 3 or 4 income groups combined
**************************************************************	
	
   
	*********************************************	
	// 1.1 Load Data 
	*********************************************		

{			
	* Obtain GDP_pc for the country
	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	

	rename Year year
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	save `gdp_data'
	
	* Load Data of regression Output 
	use "$main/proc/regressions_output_deciles_$scenario.dta", replace  
	
	**************************************************************************	
	// Reshape the data such that we have the deciles as a variable
	**************************************************************************
	keep if iteration == 1 			// Iteration 1 includes only basic hhld controls 
	drop iteration
	
	// Drop the "_" at the end of variable names
	forvalues i = 1(1)10 { 
		rename decile`i'_ mean`i'
		rename se`i'_ se`i'
		}
	
	reshape long mean se , i(country_code) j(decile)
	
	merge m:1 country_code year using `gdp_data'
	
	keep if _merge == 3
	drop _merge
	
	** Gen GDP_pc measures
	gen ln_base2_GDP = log(GDP_pc_constantUS2010) / ln(2)	
	gen log_GDP_pc_currentUS = log(GDP_pc_currentUS)	// Some missing data 
	gen log_PPP_current 	 = log(PPP_current)			// Some missing data 	

	** Group by Income levels // for now just doing even 6-6-6 to give 18 countries equal bins
	_current
	
	local option1 = 1
	local option2 = 1 - `option1' 

	if `option1' { 
	
	local low_income =  8
	local mid_income = 9.25
	
	gen income_group = .
	replace income_group = 1 if log_PPP_current <= `low_income'
	replace income_group = 2 if log_PPP_current>`low_income' & log_PPP_current <= `mid_income'
	replace income_group = 3 if log_PPP_current > `mid_income'
	
	bysort decile income_group: egen mean_incomegroup = mean(mean)
	bysort decile income_group: egen se_incomegroup = mean(se)
	egen tag_group = tag(income_group decile)
	
	keep if tag == 1		
		}
	
	if `option2' { 
	
	local low_income = ln(1025)
	local mid_income = ln(3996) 
	
	gen income_group = .
	replace income_group = 1 if log_PPP_current <= `low_income'
	replace income_group = 2 if log_PPP_current>`low_income' & log_PPP_current <= `mid_income'
	replace income_group = 3 if log_PPP_current > `mid_income'
	
	tab income_group 
	
	bysort decile income_group: egen mean_incomegroup = mean(mean)
	bysort decile income_group: egen se_incomegroup = mean(se)
	egen tag_group = tag(income_group decile)
	
	keep if tag == 1		
		} 
	
	}
	
	**************************************************************************	
	// 1.2 Figure grouped by income levels copying Figure 4 of Bick et al AER
	**************************************************************************	

	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Decile of Expenditure Distribution (Within Country)", margin(medsmall) size(medlarge))"
	local yaxis "ylabel(0(20)100, nogrid) yscale(range(0 12)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(1(1)10)"	
	
	#delim ;
	
	twoway (connected mean_incomegroup decile if income_group == 1, lcolor(black) lpattern(dash) msymbol(smcircle) mcolor(black)) 
	(connected mean_incomegroup decile if income_group == 2, lcolor(gray) lpattern(shortdash) msymbol(smsquare) mcolor(gray))
	(connected mean_incomegroup decile if income_group == 3, lcolor(gs12) msymbol(smdiamond) mcolor(gs12)), 
	`xaxis' 
	`yaxis' 
	`xtitle' 
	ytitle("Informal Expenditure Share", margin(medsmall) size(medlarge))
	legend(order(1 "Lower" 2 "Middle" 3 "Upper")) 	
	`graph_region_options'
	title("")
	legend(title("Split sample by GDP per capita", size(small)) size(small) row(1) pos(12) bmargin(zero));	
	graph export "$main/graphs/cross_country/incomegroup_informalshare_acrossdeciles_$scenario.pdf", replace;
	#delim cr	

	/*
**************************************************************	
// 2. Graph country by country at the decile level 
**************************************************************		
	
	*********************************************	
	// 2.1 Load Data 
	*********************************************		
			
	* Obtain GDP_pc for the country
	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	
	/* For now, keep only latest year but go back to post Estimation for this */ 
	bysort CountryCode: egen max_year = max(Year)
	keep if Year == max_year	
	
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current Year	
	save `gdp_data'
	
	* Load Data of regression Output 
	use "$main/proc/regressions_output_deciles.dta", replace  

	**************************************************************************	
	// Reshape the data for the iterations: yes this will give b`x' and se`x' 
	**************************************************************************
	reshape wide decile* se* , i(country_code ) j(iteration)
	
	merge 1:1 country_code using `gdp_data'
	
	keep if _merge == 3
	drop _merge
	
	** Gen GDP_pc measures
	gen ln_base2_GDP = log(GDP_pc_constantUS2010) / ln(2)	
	gen log_GDP_pc_currentUS = log(GDP_pc_currentUS)	// Some missing data 
	gen log_PPP_current 	 = log(PPP_current)			// Some missing data 	
	
	** Prepare some rations for the graphs: we need the means:
	/*
	gen ratio_b2_b1 = b2/b1
	gen ratio_b2_b3 = b3/b2
	gen ratio_b3_b4 = b4/b3
	gen ratio_b1_b4 = b4/b1	
	*/

	
*********************************************	
// 2.2 Graphs
*********************************************	
	***********************************************************
	* Coefficients from regressions
	***********************************************************		
	* Interesting: relation with GDP becomes more and more quadratic (inverse U shapped) as one controls for sectors:
	* This means: that in very poor countries product composition explains a bulk of the shop types (probably a lot through self-production)
	* While in middle-income product composition does not explain as much

	/*
{	
	#delim ;		
	
	twoway (scatter decile1_1 ln_base2_GDP, color(red) mlabel(country_code) mlabcolor(red*1.5))	,
	/// ylabel(0(2)12) yscale(range(0 12))
	xlabel(6(1)11)
	xtitle("Log GDP per capita (PPP adjusted)", margin(medsmall))
	ytitle(Slope of informal consumption on log income, margin(medsmall))
	/// legend(order(1 "Mexico" 2 "Tanzania") ring(0) position(2) rows(2)) 	
	graphregion(fcolor(white)) plotregion(fcolor(white))	
	title(Slopes of Informal Consumption Across Countries, margin(medsmall))	
	name(`name', replace) 		; 		
	
	graph export "$main/graphs/cross_country/decile10.pdf", replace	;
	
	#delim cr
	
	local outcome "decile5_1 decile5_2 decile5_3 decile5_4 decile1_1 decile1_2 decile1_3 decile1_4 "
	foreach name of local outcome {
	#delim ;		
	
	twoway (scatter `name' log_PPP_current, color(red) mlabel(country_code) mlabcolor(red*1.5))
	(lfit `name' log_PPP_current, color(blue) )	,
	/// ylabel(0(2)12) yscale(range(0 12))
	xlabel(6(1)11)
	xtitle("Log GDP per capita (PPP adjusted)", margin(medsmall))
	ytitle(Slope of informal consumption on log income, margin(medsmall))
	/// legend(order(1 "Mexico" 2 "Tanzania") ring(0) position(2) rows(2)) 	
	graphregion(fcolor(white)) plotregion(fcolor(white))	
	title(Slopes of Informal Consumption Across Countries, margin(medsmall))	
	name(`name', replace) 		; 		
	
	graph export "$main/graphs/cross_country/decile_`name'.pdf", replace	;
	
	#delim cr
	}
	
}	
	}
	
	*/ 
	
	
