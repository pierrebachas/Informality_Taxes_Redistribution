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

	// uses written ado file "latexify" 
	
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
	use "$main/proc/regressions_output_$scenario.dta", replace 
	
	
	merge m:1 country_code year using `gdp_data'
	keep if _merge == 3 
	drop _m
	}

	* Basic Data prep
	{
	* Make the slope coefficients "positive" for readability in tables
	*replace b = -b	if iteration > 5		
	
	** Generate p-values and confidence intervals (p-value probability that null hypothesis beta = 0 is true) 
	local df_r = 1000000	
	gen p_value_2s = (2 * ttail(`df_r', abs(b/se))) / 2
	
	** Note: we want to test the one-sided hypothesis: H0 beta = 0 vs Ha beta < 0 
	gen p_value_1s = p_value_2s / 2 if b >0
	replace p_value_1s = 1 - p_value_2s/2 if b < 0 
	drop p_value_2s
	
	gen ci_low = b - 1.96*se
	gen ci_high = b + 1.96*se
	}
	
	**************************************************************************	
	* Reshape the data for the iterations: this will give b`x' and se`x' 
	**************************************************************************
	
	{
	reshape wide b se r2_adj p_value_1s ci_low ci_high, i(country_code year) j(iteration)
	
	merge 1:1 country_code year using `gdp_data'
	
	keep if _merge == 3
	drop _merge

	** Gen GDP_pc measures
	gen log_GDP = log(GDP_pc_constantUS2010) 	
	gen log_GDP_pc_currentUS = log(GDP_pc_currentUS)	 
	gen log_PPP_current 	 = log(PPP_current)				
	
	* Assign Variable labels, which explain what each b is
	
	label var b1 "Informal Consumption Share of Total"
	label var b2 "Average Informal Consumption"
	label var b3 "Median Informal Consumption"
	label var b4 "p5 Informal Consumption"
	label var b5 "p95 Informal Consumption"		
	
	label var b6 "IEC slope, COICOP control level 0"
	label var b7 "IEC slope, COICOP control level 1"
	label var b8 "IEC slope, COICOP control level 2"
	label var b9 "IEC slope, COICOP control level 3"
	label var b10 "IEC slope, COICOP control level 4"
	
	label var b11 "IEC slope, COICOP control level 0 + hhlds X"
	label var b12 "IEC slope, COICOP control level 1 + hhlds X"
	label var b13 "IEC slope, COICOP control level 2 + hhlds X"
	label var b14 "IEC slope, COICOP control level 3 + hhlds X"	
	label var b15 "IEC slope, COICOP control level 4 + hhlds X"

	label var b16 "IEC slope, COICOP control level 0 + hhlds X + surveyblocks"
	label var b17 "IEC slope, COICOP control level 1 + hhlds X + surveyblocks"
	label var b18 "IEC slope, COICOP control level 2 + hhlds X + surveyblocks"
	label var b19 "IEC slope, COICOP control level 3 + hhlds X + surveyblocks"	
	label var b20 "IEC slope, COICOP control level 4 + hhlds X + surveyblocks"		

	label var b21 "IEC slope, rural/urban + hhlds X"
	label var b22 "IEC slope, surveyblocks + hhlds X"
	
	*** Top code at 0 negative values of slope coefficients
	forvalues i = 6(1)22 {
		gen t`i' = b`i'
		replace t`i' = 0 if t`i'<0
		}

	** Prepare some ratios for the graphs 
	gen ratio_b6_b7 = b7/b6
	gen ratio_b7_b8 = b8/b7
	gen ratio_b6_b8 = b8/b6
	gen ratio_b8_b9 = b9/b8
	gen ratio_b9_b10 = b10/b9	
	gen ratio_b6_b10 = b10/b6	
	
	gen ratio_p5_p95 = b4/b5
	gen dif_p5_p95 = b4-b5

	}	
		
