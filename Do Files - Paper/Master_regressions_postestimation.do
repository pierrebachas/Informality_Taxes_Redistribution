
			*****************************************************
			* 		Regression DO FILE							*
			* 	  DATA ANALYSIS to EXPORT REGRESSION RESULTS	*
			*****************************************************
*********************************************	
* 	Preliminaries
*********************************************	

	clear all
	set more off
	set matsize 800	
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
	
	global drop_housing = 1  		// Set to 1 to run the code without housing	
	display "$scenario"				// Central , Proba , Robust: see definition in Master.do
	
	* Generates a data_file which stores the coefficients from the regressions
	 cap postclose regressions_output		 
	 postfile regressions_output str10 country_code year iteration b se r2_adj using "$main/proc/regressions_output_$scenario.dta", replace

	* Generates a data_file which stores the coefficients from the regressions	for regression with rural and urban 
	 cap postclose regressions_output_urban_rural		 
	 #delim ; 
	 postfile regressions_output_urban_rural str10 country_code year iteration b_urban se_urban b_rural 
	 se_rural b_level_rural se_level_rural r2_adj using "$main/proc/regressions_output_urban_rural_$scenario.dta", replace	 ; 
	 #delim cr

*******************************************************	
* 	0. Sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	*keep if country_code == "CM"			// To run on one country select its acronym  
	
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
		* 		DATA PREP 
		********************************************
		* For some odd reason, Ecuador has negative values (Revisit Ecuador to fix this!!) 
		replace exp_TOR_item = 0 if exp_TOR_item <= 0	
	
		* Define Log income in base 2, converted to PPP USD 
		drop if $income_measure == 0 | $income_measure == . 
		gen log_income_pp = log($income_measure/($conversion_rate * hh_size))  
		** gen deciles of income (will be useful for the impuation
		** then use the decile value (1 to 10) to use it as a correction factor with a slope coming from the excel
		** Generate income decile dummies
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
	
			* GENERATE THE SHARES of INFORMAL CONSUMPTION For each level of COICOP
			*** 0-digit corresponds to the total expenditure
			cap drop ${product_code}_0dig
			gen ${product_code}_0dig = 1 		// Used to make later codes run as a loop when looking at aggregates for one household
			
			*** 1-digit corresponds to food vs non food categories 
			cap drop ${product_code}_1dig
			gen ${product_code}_1dig = 0 
			replace ${product_code}_1dig = 1 if (COICOP_2dig == 1)
			
			forvalues i = 0(1)4 { 
			gsort hhid ${product_code}_`i'dig Formal_Informal_0_1 			// Always tag first an informal category, if it exists at this level
			egen tag_`i' = tag(hhid ${product_code}_`i'dig)
			by hhid ${product_code}_`i'dig: egen total_exp_`i' = total(exp_TOR_item)
			
			gsort hhid ${product_code}_`i'dig Formal_Informal_0_1	
			by hhid ${product_code}_`i'dig Formal_Informal_0_1: egen total_exp_informal_`i' = total(Inf_weight_exp_TOR_item)		
			replace total_exp_informal_`i' = 0 if Formal_Informal_0_1 != 0
			gen share_informal_`i' = (total_exp_informal_`i' / total_exp_`i')*100 
			*drop total_exp_informal_`i'
			}
		
			* Drop untagged dobservations
			keep if tag_0 == 1 | tag_1 == 1 | tag_2 == 1 | tag_3 == 1 | tag_4 == 1 				
			
			* Drop households consuming no food (Very few)
			gen food = (COICOP_2dig == 1)
			bysort hhid: egen has_food = total(food) 
			count if has_food == 0 & tag_1 == 1
			drop if has_food == 0
			drop food 
			
			* Weights: 
			* 1. Share of total consumption of product at the level of COICOP `i' (should be net of housing)
			forvalues i = 0(1)4 { 	
			gen weight_`i' = total_exp_`i' / total_exp_0
			} 
			
			* 2. Combining sampling weights with product importance weight 
			forvalues i = 0(1)4 {
			gen weight_combined_`i' = weight_`i' * hh_weight
			}
			
			* Share of expenses of 2 digit categories multiplied by 100
			gen temp_weight_2  = weight_2 *100	
			label var temp_weight_2 "Share of expenses of category 2 digit COICOP, *100"

		********************************************
		* 		DATA CHECKS
		********************************************
		* Check that no-one is missing income
		qui count if tag_0 == 1
		display "Sample Size = `r(N)'"	
		qui count if log_income_pp!= . & tag_0 == 1
		display "Non Missing Income = `r(N)'"			
		
		* Check that everyone has weights
		qui count if hh_weight != . & tag_0 == 1
		display "Non Missing Weights = `r(N)'"			
		
		****************************************************************
		* 		Regressions :  
		/*
		Other question: i liked the re-weighting strategy in the Donovan paper:
		Fix the characteristics for a given variable to those of the top decile for example 
		And see how much of the gap one can explain. Check his procedure.
		*/
		****************************************************************
		
		local moments = 1
		if `moments' {
		
			** TOP CODE at p99 total expenditure and informal expenditure
			gen tc_total_exp_0 = total_exp_0 
			qui sum total_exp_0 [aw= hh_weight] if tag_0 == 1 , d
			replace tc_total_exp_0 = `r(p99)' if  total_exp_0 >= `r(p99)' &  total_exp_0!= .  & tag_0 == 1
			
			gen tc_total_exp_informal_0 = total_exp_informal_0
			qui sum total_exp_informal_0  [aw= hh_weight] if tag_0 == 1 , d
			replace tc_total_exp_informal_0 = `r(p99)' if  total_exp_informal_0 >= `r(p99)' & total_exp_informal_0!= . & tag_0 == 1
			
			tabstat tc_total_exp_informal_0 tc_total_exp_0 [aw= hh_weight] if tag_0 == 1, stat(sum) save
			mat agg_tot = r(StatTotal)
			local agg_inf = agg_tot[1,1]			
			local agg_tot = agg_tot[1,2]
			
			local mean =  100 * (`agg_inf' / `agg_tot')
			local se_mean = . 
			
			local reg_name "$country_code"
			local empty = .			
			local number = 1
			post regressions_output ("`reg_name'") ($year) (`number') (`mean') (`se_mean') (`empty') 
		
			drop tc_total_exp_0 tc_total_exp_informal_0
		
			** All
			sum share_informal_0 [aw= hh_weight] if tag_0 == 1, d
			
			local mean = `r(mean)'
			local se_mean = . 
			local median = `r(p50)'
			local se_median = . 
			display "`reg_name'"
			local number = 2
 			post regressions_output ("`reg_name'") ($year) (`number') (`mean') (`se_mean') (`empty') 	 	
			local number = 3
 			post regressions_output ("`reg_name'") ($year) (`number') (`median') (`se_median') (`empty') 	
			
			sum log_income_pp [aw= hh_weight] if tag_0 == 1, d
			local p10 = `r(p10)'
			local p90 = `r(p90)'
			sum share_informal_1 [aw= hh_weight] if tag_0 == 1 & log_income_pp < `p10' & log_income_pp!= . 
			local mean = `r(mean)'
			local se_mean = . 
			local empty = . 
			local number = 4
 			post regressions_output ("`reg_name'") ($year) (`number') (`mean') (`se_mean') (`empty') 			
			sum share_informal_0 [aw= hh_weight] if tag_0 == 1 & log_income_pp >= `p90'	 & log_income_pp!= . 
			local mean = `r(mean)'			
			local se_mean = . 
			local number = 5
 			post regressions_output ("`reg_name'") ($year) (`number') (`mean') (`se_mean') (`empty') 	
			
			** Rural-Urban: Note CL and SN only urban, no distinction
			tab urban 
			if `r(r)' > 1 {
			sum share_informal_0 [aw= hh_weight] if tag_0 == 1 & urban == 1 , d
			local mean_urban = `r(mean)'
			local se_mean_urban = . 
			local median_urban = `r(p50)'
			local se_median_urban = .
			sum share_informal_0 [aw= hh_weight] if tag_0 == 1 & urban == 0 , d			
			local mean_rural = `r(mean)'
			local se_mean_rural = . 
			local median_rural = `r(p50)'
			local se_median_rural = . 	
			local empty = . 
			local number = 1
 			post regressions_output_urban_rural ("`reg_name'") ($year) (`number') (`mean_urban') (`se_mean_urban') (`mean_rural') (`se_mean_rural')	(`empty') (`empty') (`empty')	 		
			local number = 2
 			post regressions_output_urban_rural ("`reg_name'") ($year) (`number') (`median_urban') (`se_median_urban') (`median_rural') (`se_median_rural')	(`empty') (`empty') (`empty')	 	 					
			}
			}
			
	
		local regressions = 1
		if `regressions' {
			
		* Windsoriwing top and bottom income outliers: 
		local low = 1						// Set your percentile to windsorize
		local high = 100 - `low'
		
		_pctile log_income_pp if tag_0== 1 [aw= hh_weight], p(`low')  
		return list
		local p_low = `r(r1)'
		_pctile log_income_pp if tag_0== 1 [aw= hh_weight], p(`high') 
		return list
		local p_high = `r(r1)'	
		
		replace log_income_pp = `p_low' if log_income_pp < `p_low'	& log_income_pp != .
		replace log_income_pp = `p_high' if log_income_pp > `p_high' & log_income_pp != .
		
		* Local for controls: confirm that it exists in dataset				
		
		local hhld_controls	""	// Set empty local 
		
		local vlist hh_size head_sex head_age 
			foreach v of local vlist  {
				capture confirm variable `v'
				display "is `v' present in $country_fullname? " (_rc == 0)
						if _rc == 0 {
									qui duplicates report `v'
										if `r(unique_value)' <= 10 { 
										local hhld_controls `hhld_controls' i.`v' 
										}
										else if `r(unique_value)' > 10  {
										local hhld_controls `hhld_controls' c.`v' 									
										}
									}
				}
		display "`hhld_controls'"	
		
		* Destring census_block to add it as a control
		* cap destring geo_loc_min, replace force
		cap destring census_block, replace force 

		* Destring product codes if needed
		cap destring ${product_code}_2dig, replace force
		cap destring ${product_code}_3dig, replace force
		cap destring ${product_code}_4dig, replace force
		
			* Regressions: COICOP codes no hhld Characteristics
			forvalues i = 0(1)4 { 

			display "***** Regressions at Product Level `i' ***** " 		
			qui reg share_informal_`i' log_income_pp i.${product_code}_`i'dig [aweight=weight_combined_`i'] if tag_`i' == 1, vce(robust)	
			local b = _b[log_income_pp]
			display `b'
			local se = _se[log_income_pp]
			display `se'
			local r2 = e(r2_a)
			display `r2'			
			local reg_name "$country_code"
			display "`reg_name'"
			local number = `i'+ 6			
			display "`number'"
 			post regressions_output ("`reg_name'") ($year) (`number') (`b') (`se') (`r2') 
			}	
		
			* Regressions: COICOP codes with hhld Characteristics
			forvalues i = 0(1)4 { 
			display "***** Regressions at Product Level `i' + hhld controls ***** " 		
			qui reghdfe share_informal_`i' log_income_pp `hhld_controls' [aweight=weight_combined_`i'] if tag_`i' == 1, absorb(${product_code}_`i'dig) vce(robust)	
			local b = _b[log_income_pp]
			display `b'
			local se = _se[log_income_pp]
			display `se'
			local r2 = e(r2_a)
			display `r2'
			local reg_name "$country_code"
			display "`reg_name'"
			local number = `i'+ 11			
			display "`number'"
 			post regressions_output ("`reg_name'") ($year) (`number') (`b') (`se')	(`r2')								
			}		
			
			* Regressions: COICOP codes + survey_block
			forvalues i = 0(1)4 { 
			display "***** Regressions at Product Level `i' + hhld controls + survey_block ***** "		
			qui reghdfe share_informal_`i' log_income_pp `hhld_controls' [aweight=weight_combined_`i'] if tag_`i' == 1, absorb(census_block ${product_code}_`i'dig) vce(robust)	
			local b = _b[log_income_pp]
			display `b'
			local se = _se[log_income_pp]
			display `se'
			local r2 = e(r2_a)
			display `r2'			
			local reg_name "$country_code"
			display "`reg_name'"
			local number = `i'+ 16			
			display "`number'"
 			post regressions_output ("`reg_name'") ($year) (`number') (`b') (`se')	(`r2')										
			}	
			
			* Regressions: Hhhld controls + urban
			display "***** hhld controls + urban ***** " 		
			qui reg share_informal_0 log_income_pp  `hhld_controls' i.urban [aweight=weight_combined_0] if tag_0 == 1, vce(robust)	
			local b = _b[log_income_pp]
			display `b'
			local se = _se[log_income_pp]
			display `se'
			local r2 = e(r2_a)
			display `r2'
			local reg_name "$country_code"
			display "`reg_name'"
			local number = 21			
			display "`number'"
 			post regressions_output ("`reg_name'") ($year) (`number') (`b') (`se')	(`r2')				
		
			// Regressions: Hhhld controls + survey_blocks
			display "***** hhld controls + survey_block ***** " 		
			qui reghdfe share_informal_0 log_income_pp  `hhld_controls' [aweight=weight_combined_0] if tag_0 == 1, absorb(census_block) vce(robust)	
			local b = _b[log_income_pp]
			display `b'
			local se = _se[log_income_pp]
			display `se'
			local r2 = e(r2_a)
			display `r2'
			local reg_name "$country_code"
			display "`reg_name'"
			local number = 22			
			display "`number'"
 			post regressions_output ("`reg_name'") ($year) (`number') (`b') (`se') (`r2')					
	
		}	
				
		local regressions_ruralurban = 1
		if `regressions_ruralurban' {
	
			tab urban 
			if `r(r)' > 1 {	
	
			* Regressions: dummy rural
			forvalues i = 0(1)4 { 
			display "***** Regressions at Product Level `i' ***** " 		
			qui reghdfe share_informal_`i' ib1.urban log_income_pp `hhld_controls' [aweight=weight_combined_`i'] if tag_`i' == 1, absorb(${product_code}_`i'dig) vce(robust)	
			local b = _b[log_income_pp]
			local se = _se[log_income_pp]
			local r2 = e(r2_a)			
			local b_level_rural = _b[0.urban]
			local se_level_rural = _se[0.urban]			
			local reg_name "$country_code"
			local empty = . 
			display "`reg_name'"
			local number = `i'+3
			display "`number'"
			post regressions_output_urban_rural ("`reg_name'") ($year) (`number') (`b') (`se') (`empty') (`empty') (`b_level_rural') (`se_level_rural')	(`r2')														
			}
		
			* Regressions: separate slopes rural urban
			forvalues i = 0(1)4 { 
			display "***** Regressions at Product Level `i' ***** " 		
			qui reghdfe share_informal_`i' ib1.urban c.log_income_pp#i.urban `hhld_controls' [aweight=weight_combined_`i'] if tag_`i' == 1, absorb(${product_code}_`i'dig) vce(robust)	
			fvexpand c.log_income_pp#i.urban			
			local r2 = e(r2_a)			
			local b_urban = _b[1.urban#c.log_income_pp]
			local se_urban = _se[1.urban#c.log_income_pp]
			local b_rural = _b[0.urban#c.log_income_pp]
			local se_rural = _se[0.urban#c.log_income_pp]			
			local b_level_rural = _b[0.urban]
			local se_level_rural = _se[0.urban]			
			local reg_name "$country_code"
			display "`reg_name'"
			local number = `i'+8
			display "`number'"
			post regressions_output_urban_rural ("`reg_name'") ($year) (`number') (`b_urban') (`se_urban') (`b_rural') (`se_rural') (`b_level_rural') (`se_level_rural') (`r2')															
			}	
			}
		}	 			
	}
	
	postclose regressions_output
	postclose regressions_output_urban_rural				
			
	
