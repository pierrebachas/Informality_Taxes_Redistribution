
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
	local filename "regressions_output_deciles"
	cap postclose `filename'	 
	 
	#delim ;
	postfile `filename' str10 country_code year iteration decile1_ se1_ decile2_ se2_ decile3_ se3_ decile4_ se4_ decile5_ se5_ 
				decile6_ se6_ decile7_ se7_ decile8_ se8_ decile9_ se9_ decile10_ se10_ using "$main/proc/`filename'_$scenario.dta", replace ;
	#delim cr
	 
*******************************************************	
* 	0. Sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	* keep if country_code == "BO"			// To run on one country select its acronym  
	
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
		global annualization_factor `: word `k' of `annualization_factor''
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
		if $category_4_factor == 1 {	
			gen Inf_weight = .
			replace Inf_weight = 0 										 if inlist(detailed_classification,6,8,10,99)
			replace Inf_weight = $Inf_weight_5							 if inlist(detailed_classification,5)
			replace Inf_weight = $Inf_weight_4 							 if inlist(detailed_classification,4) 
			replace Inf_weight = $Inf_weight_3   	 					 if inlist(detailed_classification,3) 			
			replace Inf_weight = 1 										 if inlist(detailed_classification,1,2,7,9) 		
			}
		else if $category_4_factor != 1 {
			replace detailed_classification = 3 if detailed_classification == 4
			
			gen Inf_weight = .
			replace Inf_weight = 0 										 							  if inlist(detailed_classification,6,8,10,99)
			replace Inf_weight = $Inf_weight_5							 							  if inlist(detailed_classification,5)
			replace Inf_weight = $Inf_weight_4 							 							  if inlist(detailed_classification,4) 
			replace Inf_weight = $Inf_weight_3*((1-$category_4_factor)+$slope_4*(5.5- decile_income)) if inlist(detailed_classification,3) 			
			replace Inf_weight = 1 																	  if inlist(detailed_classification,1,2,7,9) 	
			} 		 
				
			drop decile_income	
			tab detailed_classification
			gen Inf_weight_exp_TOR_item = exp_TOR_item * Inf_weight 	
					
			cap drop Formal_Informal_0_1  
			gen Formal_Informal_0_1 = . 
			replace Formal_Informal_0_1  = 0 if Inf_weight > 0 & Inf_weight!= . 
			replace Formal_Informal_0_1  = 1 if Inf_weight == 0
	
			* GENERATE THE SHARES of INFORMAL CONSUMPTION For each level of COICOP
			cap drop ${product_code}_1dig
			gen ${product_code}_1dig = 1 		// Used to make later codes run as a loop when looking at aggregates for one household
			
			forvalues i = 1(1)4 { 
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
			keep if tag_1 == 1 | tag_2 == 1 | tag_3 == 1 | tag_4 == 1 				
			
			* Weights: 
			* 1. Share of total consumption of product at the level of COICOP `i' (should be net of housing)
			forvalues i = 1(1)4 { 	
			gen weight_`i' = total_exp_`i' / total_exp_1
			} 
			
			* 2. Combining sampling weights with product importance weight 
			forvalues i = 1(1)4 {
			gen weight_combined_`i' = weight_`i' * hh_weight
			}
			
			* Share of expenses of 2 digit categories multiplied by 100
			gen temp_weight_2  = weight_2 *100	
			label var temp_weight_2 "Share of expenses of category 2 digit COICOP, *100"

		********************************************
		* 		DATA CHECKS
		********************************************
		// Check that no-one is missing income
		qui count if tag_1 == 1
		display "Sample Size = `r(N)'"	
		qui count if log_income_pp!= . & tag_1 == 1
		display "Non Missing Income = `r(N)'"			
	
		// Check that everyone has weights
		qui count if hh_weight != . & tag_1 == 1
		display "Non Missing Weights = `r(N)'"			
	
		****************************************************************
		* 		Regressions :  
		/*
		Question a linear fit might not be the best regression to run? 
		Is there some type of more interesting quantile thing to do?
		
		Other question: i did like the re-weighting strategy in the Donovan paper:
		Fix the characteristics for a given variable to those of the top decile for example 
		And see how much of the gap one can explain. Check his procedure.
		these issues to be discussed with the team 
		*/
		****************************************************************
	
		local regressions = 1
		if `regressions' {
	
		* Windsoriwing top and bottom income outliers: 
		local low = 1						// Set your percentile to windsorize
		local high = 100 - `low'
		
		_pctile log_income_pp if tag_1== 1 [aw= hh_weight], p(`low')  
		return list
		local p_low = `r(r1)'
		_pctile log_income_pp if tag_1== 1 [aw= hh_weight], p(`high') 
		return list
		local p_high = `r(r1)'	
		
		replace log_income_pp = `p_low' if log_income_pp < `p_low'	& log_income_pp != .
		replace log_income_pp = `p_high' if log_income_pp > `p_high' & log_income_pp != .
		
		* Generate deciles and decile dummies
		gen decile_income = . 
		forvalues i = 10(10)90 { 	
			_pctile log_income_pp if tag_1 == 1 [aw= hh_weight], p(`i')  
			local p_low = `r(r1)'
			replace decile_income = `i'/10 if log_income_pp <= `p_low' & decile_income == . 
			} 
		replace decile_income = 10 if decile_income == .
		
		tab decile_income, gen(decile_dummy)
	
		* Destring product codes if needed
		cap destring ${product_code}_2dig, replace force
		cap destring ${product_code}_3dig, replace force
		cap destring ${product_code}_4dig, replace force	
	
		* Then regress with the decile and save the dummies from these residuals 	
		
			forvalues i = 1(1)1 { 
			display "***** Regressions at Product Level `i' ***** " 		
			qui reg share_informal_`i' decile_dummy1-decile_dummy10 i.${product_code}_`i'dig [iweight=weight_combined_`i'] if tag_`i' == 1, vce(robust) nocons	
			
				forvalues j = 1(1)10{		
					local dum`j' = _b[decile_dummy`j']
					local se`j' = _se[decile_dummy`j']
					}
					
				local reg_name "$country_code"
				display "`reg_name'"
				local number = `i'
				display "`number'"
			
			#delim ;
			
 			post `filename'("`reg_name'") ($year) (`i') (`dum1') (`se1') (`dum2') (`se2') (`dum3') (`se3') (`dum4') (`se4') (`dum5') (`se5') 						
										  (`dum6') (`se6') (`dum7') (`se7') (`dum8') (`se8') (`dum9') (`se9') (`dum10') (`se10') 	; 
			
			#delim cr
			
			}
		}		
	}	

		postclose `filename'