**************************************************	
* 1. Summary statistics and slope coefficients	
************************************************** 
	*Table 2, mean over countries
	local sum_stats = 1
	
	if `sum_stats' {	
	{
	cap log close 
	log using "$main/logs/graphs_regression_output_${scenario}_`c(current_date)'.log" , replace
	
	sum b1, d 				// Average level in sample (Correct but for comparability with food use b2 for now) 
	sum b2, d               // Average share in sample 
	sum b6, d 				// Average slope in sample	
	
	local low_income 7
	local mid_income 8.6
	
	gen income_group = .
	replace income_group = 1 if log_GDP <= `low_income'
	replace income_group = 2 if log_GDP>`low_income' & log_GDP <= `mid_income'
	replace income_group = 3 if log_GDP > `mid_income'	

	bysort income_group: sum b6
	
	** COICOP controls
	sum b6 t6 b7 t7 b8 t8 b9 t9 b10 t10 
	
	** HHLD CONTROLS + COICOP 
	sum b11 t11 b12 t12 b13 t13 b14 t14 b15 t15
	
	** HHLD CONTROLS + COICOP + GEO_LOC
	sum b16 t16 b17 t17 b18 t18 b19 t19 b20 t20
	
	sum b21 t21 				// hhld controls + urban
	sum b22 t22					// hhld controls + survey_block
	}
	}
	** For Table 2: IEC SLOPES in PAPER
	
	matrix results = J(5,9,.)
	local col = 0
	
	foreach i in 6 11 21 22 12 13 14 15 20{
		local ++col
		display "This is specification `i'" 
		sum t`i' 
		matrix results[1,`col'] = `r(mean)' 
		sum ci_low`i'
		matrix results[2,`col'] = `r(mean)' 
		sum ci_high`i'
		matrix results[3,`col'] = `r(mean)' 	
		sum r2_adj`i'
		matrix results[4,`col'] = `r(mean)' 
		count if p_value_1s`i' <= 0.05 				// Count how many rejected one-sided t-tests
		matrix results[5,`col'] = `r(N)' 		
		}
		
		mat list results
		
		// Generate an automatic table of results 
		global writeto "$main/tables/cross_country/table2_$scenario.tex"
		cap erase $writeto
		local u using $writeto
		local cc=1
		local tt=1
	
		latexify results[1,1...] `u', format(%4.1f) append
		latexify results[2,1...] `u', brackets("[]") format(%4.1f) append
		latexify results[3,1...] `u',  format(%4.1f) append
		latexify results[4,1...] `u', format(%4.2f) append	
		latexify results[5,1...] `u', format(%4.0f) append			
		
	log close 	
	
	*Table A1, coef by country 
	
	gen country_fullname="Benin" if country_code=="BJ"
	replace 	country_fullname="Burkina Faso" 	if 	country_code=="BF"
	replace 	country_fullname="Burundi" 	if 	country_code=="BI"
	replace 	country_fullname="Bolivia" 	if 	country_code=="BO"
	replace 	country_fullname="Brazil" 	if 	country_code=="BR"
	replace 	country_fullname="Congo DRC" 	if 	country_code=="CD"
	replace 	country_fullname="Congo Rep" 	if 	country_code=="CG"
	replace 	country_fullname="Chile" 	if 	country_code=="CL"
	replace 	country_fullname="Cameroon" 	if 	country_code=="CM"
	replace 	country_fullname="Colombia" 	if 	country_code=="CO"
	replace 	country_fullname="Costa Rica" 	if 	country_code=="CR"
	replace 	country_fullname="Dominican Republic" 	if 	country_code=="DO"
	replace 	country_fullname="Ecuador" 	if 	country_code=="EC"
	replace 	country_fullname="Comoros" 	if 	country_code=="KM"
	replace 	country_fullname="Morocco" 	if 	country_code=="MA"
	replace 	country_fullname="Montenegro" 	if 	country_code=="ME"
	replace 	country_fullname="Mexico" 	if 	country_code=="MX"
	replace 	country_fullname="Mozambique" 	if 	country_code=="MZ"
	replace 	country_fullname="Niger" 	if 	country_code=="NE"
	replace 	country_fullname="Peru" 	if 	country_code=="PE"
	replace 	country_fullname="Papua New Guinea" 	if 	country_code=="PG"
	replace 	country_fullname="Serbia" 	if 	country_code=="RS"
	replace 	country_fullname="Rwanda" 	if 	country_code=="RW"
	replace 	country_fullname="Senegal" 	if 	country_code=="SN"
	replace 	country_fullname="Sao Tome and Principe" 	if 	country_code=="ST"
	replace 	country_fullname="Eswatini" 	if 	country_code=="SZ"
	replace 	country_fullname="Chad" 	if 	country_code=="TD"
	replace 	country_fullname="Tunisia" 	if 	country_code=="TN"
	replace 	country_fullname="Tanzania" 	if 	country_code=="TZ"
	replace 	country_fullname="Uruguay" 	if 	country_code=="UY"
	replace 	country_fullname="South Africa" 	if 	country_code=="ZA"
	
	sort country_fullname
	gen id_country=_n
	
	
	sum id_country 
	matrix results = J(`r(max)'*2,9,.)	
	
	forvalues i = 1(1)`r(max)'  {
		
		local k = 2*`i'-1
		local l = 2*`i'	
		
	    sum t6 if id_country==`i' 	
	    matrix results[`k',1] = `r(mean)'
	
	    sum se6 if id_country==`i' 	
	    matrix results[`l',1] = `r(mean)'
		
		sum t11 if id_country==`i' 	
	    matrix results[`k',2] = `r(mean)'
	
	    sum se11 if id_country==`i' 	
	    matrix results[`l',2] = `r(mean)'
		
		sum t21 if id_country==`i' 	
	    matrix results[`k',3] = `r(mean)'
	
	    sum se21 if id_country==`i' 	
	    matrix results[`l',3] = `r(mean)'
		
		sum t22 if id_country==`i' 	
	    matrix results[`k',4] = `r(mean)'
	
	    sum se22 if id_country==`i' 	
	    matrix results[`l',4] = `r(mean)'
		
		sum t12 if id_country==`i' 	
	    matrix results[`k',5] = `r(mean)'
	
	    sum se12 if id_country==`i' 	
	    matrix results[`l',5] = `r(mean)'
		
		sum t13 if id_country==`i' 	
	    matrix results[`k',6] = `r(mean)'
	
	    sum se13 if id_country==`i' 	
	    matrix results[`l',6] = `r(mean)'
		
		sum t14 if id_country==`i' 	
	    matrix results[`k',7] = `r(mean)'
	
	    sum se14 if id_country==`i' 	
	    matrix results[`l',7] = `r(mean)'
		
		sum t15 if id_country==`i' 	
	    matrix results[`k',8] = `r(mean)'
	
	    sum se15 if id_country==`i' 	
	    matrix results[`l',8] = `r(mean)'
		
		sum t20 if id_country==`i' 	
	    matrix results[`k',9] = `r(mean)'
	
	    sum se20 if id_country==`i' 	
	    matrix results[`l',9] = `r(mean)'
	    }
			
	mat list results
	
