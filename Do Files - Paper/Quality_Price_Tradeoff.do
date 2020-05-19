					*************************************
					* 	Quality - Price Tradeoff    	*
					* 	  								*
					*************************************

***********************************************************************************************
* LOAD data to Harmonized across the 6 countries which have the relevant information *
***********************************************************************************************
*********************************************
* Descriptive Tables for the reason to choose a retailer
*********************************************	
	
	/*
	
	- Only keep Goods in categories 1-5 (drop services and unspecified) 	
	*/
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
	

*******************************************************	
* 	0. Sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop_reason.xlsx" , clear firstrow sheet("main_sample") 
	// keep if country_code == "KM"			// To run on one country select its acronym  
	
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
		global conversion_rate = GDP_pc_currentLCU[1]/PPP_current[1]		
		display "Conversion rate = $conversion_rate"	

		**********************
		* LOAD SURVEY 	 *
		**********************	

		use "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" , clear	
	
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
	
		* Define Log income in base 2, converted to PPP USD 
		gen log_income_pp = log(exp_noh/($conversion_rate * hh_size))  
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
				
					
			cap drop Formal_Informal_0_1  
			gen Formal_Informal_0_1 = . 
			replace Formal_Informal_0_1  = 0 if Inf_weight > 0 & Inf_weight!= . 
			replace Formal_Informal_0_1  = 1 if Inf_weight == 0
	
		
			qui drop if Formal_Informal_0_1  == 9		
	
			qui gen price_matters = 0
			qui replace price_matters = 1 if reason_recode == 2
		
			qui gen quality_matters = 0
			qui replace quality_matters = 1 if reason_recode == 3
			
			bysort hhid: gen count_purchases = _N 
			bysort hhid: egen count_quality = total(quality_matters)
			gen share_quality = count_quality / count_purchases
		
	local reg = 1
	if `reg' { 	
	
		egen numeric_hhid = group(hhid)
		xtset numeric_hhid		
		// gen log_exp = log(exp_total_pp)
	
		cap destring ${product_code}_4dig, replace 
	
		* Other outcome (price_matters )
		foreach name in quality_matters { 
			display "********  Outcome is: `name' *******"
			* Basic Regressions
			reg `name'   i.Formal_Informal_0_1 [aw = hh_weight] , baselevels
			reg `name'   i.Formal_Informal_0_1  ib(10).decile_noh [aw = hh_weight] , baselevels
			// logit `name'   i.Formal_Informal_0_1 [pw = hh_weight] // Takes a while to iterate
			
			* Within household regression: f.e. for households
			xtreg `name'  i.Formal_Informal_0_1 [aw = hh_weight] , baselevels fe vce(robust)
			// xtreg `name'  i.Formal_Informal_0_1  i.COICOP_2dig [aw = hh_weight] , fe vce(robust)
			}
			}
		
	
	local graph = 1
	if `graph' { 
		preserve 
		keep if tag == 1
		
		qui sum log_income_pp [aw = hh_weight]  , d
		local median  = `r(p50)' 
		local p5 = `r(p5)'
		local p95 = `r(p95)'
		local bottom_range = floor(`r(p5)'*10)/10
		local top_range = ceil(`r(p95)'*10)/10
		local bottom_axis = ceil(`r(p5)')
		local top_axis = floor(`r(p95)')
		local size vlarge
		
		* Food ENGEL curve:
		#delim ;
		twoway (lpolyci share_quality log_income_pp if log_income_pp>= `bottom_range' & log_income_pp <= `top_range' [aw = hh_weight]), 
		xscale(range(`bottom_range' `top_range')) xlabel(`bottom_axis'(1)`top_axis', labsize(`size'))
		ylabel(0(0.1)0.3, nogrid labsize(`size')) yscale(range(0 0.3)) yline(0(0.1)0.3, lstyle(minor_grid) lcolor(gs1)) 		
		xline(`median', lcolor(gs10))  xline( `p5', lcolor(gs10) lpattern(dash))  xline( `p95', lcolor(gs10) lpattern(dash))
		graphregion(color(white)) plotregion(color(white))  bgcolor(white)			
		legend(off) 		
		xtitle("Log Expenditure PP, Constant 2010 USD",  margin(medlarge) size(`size'))
		ytitle("Purchased for Quality (%)", margin(medlarge) size(`size')) ;

		graph export "$main/graphs/cross_country/Food_Engel_Curves/${country_code}_quality_price.pdf", replace ;		
		
		#delim cr
		restore		
		}
		
	local table = 1
	if `table' { 
		**** TABLES of reason for purchase by formaity and by place of purchase 
		keep if detailed_classification <= 5
		tab reason_recode Formal_Informal_0_1 [aw = hh_weight] , col matcell(X)
		
		clear 
		svmat X
		gen country_code = "$country_code"
		gen year = $year
		gen reason = _n 
		
		#delim ; 
		label define reason_recode_label
           1 "Access"
           2 "Price"
           3 "Quality"
           4 "Attributes of retailer"
           5 "Other" 			; 
		
		#delim cr	
		
		label value reason reason_recode_label
		
		save "$main/waste/${country_code}_reason_freq.dta", replace 
		}
		
		}
		
	***************************************************************
	** Assemble the frequencies together 
	***************************************************************
	
	* TABLE 3 
	use "$main/waste/BI_reason_freq.dta", clear
	append using "$main/waste/BJ_reason_freq.dta"
	append using "$main/waste/KM_reason_freq.dta"
	append using "$main/waste/CD_reason_freq.dta"
	append using "$main/waste/CG_reason_freq.dta"
	append using "$main/waste/MA_reason_freq.dta"
	
	gen X0 = X1 + X2 // Create the Total variable (Informal+Formal)
	order X0, first 
	
	*Create the mean for each reason
	forvalues i = 0(1)2 { 
		bysort country_code: egen total_x`i' = total(X`i')	
		replace X`i' = X`i' / total_x`i'
		bysort reason: egen mean_X`i' = mean(X`i')
		}
		
	*Multiply by 100 to get percentages 
	forvalues i = 0(1)2 { 
		replace mean_X`i'=mean_X`i'*100
		replace X`i'=X`i'*100
		}	
	 
	*Store the results into matrices
	 tabstat mean_X0 mean_X1 mean_X2 , by(reason) stat(mean) save
	 tabstatmat meanstat
	 mat list meanstat		

	* Generate an automatic table of results - Table 3 in the paper
	global writeto "$main/tables/cross_country/table_price_quality_$scenario.tex"
	cap erase $writeto
	local u using $writeto
	local cc=1
	local tt=1

	latexify meanstat[1,1...] `u', title("Access") format(%4.1f) append
	latexify meanstat[2,1...] `u', title("Price")format(%4.1f) append
	latexify meanstat[3,1...] `u', title("Quality") format(%4.1f) append
	latexify meanstat[4,1...] `u', title("Store Attributes") format(%4.1f) append	
	latexify meanstat[5,1...] `u', title("Other") format(%4.1f) append			
		

	
	
	* TABLE A4 - Country by country 
	keep X0 X1 X2 country_code year reason 
	reshape wide X0 X1 X2 , i(reason year) j(country_code) string
	xfill X0BI-X2MA , i(reason)
		
	*Store the results into matrices
	tabstat X0BJ-X2BJ X0BI-X2BI X0KM-X2KM , by(reason) stat(mean) save
	tabstatmat meanstat_country1
	mat list meanstat_country1
	
	tabstat X0CD-X2CD X0MA-X2MA X0CG-X2CG , by(reason) stat(mean) save
	tabstatmat meanstat_country2
	mat list meanstat_country2
		
	// Generate an automatic table of results 
	global writeto "$main/tables/cross_country/table_price_quantity_country1_$scenario.tex"
	cap erase $writeto
	local u using $writeto
	local cc=1
	local tt=1

	latexify meanstat_country1[1,1...] `u', title("Access") format(%4.1f) append
	latexify meanstat_country1[2,1...] `u', title("Price")format(%4.1f) append
	latexify meanstat_country1[3,1...] `u', title("Quality") format(%4.1f) append
	latexify meanstat_country1[4,1...] `u', title("Store Attributes") format(%4.1f) append	
	latexify meanstat_country1[5,1...] `u', title("Other") format(%4.1f) append				
	
	global writeto "$main/tables/cross_country/table_price_quantity_country2_$scenario.tex"
	cap erase $writeto
	local u using $writeto
	local cc=1
	local tt=1

	latexify meanstat_country2[1,1...] `u', title("Access") format(%4.1f) append
	latexify meanstat_country2[2,1...] `u', title("Price")format(%4.1f) append
	latexify meanstat_country2[3,1...] `u', title("Quality") format(%4.1f) append
	latexify meanstat_country2[4,1...] `u', title("Store Attributes") format(%4.1f) append	
	latexify meanstat_country2[5,1...] `u', title("Other") format(%4.1f) append		
	
	
	
	
	
	
	
	
	
	
	
