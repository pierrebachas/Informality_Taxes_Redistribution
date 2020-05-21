*****************************************************
/* 
	This file generates the missing expenses by
		COICOP2 * Decile * country 

*/ 
*****************************************************
					*****************************************************
					* 		Regression DO FILE							*
					* 	  DATA ANALYSIS to EXPORT REGRESSION RESULTS	*
					*****************************************************
*********************************************	
* Preliminaries
*********************************************	
		
	clear all
	set more off
	set matsize 800	
	
	qui include "$main/dofiles/server_header.doh" 	// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
	
	global drop_housing = 1  		// Set to 1 to run the code without housing	
	display "$scenario"				// Central , Proba , Robust: see definition in Master.do	
	
	* Generates a data_file which stores the coefficients from the regressions
	* three iterations: first the alphas, then the shares, then the betas 
	* 12 COICOP values 
	* 3 coefficient: All, Formal and Informal
	 
	cap postclose regressions			 
	 
	#delim ; 
	postfile regressions str10 country_code year COICOP_2dig total_exp mean_exp total_exp_COICOP mean_exp_COICOP total_exp_missing mean_exp_missing
	using "$main/proc/tmp_missing_COICOP12_$scenario.dta", replace	;  	 

	#delim cr		
		 
*******************************************************	
* 	0. Sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	//keep if country_code == "BO"				// To run on one country select its acronym  
	
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
		* 	DATA PREP: Missing
		********************************************
	
		* Define Log income in base 2, converted to PPP USD 
		drop if $income_measure == 0 | $income_measure == . 
		gen log_income_pp = log($income_measure/($conversion_rate * hh_size))
		
		** Generate income decile dummies(will be useful for the impuation)
		** then use the decile value (1 to 10) to use it as a correction factor with a slope coming from the excel
		egen tag = tag(hhid)
		
		gen decile_income = . 
		forvalues i = 10(10)90 { 	
			_pctile log_income_pp if tag == 1 [aw= hh_weight], p(`i')  
			local p_low = `r(r1)'
			replace decile_income = `i'/10 if log_income_pp <= `p_low' & decile_income == . 
			} 
						
		replace decile_income = 10 if decile_income == .	

		drop tag
		tab detailed_classification
		
		* Definition of Missing:
		gen Missing_0_1 = .
		replace Missing_0_1 = 1 if detailed_classification==99
		replace Missing_0_1 = 0 if detailed_classification >=1 & detailed_classification <= 10 
		
		********************************************
		* 	Generate Missing Shares
		********************************************				

		* GENERATE THE SHARES of INFORMAL CONSUMPTION For each level of COICOP
		cap drop COICOP_1dig
		gen COICOP_1dig = 1 		// Used to make later codes run as a loop when looking at aggregates for one household
		
		forvalues i = 1(1)2 { 
			gsort hhid COICOP_`i'dig -Missing_0_1 			// Always tag first a missing category, if it exists at this level
			egen tag_`i' = tag(hhid COICOP_`i'dig)
			by hhid COICOP_`i'dig: egen total_exp_`i' = total(exp_TOR_item)
			
			gsort hhid COICOP_`i'dig Missing_0_1	
			by hhid COICOP_`i'dig Missing_0_1: egen total_exp_missing_`i' = total(exp_TOR_item)   
			replace total_exp_missing_`i' = 0 if Missing_0_1 == 0
			}
			
		* Drop untagged dobservations
		keep if tag_1 == 1 | tag_2 == 1 
		
		* Drop households consuming no food (Very few)
		gen food = (COICOP_2dig == 1)
		bysort hhid: egen has_food = total(food) 
		count if has_food == 0 & tag_1 == 1
		drop if has_food == 0	

		** Loop to generate the total and informal variables at the hhid level for a single observation 
		** Only keep relevant data to make code faster
		cap drop exp_informal exp_intermediate census_block urban exp_ir exp_rent unknown_housing inc_ir_withzeros exp_rent_withzeros exp_housing exp_nir inc_nir
		
		** Loop over COICOP2s
		forvalues c = 1(1)12 { 
			gen tmp_total_exp_missing_`c' = total_exp_missing_2   	if COICOP_2dig == `c'
			gen tmp_total_exp_`c' = total_exp_2 					if COICOP_2dig == `c'
			replace tmp_total_exp_missing_`c'  = 0 if tmp_total_exp_missing_`c'  == . 
			replace tmp_total_exp_`c'  = 0 if tmp_total_exp_`c'  == . 			
			by hhid: egen max_total_exp_missing_`c' = max(tmp_total_exp_missing_`c') 
			by hhid: egen max_total_exp_all_`c' = max(tmp_total_exp_`c') 
			replace max_total_exp_missing_`c' = 0 if max_total_exp_missing_`c' == .
			replace max_total_exp_all_`c' = 0 if max_total_exp_all_`c' == .		
			drop  tmp_total_exp_`c' tmp_total_exp_missing_`c'
			}

		keep if tag_1 == 1	
		drop tag_1 total_exp_missing_1 total_exp_missing_2 total_exp_1 total_exp_2
		
		egen total_exp = rowtotal(max_total_exp_all_*)
		egen total_exp_missing = rowtotal(max_total_exp_missing_*)
				
		** Rename the spending by COICOP (all and informal) 
		forvalues i = 1(1)12 {
			rename max_total_exp_missing_`i' exp_coicop_missing_`i'
			rename max_total_exp_all_`i' exp_coicop_tot_`i' 
			}
		
		********************************************
		* 		DATA CHECKS
		********************************************
		* Sample Size
		qui count 
		display "Sample Size = `r(N)'"	
		
		* Check that everyone has weights
		qui count if hh_weight != . 
		display "Non Missing Weights = `r(N)'"
		
		qui count if hh_weight != .					

		*********************************************************
		* GENERATE THE OUTPUT
		*********************************************************			
		** 	We now have a dataset with all the requiered information at the individual level:	
		*** Shares: 
		
			qui tabstat total_exp [aw= hh_weight] , stat(sum) save //total
			mat results_total = r(StatTotal)
			local results_total = results_total[1,1]
			
			qui tabstat exp_coicop_tot_* [aw= hh_weight] , stat(sum) save  //total per coicop
			mat results_exp = r(StatTotal)
			qui tabstat exp_coicop_missing_* [aw= hh_weight] , stat(sum) save //total missing
			mat results_exp_missing = r(StatTotal)	
			
		
			qui tabstat total_exp [aw= hh_weight] , stat(mean) save //mean total
			mat results_mean = r(StatTotal)
			local results_mean = results_mean[1,1]
			
			qui tabstat exp_coicop_tot_* [aw= hh_weight] , stat(mean) save //mean total per coicop
			mat results_exp_mean = r(StatTotal)
			qui tabstat exp_coicop_missing_* [aw= hh_weight] , stat(mean) save //mean missing per coicop
			mat results_exp_missing_mean = r(StatTotal)	
			
			mat list results_total
			mat list results_exp
			mat list results_exp_missing
			mat list results_mean
			mat list results_exp_mean
			mat list results_exp_missing_mean

			forvalues c = 1(1)12 {
				local m  = `c'
				local results_exp = results_exp[1,`c']
				local results_exp_missing = results_exp_missing[1,`c']
				local results_exp_mean = results_exp_mean[1,`c']
				local results_exp_missing_mean = results_exp_missing_mean[1,`c']				
				local empty = . 
				post regressions ("$country_code") ($year) (`c') (`results_total') (`results_mean')  (`results_exp') (`results_exp_mean')  (`results_exp_missing') (`results_exp_missing_mean')

				}
			* output data
			
			
			}


		cap log close 
		postclose regressions	
		
		* Assign value labels to the COICOP2 categories		
		
		use "$main/proc/tmp_missing_COICOP12_$scenario.dta", replace			

		merge m:1 COICOP_2dig using "$main/proc/COICOP_label_2dig.dta"
		drop if _m == 2 
		drop _m COICOP_2dig		
		
		rename COICOP_Name2 COICOP2
		order country_code year COICOP2 
		
		save "$main/proc/missing_COICOP12_$scenario.dta", replace		
		
		
		
		
		
		
