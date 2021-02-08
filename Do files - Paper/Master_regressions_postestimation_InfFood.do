	 				*************************************
					* 	INFORMAl/FORMAL ENGEL CURVES 	*
					* For Food and Non Food Separately	*
					*************************************		
*********************************************	
* Preliminaries
*********************************************	
	
	** NEED TO RUM Master.do 
	cap log close
	clear all 
	set more off
	set matsize 10000	
	set type double 
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
	
	global drop_housing = 1  // Set to 1 to run same code without housing	
	display "$scenario"	
		
	set linesize 100 

	* Generates a data_file which stores the coefficients from the regressions
	* b will take 4 values (foodinf, foodfor, restinf, restfor, we will add labels at the bottom when outsheeting the file, similar to what we did in other files 
	 cap postclose regressions_output		 
	 postfile regressions_output str10 country_code year iteration b1 se1 b2 se2 b3 se3 b4 se4 using "$main/proc/regressions_inffood_$scenario.dta", replace
	 
*******************************************************	
* 	0. Parameters: Informality definition and sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	// keep if country_code == "BJ"					// To run on one country select its acronym  
	
	qui valuesof country_code
	local country_code = r(values)
	display `"`country_code'"'
	qui valuesof country_fullname
	local country_fullname = r(values)
	display `"`country_fullname'"'
	qui valuesof income_measure
	local income_measure = r(values)
	qui valuesof product_code
	local product_code = r(values)	
	qui valuesof category_4
	local category_4 = r(values)	
	qui valuesof slope_4
	local slope_4 = r(values)	
	
	local n_models : word count `country_code'
	assert `n_models'==`:word count `country_fullname''  // this ensures that the two lists are of the same length		
		
*********************************************	
* 1. Loop Over all Countries with COICOP
*********************************************		

	forval k=1/`n_models' {
	
		***************
		* GLOBALS	 *
		***************	
		
		global country_code `: word `k' of `country_code''		
		global country_fullname `: word `k' of `country_fullname''	
		global income_measure `: word `k' of `income_measure''		
		global product_code `: word `k' of `product_code''
		global cat4_factor `: word `k' of `category_4''
		global slope4 `: word `k' of `slope_4''
		global year = substr("$country_fullname",-4,4)	
		
		display "*************** Country: $country_fullname **************************" 	
	
		* Obtain GDP_pc for the country
		import excel using "$main/data/Country_information.xlsx" , clear firstrow
		qui keep if CountryCode == "$country_code"	& Year == $year
	
		global GDP_pc_constantUS2010 = GDP_pc_constantUS2010[1] 	
		global conversion_rate = GDP_pc_currentLCU[1]/PPP_current[1]		// Coefficient to divide income by
		display "Conversion rate = $conversion_rate"	

		**********************
		* LOAD SURVEY 	 *
		**********************	
		
		use "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_${product_code}_4dig.dta" , clear	

		* Determine if with housing or net of housing 
			if $drop_housing == 1 { 
			drop if housing == 1
			}	
	
		* Dataset: household_cov
		merge m:1 hhid using "$main/proc/$country_fullname/${country_code}_household_cov.dta" 
		drop if _merge!= 3 
		drop _merge	
		
		********************************************
		* 		DATA PREP 
		********************************************
	
		* Define  Log Income per persom   	
		drop if $income_measure == 0 | $income_measure == . 
		gen log_income_pp = log($income_measure/($conversion_rate * hh_size))  

		** Generate income decile dummies (will be useful for the impuation
		** then use the decile value (1 to 10) to use it as a correction factor with a slope coming from the excel
		egen tag = tag(hhid)
		
		gen decile_income = . 
		forvalues i = 10(10)90 { 	
			_pctile log_income_pp if tag == 1 [weight= hh_weight], p(`i')  
			local p_low = `r(r1)'
			replace decile_income = `i'/10 if log_income_pp <= `p_low' & decile_income == . 
			} 
		replace decile_income = 10 if decile_income == .				
		drop tag
		*xtile decile_income = log_income_pp [weight=hh_weight], nq(10) 	// Faster command but not appropirate since we are at the COICP4 level and not at the hhld level
		
		* Definition of Formality:
		** Country specific imputations to deal with places where categories 3 and 4 are mixed:
		if $cat4_factor == 1 {	
			gen Inf_weight = .
			replace Inf_weight = 0 										 if inlist(detailed_classification,6,8,10,99)
			replace Inf_weight = $Inf_weight_5							 if inlist(detailed_classification,5)
			replace Inf_weight = $Inf_weight_4 							 if inlist(detailed_classification,4) 
			replace Inf_weight = $Inf_weight_3   	 					 if inlist(detailed_classification,3) 			
			replace Inf_weight = 1 										 if inlist(detailed_classification,1,2,7,9) 		
			}
		else if $cat4_factor != 1 {
			replace detailed_classification = 3 if detailed_classification == 4
			
			gen Inf_weight = .
			replace Inf_weight = 0 										 							  													if inlist(detailed_classification,6,8,10,99)
			replace Inf_weight = $Inf_weight_5							 							  													if inlist(detailed_classification,5)
			replace Inf_weight = $Inf_weight_4 							 							  													if inlist(detailed_classification,4) 
			replace Inf_weight = $Inf_weight_3*((1-$cat4_factor)+$slope4*(5.5-decile_income))+$Inf_weight_4*($cat4_factor+$slope4*(decile_income-5.5))  if inlist(detailed_classification,3) 			
			replace Inf_weight = 1 																	 			 										if inlist(detailed_classification,1,2,7,9) 	
			* 	bysort decile_income: sum Inf_weight if detailed_classification == 3 // This allows to check the assignment is correctly done
			} 	
				
			tab detailed_classification
			gen Inf_weight_exp_TOR_item = exp_TOR_item * Inf_weight 	
					
			cap drop Formal_Informal_0_1  
			gen Formal_Informal_0_1 = . 
			replace Formal_Informal_0_1  = 0 if Inf_weight > 0 & Inf_weight!= . 
			replace Formal_Informal_0_1  = 1 if Inf_weight == 0
	
			* GENERATE THE SHARES of INFORMAL CONSUMPTION For each level of COICOP
			gen COICOP_1dig = 1 // Used to make later codes run as a loop when looking at aggregates for one household
			
			forvalues i = 1(1)2 { 
			gsort hhid COICOP_`i'dig Formal_Informal_0_1 			// Always tag first an informal category, if it exists at this level
			egen tag_`i' = tag(hhid COICOP_`i'dig)
			by hhid COICOP_`i'dig: egen total_exp_`i' = total(exp_TOR_item)
			
			gsort hhid COICOP_`i'dig Formal_Informal_0_1	
			by hhid COICOP_`i'dig Formal_Informal_0_1: egen total_exp_informal_`i' = total(Inf_weight_exp_TOR_item)	
			replace total_exp_informal_`i' = 0 if Formal_Informal_0_1 != 0
			gen share_informal_`i' = (total_exp_informal_`i' / total_exp_`i')
			drop total_exp_informal_`i'
			}
			
			** Check that the sum of expenditure corresponds to the one we had already constructed in the micro data 
			gen dif = total_exp_1  - exp_noh 
			count if tag_1 == 1
			count if tag_1 == 1 & abs(dif)>= 1000		

		********************************************
		* 	RESHAPE DATA TO GO TO WIDE and CLEANING
		********************************************			
			
		* Keep one observation per COICOP2 hhid, when the COICOP2 category exists
		gen item = (exp_TOR_item>0) 
		bys hhid: egen total_item=sum(item) // sum items per hh
		
		keep if tag_2 == 1  				
				
		replace total_exp_2= 0 if total_exp_2==.

		* Keep relevant variables and reshape such that we have in wide format the COICOP2 consumption at the hosuehold level 
		
		keep total_exp_2 share_informal_2  hhid COICOP_2dig hh_weight log_income_pp total_exp_1 decile_income  hh_size head_sex head_age total_item
		reshape wide total_exp_2  share_informal_2, i(hhid) j(COICOP_2dig)
		
		** Issue: If no purchase of a given category then it is a missing not a zero, replace as a zero and make into a share of total * 100
		forvalues i = 1(1)12 {
			gen share_exp_2`i' = . 
			cap replace total_exp_2`i' = 0 if total_exp_2`i' == .
			cap replace share_exp_2`i' = total_exp_2`i'/total_exp_1
			} 
			
		** Drop households which consume no food, for consist Food Engel curves (Very few) 	
		gen nofood = . 
		replace nofood = 1 if total_exp_21 == 0 
		
		** Checks how many items are consumed by households without any food consumption 
		gen total_item_ifnofood = .
		replace total_item_ifnofood = total_item if nofood == 1
	
		bysort decile_income: sum share_exp_21 share_exp_22 nofood total_item_ifnofood [weight= hh_weight]
		
		drop if nofood == 1        // Drop households that never purchase any food items 
		drop nofood total_item_ifnofood
		
		** Similarly count how many households only have food items (Not necessary) 
		count if share_exp_21 == 1
		drop if share_exp_21 == 1
		
		** Total consumption divided in 4 bins: ForFood, InfFood, ForRest, InfRest, in shares of total and in total spending
		
		** FOOD 
		gen share_InfFood = share_exp_21 * share_informal_21
		gen share_ForFood = share_exp_21 * (1-share_informal_21)
		gen total_InfFood = total_exp_21 * share_informal_21
		gen total_ForFood = total_exp_21 * (1-share_informal_21)
		
		* NONFOOD: has to be added up from the other 11 COICOP categories (numbered 2 to 12) 
		foreach name in "total" "share" {
		forvalues i = 2(1)12 {
			gen tmp_`name'_informal_2`i' = . 
			gen tmp_`name'_formal_2`i' = . 
			replace tmp_`name'_informal_2`i' = `name'_exp_2`i' * share_informal_2`i' 
			replace tmp_`name'_formal_2`i' = `name'_exp_2`i' * (1-share_informal_2`i')
			}
			}

		order _all, sequential
		foreach name in "total" "share" {
		egen `name'_InfRest = rowtotal(tmp_`name'_informal_22-tmp_`name'_informal_212)
		egen `name'_ForRest = rowtotal(tmp_`name'_formal_22-tmp_`name'_formal_212)
		}
		
		foreach var in share_InfFood share_ForFood share_InfRest share_ForRest {
			replace `var' = `var' * 100
			}
		drop tmp* 
		
		** Test adds up to 100 
		egen test  = rowtotal(share_InfFood share_ForFood share_InfRest share_ForRest)
		sum test, d
		drop test 

		********************************************
		* 		DATA CHECKS
		********************************************
		* Check that no-one is missing income
		qui count 
		display "Sample Size = `r(N)'"	
		qui count if log_income_pp!= . 
		display "Non Missing Income = `r(N)'"				
		
		* Check that everyone has weights
		qui count if hh_weight != . 
		display "Non Missing Weights = `r(N)'"				
		
		* Graph options:
		cap grstyle init
		cap grstyle set ci gs10, opacity(60) 
		cap grstyle set color gs1
		
		********************************************
		* 		Moments 
		********************************************		
		local moments = 1
		if `moments' {	
			
			** TOP CODE at p99 when doign aggregates
			foreach var in total_InfFood total_ForFood total_InfRest total_ForRest {
				gen tc_`var' = `var'
				qui sum `var', d
				replace tc_`var'  = `r(p99)' if  `var' >= `r(p99)' &  `var' != . 
				} 

			tabstat tc_total_InfFood tc_total_ForFood tc_total_InfRest tc_total_ForRest [aw= hh_weight], stat(sum) save
			mat agg_tot = r(StatTotal)
			
			local tot = agg_tot[1,1] + agg_tot[1,2] + agg_tot[1,3] + agg_tot[1,4]
			
			local b1 = agg_tot[1,1] / `tot'
			local b2 = agg_tot[1,2] / `tot'
			local b3 = agg_tot[1,3] / `tot'
			local b4 = agg_tot[1,4] / `tot'
			
			local reg_name "$country_code"
			local empty = .			
			local number = 1
			post regressions_output ("`reg_name'") ($year) (`number') (`b1') (`empty') (`b2') (`empty') (`b3') (`empty') (`b4') (`empty') 
		
			drop tc_*
		
			** All
			tabstat share_InfFood share_ForFood share_InfRest share_ForRest [aw= hh_weight], stat(mean) save
			mat agg_tot = r(StatTotal)
			local b1 = agg_tot[1,1]
			local b2 = agg_tot[1,2]
			local b3 = agg_tot[1,3]
			local b4 = agg_tot[1,4]
			
			display "`reg_name'"
			local number = 2
 			post regressions_output ("`reg_name'") ($year) (`number') (`b1') (`empty') (`b2') (`empty') (`b3') (`empty') (`b4') (`empty')  	
		} 	// Close Moments Section 
		
		
		********************************************
		* 		Regressions
		********************************************			
		local regressions = 1
		if `regressions' {	
		
		* Windsoriwing top and bottom income outliers: 
		local low = 1						// Set your percentile to windsorize
		local high = 100 - `low'
		
		_pctile log_income_pp [aw= hh_weight], p(`low')  
		return list
		local p_low = `r(r1)'
		_pctile log_income_pp [aw= hh_weight], p(`high') 
		return list
		local p_high = `r(r1)'	
		
		replace log_income_pp = `p_low' if log_income_pp < `p_low'	& log_income_pp != .
		replace log_income_pp = `p_high' if log_income_pp > `p_high' & log_income_pp != .		
			
			local i = 1
			foreach var in share_InfFood share_ForFood share_InfRest share_ForRest { 
			qui reg `var' log_income_pp [aweight=hh_weight] , vce(robust)	
			local b`i' = _b[log_income_pp]
			display `b`i''
			local se`i' = _se[log_income_pp]
			display `se`i''
			local i = `i' + 1
				} 	// Close variable loop 
				
			local number = 3
 			post regressions_output ("`reg_name'") ($year) (`number') (`b1') (`se1') (`b2') (`se2') (`b3') (`se3') (`b4') (`se4')  				
			
			} 		// Close Regressions Section 		
		
		
		********************************************
		* 		ENGEL CURVES 
		********************************************
		
		local engel_curves = 0
		if `engel_curves' {
		
		* Generate moments (median, percentiles) 
		qui sum log_income_pp [aw = hh_weight]  , d
		local median  = `r(p50)' 
		local p5 = `r(p5)'
		local p95 = `r(p95)'
		local bottom_range = floor(`r(p5)'*10)/10
		local top_range = ceil(`r(p95)'*10)/10
		local bottom_axis = ceil(`r(p5)')
		local top_axis = floor(`r(p95)')	
	
		* Figures Locals 
		local yaxis "ylabel(0(20)100) ytitle("")"
		local xaxis "xlabel(`bottom_axis'(1)`top_axis') xtitle("")"
		local xlines "xline(`median', lcolor(gs10)) xline( `p5', lcolor(gs10) lpattern(dash))  xline( `p95', lcolor(gs10) lpattern(dash))"
		local xscale "xscale(range(`bottom_range' `top_range'))"
		local graph_region_options "graphregion(fcolor(white)) plotregion(fcolor(white))" 
			
		* Food Informal ENGEL curve:
		#delim ;
		twoway (lpolyci share_InfFood log_income_pp if log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight])
		(lfit share_InfFood log_income_pp if  log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight])	, 
		`yaxis'
		`xaxis'
		`xlines'
		`xscale'
		`graph_region_options'
		legend(off) 	 
		title(Informal Food Engel Curve)
		name(InfFood, replace) ;

		#delim cr		
	
		* Food Formal ENGEL curve:	
		#delim ;
		twoway (lpolyci share_ForFood log_income_pp if log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight])
		(lfit share_ForFood log_income_pp if  log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight])	, 
		`yaxis'
		`xaxis'
		`xlines'
		`xscale'
		`graph_region_options'
		legend(off) 	
		title(Formal Food Engel Curve) 
		name(ForFood, replace) ;	
		#delim cr
		
		* Non-Food Informal ENGEL curve:	
		#delim ;
		twoway (lpolyci share_InfRest log_income_pp if log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight])
		(lfit share_InfRest log_income_pp if  log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight])	, 
		`yaxis'
		`xaxis'
		`xlines'
		`xscale'
		`graph_region_options'
		legend(off) 	
		title(Informal Non Food Engel Curve)	
		name(InfRest, replace) ;	
		#delim cr

		* Non-Food Formal ENGEL curve:		
		
		#delim ;
		twoway (lpolyci share_ForRest log_income_pp if log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight])
		(lfit share_ForRest log_income_pp if  log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight])	, 
		`yaxis'
		`xaxis'
		`xlines'
		`xscale'	
		`graph_region_options'
		legend(off) 	
		title(Formal Non Food Engel Curve)
		name(ForRest, replace) ;	
		#delim cr		

		#delim ; 
		graph combine InfFood ForFood InfRest ForRest , iscale(0.6) `graph_region_options' ; 

		graph export "$main/graphs/$country_fullname/${country_code}_ForInf_FoodRest.pdf", replace ;	
		#delim cr
		
		/*  * Obtain slope of Engel curve 
		local hhld_controls hh_size head_sex head_age 
		reg total_exp_21 log_income_pp `hhld_controls' if log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight] , robust
		*/ 
				} // End of engel_curves graphs 
			
		}		// Close Engel Curves Section  
		// Close country loop
	
		cap log close 
		postclose regressions_output
	
		** Assign Variable labels
		use "$main/proc/regressions_inffood_$scenario.dta", replace 
		label var b1 "Informal Food"
		label var b2 "Formal Food"
		label var b3 "Informal Non-Food"
		label var b4 "Formal Non-Food"
		save "$main/proc/regressions_inffood_$scenario.dta", replace 
	
	 
	 
	 
