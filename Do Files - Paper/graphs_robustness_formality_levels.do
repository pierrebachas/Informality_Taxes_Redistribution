					*****************************************************************
					* 	Cross-Country Robustness Graphs (Formality Levels) 			*
					*****************************************************************
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"
		
********************
* ROBUSTNESS GRAPHS*
********************
*********************************************
	* 1. Control Center  
*********************************************
	global only_nonfood = 0				// change to 0 to run on all 
	
	local stats_for_country_loop = 0
	
	local alllevels_separated = 1
	local alllevels_together = 0
	
	local layers_graph_simple = 0	 	// Figure with the different layers, separated formal vs informal
	local layers_graph_adjusted = 1	 	// Figure in PAPER with the different layers, separated formal vs informal with the adjustments for categories 3 and 4

	
	************************************************************************************************************		
	* PRELIM. Generate level and slopes for the 4 countries which do not have a layer 3 and 4 that are distinct
	************************************************************************************************************		
	**** Here produce the statistics for the countries missing the separation between level 3 and level 4: 
	**** Exlcude these countries (ZA,TN,TZ,ME) and then do the curve with share of catgeory 3 by decile of total 3+4
	** This then feeds into the "$main/data/Country_index_for_stata_loop.xlsx" for the 4 countries mentioned

	if `stats_for_country_loop' {
	* Prepare GDP data 
	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	

	rename Year year
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	save `gdp_data'	

	* Merge with Layers data 
	use "$main/proc/levels_robust_${only_nonfood}.dta", clear  
	merge m:1 country_code using `gdp_data'
	drop _merge 
	
	keep if level == 3 | level == 4 
	bysort country_code decile: egen total_3_4 = total(share_level)	
	gen share_3 = share_level / total_3_4
	keep if level == 3
	drop level 
	
	bysort decile: egen mean_total_3_4 = mean(total_3_4)
	bysort decile: egen mean_share_3 = mean(share_3)
	
	foreach name in "ZA" "TZ" "TN" "ME" { 
		sum GDP_pc_constantUS2010 if country_code == "`name'" 
		local min_`name' = `r(mean)' / 2
		local max_`name' = `r(mean)' * 1.5
		gen sample_`name' = 0 
		replace sample_`name' = 1 if GDP_pc_constantUS2010 >= `min_`name'' & GDP_pc_constantUS2010 <= `max_`name'' 
	}
	
	drop if inlist(country_code, "ZA", "TZ", "TN", "ME", "MZ")  // Note Mozambique has its own treatment since both 5 and 3 are missing and not only 3 
	
	**** Relation On average in the sample, share of category 3 among total of category 3 and 4 by deciles: 
	twoway scatter mean_share_3 decile  , name(all, replace)
	// NOTE: This goes from 0.6 to 0.35 from bottom to top 

	**** Relation dividing sample by 3, share of category 3 among total of category 3 and 4 by deciles: 
	local terciles = 0 
	if `terciles' {
	
	xtile pct = GDP_pc_constantUS2010, nq(3) 
	
	drop mean_share_3 mean_total_3_4 
	bysort decile pct: egen mean_total_3_4 = mean(total_3_4)
	bysort decile pct: egen mean_share_3 = mean(share_3)		
	
	forvalues i = 1(1)3 { 	
		twoway scatter mean_share_3 decile if pct == `i' , name("pct_`i'", replace) 
		}	
	}	
	
	*** CAN NOW GENERATE THE PARAMETERS WE NEED BY COMPARING THE 4 COUNTRIES WITH MISSING INFO with their peers (50% poorer to 50% richer) 
	
	** Obtain the Beta and obtain the average level and you are done, plug these into the formulas!
	
	foreach name in "ZA" "TZ" "TN" "ME" { 	
		display "`name'" 
		cap drop mean_share_3 mean_total_3_4 
		bysort decile sample_`name': egen mean_total_3_4 = mean(total_3_4)
		bysort decile sample_`name': egen mean_share_3 = mean(share_3)	
		twoway scatter mean_share_3 decile if sample_`name' == 1 , name("`name'", replace) 		
		reg mean_share_3 decile if sample_`name' == 1 
		local constant = _b[_cons]
		local decile = _b[decile]
		local med_effect = 1 - (`constant' + `decile'*5.5)
		count if sample_`name' & decile == 1
		display `med_effect' 
		drop mean_share_3 mean_total_3_4 
	} 
	} 
	
	 
	**************************************************************************	
	* A. Figure One by One of Each Formality Level
	**************************************************************************	
	if `alllevels_separated' {
	
	* Load Data of regression Output 
	use "$main/proc/levels_robust_${only_nonfood}.dta", clear  
	// drop if country_code  == "ME" 
	
	gen group_level = level 
	replace group_level = 5 if level == 10 
	replace group_level = 6 if level == 8 
	replace group_level = 7 if level == 9 
	drop if inlist(group_level, 8,9,10)
	replace group_level = 8 if level == 11	
	
	bysort group_level country_code decile: egen total_share_level = total(share_level)
	egen tag_group = tag(decile group_level country_code)
	keep if tag_group == 1		
	drop tag_group
	
	* Take average across countries 
	bysort decile group_level: egen mean_sharelevel = mean(total_share_level)
	egen tag_group = tag(group_level decile)
	keep if tag_group == 1	
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Decile of Expenditure Distribution", margin(medsmall) size(medlarge))"
	local yaxis "ylabel(0(5)30, nogrid) yscale(range(0 30)) yline(0(5)30, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(1(1)10)"	
	
	forvalues i = 1(1)8 {  
	#delim ;  
		twoway (connected mean_sharelevel decile if group_level == `i') , 
		`xaxis' 
		`yaxis' 
		// `xtitle' 
		// ytitle("Share of Expenditures", margin(medsmall) size(med))	
		ytitle("") 
		xtitle("") 
		title("") 
		name(G`i', replace)  
		`graph_region_options' ; 
	graph export "$main/graphs/cross_country/levels_share_combined_G`i'.pdf", replace		; 
	#delim cr 	
		}

	local graph_region_options "graphregion(color(white)) plotregion(color(white))" 		
	
	graph combine G1 G2 G3 G7 G4 G5 G6 G8,  `graph_region_options' iscale(*0.5) rows(2)
	graph export "$main/graphs/cross_country/levels_share_acrossdeciles_combined.pdf", replace		
	}
		
	**************************************************************************	
	* B. Figure All Together of the formality level 
	**************************************************************************	
	if `alllevels_together' {
	
	* Load Data of regression Output 
	use "$main/proc/levels_robust_${only_nonfood}.dta", clear  
	
	bysort decile level: egen mean_sharelevel = mean(share_level)
	egen tag_group = tag(level decile)
	keep if tag == 1	
	
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Decile of Expenditure Distribution", margin(medsmall) size(medlarge))"
	local yaxis "ylabel(0(20)100, nogrid) yscale(range(0 12)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(1(1)10)"	

	#delim ;
	
	twoway (connected mean_sharelevel decile if level == 1, lcolor(black) lpattern(dash) msymbol(smcircle) mcolor(black)) 
	(connected mean_sharelevel decile if level == 2, lcolor(gray) lpattern(shortdash) msymbol(smsquare) mcolor(gray))
	(connected mean_sharelevel decile if level == 3, lcolor(gs12) msymbol(smdiamond) mcolor(gs12))
	(connected mean_sharelevel decile if level == 4, lcolor(olive) msymbol(dash) mcolor(olive))
	(connected mean_sharelevel decile if level == 5, lcolor(sand) msymbol(shortdash) mcolor(sand))
	(connected mean_sharelevel decile if level == 6, lcolor(midblue) msymbol(smdiamond) mcolor(midblue))
	(connected mean_sharelevel decile if level == 11, lcolor(navy) msymbol(dash) mcolor(navy)), 
	`xaxis' 
	`yaxis' 
	`xtitle' 
	ytitle("Share of Expenditures", margin(medsmall) size(med))
	legend(order(1 "Non-market" 2 "No store front" 3 "Conv/corner shops" 4 "Specialized shops" 5 "Large stores" 6 "Other consumption" 7 "Missing")) 	
	`graph_region_options'
	title("")
	legend(title("Split sample by formality classification", size(vsmall)) size(vsmall) row(2) pos(12) bmargin(zero));	
	#delim cr
	}
	
	**************************************************************************	
	* C. Shaded graphs by formality levels "Layers" (Simple)
	**************************************************************************		
	* C.1 INFORMAL
	
	if `layers_graph_simple' {
	
	* Load Data of regression Output 
	use "$main/proc/levels_robust_${only_nonfood}.dta", clear   
	
	** bysort decile level: egen mean_sharelevel = mean(share_level)	
	reshape wide share_level , i(country_code decile) j(level)
	
	gen tmp_area1 = share_level1
	gen tmp_area2 = share_level1 + share_level2
	gen tmp_area3 = share_level1 + share_level2 + share_level3
	gen tmp_area4 = share_level1 + share_level2 + share_level3 + share_level7 + share_level9 	// Adding informal services
	
	forvalues i=1(1)4 {
		bysort decile: egen area`i' = mean(tmp_area`i')
		}
	
	egen tag_decile = tag(decile) 	
	
	#delim ;
	
	twoway (area area4 area3 area2 area1 decile if tag_decile == 1, color(gs1 gs4 gs7 gs10) sort) ,
	xlabel(1(1)10) 
	ylabel(0(10)70, nogrid) yscale(range(0 12)) yline(0(10)70, lstyle(minor_grid) lcolor(gs1))
	xtitle("Decile of Expenditure Distribution", margin(medsmall) size(medlarge))
	ytitle("Mean Share of Expenditures", margin(medsmall) size(med))
	text(10 3 "Non-market", size(small)) text(30 5 "No Store Front", size(small)) 
	text(46 7 "Corner Stores", size(small)) text(52.5 9 "Informal Services", size(small))
	legend(off) name(informal, replace)
	graphregion(color(white)) bgcolor(white) plotregion(color(white));		
	
	#delim cr
	
	* C.2 FORMAL
	use "$main/proc/levels_robust_${only_nonfood}.dta", clear   
	
	** bysort decile level: egen mean_sharelevel = mean(share_level)	
	reshape wide share_level , i(country_code decile) j(level)
	
	gen tmp_area1 = share_level4 + share_level10
	gen tmp_area2 = share_level4 + share_level10 + share_level5
	gen tmp_area3 = share_level4 + share_level10 + share_level5 + share_level6 + share_level8  // Adding formal services
	gen tmp_area4 = share_level4 + share_level10 + share_level5 + share_level6 + share_level8 + share_level11
	
	forvalues i=1(1)4 {
		bysort decile: egen area`i' = mean(tmp_area`i')
		}
	
	egen tag_decile = tag(decile) 	
	
	#delim ;
	
	twoway (area area4 area3 area2 area1 decile if tag_decile == 1, color(gs1 gs4 gs7 gs10) sort) ,
	xlabel(1(1)10) 
	ylabel(0(10)70, nogrid) yscale(range(0 12)) yline(0(10)70, lstyle(minor_grid) lcolor(gs1))
	xtitle("Decile of Expenditure Distribution", margin(medsmall) size(medlarge))
	ytitle("Mean Share of Expenditures", margin(medsmall) size(med))
	text(5 3 "Specialized Stores", size(small)) text(15.5 5 "Large Stores", size(small)) 
	text(25 7 "Formal Services", size(small)) text(40 9 "Utilities, Telecoms", size(small))
	legend(off) name(formal, replace)
	graphregion(color(white)) bgcolor(white) plotregion(color(white));		
	
	#delim cr
		
	}
	
	**************************************************************************	
	* D. Shaded graphs by formality levels "Layers": Scneario Adjusted 
	**************************************************************************		
	* D.1 INFORMAL
	
	if `layers_graph_adjusted' {

	** Prep data to merge to get the adjustment parameters and the country information
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 	
	tempfile parameter_data
	destring slope_4, force replace 
	save `parameter_data'	
	
	* Load Data of regression Output 
	use "$main/proc/levels_robust_${only_nonfood}.dta", clear   
	
	** bysort decile level: egen mean_sharelevel = mean(share_level)	
	reshape wide share_level total_level , i(country_code decile) j(level)
	
	** merge to get the parameters
	merge m:1 country_code using `parameter_data'	
	keep if _merge == 3
	drop _merge 
	
	** Country Adjustments
	replace share_level3 = share_level4 * (1-category_4) + share_level4*slope_4*(5.5- decile) 	if category_4 != 1
	replace share_level4 = share_level4 - share_level3 											if category_4 != 1
	
	** Gen levels
	gen tmp_area1 = share_level1
	gen tmp_area2 = share_level1 + share_level2
	gen tmp_area3 = share_level1 + share_level2 + share_level3
	gen tmp_area4 = share_level1 + share_level2 + share_level3 + share_level7 + share_level9 	// Adding informal services
	
	forvalues i=1(1)4 {
		bysort decile: egen area`i' = mean(tmp_area`i')
		}
	
	egen tag_decile = tag(decile) 	
	
	#delim ;
	
	twoway (area area4 area3 area2 area1 decile if tag_decile == 1, color(gs1 gs4 gs7 gs10) sort) ,
	xlabel(1(1)10) 
	ylabel(0(10)70, nogrid) yscale(range(0 12)) yline(0(10)70, lstyle(minor_grid) lcolor(gs1))
	xtitle("Decile of Expenditure Distribution", margin(medsmall) size(medlarge))
	ytitle("Mean Share of Expenditures", margin(medsmall) size(med))
	text(10 3 "Non-market", size(small)) text(30 5 "No Store Front", size(small)) 
	text(46.5 7 "Corner Stores", size(small)) text(58 9.1 "Informal Services", size(small))
	legend(off) name(informal, replace)
	graphregion(color(white)) bgcolor(white) plotregion(color(white));		

	graph export "$main/graphs/cross_country/shaded_informality_levels.pdf", replace;		
	
	#delim cr
	
	* D.2 FORMAL
	use "$main/proc/levels_robust_${only_nonfood}.dta", clear   
	
	** bysort decile level: egen mean_sharelevel = mean(share_level)	
	reshape wide share_level total_level , i(country_code decile) j(level)

	** merge to get the parameters
	merge m:1 country_code using `parameter_data'	
	keep if _merge == 3
	drop _merge 
	
	** Country Adjustments
	replace share_level3 = share_level4 * (1-category_4) + share_level4*slope_4*(5.5- decile) 	if category_4 != 1
	replace share_level4 = share_level4 - share_level3 											if category_4 != 1	
	
	** Gen levels
	gen tmp_area1 = share_level4 + share_level10
	gen tmp_area2 = share_level4 + share_level10 + share_level5
	gen tmp_area3 = share_level4 + share_level10 + share_level5 + share_level6 + share_level8  // Adding formal services
	gen tmp_area4 = share_level4 + share_level10 + share_level5 + share_level6 + share_level8 + share_level11
	
	forvalues i=1(1)4 {
		bysort decile: egen area`i' = mean(tmp_area`i')
		}
	
	egen tag_decile = tag(decile) 	
	
	#delim ;
	
	twoway (area area4 area3 area2 area1 decile if tag_decile == 1, color(gs1 gs4 gs7 gs10) sort) ,
	xlabel(1(1)10) 
	ylabel(0(10)70, nogrid) yscale(range(0 12)) yline(0(10)70, lstyle(minor_grid) lcolor(gs1))
	xtitle("Decile of Expenditure Distribution", margin(medsmall) size(medlarge))
	ytitle("Mean Share of Expenditures", margin(medsmall) size(med))
	text(4.5 3 "Specialized Stores", size(small)) text(13.5 5 "Large Stores", size(small)) 
	text(22.5 7 "Formal Services", size(small)) text(40 9 "Unspecified", size(small))
	legend(off) name(formal, replace)
	graphregion(color(white)) bgcolor(white) plotregion(color(white));		
	
	graph export "$main/graphs/cross_country/shaded_formality_levels.pdf", replace;	
	
	#delim cr
		
	}	
	
	

	
