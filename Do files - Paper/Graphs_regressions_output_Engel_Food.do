					*************************************
					* 		CROSS COUNTRY GRAPHS + 		*
					*************************************
					
**************************************************************************
/* 		

SUMMARY:
	0. Load Dataset 
	1. Summary statistics and slope coefficients	
	2. Graphs 
		2.1 Summary Statistics
		2.2 Coefficients from regressions
	3. Analysis of R_2 across regressions
		

ISSUES:

(1) Issue with survey_bloc min and R2 for PNG in particular 
(2) Idea of a nice graph: 
x-axis ordering by country gdp
y-axis box plot which shows, median, average, interquartile
and p95 p5 --> This contains a lot of the interesting info!
	
	*/
**************************************************************************										
*********************************************	
* Preliminaries
*********************************************	
	cap log close
	clear all
	set more off
	
	qui include "$main/dofiles/server_header.doh" 		// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
		
	global scenario "central"    // central , proba , robust: see definition in Master.do

************************************************************************	
* 0. Load Dataset 
************************************************************************	
	
{	
	* Obtain GDP_pc for the country
	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	
	
	rename Year year
	
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	save `gdp_data'
	
	* Load Data of regression Output 
	use "$main/proc/Food_Engel_Curve.dta", replace 
	
	// for robustness scenarios, replace above with
		// "$main/proc/regressions_output_robust_B.dta"
		// "$main/proc/regressions_output_robust_C.dta"
	
	merge m:1 country_code year using `gdp_data'
	keep if _merge == 3 
	drop _m
	}

	* Basic Data prep
	{
	* Make the slope coefficients "positive" 
	replace b = -b	if iteration <= 3		
	
	* Confidence intervals		
	gen ci_low = b - 1.96*se
	gen ci_high = b + 1.96*se
	
	* t stats
	gen t_stat = b / se 
	replace t_stat = abs(t_stat)
	
	}
	
	
	** TO BE DELETED NEXT TIME RUN 
	duplicates tag country_code iteration, gen(tag)
	drop if tag ==1
	drop tag 
	
	**************************************************************************	
	* Reshape the data for the iterations: this will give b`x' and se`x' 
	**************************************************************************
	
	{
	reshape wide b se t_stat ci_low ci_high, i(country_code year)  j(iteration)
	
	merge 1:1 country_code year using `gdp_data'
	
	keep if _merge == 3
	drop _merge

	** Gen GDP_pc measures
	gen ln_base2_GDP = log(GDP_pc_constantUS2010) / ln(2)	
	gen log_GDP_pc_currentUS = log(GDP_pc_currentUS)	// Some missing data 
	gen log_PPP_current 	 = log(PPP_current)			// Some missing data 	
	
	* Assign Variable labels, which explain what each b is
	
	label var b1 "Linear Slope, no sample restriction"
	label var b2 "Linear Slope, p5-p95 restriction"
	label var b3 "Linear Slope, p10-p90 restriction"
	cap label var b4 "Quadratic Slope, no sample restriction"
	cap label var b5 "Quadratic Slope, p5-p95 restriction"		
	cap label var b6 "Quadratic Slope, p10-p90 restriction"

}	
		
**************************************************	
* 1. Summary statistics and slope coefficients	
************************************************** 
	local sum_stats = 0
	
	if `sum_stats' {	
	
	log using "$main/logs/graphs_regression_output_${scenario}_`c(current_date)'.log" , replace

	sum b1, d 				
	sum b2, d 				
	sum b3, d 				// 10 on average 
	
	local low_income 8
	local mid_income 9.25
	
	gen income_group = .
	replace income_group = 1 if log_PPP_current <= `low_income'
	replace income_group = 2 if log_PPP_current>`low_income' & log_PPP_current <= `mid_income'
	replace income_group = 3 if log_PPP_current > `mid_income'	

	sum b3 if income_group == 1				// 6
	sum b3 if income_group == 2				// 13
	sum b3 if income_group == 3				// 12
	
	** For Table 2: IEC SLOPES in PAPER
	
	foreach i in 4 5 6{
		display "This is specification `i'" 
		sum t_stat`i'
		count if t_stat`i' >= 1.96
		}
		
	list CountryName b6 se6 
		
	
	// log close 
	
	}
	
