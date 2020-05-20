*****************************************************
/* 
	This file generates total consumption by
		COICOP2 * Country * Decile 
	used for mechanical simulations and optimal tax	
*/ 
*****************************************************
*********************************************	
* Preliminaries
*********************************************	
	
	clear all
	set more off
	set matsize 800	
	
	global drop_housing = 1  		// Set to 1 to run the code without housing	
	display "$scenario"				// Central , Proba , Robust: see definition in Master.do	
	
	* Generates a dataset which stores the coefficients from the regressions	 
	local filename "tmp_output_for_simulation"
	cap postclose `filename'		 
	 
	 #delim ;
	 postfile `filename' str10 country_code year decile COICOP_2dig 
	 exp_total exp_informal  using "$main/proc/`filename'_COICOP2_$scenario.dta", replace ; 
	 #delim cr

*******************************************************	
* 	0. Sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	// keep if country_code == "CM"			// To run on one country only select its acronym  
	
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
		* 	DATA PREP: Formality
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
			
		********************************************
		* 	Generate Informal Shares
		********************************************				

		* GENERATE THE SHARES of INFORMAL CONSUMPTION For each level of COICOP
		cap drop COICOP_1dig
		gen COICOP_1dig = 1 		// Used to make later codes run as a loop when looking at aggregates for one household
		
		forvalues i = 1(1)2 { 
			gsort hhid COICOP_`i'dig Formal_Informal_0_1 			// Always tag first an informal category, if it exists at this level
			egen tag_`i' = tag(hhid COICOP_`i'dig)
			by hhid COICOP_`i'dig: egen total_exp_`i' = total(exp_TOR_item)
			
			gsort hhid COICOP_`i'dig Formal_Informal_0_1	
			by hhid COICOP_`i'dig Formal_Informal_0_1: egen total_exp_informal_`i' = total(Inf_weight_exp_TOR_item)		
			replace total_exp_informal_`i' = 0 if Formal_Informal_0_1 != 0
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
			gen tmp_total_exp_informal_`c' = total_exp_informal_2   if COICOP_2dig == `c'
			gen tmp_total_exp_`c' = total_exp_2 					if COICOP_2dig == `c'
			replace tmp_total_exp_informal_`c'  = 0 if tmp_total_exp_informal_`c'  == . 
			replace tmp_total_exp_`c'  = 0 if tmp_total_exp_`c'  == . 			
			by hhid: egen max_total_exp_informal_`c' = max(tmp_total_exp_informal_`c') 
			by hhid: egen max_total_exp_all_`c' = max(tmp_total_exp_`c') 
			replace max_total_exp_informal_`c' = 0 if max_total_exp_informal_`c' == .
			replace max_total_exp_all_`c' = 0 if max_total_exp_all_`c' == .		
			drop  tmp_total_exp_`c' tmp_total_exp_informal_`c'
			}	

		keep if tag_1 == 1	
		drop tag_1 total_exp_informal_1 total_exp_informal_2 total_exp_1 total_exp_2
		
		egen total_exp = rowtotal(max_total_exp_all_*)
		egen total_exp_informal = rowtotal(max_total_exp_informal_*)
				
		** Rename the spending by COICOP (all and informal) 
		forvalues i = 1(1)12 {
			rename max_total_exp_informal_`i' exp_coicop_inf_`i'
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
		* STATISTICS FOR OUTPUT
		*********************************************************					
		**  Windsorize at the top the total consumption
		** (Note the categories then wont add up, so we do an adjustment which is to reduce for each COICOP by the percentage reduction)
			
			qui sum total_exp [aw= hh_weight] , d
			local p99 = `r(p99)'
			gen ratio_wins = `r(p99)' / total_exp 
			replace ratio_wins = 1 if ratio_wins >= 1
		
			replace total_exp = total_exp * ratio_wins 
			replace total_exp_informal = total_exp_informal * ratio_wins 
			
		forvalues c = 1(1)12 { 
			replace exp_coicop_tot_`c' = exp_coicop_tot_`c' * ratio_wins 
			replace exp_coicop_inf_`c' = exp_coicop_inf_`c' * ratio_wins 
			}
				
		** 	We now have a dataset with all the requiered information at the household level:		
		forvalues d = 1(1)10 { 
			qui tabstat exp_coicop_tot_* [aw= hh_weight] if decile_income == `d' , stat(sum) save
			mat results_exp = r(StatTotal)
			qui tabstat exp_coicop_inf_* [aw= hh_weight] if decile_income == `d' , stat(sum) save
			mat results_exp_informal = r(StatTotal)
			
			forvalues c = 1(1)12 { 
				local exp_total = results_exp[1,`c']
				local exp_inf = results_exp_informal[1,`c']
			
			* output data
			post `filename'	("$country_code") ($year) (`d') (`c') (`exp_total') (`exp_inf')			
			}
		} 	
		
		forvalues d = 1(1)10 { 
			qui tabstat total_exp [aw= hh_weight] if decile_income == `d' , stat(sum) save
			mat results_exp = r(StatTotal)
			qui tabstat total_exp_informal [aw= hh_weight] if decile_income == `d' , stat(sum) save
			mat results_exp_informal = r(StatTotal)
			
			local exp_total = results_exp[1,1]
			local exp_inf = results_exp_informal[1,1]
			local c = 0 
			
			* output data
			post `filename'	("$country_code") ($year) (`d') (`c') (`exp_total') (`exp_inf')			
			}
		} 				// End of Cross Country Loop 

		
		*stop 
		postclose `filename'	
				
		******************************************************
		* Assign value labels to the COICOP2 categories		
		******************************************************
	
		use "$main/proc/`filename'_COICOP2_$scenario.dta", replace
	
		merge m:1 COICOP_2dig using "$main/proc/COICOP_label_2dig.dta"
		drop if _m == 2 
		drop _m COICOP_2dig		
		
		replace COICOP_Name2 = 0 if COICOP_Name2 == . 
		label define COICOP_Name2 0 "All Expenses", add
		label values COICOP_Name2 COICOP_Name2
		rename COICOP_Name2 COICOP2
		
		order country_code year COICOP2 decile
		sort country_code COICOP2 decile
		save "$main/proc/`filename'_COICOP2_$scenario.dta" , replace		
		
		
		
		
		
		
