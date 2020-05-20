					*****************************************************
					* 			Price - quantity regressions			*
					*****************************************************

*********************************************	
// Preliminaries
*********************************************	
	** NEED TO RUN Master.do 
	
	cap log close
	clear all 
	set more off
	set matsize 800

	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	
	
	global drop_housing = 1  // Set to 1 to run same code without housing	
	display "$scenario"	
	

	 * Generates a data_file which stores the coefficients from the regressions
	 cap postclose regressions_output_price		 
	 postfile regressions_output_price str10 country_fullname b se nb_purchases nb_geo_clusters nb_product_code nb_fixed_effects  using "$main/proc/tmp_regressions_output_price_$scenario.dta", replace
	

*******************************************************	
* 	0. Parameters: Informality definition and sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_unit_values_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	drop if country_code == "MZ"   // To run on one country select its acronym  
	
	qui valuesof country_code
	local country_code = r(values)
	display `"`country_code'"'
	qui valuesof country_fullname
	local country_fullname = r(values)
	display `"`country_fullname'"'
	qui valuesof geolevels
	local geolevels = r(values)
	display `"`geolevels'"'
	
	
	local n_models : word count `country_code'
	assert `n_models'==`:word count `country_fullname''  // this ensures that the two lists are of the same length		
								

	forval k=1/`n_models' {
	
	global country_code `: word `k' of `country_code''		
	global country_fullname `: word `k' of `country_fullname''	
	global geolevel_reg `: word `k' of `geolevels''		
	global year = substr("$country_fullname",-4,4)	
		
		display "*************** Country: $country_fullname **************************" 
	
	
	local geo_level $geolevel_reg

	***************************************
	** Import multimodality tests_results
	***************************************
	
	use "$main/waste/${country_fullname}/${country_code}_price_quantity_food_beverages.dta", clear
	
	* Define the triplet and accompanying variables we will use in regressions
	local geo_level $geolevel_reg
	cap drop triplet_id
	gen triplet_id = product_id_geo`geo_level'
	gen triplet_id_count = count_id_level`geo_level'
	gen tag_triplet_id = tag_product_id_geo`geo_level'
	gen share_exp_triplet_id = share_exp_id_level`geo_level'

	* Compute sd (missing for triplets containing only one observation)
	bysort triplet_id: egen triplet_id_sd = sd(unit_value)

	* Identify outliers  
	sort triplet_id
	bysort triplet_id : egen percentile95 = pctile(unit_value), p(95)
	bysort triplet_id : egen percentile05 = pctile(unit_value), p(05)
	order triplet_id unit_value percentile95 percentile05 //usable_triplet_id
	gen outlier = 0
	replace outlier = 1 if unit_value < percentile05 | unit_value > percentile95
	bysort triplet_id: egen triplet_id_mean = mean(unit_value)

	* compute sd of truncated distribution (still missing with triplets containing only one obs)
	bysort triplet_id: egen triplet_id_truncated_sd = sd(unit_value) if outlier == 0
	xtset triplet_id
	xfill triplet_id_truncated_sd, i(triplet_id)
	
	* Are there usable triplets without test value, excluding the unimodal truncated distributions?
*	count if one_sd == . & triplet_id_truncated_sd !=0 ///
	
			//& usable_triplet_id != . & outlier == 0
	// No, 0, so everything has worked
	local check_result = r(N)