*********************************************	
* 2. Graphs
*********************************************	
	***********************************************************
	* 2.1 Summary Statistics 
	***********************************************************		

	local slope_Food_Engel1 = 1   
	local slope_Food_Engel2 = 1   
	local slope_Food_Engel3 = 1   	
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita, Constant 2010 USD (log base 2)", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(2)20, nogrid labsize(`size')) yscale(range(0 20)) yline(0(2)20, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(8(1)15, labsize(`size'))"	
	local ytitle "ytitle("Slope of Food Engel Curve", margin(medsmall) size(`size'))"

	if `slope_Food_Engel1'	{
	
		#delim ;		
		
		twoway (scatter b1 ln_base2_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)),	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		`ytitle'
		legend(off) 	
		`graph_region_options'
		// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
		name(level_informality, replace) ; 
		
		graph save "$main/graphs/cross_country/Food_Engel.gph", replace	;
		graph export "$main/graphs/cross_country/Food_Engel1.pdf", replace	;
		
		#delim cr	
		} 

	if `slope_Food_Engel2'	{
	
		#delim ;		
		
		twoway (scatter b2 ln_base2_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)),	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		`ytitle'
		legend(off) 	
		`graph_region_options'
		// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
		name(level_informality, replace) ; 
		
		graph save "$main/graphs/cross_country/Food_Engel.gph", replace	;
		graph export "$main/graphs/cross_country/Food_Engel2.pdf", replace	;
		
		#delim cr	
		} 

	if `slope_Food_Engel3'	{
	
		#delim ;		
		
		twoway (scatter b3 ln_base2_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)),	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		`ytitle'
		legend(off) 	
		`graph_region_options'
		// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
		name(level_informality, replace) ; 
		
		graph save "$main/graphs/cross_country/Food_Engel.gph", replace	;
		graph export "$main/graphs/cross_country/Food_Engel3.pdf", replace	;
		
		#delim cr	
		} 		
	
	***********************************************************
	* 2.2 Coefficients from regressions
	***********************************************************		
	* Define a local with the set of variables to run this over 

	local slope_informality 		= 1		// Average Informality on country log_gdp_pc
	local slope_informality_ci 		= 1		// With confidence intervals 
	local slope_COICOP 				= 0		// Shows slopes when controlling more narrowly for product composition 
	local slope_arrows_COICOP 		= 0		// Shows arrows when going from one COICOP level to the next
	local slope_arrows_COICOP_1to4 	= 1		// Shows arrows when going from one COICOP1 to COICOP4
	local slope_ratio_COICOP 		= 1		// Ratio of Slopes when going from one COICOP level to the next
	local bar_slope_ratio_COICOP 	= 0
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita, Constant 2010 USD (log base 2)", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(5)15, nogrid labsize(`size')) yscale(range(-2 16)) yline(0(5)15, lstyle(minor_grid) lcolor(gs1))" 		
	local xaxis "xlabel(8(1)15, labsize(`size'))"
	
if `slope_informality' {
		#delim ;		
		
		twoway (scatter b6 ln_base2_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) ,
		`xaxis' 
		`yaxis' 
		`xtitle'		
		ytitle("Informal Consumption Slope", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(slope_informality, replace) 		; 
		
		graph save "$main/graphs/cross_country/slope_informality_$scenario.gph", replace	;
		graph export "$main/graphs/cross_country/slope_informality_$scenario.pdf", replace	;
		
		#delim cr	
		} 
		
	*** Slopes graphs 
if `slope_informality_ci' {
		#delim ;		
		
		twoway (rspike ci_low6 ci_high6 ln_base2_GDP, lstyle(ci) lcolor(gs6) )
		(scatter b6 ln_base2_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) ,
		`xaxis' 
		`yaxis' 
		`xtitle'		
		ytitle("Informal Consumption Slope", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(slope_informality, replace) 		; 
		
		graph save "$main/graphs/cross_country/slope_informality_ci_$scenario.gph", replace	;
		graph export "$main/graphs/cross_country/slope_informality_ci_$scenario.pdf", replace	;
		
		#delim cr	
		} 			
		
if `slope_COICOP' {
	local outcome "b6 b7 b8 b9"
	foreach name of local outcome {
		#delim ;		
		
		twoway (scatter `name' ln_base2_GDP, color(red) mlabel(country_code) mlabcolor(red*1.5)) ,
		`xaxis' 
		`yaxis' 
		`xtitle'	
		ytitle("Change in Slope of informal consumption", margin(medsmall)  size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(`name', replace) 		; 		
		
		graph export "$main/graphs/cross_country/slope_`name'_$scenario.pdf", replace	;
		
		#delim cr
		}
	}	
		
	
	*** pcarrow graphs
	
