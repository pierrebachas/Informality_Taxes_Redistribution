					*****************************************************************
					* 	Cross-Country Robustness Datasets (Formality Levels)		*
					*****************************************************************
******************	
* DATA PREPARATON*
******************
	
* This data is used to create Figure A in graphs_robustness_formality_levels.do
* it is also used to adjust in the country loop the slopes and levels for a few countries which do not have the distinction 
* of categories (3) vs (4) 

*********************************************	
* Preliminaries
*********************************************	
	
	clear all
	set more off
	set matsize 10000	

	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"
			
	global drop_housing = 1  // Set to 1 to run same code without housing	
	global only_nonfood = 0	// change to 0 to run on all 
	
	* Generates a data_file which stores the coefficients from the regressions
	 local filename "levels_robust_${only_nonfood}" 
	 cap postclose `filename'	 
	 
	 postfile `filename' str10 country_code year level decile share_level total_level using "$main/proc/`filename'.dta", replace 
	 
*******************************************************	
* 	0. Sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	// keep if country_code == "BO"			// To run on one country select its acronym  
	
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
	assert `n_models'==`:word count `income_measure''
	assert `n_models'==`:word count `product_code''
	
*********************************************	
* 1. Loop Over ALL Countries
*********************************************					
	
	forval k=1/`n_models' {
	
		***************
		* GLOBALS	 *
		***************	
		global country_code `: word `k' of `country_code''		
		global country_fullname `: word `k' of `country_fullname''	
		global income_measure `: word `k' of `income_measure''		
		global product_code `: word `k' of `product_code''
		global category_4_factor `: word `k' of `category_4''
		global slope_4 `: word `k' of `slope_4''
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
			
		gen levels = . 
		replace levels = 1 if inlist(detailed_classification,1) 
		replace levels = 2 if inlist(detailed_classification,2) 
		replace levels = 3 if inlist(detailed_classification,3) 			// corner, convenience store
		replace levels = 4 if inlist(detailed_classification,4)				// specialized shops
		replace levels = 5 if inlist(detailed_classification,5)
		replace levels = 6 if inlist(detailed_classification,6)
		replace levels = 7 if inlist(detailed_classification,7)
		replace levels = 8 if inlist(detailed_classification,8)
		replace levels = 9 if inlist(detailed_classification,9)
		replace levels = 10 if inlist(detailed_classification,10)		
		replace levels = 11 if inlist(detailed_classification,99)		
		
		* label for levels
		#delim ; 
		label define levels_lab 1 "non-market" 2 "no store front" 3 "conv/corner shops" 4 "specialized shops" 5 "large stores" 6 "services (Formal)"
								7 "Services (Inf)" 8 "Entertainement (Formal)" 9 "Entertainement (Inf)" 10 "Pharmacies" 11 "missing, etc" 	; 
		#delim cr
		label values levels levels_lab
	
	/*
		if `keylevels' {
		gen levels = . 
		replace levels = 1 if inlist(detailed_classification,1) 
		replace levels = 2 if inlist(detailed_classification,2,7,9) 
		replace levels = 3 if inlist(detailed_classification,3) 			// corner, convenience store
		replace levels = 4 if inlist(detailed_classification,4)				// specialized shops
		replace levels = 5 if inlist(detailed_classification,5,10)
		replace levels = 6 if inlist(detailed_classification,6,8)
		replace levels = 7 if inlist(detailed_classification,99)		
		
		* label for levels
		label define levels_lab 1 "non-market" 2 "no store front" 3 "conv/corner shops" 4 "specialized shops" 5 "large stores" 6 "other consumption" 7 "missing, etc" 
		label values levels levels_lab
		}
	*/ 	
				
		* Drop households consuming no food (Very few)
		gen food = (COICOP_2dig == 1)
		bysort hhid: egen has_food = total(food) 
		drop if has_food == 0	
		
		if $only_nonfood == 1 { 
		drop if COICOP_2dig == 1
		}	
		
		sort hhid
		by hhid: egen total = total(exp_TOR_item)
				
		forvalues i = 1(1)11 {
		gsort hhid levels
		by hhid levels: egen temp_sum_level_`i' = total(exp_TOR_item) if level == `i'
		}
		
		forvalues i = 1(1)11 {
		replace temp_sum_level_`i' = 0 if temp_sum_level_`i' == . 
		}
		
		forvalues i = 1(1)11 {
		gsort hhid 
		by hhid: egen sum_level_`i' = max(temp_sum_level_`i') 
		}
		
		drop temp_sum_level_1 - temp_sum_level_11

		* Keep one obs per hhld
		egen tag = tag(hhid)
		keep if tag == 1
		drop tag
		
		forvalues i = 1(1)11 {
		gen share_level_`i' = (sum_level_`i'/ total)*100 
		}			
				
		* Define Log income in base 2, converted to PPP USD 
		gen log_income_pp = log($income_measure /($conversion_rate * hh_size))  

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
		
		* Generate deciles and decile dummies
		gen decile_income = . 
		forvalues i = 10(10)90 { 	
			_pctile log_income_pp  [aw= hh_weight], p(`i')  
			local p_low = `r(r1)'
			replace decile_income = `i'/10 if log_income_pp <= `p_low' & decile_income == . 
			} 
		replace decile_income = 10 if decile_income == .
			
		* summarize
		local sum_name "$country_code"
		
		forvalues i = 1(1)11 { 
		display "***** Sums at Level `i' ***** " 
				forvalues j = 1(1)10{
				qui tabstat sum_level_`i' if decile_income == `j' [aw= hh_weight] , stat(sum) save  //total per coicop
				mat results_exp = r(StatTotal)
				local exp_total = results_exp[1,1]
				qui tabstat share_level_`i' if decile_income == `j' [aw= hh_weight] , stat(mean) save  // mean share by coicop
				mat results_exp = r(StatTotal)
				local exp_mean = results_exp[1,1]	
				post `filename' ("`sum_name'") ($year) (`i') (`j') (`exp_mean') (`exp_total')
				}
				}
				
			}
				postclose `filename'
	
	
	
	
	/*
	use "$main/proc/levels_robust_0" , replace

	bysort decile: egen total = total(total_level)
	gen missing = total_level / total
		
	keep if level == 11
	*/ 			
				
				
				
				
				
				
				
				
