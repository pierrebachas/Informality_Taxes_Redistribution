					*************************************
					* 	INFORMALITY ENGEL CURVES 		*
					*************************************
*********************************************	
* Preliminaries
*********************************************	
	** NEED TO RUM Master.do 
	cap log close
	clear all 
	set more off
	set matsize 800	

	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
	
	global drop_housing = 1  // Set to 1 to run same code without housing	
	display "$scenario"	
	
	* Generates a data_file which stores the coefficients from the regressions
	 cap postclose regressions_output		 
	 postfile regressions_output str10 country_code year iteration b se using "$main/proc/Food_Consumption_Data.dta",  replace
	
	// log using "$main/logs/Food_Engel_curves.log" , replace 
	set linesize 100 
	
*******************************************************	
* 	0. Parameters: Informality definition and sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	// keep if country_code == "SN"			// To run on one country select its acronym  
	
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
	
		* Define  Log Income per persom   (Note: use to be Log income in base 2, converted to PPP USD) 		
		drop if $income_measure == 0 | $income_measure == . 
		gen log_income_pp = log($income_measure/($conversion_rate * hh_size))

		** gen deciles of income (will be useful for the impuation
		** then use the decile value (1 to 10) to use it as a correction factor with a slope coming from the excel
		** Generate income decile dummies
		egen tag = tag(hhid)
		
		gen decile_income = . 
		forvalues i = 10(10)90 { 	
			_pctile log_income_pp if tag == 1 [weight= hh_weight], p(`i')  
			local p_low = `r(r1)'
			replace decile_income = `i'/10 if log_income_pp <= `p_low' & decile_income == . 
			} 
		replace decile_income = 10 if decile_income == .				
		drop tag
		

			* GENERATE THE SHARES of INFORMAL CONSUMPTION For each level of COICOP
			gen COICOP_1dig = 1 // Used to make later codes run as a loop when looking at aggregates for one household
			
			forvalues i = 1(1)2 { 
			gsort hhid COICOP_`i'dig 			// Always tag first an informal category, if it exists at this level
			egen tag_`i' = tag(hhid COICOP_`i'dig)
			by hhid COICOP_`i'dig: egen total_exp_`i' = total(exp_TOR_item)
			}
			
			** Check on reconstructed total expenditure 
			gen dif = total_exp_1  - exp_noh 
			sum dif, d
			count if tag_1 == 1
			count if tag_1 == 1 & abs(dif)>= 1000		

		********************************************
		* 	RESHAPE DATA TO GO TO WIDE and CLEANING
		********************************************			
			
		* Keep one observation per COICOP2 hhid, when the COICOP2 category exists
		gen item=(exp_TOR_item>0) 
		bys hhid: egen total_item=sum(item) // sum items per hh
		
		keep if tag_2 == 1  				
				
		replace total_exp_2=0 if total_exp_2==.

		* Keep relevant variables 
		keep total_exp_2 hhid COICOP_2dig hh_weight log_income_pp total_exp_1 decile_income  hh_size head_sex head_age total_item
	
		reshape wide total_exp_2 , i(hhid) j(COICOP_2dig)
		
		** Issue: If no purchase of a given category then it is a missing not a zero, replace as a zero and make into a share of total * 100
		forvalues i = 1(1)12 {
			replace total_exp_2`i' = 0 if total_exp_2`i' == .
			gen share_exp_2`i' = 100*total_exp_2`i'/total_exp_1
			} 
			
		** Drop households which consume no food 	
		gen nofood = . 
		replace nofood = 1 if total_exp_21 == 0 
		
		gen total_item_ifnofood = .
		replace total_item_ifnofood = total_item if nofood == 1
	
		bysort decile_income: 	sum share_exp_21 nofood total_item_ifnofood [weight= hh_weight]
		
		drop if nofood == 1        // Drop households that never purchase any food items 
		drop nofood total_item_ifnofood
		
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
		
		local Engel_curves = 0
		if `Engel_curves' { 
		********************************************
		* 		ENGEL CURVES 
		********************************************
		
		* Graph options:
		cap grstyle init
		cap grstyle set ci gs10, opacity(60) 
		cap grstyle set color gs1
		
		* Generate moments (median, percentiles) 
		qui sum log_income_pp [aw = hh_weight]  , d
		local median  = `r(p50)' 
		local p5 = `r(p5)'
		local p95 = `r(p95)'
		local bottom_range = floor(`r(p5)'*10)/10
		local top_range = ceil(`r(p95)'*10)/10
		local bottom_axis = ceil(`r(p5)')
		local top_axis = floor(`r(p95)')
			
		* Food ENGEL curve:
		#delim ;
		twoway (lpolyci total_exp_21 log_income_pp if log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight])	, 
		xscale(range(`bottom_range' `top_range')) xlabel(`bottom_axis'(1)`top_axis')
		ylabel(0(20)100, nogrid labsize(`size')) yscale(range(0 100)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1)) 		
		xline(`median', lcolor(gs10)) xline( `p5', lcolor(gs10) lpattern(dash))  xline( `p95', lcolor(gs10) lpattern(dash))
		graphregion(color(white)) plotregion(color(white))  bgcolor(white)			
		legend(off) 		
		xtitle("Log Expenditure per Person, Constant 2010 USD",  margin(medsmall) size(med))
		ytitle("Food Expenditure Share", margin(medsmall) size(med)) ;
		
		graph export "$main/graphs/$country_fullname/${country_code}_Engel_food.pdf", replace ;	
		graph export "$main/graphs/cross_country/Food_Engel_Curves/${country_code}_Engel_food.pdf", replace ;
		#delim cr	
		
		} // End og Engel Curves loop 
		
	
		***********************************************
		* 	Aggregate Statistics on Food Consumption 
		***********************************************		
		
		local moments = 1
		if `moments' {
		
			** Economy wide Food consumption as a share of total consumption
			qui tabstat total_exp_21 total_exp_1 [aw= hh_weight], stat(sum) save
			mat agg_tot = r(StatTotal)
			local agg_food = agg_tot[1,1]
			local agg_tot = agg_tot[1,2]
			
			local mean =  100* (`agg_food' / `agg_tot')
			local se_mean = . 
			
			local reg_name "$country_code"		
			local number = 1
			post regressions_output ("`reg_name'") ($year) (`number') (`mean') (`se_mean')  
		
			** Average Food consumption 
			qui tabstat share_exp_21 [aw= hh_weight], stat(mean) save
			mat agg_tot = r(StatTotal)
			local agg_food = agg_tot[1,1]
			
			local mean = `agg_food'
			local se_mean = . 

			display "`reg_name'"
			local number = 2
 			post regressions_output ("`reg_name'") ($year) (`number') (`mean') (`se_mean')  	 	
		
		} // End of Agg stats loop  		

		***********************************************
		* 	Slopes of Food Engel Curves 
		***********************************************	
	
		local reg = 1
		if `reg' {
		
		* Generate moments (median, percentiles) 
		qui sum log_income_pp [aw = hh_weight]  , d
		local median  = `r(p50)' 
		local p5 = `r(p5)'
		local p95 = `r(p95)'
	
		local hhld_controls hh_size head_sex head_age 
		
		qui reg share_exp_21 log_income_pp `hhld_controls' if log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight] , robust		
		local b = _b[log_income_pp]
		display `b'
		local se = _se[log_income_pp]
		display `se'
		local number = 3
		post regressions_output ("`reg_name'") ($year) (`number') (`b') (`se')  			
		
		} 	// End of Slopes loop 
		
		}   // End of country loop 
	
	
		cap log close 		// End of Country Loop 
		postclose regressions_output		
	
	
		********************************************
		* 		ENGEL CURVES SLOPES 
		********************************************		
		/* 
		local hhld_controls hh_size head_sex head_age 
		reg total_exp_21 log_income_pp `hhld_controls' if log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight] , robust	
			
		
		local hhld_controls hh_size head_sex head_age 
		
		** Linear: 
		reg temp_weight_2 log_income_pp `hhld_controls' if tag_2 == 1 & COICOP_2dig == 1 [aw = hh_weight] , robust
		reg temp_weight_2 log_income_pp `hhld_controls' if tag_2 == 1 & COICOP_2dig == 1 & log_income_pp>= `p5' & log_income_pp <= `p95' [aw = hh_weight] , robust
		reg temp_weight_2 log_income_pp `hhld_controls' if tag_2 == 1 & COICOP_2dig == 1 & log_income_pp>= `p10' & log_income_pp <= `p90' [aw = hh_weight] , robust		
		
		** Quadratic
		gen log_income_pp_sq = log_income_pp^2		

		reg temp_weight_2 log_income_pp log_income_pp_sq `hhld_controls' if tag_2 == 1 & COICOP_2dig == 1  [aw = hh_weight] , robust			
		reg temp_weight_2 log_income_pp log_income_pp_sq `hhld_controls' if tag_2 == 1 & COICOP_2dig == 1 & log_income_pp>= `p5' & log_income_pp <= `p95'  [aw = hh_weight] , robust	
		reg temp_weight_2 log_income_pp log_income_pp_sq `hhld_controls' if tag_2 == 1 & COICOP_2dig == 1 & log_income_pp>= `p10' & log_income_pp <= `p90'  [aw = hh_weight] , robust		
		*/ 	
		