*	if `check_result' != 0 {
*	stop // Problem! Missing test results for triplets with more than 15 obs
	// and strictly positive sd of truncated distribution
	

	* For things to be clearer, we set to 0 test when the truncated distribution is unimodal
*	replace one_sd = 0 if one_sd == . & triplet_id_truncated_sd == 0 & usable_triplet_id != .
*	replace halved_sd = 0 if halved_sd == . & triplet_id_truncated_sd == 0 & usable_triplet_id != .
*	replace third_sd = 0 if third_sd == . & triplet_id_truncated_sd == 0 & usable_triplet_id != .


//	save "$main/waste/$country_fullname/${country_code}_unit_values_with_tests_results_${geolevel_reg}.dta", replace
	
	* Label variables
	*****************************
	label variable Formal_Informal_0_1 "Formality level"
	label variable unit "Unit of measure"
*	label variable one_sd "Prob (multimodality) with par = 1*sd"
*	label variable halved_sd "Prob (multimodality) with par = 1/2*sd"
*	label variable third_sd "Prob (multimodality) with par = 1/3*sd"

	
	* Generate variables for regressions
	*************************************
	gen log_unit_value = log(unit_value)
	gen zscore = (unit_value - triplet_id_mean) / triplet_id_sd
	replace zscore = 0 if triplet_id_sd == 0
	gen unit_value_winsorized = unit_value
	replace unit_value_winsorized = percentile95 if unit_value > percentile95
	replace unit_value_winsorized = percentile05 if unit_value < percentile05
	gen log_unit_value_winsorized = log(unit_value_winsorized)

	
	** Retailer variables
	************************
	
		* Correction of Formal_Informal_0_1
		replace Formal_Informal_0_1 = 1 if detailed_classification == 10 | detailed_classification == 4 | detailed_classification == 8 
		replace Formal_Informal_0_1 = 0 if detailed_classification == 3 | detailed_classification == 7 | detailed_classification == 9 

		* We want Formal_Informal to be ordered in the same direction as Formal_Informal_0_1 and others
		ta Formal_Informal, m
		ta Formal_Informal, m nol
		gen Formal_Informal_temp = Formal_Informal
		replace Formal_Informal = 1 if Formal_Informal_temp == 3
		replace Formal_Informal = 2 if Formal_Informal_temp == 2
		replace Formal_Informal = 3 if Formal_Informal_temp == 1
		replace Formal_Informal = 4 if Formal_Informal_temp == 4
		drop Formal_Informal_temp
		label define formal_informal_lab 1 "Informal" 2 "Semi-formal" 3 "Formal" 4 "Unspecified"
		label values Formal_Informal formal_informal_lab
		ta Formal_Informal, m
		ta Formal_Informal, m nol

		* We create the variable levels which is more sophisticated than new_classification
		gen levels = 1 if detailed_classification == 1
		replace levels = 2 if detailed_classification == 2 | detailed_classification == 7 | detailed_classification == 9
		replace levels = 3 if detailed_classification == 3 
				// corner, convenience store
		replace levels = 4 if detailed_classification == 4 			
				// specialized shops
		replace levels = 5 if detailed_classification == 5
		replace levels = 6 if detailed_classification == 6 | detailed_classification == 10  | detailed_classification == 8
		replace levels = 7 if detailed_classification == 99 
		*know what share is coicop 2 categories in level 7
			
		* label for levels
		label define levels_lab 1 "non-market" 2 "no store front" 3 "conv/corner shops" ///
				4 "specialized shops" 5 "large stores" 6 "other consumption" 7 "unspecified" 
		label values levels levels_lab
		
		* We create a last classification with the detailed_classification
		gen detailed_levels = .
		replace detailed_levels = 1 if detailed_classification == 1
		replace detailed_levels = 2 if detailed_classification == 2 
		replace detailed_levels = 3 if detailed_classification == 3
		replace detailed_levels = 4 if detailed_classification == 4 
		replace detailed_levels = 5 if detailed_classification == 5
		replace detailed_levels = 6 if detailed_classification == 6 | detailed_classification == 10
		replace detailed_levels = 7 if detailed_classification == 8
		replace detailed_levels = 8 if detailed_classification == 7 | detailed_classification == 9
		replace detailed_levels = 9 if detailed_classification == 99 
		label define detailed_levels_lab 1 "non-market" 2 "no store front" 3 "conv/corner shops" ///
				4 "specialized shops" 5 "large stores" 6 "institutions" 7 "entertainment" 8 "informal entertainment" 9 "unspecified" 
		label values detailed_levels detailed_levels_lab
		
	*Create a variable without self consumption
	gen Formal_Informal_0_1_noself=0 if Formal_Informal_0_1==0 & detailed_classification!=1
	replace Formal_Informal_0_1_noself=1 if Formal_Informal_0_1==1 & detailed_classification!=1
	replace Formal_Informal_0_1_noself=9 if Formal_Informal_0_1==9 & detailed_classification!=1

	
	
	************************
	* Household controls : THIS PART IS COUNTRY-SPECIFIC (remove "stop" when harmonized by hand)
	************************
	*stop
	
	cap drop _merge
	merge m:1 hhid using "$main/proc/$country_fullname/${country_code}_household_cov.dta", ///
		keepusing(head_sex head_edu hh_size head_age exp_noh)
	drop if _merge == 2 // household without expenditures in our database of usable triplets
	
	ta head_sex, missing
	ta head_edu, missing
	ta hh_size, missing
	ta head_age, missing // some missing observations
	
	gen head_edu_reg = .
	replace head_edu_reg = 0 if head_edu == 0 // no education
	replace head_edu_reg = 1 if head_edu_reg == . & head_edu <= 16 // imcomplete primary education
	replace head_edu_reg = 2 if head_edu_reg == . & head_edu <= 19 // completed primary education
	replace head_edu_reg = 3 if head_edu_reg == . & head_edu <= 24 	// secondary education
	replace head_edu_reg = 4 if head_edu_reg == . & head_edu <= 47 // more than secondary education
	#delim ;
	label define head_edu_reg_label 0 "No education" 
									1 "imcomplete primary education" 
									2 "completed primary education" 
									3 "secondary education" 
									4 "more than secondary education";
	#delim cr
	label values head_edu_reg head_edu_reg_label
	ta head_edu_reg
	
	gen hh_size2 = hh_size^2
	ta hh_size2
	
	replace exp_noh = 1 if exp_noh < 1
	gen log_exp_noh = log(exp_noh)
		
	global hh_demo_controls i.head_sex hh_size hh_size2 head_age
	di " $hh_demo_controls "
	global hh_full_controls i.head_sex hh_size hh_size2 head_age i.head_edu_reg log_exp_noh
	di " $hh_full_controls "

	label variable head_age "Household head age"
	label variable hh_size "Household size"
	label variable hh_size2 "Household size (squared)"
	label variable head_sex "Household head sex"
	label variable head_edu_reg "Household head education level"
	label variable log_exp_noh "HH log total expenditures without housing"

	*************************
	* Drop small triplets
	*************************
	
	
	drop if triplet_id_count<15 	
	
	save "$main/waste/${country_fullname}/${country_code}_pqty_regressions_harmonized_geo${geolevel_reg}.dta", replace

	*stop

	*****************************************
	* 	Regressions	Formal_Informal_0_1		*
	*****************************************
	unique product_code
	local nb_product_code = r(unique)
	
 	local Formal_Informal_0_1 = 1
	if `Formal_Informal_0_1' {
	foreach retailer_reg in Formal_Informal_0_1_noself Formal_Informal_0_1  {
	
	* create folder "${country_fullname}_geo${geolevel_reg}" in tables>price_quantity
	local savefile "$main/tables/price_quantity/${country_fullname}_geo${geolevel_reg}/${country_fullname}_regressions_comparing_specifications_`retailer_reg'.xls"

* Regression with all multimodality tests values
*************************************************

* with unspecified and all multimodality tests values	 
*			reghdfe log_unit_value ib1.`retailer_reg' [aweight=hh_weight] , ///
*				vce(cluster geo$geolevel_reg) absorb(triplet_id)			
*			local nb_fixed_effects = e(df_a)														
*			local notes addtext(Triplets with more than 16 obs only, YES, ///
*							Triplet fixed effects, YES, ///
*							Nb of triplets, `nb_fixed_effects', ///
*							Household Weights, YES, ///
*							Unspecified excluded, YES, ///
*							High multimodality probability excluded, NO, ///
*							Minimum nb of obs per triplet, NO, ///
*							Geographical level, $geolevel_reg)
*			outreg2 using `savefile', dta replace ctitle(Baseline with unspecified) `notes' label
*