// Generate an automatic table of results 
		global writeto "$main/tables/cross_country/tableA1_$scenario.tex"
		cap erase $writeto
		local u using $writeto
		local o extracols(1)
		local t1 "Benin"
		local t2 "Bolivia"
		local t3 "Brazil"
		local t4 "Burkina Faso"
		local t5 "Burundi"
		local t6 "Cameroon"
		local t7 "Chad"
		local t8 "Chile"
		local t9 "Colombia"
		local t10 "Comoros"
		local t11 "CongoDRC"
		local t12 "Congo Rep"
		local t13 "Costa Rica"
		local t14 "Dominican Rep"
		local t15 "Ecuador"
		local t16 "Eswatini"
		local t17 "Mexico"
		local t18 "Montenegro"
		local t19 "Morocco"
		local t20 "Mozambique"
		local t21 "Niger"
		local t22 "Papua New Guinea"
		local t23 "Peru"
		local t24 "Rwanda"
		local t25 "Sao Tome"
		local t26 "Senegal"
		local t27 "Serbia"
		local t28 "South Africa"
		local t29 "Tanzania"
		local t30 "Tunisia"
		local t31 "Uruguay"
		local cc=1
		local tt=1
		sum id_country 
		forvalues i = 1(1)`r(max)'  {
		local k = 2*`i'-1
		local l = 2*`i'	
		latexify results[`k',1...] `u', title("{`t`tt''}") format(%4.2f) append
		latexify results[`l',1...] `u', brackets("()") `o' format(%4.2f) append
		local ++tt
	}
	 
	
	