if `slope_arrows_COICOP' {
	forvalues i = 6(1)8{
		local j = `i'+1
		local k = `i'-1
		
		#delim ;				
		twoway (scatter b`i' ln_base2_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabcolor(gs1*1.5))
		(pcarrow b`i' ln_base2_GDP b`j' ln_base2_GDP, color(gs10) )	,
		`xaxis' 
		`yaxis' 
		`xtitle'
		ytitle(Slope Change of Informal Engel Curve, margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'	
		// title("Change in Slopes: COICOP`k' to COICOP`i'", margin(medsmall) size(med))	
		name(graphb`i'tob`j', replace) 		; 	
		
		graph export "$main/graphs/cross_country/slope_arrows_b`i'tob`j'_$scenario.pdf", replace;	
		
		#delim cr	
	}
} 	

	
	
if `slope_arrows_COICOP_1to4' {  	
	#delim ;		
	
	twoway (scatter b6 ln_base2_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabcolor(gs1*1.5))
	(pcarrow b6 ln_base2_GDP b9 ln_base2_GDP, color(gs10) )	,
	`xaxis' 
	`yaxis' 
	`xtitle'
	ytitle(Slope Change of Informal Engel Curve, margin(medsmall) size(`size'))
	legend(off) 	
	`graph_region_options'	
	// title("Change in Slopes: no product controls to COICOP3", margin(medsmall) size(med))	
	name(graphb20tob23, replace) 		; 
	
	graph export "$main/graphs/cross_country/slope_arrows_b6tob9_$scenario.pdf", replace	;
	
	#delim cr
	} 
	
	
	*** Ratio of slopes graphs
	
if `slope_ratio_COICOP'  { 
	local outcome "ratio_b6_b7 ratio_b7_b8 ratio_b8_b9 ratio_b6_b9"
	foreach name of local outcome {
		#delim ;		
		
		twoway (scatter `name' ln_base2_GDP if country_code!= "CL" & country_code!= "NE", color(red) mlabel(country_code) mlabcolor(red*1.5)) ,
		`xaxis' 
		 /// yaxis "ylabel(0(0.1)2, nogrid) yscale(range(0 12)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 
		`xtitle'	
		ytitle("Change in Slope of informal consumption", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(`name', replace) 	; 		
		
		graph export "$main/graphs/cross_country/slope_`name'_$scenario.pdf", replace	;
		
		#delim cr
		}
	}
	
	
	*** Bar graph for ratio of slopes : not in the WP for now
	
if `bar_slope_ratio_COICOP'  {
	
	
	#delim ;		
	graph bar ratio_b6_b9 if country_code!= "CL" & country_code!= "NE", over(country_code, sort(ratio_b6_b9))
		`graph_region_options'	
		ytitle("Ratio of slopes", margin(medsmall))
		name(bar_slopes, replace) 			; 
		
	graph export "$main/graphs/cross_country/bar_graph_slopes_ratio_$scenario.pdf" , replace	;		
	#delim cr	

	sum ratio_b6_b7 if country_code!= "CL"	
	sum ratio_b6_b8 if country_code!= "CL"		
	sum ratio_b6_b9 if country_code!= "CL"	
	
}
	**************************************************	
	* 3. Analysis of R_2 across regressions
	************************************************** 	
	local r2_analysis	= 0	
	* Highlight MX and especially PG, R2 is worse with survey block, very odd, check!!!
	
if `r2_analysis' {

	* Generate for p-values 
	local p_value = (2 * ttail(e(df_r), abs(_b[log_income_pp]/_se[log_income_pp])))		

	gen r2_dif = (r2_adj20 - r2_adj19) / r2_adj19
	list country_code r2_d 
	list country_code r2_adj10 r2_adj11 r2_adj12 r2_adj13
	
	forvalues i = 14(1)17 {
	local j = `i' - 4
	gen r2_dif`i' = (r2_adj`i' - r2_adj`j') / r2_adj`j' 
	}
	list country_code r2_dif14 - r2_dif17
	
	list country_code r2_adj17
	sum r2_adj17  // Avg R_sq of COICOP4 + geo_loc_min = 0.51
	
	list country_code r2_adj18 r2_adj19 r2_adj20	
	}
	
	
	
	
	
	
	
	