* without unspecified and all multimodality tests values	 
			reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
				if Formal_Informal_0_1 != 9, ///
				vce(cluster geo$geolevel_reg) absorb(triplet_id)
			unique triplet_id
			local nb_fixed_effects  = r(unique)
			local b = _b[1.`retailer_reg'] *100
			local se = _se[1.`retailer_reg'] *100
			count
			local nb_purchases =r(N)
			unique geo$geolevel_reg
			local nb_geo_clusters = r(unique)
			local country "$country_fullname"
			post regressions_output_price ("`country'") (`b') (`se') (`nb_purchases')  (`nb_geo_clusters') (`nb_product_code') (`nb_fixed_effects') 
			

* Regression with one_sd = 0
******************************
*	* without unspecified
* 		reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
*				if one_sd == 0 & Formal_Informal_0_1 != 9, ///
*				vce(robust) absorb(triplet_id)	
*				
*			local nb_fixed_effects = e(df_a)
*			local notes addtext(Triplets with more than 16 obs only, YES, ///
*							Triplet fixed effects, YES, ///
*							Nb of triplets, `nb_fixed_effects', ///
*							Household Weights, YES, ///
*							Unspecified excluded, YES, ///
*							High multimodality probability excluded, YES, ///
*							Minimum nb of obs per triplet, NO, ///
*							Geographical level, $geolevel_reg)
*			outreg2 using `savefile', append ctitle(Only if 1sd test equals 0 and no unspecified) `notes' label
*
		
* Regression with winsorized unit values 
*******************************************
		reghdfe log_unit_value_winsorized i.`retailer_reg' [aweight=hh_weight] ///
				 if Formal_Informal_0_1 != 9, ///
				vce(cluster geo$geolevel_reg) absorb(triplet_id)	
			unique triplet_id
			local nb_fixed_effects  = r(unique)
			local b = _b[1.`retailer_reg'] *100
			local se = _se[1.`retailer_reg']*100
			count
			unique geo$geolevel_reg
			local nb_geo_clusters = r(unique)
			local country "$country_fullname"
			post regressions_output_price ("`country'") (`b') (`se') (`nb_purchases')  (`nb_geo_clusters') (`nb_product_code') (`nb_fixed_effects')
			local notes addtext(Triplets with more than 16 obs only, YES, ///
							Triplet fixed effects, YES, ///
							Nb of triplets, `nb_fixed_effects', ///
							Household Weights, YES, ///
							Unspecified excluded, YES, ///
							High multimodality probability excluded, NO, ///
							Minimum nb of obs per triplet, NO, ///
							Geographical level, $geolevel_reg)
			outreg2 using `savefile', dta append ctitle(Winsorization at 5% top and bottom) `notes' label


* Regression with winsorized unit values and bounded zscore
*******************************************
		reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
				 if Formal_Informal_0_1 != 9 & zscore > -2 & zscore < 2, ///
				vce(cluster geo$geolevel_reg) absorb(triplet_id)	
				local notes addtext(Triplets with more than 16 obs only, YES, ///
							Triplet fixed effects, YES, ///
							Nb of triplets, `nb_fixed_effects', ///
							Household Weights, YES, ///
							Unspecified excluded, YES, ///
							High multimodality probability excluded, NO, ///
							Minimum nb of obs per triplet, NO, ///
							Geographical level, $geolevel_reg)
			outreg2 using `savefile', dta append ctitle(Winsorization at 5% and bounded zscore) `notes' label

	
* Regression with one_sd = 0 and with > 50 obs
******************************
*		foreach h of numlist 50(50)200 {
*			local threshold = `h'
*				count if triplet_id_count >= `threshold' 
*				local nb_obs_left = r(N)
*				if `nb_obs_left' > 15 {
*			* without unspecified 
*				reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
*					if one_sd == 0 & Formal_Informal_0_1 != 9 & triplet_id_count >= `threshold', ///
*					vce(robust) absorb(triplet_id)	
*					local nb_fixed_effects = e(df_a)
*					local notes addtext(Triplets with more than 16 obs only, YES, ///
*									Triplet fixed effects, YES, ///
*									Nb of triplets, `nb_fixed_effects', ///
*									Household Weights, YES, ///
*									Unspecified excluded, YES, ///
*									High multimodality probability excluded, YES, ///
*									Minimum nb of obs per triplet, `threshold', ///
*								Geographical level, $geolevel_reg)
*					outreg2 using `savefile', append ctitle(Minimum nb of obs per triplet) `notes' label
*				}
*		 }

} // end of retailer_reg loop
}	
}
postclose regressions_output_price

	*****************************************************
	* 	Regressions - More detailed categories			*
	*****************************************************
 	
	local reg_detailed = 0
	if `reg_detailed' {
	foreach retailer_reg in  levels detailed_levels {
	
	* create folder "${country_fullname}_geo${geolevel_reg}" in tables>price_quantity
	local savefile "$main/tables/price_quantity/${country_fullname}_geo${geolevel_reg}/${country_fullname}_regressions_comparing_specifications_`retailer_reg'.xls"

* Regression with all multimodality tests values
*************************************************

* with unspecified and all multimodality tests values	 
			reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] , ///
				vce(robust) absorb(triplet_id)			
			local nb_fixed_effects = e(df_a)
			local notes addtext(Triplets with more than 16 obs only, YES, ///
							Triplet fixed effects, YES, ///
							Nb of triplets, `nb_fixed_effects', ///
							Household Weights, YES, ///
							Unspecified excluded, YES, ///
							High multimodality probability excluded, NO, ///
							Minimum nb of obs per triplet, NO, ///
							Geographical level, $geolevel_reg)
			outreg2 using `savefile', dta replace ctitle(Baseline with unspecified) `notes' label



* without unspecified and all multimodality tests values	 
			reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
				if Formal_Informal_0_1 != 9, ///
				vce(robust) absorb(triplet_id)			
			local nb_fixed_effects = e(df_a)
			local notes addtext(Triplets with more than 16 obs only, YES, ///
							Triplet fixed effects, YES, ///
							Nb of triplets, `nb_fixed_effects', ///
							Household Weights, YES, ///
							Unspecified excluded, YES, ///
							High multimodality probability excluded, NO, ///
							Minimum nb of obs per triplet, NO, ///
							Geographical level, $geolevel_reg)
			outreg2 using `savefile', dta append ctitle(Baseline No unspecified) `notes' label
		
	
* Regression with one_sd = 0
******************************
*	* without unspecified
* 		reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
*				if one_sd == 0 & Formal_Informal_0_1 != 9, ///
*				vce(robust) absorb(triplet_id)	
*				
*			local nb_fixed_effects = e(df_a)
*			local notes addtext(Triplets with more than 16 obs only, YES, ///
*							Triplet fixed effects, YES, ///
*							Nb of triplets, `nb_fixed_effects', ///
*							Household Weights, YES, ///
*							Unspecified excluded, YES, ///
*							High multimodality probability excluded, YES, ///
*							Minimum nb of obs per triplet, NO, ///
*							Geographical level, $geolevel_reg)
*			outreg2 using `savefile', append ctitle(Only if 1sd test equals 0 and no unspecified) `notes' label
*
		
* Regression with winsorized unit values 
*******************************************
		reghdfe log_unit_value_winsorized i.`retailer_reg' [aweight=hh_weight] ///
				 if Formal_Informal_0_1 != 9, ///
				vce(robust) absorb(triplet_id)	
			local nb_fixed_effects = e(df_a)
			local notes addtext(Triplets with more than 16 obs only, YES, ///
							Triplet fixed effects, YES, ///
							Nb of triplets, `nb_fixed_effects', ///
							Household Weights, YES, ///
							Unspecified excluded, YES, ///
							High multimodality probability excluded, NO, ///
							Minimum nb of obs per triplet, NO, ///
							Geographical level, $geolevel_reg)
			outreg2 using `savefile', dta append ctitle(Winsorization at 5% top and bottom) `notes' label


* Regression with winsorized unit values and bounded zscore
*******************************************
		reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
				 if Formal_Informal_0_1 != 9 & zscore > -2 & zscore < 2, ///
				vce(robust) absorb(triplet_id)	
			local nb_fixed_effects = e(df_a)
			local notes addtext(Triplets with more than 16 obs only, YES, ///
							Triplet fixed effects, YES, ///
							Nb of triplets, `nb_fixed_effects', ///
							Household Weights, YES, ///
							Unspecified excluded, YES, ///
							High multimodality probability excluded, NO, ///
							Minimum nb of obs per triplet, NO, ///
							Geographical level, $geolevel_reg)
			outreg2 using `savefile', dta append ctitle(Winsorization at 5% and bounded zscore) `notes' label

	
* Regression with one_sd = 0 and with > 50 obs
******************************
*		foreach h of numlist 50(50)200 {
*			local threshold = `h'
*				count if triplet_id_count >= `threshold' 
*				local nb_obs_left = r(N)
*				if `nb_obs_left' > 15 {
*			* without unspecified 
*				reghdfe log_unit_value i.`retailer_reg' [aweight=hh_weight] ///
*					if one_sd == 0 & Formal_Informal_0_1 != 9 & triplet_id_count >= `threshold', ///
*					vce(robust) absorb(triplet_id)	
*					local nb_fixed_effects = e(df_a)
*					local notes addtext(Triplets with more than 16 obs only, YES, ///
*									Triplet fixed effects, YES, ///
*									Nb of triplets, `nb_fixed_effects', ///
*									Household Weights, YES, ///
*									Unspecified excluded, YES, ///
*									High multimodality probability excluded, YES, ///
*									Minimum nb of obs per triplet, `threshold', ///
*								Geographical level, $geolevel_reg)
*					outreg2 using `savefile', append ctitle(Minimum nb of obs per triplet) `notes' label
*				}
*		 }

} // end of retailer_reg loop
	
}	
	
	
	
}	