*********************************************	
* 2. Graphs
*********************************************	
	***********************************************************
	* 2.1 Summary Statistics 
	***********************************************************		

	local share_informality     = 1       // Informality share of total: this is panel A of Figure XX
	local average_informality 	= 0		    // Average Informality on country log_gdp_pc: this is panel A of Appendix Figure XX
	local median_informality 	= 0			// Median Informality on country log_gdp_pc
	local ratio_p90_p10 		= 0			// Informality ratio between p90 to p10
	local dif_p90_p10 			= 0			// Informality absolute difference between p90 to p10			
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(20)100, nogrid labsize(`size')) yscale(range(0 12)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	

	if `share_informality'	{
	
		#delim ;		
		
		twoway (scatter b1 log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)),	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Informal Consumption Share", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'
		// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
		name(level_informality, replace) ; 
		
		graph save "$main/graphs/cross_country/level_informality_$scenario.gph", replace	;
		graph export "$main/graphs/cross_country/level_informality_$scenario.pdf", replace	;
		
		#delim cr	
		} 
		
		reg  b1 log_GDP
		
	if `average_informality'	{
	
		#delim ;		
		
		twoway (scatter b2 log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)),	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Avg Informal Consumption Share", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'
		// title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
		name(mean_informality, replace) ; 
		
		graph save "$main/graphs/cross_country/mean_informality_$scenario.gph", replace	;
		graph export "$main/graphs/cross_country/mean_informality_$scenario.pdf", replace	;
		
		#delim cr	
		} 
	
	if `median_informality' { 
		#delim ;		
		
		twoway (scatter b3 log_GDP, msize(vsmall) color(red) mlabel(country_code) mlabcolor(red*1.5))
		(lfit b7 ln_base2_GDP, color(blue) )	,	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle(Median Informal Consumption, margin(small))
		legend(off) 	
		`graph_region_options'	
		title("Level of Informal Consumption on GDP", margin(medsmall) size(med))	
		name(mean, replace) 		; 
		
		graph export "$main/graphs/cross_country/median_informality_$scenario.pdf", replace	;
		#delim cr	
		}	
	
	if `ratio_p90_p10' { 
		#delim ;		
		
		twoway (scatter ratio_p5_p95 log_GDP, msize(vsmall) color(red) mlabel(country_code) mlabcolor(red*1.5))
		(lfit ratio_p5_p95 ln_base2_GDP, color(blue) )	,	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Ratio bottom to top income decile", margin(small))
		legend(off) 	
		`graph_region_options'	
		title("Ratio bottom to top decile of Informal Consumption", margin(medsmall) size(med))	
		name(deciles_ratio, replace) 		; 
		
		graph export "$main/graphs/cross_country/ratio_p10p90_informality_$scenario.pdf", replace	;
		#delim cr		
		} 
	
	if `dif_p90_p10' {
		#delim ;		
		
		twoway (scatter dif_p5_p95 log_GDP, msize(vsmall) color(red) mlabel(country_code) mlabcolor(red*1.5)),	
		ylabel(0(5)50) yscale(range(0 50))
		`xaxis' 
		`yaxis' 
		`xtitle'
		legend(off) 	
		`graph_region_options'	
		title("Difference bottom to top decile of Informal Consumption", margin(medsmall) size(med))	
		name(deciles_ratio, replace) 		; 
		
		graph export "$main/graphs/cross_country/dif_p10p90_informality_$scenario.pdf", replace	;
		#delim cr	
		} 
	
	***********************************************************
	* 2.2 Coefficients from regressions
	***********************************************************		
	* Define a local with the set of variables to run this over 

	local slope_informality_fits 	= 0		// Average Informality on country log_gdp_pc
	local slope_informality_ci 		= 1		// With confidence intervals 
	local slope_COICOP 				= 1		// Shows slopes when controlling more narrowly for product composition 
	local slope_geo					= 1     // Shows sloped when controlling for urbban vs rural and for survey blocks
	local slope_arrows_COICOP 		= 0		// Shows arrows when going from one COICOP level to the next
	local slope_arrows_COICOP_1to4 	= 0		// Shows arrows when going from one COICOP1 to COICOP4
	local slope_ratio_COICOP 		= 0		// Ratio of Slopes when going from one COICOP level to the next
	local bar_slope_ratio_COICOP 	= 0
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local yaxis "ylabel(-25(5)5, nogrid labsize(`size')) yscale(range(-25 5)) yline(-25(5)5, lstyle(minor_grid) lcolor(gs1))" 		
	local xaxis "xlabel(5(1)10, labsize(`size'))"
	
