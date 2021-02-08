					*************************************
					* 	INFORMALITY ENGEL CURVES 		*
					* Plots the Informality Engel Curves*
					*************************************
*********************************************	
// Preliminaries
*********************************************	
	** NEED TO Run Master.do 
	
	cap log close
	clear all 
	set more off
	set matsize 800

	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
	
	global drop_housing = 1  // Set to 1 to run same code without housing	
	display "$scenario"	
		
*******************************************************	
* 	0. Parameters: Informality definition and sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	keep if country_code == "BI"			// To run on one country select its acronym  
	
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
// 1. Loop Over all Countries with COICOP
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

		* For country-specific probabilities of formality 
		if "$scenario" == "specific"	 {
		use "$main/proc/WB_Enterprise/dataset_formalityshare_actualpredict.dta" , replace
		qui keep if country_code == "$country_code"	
		global Inf_weight_5 = 1-fit_modernshare			// Share of large stores informal 
		global Inf_weight_4 = 1-fit_modernshare			// Share of specialized stores informal
		global Inf_weight_3 = 1-fit_tradishare			// Share of corner stores informal		
		global Inf_weight_2 = 1-fit_tradishare			// Share of non-brick retailers		
		} 	

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
		replace exp_TOR_item = 0 if exp_TOR_item <= 0			// Safety, Avoids negative values. 
	
		* Define Log income per person, converted to PPP USD 
		drop if $income_measure == 0 | $income_measure == . 
		gen log_income_pp = log($income_measure/($conversion_rate * hh_size)) 
		
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
			replace Inf_weight = $Inf_weight_2   	 					 if inlist(detailed_classification,2) 
			replace Inf_weight = 1 										 if inlist(detailed_classification,1,7,9) 		
			}
		else if $cat4_factor != 1 {
			replace detailed_classification = 3 if detailed_classification == 4
			gen Inf_weight = .
			replace Inf_weight = 0 										 							  													if inlist(detailed_classification,6,8,10,99)
			replace Inf_weight = $Inf_weight_5							 							  													if inlist(detailed_classification,5)
			replace Inf_weight = $Inf_weight_4 							 							  													if inlist(detailed_classification,4) 
			replace Inf_weight = $Inf_weight_3*((1-$cat4_factor)+$slope4*(5.5-decile_income))+$Inf_weight_4*($cat4_factor+$slope4*(decile_income-5.5))  if inlist(detailed_classification,3) 	
			replace Inf_weight = $Inf_weight_2   	 																									if inlist(detailed_classification,2) 	
			replace Inf_weight = 1 																	 			 										if inlist(detailed_classification,1,7,9) 	
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
			gen share_informal_`i' = (total_exp_informal_`i' / total_exp_`i')*100 
			drop total_exp_informal_`i'
			}
			
			** Check that the sum of expenditure corresponds to the one we had already constructed in the micro data 
			gen dif = total_exp_1  - exp_noh 
			count if tag_1 == 1
			count if tag_1 == 1 & abs(dif)>= 1000		
			
			* Drop untagged observations (observations that are no the first occurence of their COICOP1 or COICOP2
			keep if tag_1 == 1 | tag_2 == 1  				
		
			* Drop households consuming no food (Very few)
			gen food = (COICOP_2dig == 1)
			bysort hhid: egen has_food = total(food) 
			count if has_food == 0 & tag_1 == 1
			drop if has_food == 0
			
		********************************************
		* 		DATA CHECKS
		********************************************
		* Check that no-one is missing income
		qui count if tag_1 == 1
		display "Sample Size = `r(N)'"	
		qui count if log_income_pp!= . & tag_1 == 1
		display "Non Missing Income = `r(N)'"			
		qui count if log_income_pp != 0 & tag_1 == 1
		display "Non Zero Income = `r(N)'"		
		qui count if share_informal_1 != . & tag_1 == 1
		display "Non Missing share informal = `r(N)'"	
		
		* Check that everyone has weights
		qui count if hh_weight != . & tag_1 == 1
		display "Non Missing Weights = `r(N)'"				
		
		* Graph options:
		cap grstyle init
		cap grstyle set ci gs10, opacity(60) 
		cap grstyle set color gs1
		
		********************************************
		* 		ENGEL CURVES 
		********************************************
		* Generate moments (median, percentiles) 
		qui sum log_income_pp if tag_1== 1 [aw = hh_weight]  , d
		local median  = `r(p50)' 
		local p5 = `r(p5)'
		local p95 = `r(p95)'
		local bottom_range = floor(`r(p5)'*10)/10
		local top_range = ceil(`r(p95)'*10)/10
		local bottom_axis = ceil(`r(p5)')
		local top_axis = floor(`r(p95)')
			
		reg share_informal_1 log_income_pp if tag_1 == 1 & log_income_pp>= `bottom_range' & log_income_pp <= `top_range' 	[aw = hh_weight]
			
		* Informal Engel Curve		
		#delim ;
		twoway (lpolyci share_informal_1 log_income_pp if tag_1 == 1 & log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight], clcolor(navy)),
		xscale(range(`bottom_range' `top_range'))
		xlabel(`bottom_axis'(1)`top_axis')
		ylabel(0(20)100, nogrid labsize(`size')) yscale(range(0 100)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1)) 		
		xline(`median', lcolor(gs10)) xline( `p5', lcolor(gs10) lpattern(dash))  xline( `p95', lcolor(gs10) lpattern(dash))
		graphregion(color(white)) plotregion(color(white))  bgcolor(white)	
		name(informal, replace) 
		legend(off) 
		xtitle("")
		ytitle("") ;
		
		graph export "$main/graphs/$country_fullname/${country_code}_Engel_informal_${income_measure}.pdf", replace ;	
		graph export "$main/graphs/cross_country/Informality_Engel_Curves/${country_code}_Engel_informal_${income_measure}.eps", replace ;	

		#delim cr
	
		* Informal Engel Curve with axis titles
		#delim ;
		twoway (lpolyci share_informal_1 log_income_pp if tag_1 == 1 & log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight], clcolor(navy)),
		xscale(range(`bottom_range' `top_range'))
		xlabel(`bottom_axis'(1)`top_axis')
		ylabel(0(20)100, nogrid labsize(`size')) yscale(range(0 100)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1)) 		
		xline(`median', lcolor(gs10)) xline( `p5', lcolor(gs10) lpattern(dash))  xline( `p95', lcolor(gs10) lpattern(dash))
		graphregion(color(white)) plotregion(color(white))  bgcolor(white)	
		name(informal, replace) 
		legend(off) 
		xtitle("Log Expenditure per Person, Constant 2010 USD",  margin(medsmall) size(med))
		ytitle("Informal Budget Share", margin(medsmall) size(med)) ;
		
		graph export "$main/graphs/$country_fullname/${country_code}_Engel_informal_${income_measure}_axis.pdf", replace ;	
		graph export "$main/graphs/cross_country/Informality_Engel_Curves/${country_code}_Engel_informal_${income_measure}_axis.eps", replace ;	

		#delim cr	
	
		}    // Close country loop
	
	
	

 
 