if `slope_informality_fits' {
		#delim ;		
		
		twoway (scatter b6 log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit b6 log_GDP, msize(vsmall) color(green))
		(qfit b6 log_GDP, msize(vsmall) color(red)),
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
		
		twoway (rspike ci_low6 ci_high6 log_GDP, lstyle(ci) lcolor(gs6) )
		(scatter b6 log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) ,
		`xaxis' 
		`yaxis' 
		`xtitle'		
		ytitle("Informal Consumption Slope", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(slope_informality, replace) 		; 
		
		graph export "$main/graphs/cross_country/slope_informality_ci_$scenario.pdf", replace	;
		
		#delim cr	
		} 			
		
if `slope_COICOP' {
	forvalues i = 11(1)15 { 
		#delim ;		
		
		twoway (rspike ci_low`i' ci_high`i' log_GDP, lstyle(ci) lcolor(gs6) )
		(scatter b`i' log_GDP, msize(vsmall) color(gs1) mlabel(country_code)  mlabsize(2.5) mlabcolor(gs10*1.5)) ,
		`xaxis' 
		`yaxis' 
		`xtitle'	
		ytitle("Informal Consumption Slope", margin(medsmall)  size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(b`name', replace) 		; 		
		
		graph export "$main/graphs/cross_country/slope_b`i'_$scenario.pdf", replace	;
		
		#delim cr
		}
	}	
		
if `slope_geo' {
	forvalues i = 21(1)22 { 
		#delim ;		
		
		twoway (rspike ci_low`i' ci_high`i' log_GDP, lstyle(ci) lcolor(gs6) )
		(scatter b`i' log_GDP, msize(vsmall) color(gs1) mlabel(country_code)  mlabsize(2.5) mlabcolor(gs10*1.5)) ,
		`xaxis' 
		`yaxis' 
		`xtitle'	
		ytitle("Informal Consumption Slope", margin(medsmall)  size(`size'))
		legend(off) 	
		`graph_region_options'	
		name(b`name', replace) 		; 		
		
		graph export "$main/graphs/cross_country/slope_b`i'_$scenario.pdf", replace	;
		
		#delim cr
		}
	}
	
	*** pcarrow graphs
	
if `slope_arrows_COICOP' {
	forvalues i = 6(1)8{
		local j = `i'+1
		local k = `i'-1
		
	local outcome "ratio_b6_b8 ratio_b8_b9 ratio_b9_b10 ratio_b6_b10"
	foreach name of local outcome {		
		
		#delim ;				
		twoway (scatter b`i' log_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabcolor(gs1*1.5))
		(pcarrow b`i' log_GDP b`j' log_GDP, color(gs10) )	,
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


	
	*** Ratio of slopes graphs
	
if `slope_ratio_COICOP'  { 
	local outcome "ratio_b6_b7 ratio_b7_b8 ratio_b8_b9 ratio_b6_b9"
	foreach name of local outcome {
		#delim ;		
		
		twoway (scatter `name' log_GDP if country_code!= "CL" & country_code!= "NE", color(red) mlabel(country_code) mlabcolor(red*1.5)) ,
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
	
	
	
	
	
	
	
	}
