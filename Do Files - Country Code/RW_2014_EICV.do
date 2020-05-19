

					*************************************
					* 			Main DO FILE			*
					* 	       RWANDA: 2013-2014		*
					*************************************



***************
* DIRECTORIES *
***************

if "`c(username)'"=="wb520324" { 													// Eva's WB computer 
	global main "C:/Users/wb520324/Dropbox/Regressivity_VAT/Stata"		
}	
 else if "`c(username)'"=="" { 										
	global main ""
	}
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath
	display "`c(current_date)' `c(current_time)'"


********************************************************************************
********************************************************************************

	
	global country_fullname "Rwanda2014"
	global country_code "RW"
	
************
*   NOTE   *
************
/*
- Pre-filled diary
- Do file inspired by the Global Consumption Database dofile
*/
	
/* SUMMARY:
   Step 0:  Data overview
   Step 1:  Prepare covariates at the household level
   Step 2: Preparing the expenditures database 
   Step 2.1: Harmonization of names, introduction of labels
   Step 2.2: Product crosswalk if product codes are not COICOP
   Step 3: Generating total expenditures and total income
   Step 3.1: Total expenditures
   Step 3.2 Total income
   Step 3.3: Merge with the household covariates datafile
   Step 4: Crosswalk between places of purchase and classification
   Step 5: Creation of database at the COICOP_4dig level
   */
	
*****************************
* Step 0:  Data overview    *
*****************************	
	
/*
	cs_s1_s2_s3_s4_s6a_s6e_s6f_person.dta
	Household and individual level general statistics (+education), one line per individual. 	
	
	cs_s6b_employement_6c_salaried_s6d_business.dta - data on wages, employment, benefits
	cs_s9d_other_income.dta - data on household income forms of public support and transfers
	S09A1_consnonfood.dta - data on non-food expenditures in last 12 months, with TOR
	S09A3_consnonfood.dta - more frequently made non-food expenditures
	S09B_consfood.dta - frequently made food expenditures 
	cs_s0_s5_household.dta - actual and imputed rent, type of habitat and dwelling 
*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear	
	set more off
	use "$main/data/$country_fullname/cs_s1_s2_s3_s4_s6a_s6e_s6f_person.dta", clear


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename weight  								hh_weight
	rename province								geo_loc
	rename district								geo_loc_min
	rename clust								census_block // unsure about this "Cluster"  1230 unique values
	rename ur2_2012 							urban //two categories
	rename ur2012								urb_sem_per_rur //four categories
	rename s1q1									head_sex
	rename s1q3y								head_age
	rename s4aq2								head_edu
	

	*We need to construct/modify some of them
	
	*exp_agg_tot, inc_agg_tot look at: cs_s6b_employement_6c_salaried_s6d_business.dta , cs_s9d_other_income.dta
	
	*hh_size
	sort hhid 
	by hhid: gen _nval = _n
	by hhid: egen hh_size = max(_nval)
	drop _nval

	*We destring and label some variables for clarity/uniformity 
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace					// Some of these variables are already numeric
	
	ta head_sex, missing
	label define head_sex_lab 1 "Male" 2 "Female"
	label values head_sex head_sex_lab
	
	ta urban
	ta urban, nol
	replace urban = 0 if urban == 2
	label define urban_lab 0 "Rural" 1 "Urban"
	label values urban urban_lab
	
	
	*We keep only one line by household and necessary covariates 
 	duplicates drop hhid , force
	drop if s1q2 !=1
 
	keep hhid hh_weight geo_loc geo_loc_min census_block urban urb_sem_per_rur head_sex head_age head_edu hh_size  
	destring hhid, replace
	order hhid, first 
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , replace
	


************************************************************
* Step 2: Renaming and labelling the expenditures database *
************************************************************

************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************


	*DIARY
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s8b_expenditure.dta", clear
			
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
			rename weight							hh_weight
			rename s8bq13							TOR_original 
			rename s8bq1d							product_code
			rename s8bq0  							product_code_original
			rename s8bq0d 							product_code_label
	
	
	*We need to construct/modify some of them
	*agg_value_on_period
	egen agg_total = rowtotal(s8bq3-s8bq12), missing
	drop if agg_total==0
	replace s8bq2=12 if inlist(s8bq2,0,.)
	gen agg_value_on_period=agg_total* (1/(12*4/52)) * s8bq2 if ur2_2012 ==1 // GCD 
	replace agg_value_on_period=agg_total* (1/(12*2/52)) * s8bq2 if ur2_2012 ==2 // GCD
	drop if agg_value_on_period==0

	*TOR_original
	replace TOR_original = 99 if TOR_original == .
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original, missing

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
			
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_code_label product_code_original
	gen module_tracker = "Diary 1"
	tempfile diary
	save `diary'
	
	*DIARY 2
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s8a3_expenditure.dta", clear
				
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight 							hh_weight
	rename s8a3q13 							TOR_original 
	rename s8a3q1d 							product_code // follows COICOP
	rename s8a3q0d 							product_code_label

			
	*We need to construct/modify some of them
	*product_code, COICOP needs correction 
	replace 	product_code=		"0941"	 if 	s8a3q0==	1
	replace 	product_code=		"0942"	 if 	s8a3q0==	2
	replace 	product_code=		"0942"	 if 	s8a3q0==	3
	replace 	product_code=		"0952"	 if 	s8a3q0==	4
	replace 	product_code=		"0954"	 if 	s8a3q0==	5
	replace 	product_code=		"0561"	 if 	s8a3q0==	6
	replace 	product_code=		"1213"	 if 	s8a3q0==	7
	replace 	product_code=		"0561"	 if 	s8a3q0==	8
	replace 	product_code=		"0561"	 if 	s8a3q0==	9
	replace 	product_code=		"1213"	 if 	s8a3q0==	10
	replace 	product_code=		"0722"	 if 	s8a3q0==	11
	replace 	product_code=		"0722"	 if 	s8a3q0==	12
	replace 	product_code=		"0722"	 if 	s8a3q0==	13
	replace 	product_code=		"0724"	 if 	s8a3q0==	14
	replace 	product_code=		"0732"	 if 	s8a3q0==	15
	replace 	product_code=		"0732"	 if 	s8a3q0==	16
	replace 	product_code=		"0732"	 if 	s8a3q0==	17
	replace 	product_code=		"0734"	 if 	s8a3q0==	18
	replace 	product_code=		"0452"	 if 	s8a3q0==	19
	replace 	product_code=		"0453"	 if 	s8a3q0==	20
	replace 	product_code=		"0454"	 if 	s8a3q0==	21
	replace 	product_code=		"0454"	 if 	s8a3q0==	22
	replace 	product_code=		"0552"	 if 	s8a3q0==	23
	replace 	product_code=		"0552"	 if 	s8a3q0==	24
	replace 	product_code=		"0561"	 if 	s8a3q0==	25
	replace 	product_code=		"0561"	 if 	s8a3q0==	26
	replace 	product_code=		"0722"	 if 	s8a3q0==	27
	replace 	product_code=		"0314"	 if 	s8a3q0==	28
	replace 	product_code=		"0322"	 if 	s8a3q0==	29
	replace 	product_code=		"0513"	 if 	s8a3q0==	30
	replace 	product_code=		"0820"	 if 	s8a3q0==	31
	replace 	product_code=		"0830"	 if 	s8a3q0==	32
	replace 	product_code=		"0830"	 if 	s8a3q0==	33
	replace 	product_code=		"0830"	 if 	s8a3q0==	34
	replace 	product_code=		"0220"	 if 	s8a3q0==	35
	replace 	product_code=		"0220"	 if 	s8a3q0==	36
	replace 	product_code=		"0220"	 if 	s8a3q0==	37
	rename s8a3q0  							product_code_original

	*agg_value_on_period
	egen agg_total = rowtotal(s8a3q3-s8a3q12), missing
	drop if agg_total==0
	replace s8a3q2 =12 if inlist(s8a3q2,0,.) //impute missing number of months with 12
	gen agg_value_on_period=agg_total* (1/(12*4/52)) * s8a3q2 if ur2_2012 ==1
	replace agg_value_on_period=agg_total* (1/(12*2/52)) * s8a3q2 if ur2_2012 ==2
	drop if agg_value_on_period==0

	*TOR_original
	replace TOR_original = 99 if TOR_original == .
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original, missing

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == .  // 0 obs deleted
			
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_code_label product_code_original
	gen module_tracker = "Diary 2"
	tempfile diary2
	save `diary2'
	
	*RECALL MONTH 
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s8a2_expenditure.dta", clear

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight 							hh_weight
	rename s8a2q4 							TOR_original 
	rename s8a2q1d							product_code //follows COICOP
	rename s8a2q0d 							product_code_label
	
			
	*We need to construct/modify some of them
	*product_code, COICOP needs correction 
	replace 	product_code=		"0561"	 if 	s8a2q0==	1
	replace 	product_code=		"0442"	 if 	s8a2q0==	2
	replace 	product_code=		"0314"	 if 	s8a2q0==	3
	replace 	product_code=		"0561"	 if 	s8a2q0==	4
	replace 	product_code=		"0561"	 if 	s8a2q0==	5
	replace 	product_code=		"0561"	 if 	s8a2q0==	6
	replace 	product_code=		"0561"	 if 	s8a2q0==	7
	replace 	product_code=		"0561"	 if 	s8a2q0==	8
	replace 	product_code=		"0531"	 if 	s8a2q0==	9
	replace 	product_code=		"0721"	 if 	s8a2q0==	10
	replace 	product_code=		"0721"	 if 	s8a2q0==	11
	replace 	product_code=		"0723"	 if 	s8a2q0==	12
	replace 	product_code=		"0723"	 if 	s8a2q0==	13
	replace 	product_code=		"0911"	 if 	s8a2q0==	14
	replace 	product_code=		"0911"	 if 	s8a2q0==	15
	replace 	product_code=		"0912"	 if 	s8a2q0==	16
	replace 	product_code=		"0931"	 if 	s8a2q0==	17
	replace 	product_code=		"0933"	 if 	s8a2q0==	18
	replace 	product_code=		"0933"	 if 	s8a2q0==	19
	replace 	product_code=		"0934"	 if 	s8a2q0==	20
	replace 	product_code=		"0951"	 if 	s8a2q0==	21
	replace 	product_code=		"0952"	 if 	s8a2q0==	22
	replace 	product_code=		"0954"	 if 	s8a2q0==	23
	replace 	product_code=		"1270"	 if 	s8a2q0==	24
	replace 	product_code=		"1211"	 if 	s8a2q0==	25
	replace 	product_code=		"1211"	 if 	s8a2q0==	26
	replace 	product_code=		"1211"	 if 	s8a2q0==	27
	replace 	product_code=		"1213"	 if 	s8a2q0==	28
	replace 	product_code=		"1213"	 if 	s8a2q0==	29
	replace 	product_code=		"1213"	 if 	s8a2q0==	30
	replace 	product_code=		"1213"	 if 	s8a2q0==	31
	replace 	product_code=		"1213"	 if 	s8a2q0==	32
	replace 	product_code=		"1213"	 if 	s8a2q0==	33
	replace 	product_code=		"1213"	 if 	s8a2q0==	34
	replace 	product_code=		"1213"	 if 	s8a2q0==	35
	replace 	product_code=		"0810"	 if 	s8a2q0==	36
	replace 	product_code=		"0830"	 if 	s8a2q0==	37
	replace 	product_code=		"0830"	 if 	s8a2q0==	38
	replace 	product_code=		"0830"	 if 	s8a2q0==	39
	replace 	product_code=		"0444"	 if 	s8a2q0==	40
	replace 	product_code=		"1270"	 if 	s8a2q0==	41
	replace 	product_code=		"0611"	 if 	s8a2q0==	42
	replace 	product_code=		"0611"	 if 	s8a2q0==	43
	replace 	product_code=		"0611"	 if 	s8a2q0==	44
	replace 	product_code=		"0611"	 if 	s8a2q0==	45
	replace 	product_code=		"0611"	 if 	s8a2q0==	46
	replace 	product_code=		"0611"	 if 	s8a2q0==	47
	replace 	product_code=		"0611"	 if 	s8a2q0==	48
	replace 	product_code=		"0611"	 if 	s8a2q0==	49
	replace 	product_code=		"0611"	 if 	s8a2q0==	50
	replace 	product_code=		"0611"	 if 	s8a2q0==	51
	replace 	product_code=		"0611"	 if 	s8a2q0==	52
	replace 	product_code=		"0612"	 if 	s8a2q0==	53
	replace 	product_code=		"0621"	 if 	s8a2q0==	54
	replace 	product_code=		"0623"	 if 	s8a2q0==	55
	rename s8a2q0  							product_code_original

	*agg_value_on_period
	gen agg_value_on_period = s8a2q3* 52/4
	keep if agg_value_on_period > 0 & agg_value_on_period~=.
			

	*TOR_original
	replace TOR_original = 99 if TOR_original == .
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original, missing
	
	drop if TOR_original == .   // 0 obs deleted
	
	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_code_label product_code_original
	gen module_tracker="Recall Month"
	tempfile recall_month
	save `recall_month'
	
	
	
	*RECALL YEAR
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s8a1_expenditure.dta", clear

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight 							hh_weight
	rename s8a1q4 							TOR_original 
	rename s8a1q3 							agg_value_on_period	//period is annualized already				
	rename s8a1q1d							product_code // it is COICOP
	rename s8a1q0d 							product_code_label
			
	*We need to construct/modify some of them
	*product_code, COICOP needs correction 
	replace 	product_code=		"0311"	 if 	s8a1q0==	1
	replace 	product_code=		"0311"	 if 	s8a1q0==	2
	replace 	product_code=		"0313"	 if 	s8a1q0==	3
	replace 	product_code=		"0312"	 if 	s8a1q0==	4
	replace 	product_code=		"0314"	 if 	s8a1q0==	5
	replace 	product_code=		"0312"	 if 	s8a1q0==	6
	replace 	product_code=		"0313"	 if 	s8a1q0==	7
	replace 	product_code=		"0312"	 if 	s8a1q0==	8
	replace 	product_code=		"0314"	 if 	s8a1q0==	9
	replace 	product_code=		"0312"	 if 	s8a1q0==	10
	replace 	product_code=		"0313"	 if 	s8a1q0==	11
	replace 	product_code=		"0312"	 if 	s8a1q0==	12
	replace 	product_code=		"0312"	 if 	s8a1q0==	13
	replace 	product_code=		"0314"	 if 	s8a1q0==	14
	replace 	product_code=		"0321"	 if 	s8a1q0==	15
	replace 	product_code=		"0321"	 if 	s8a1q0==	16
	replace 	product_code=		"0321"	 if 	s8a1q0==	17
	replace 	product_code=		"1231"	 if 	s8a1q0==	18
	replace 	product_code=		"1231"	 if 	s8a1q0==	19
	replace 	product_code=		"1231"	 if 	s8a1q0==	20
	replace 	product_code=		"1232"	 if 	s8a1q0==	21
	replace 	product_code=		"1232"	 if 	s8a1q0==	22
	replace 	product_code=		"1232"	 if 	s8a1q0==	23
	replace 	product_code=		"1232"	 if 	s8a1q0==	24
	replace 	product_code=		"1232"	 if 	s8a1q0==	25
	replace 	product_code=		"1232"	 if 	s8a1q0==	26
	replace 	product_code=		"1232"	 if 	s8a1q0==	27
	replace 	product_code=		"1232"	 if 	s8a1q0==	28
	replace 	product_code=		"0431"	 if 	s8a1q0==	29
	replace 	product_code=		"0431"	 if 	s8a1q0==	30
	replace 	product_code=		"0511"	 if 	s8a1q0==	31
	replace 	product_code=		"0512"	 if 	s8a1q0==	32
	replace 	product_code=		"0512"	 if 	s8a1q0==	33
	replace 	product_code=		"0513"	 if 	s8a1q0==	34
	replace 	product_code=		"0520"	 if 	s8a1q0==	35
	replace 	product_code=		"0520"	 if 	s8a1q0==	36
	replace 	product_code=		"0520"	 if 	s8a1q0==	37
	replace 	product_code=		"0520"	 if 	s8a1q0==	38
	replace 	product_code=		"0520"	 if 	s8a1q0==	39
	replace 	product_code=		"0520"	 if 	s8a1q0==	40
	replace 	product_code=		"0520"	 if 	s8a1q0==	41
	replace 	product_code=		"0541"	 if 	s8a1q0==	42
	replace 	product_code=		"0520"	 if 	s8a1q0==	43
	replace 	product_code=		"0531"	 if 	s8a1q0==	44
	replace 	product_code=		"0532"	 if 	s8a1q0==	45
	replace 	product_code=		"0552"	 if 	s8a1q0==	46
	replace 	product_code=		"0532"	 if 	s8a1q0==	47
	replace 	product_code=		"0531"	 if 	s8a1q0==	48
	replace 	product_code=		"0533"	 if 	s8a1q0==	49
	replace 	product_code=		"0540"	 if 	s8a1q0==	50
	replace 	product_code=		"0540"	 if 	s8a1q0==	51
	replace 	product_code=		"0532"	 if 	s8a1q0==	52
	replace 	product_code=		"0552"	 if 	s8a1q0==	53
	replace 	product_code=		"0732"	 if 	s8a1q0==	54
	replace 	product_code=		"0733"	 if 	s8a1q0==	55
	replace 	product_code=		"0734"	 if 	s8a1q0==	56
	replace 	product_code=		"1254"	 if 	s8a1q0==	57
	replace 	product_code=		"0922"	 if 	s8a1q0==	58
	replace 	product_code=		"0932"	 if 	s8a1q0==	59
	replace 	product_code=		"0942"	 if 	s8a1q0==	60
	replace 	product_code=		"1120"	 if 	s8a1q0==	61
	replace 	product_code=		"0613"	 if 	s8a1q0==	62
	replace 	product_code=		"0613"	 if 	s8a1q0==	63
	replace 	product_code=		"0613"	 if 	s8a1q0==	64
	replace 	product_code=		"0630"	 if 	s8a1q0==	65
	replace 	product_code=		"0630"	 if 	s8a1q0==	66
	replace 	product_code=		"1253"	 if 	s8a1q0==	67
	replace 	product_code=		"1010"	 if 	s8a1q0==	68
	replace 	product_code=		"1270"	 if 	s8a1q0==	69
	rename s8a1q0  							product_code_original

	
	*agg_value_on_period
	drop if inlist(agg_value_on_period,0,.)
	keep if agg_value_on_period > 0 & agg_value_on_period~=.

	*TOR_original
	replace TOR_original = 99 if TOR_original == . 
	destring TOR_original, force replace
	ta TOR_original
		
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original, missing
	
	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	drop if TOR_original==.
	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_code_label product_code_original
	gen module_tracker="Recall Year"
	tempfile recall_year
	save `recall_year'
	
	*SELF CONSUMPTION
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s8c_farming.dta", clear

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight							hh_weight
	rename s8cq1d							product_code
	rename s8cq0d 							product_code_label
			
	*We need to construct/modify some of them
	*product_code, COICOP needs correction 

	
	*agg_value_on_period
	egen agg_total = rowtotal(s8cq3-s8cq12), missing
	drop if agg_total==0

	preserve
	drop if inlist(s8cq2,0,99)

	collapse avmonth=s8cq2, by(s8cq0)
	sort s8cq0
	tempfile nmonths
	save `nmonths', replace

	restore
	sort s8cq0
	merge m:1 s8cq0 using `nmonths'
	tab _
	drop _
	count


	replace s8cq2 =s8cq0 if inlist(s8cq2,0,99) // impute 0 or 99 number of months with average number of months at item level
	drop if inlist(s8cq2,0,99)
	gen agg_value_on_period=agg_total*s8cq14 * (1/(12*4/52)) * s8cq2 if ur2_2012 ==1
	replace agg_value_on_period=agg_total*s8cq14* (1/(12*2/52)) * s8cq2 if ur2_2012 ==2
	keep if agg_value_on_period > 0 & agg_value_on_period~=.
	rename s8cq0 product_code_original



	*TOR_original
	gen TOR_original = . 
	replace TOR_original = 11 //self-production
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_code_label product_code_original
	gen module_tracker="Self-Consumption"
	tempfile self_conso
	save `self_conso'
	
	*HOUSING
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s0_s5_household.dta", clear
	duplicates drop hhid, force //0 dropped

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight 							hh_weight

	
			
	*We need to construct/modify some of them
	*agg_value_on_period
	summ s5bq3a s5bq4a s5bq6a s5cq9b s5cq11 s5cq14 s5cq17
	recode s5cq14 (99999=0)
	recode s5bq3a s5bq4a s5bq6a s5cq9b s5cq11 s5cq14 s5cq17 (100000000=0)
	* 501 Estimated rent 
	gen exp501 = s5bq3a
	*Annualization
	replace exp501 = exp501 * 12 if s5bq3b ==1
	replace exp501 = exp501 * 4 if s5bq3b ==2
	
	* 502 Actual rent
	gen exp502 = s5bq4a
	*Annualization
	replace exp502 = exp502 * 12 if s5bq4b ==1
	replace exp502 = exp502 * 4 if s5bq4b ==2
	
	* 503 Service provided instead of rent
	gen exp503 =s5bq6a 
	*Annualization
	replace exp503 = exp503 * 12 if s5bq6b ==1
	replace exp503 = exp503 * 4 if s5bq6b ==2
	
	* 511 Dwelling repairs and painting
	*gen exp511 =S5BQ11
	
	* 504 Electricity (RECO RWASCO/Electrogaz) bill
	recode s5cq9b (0=.)
	gen exp504 =s5cq9b 
	replace s5cq9a=1 if s5cq9a==. & s5cq9b <.
	replace exp504 = exp504 * 12/s5cq9a
	
	* 505 Expenses paid to a private water vendor/ neighbour 
	gen exp505 =s5cq11
	replace exp505 =exp505 * 52
	
	* 506 Contribute to maintain the water soure
	gen exp506 =s5cq14
	replace exp506 =exp506 * 12
	
	* 507 Electricity bill
	gen exp507 =s5cq17
	replace exp507 =exp507 * 52/4
	
	keep hhid hh_weight exp*
	
	recode exp501 exp502 exp503 exp504 exp505 exp506 exp507 (.=0)
	egen agg_value_on_period=rsum(exp501 exp502 exp503 exp504 exp505 exp506 exp507)
	drop if inlist(agg_value_on_period,0,.)
	drop agg_value_on_period
	reshape long exp, i(hhid) j(product_code)
	drop if inlist(exp,0,.)
	
	gen agg_value_on_period=exp
	keep if agg_value_on_period > 0 & agg_value_on_period~=.

	*product_code, COICOP needs correction 
	tostring product_code , replace force
	replace product_code = "0411" if product_code=="502"
	replace product_code = "0421" if product_code=="501"
	replace product_code = "0421" if product_code=="503"
	replace product_code = "0451" if product_code=="504"
	replace product_code = "0441" if product_code=="505"
	replace product_code = "0441" if product_code=="506"
	replace product_code = "0451" if product_code=="507"
	
	tostring product_code, replace 
	gen product_code_label = "Housing"
	gen product_code_original = 9999
	
	*TOR_original
	gen TOR_original = . 
	replace TOR_original = 9 if TOR_original == . 
	
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == . 

	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_code_label product_code_original
	gen module_tracker="Housing"
	tempfile housing
	save `housing'
	
	*EDUCATION
	clear 
	set more off
	use  "$main/data/$country_fullname/cs_s1_s2_s3_s4_s6a_s6e_s6f_person.dta", clear

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight 							hh_weight

	
			
	*We need to construct/modify some of them	
	*agg_value_on_period
	keep hhid hh_weight s4aq11a s4aq11b s4aq11c s4aq11d s4aq11e s4aq11f s4aq11g s4aq11h s4bq2
	summ s4aq11a s4aq11b s4aq11c s4aq11d s4aq11e s4aq11f s4aq11g s4aq11h s4bq2
	recode s4aq11a s4aq11d s4aq11e s4aq11f s4aq11h (9999999=0)
	recode s4aq11b s4aq11c s4aq11g (999999=0)
	summ s4aq11a s4aq11b s4aq11c s4aq11d s4aq11e s4aq11f s4aq11g s4aq11h s4bq2
	egen toteduc=rsum(s4aq11a s4aq11b s4aq11c s4aq11d s4aq11e s4aq11f s4aq11g s4aq11h s4bq2)
	drop if inlist(toteduc,0,.)
	
	collapse (sum) s4aq11a s4aq11b s4aq11c s4aq11d s4aq11e s4aq11f s4aq11g s4aq11h s4bq2, by(hhid hh_weight)
	
	ren s4aq11a exp701
	ren s4aq11b exp702
	ren s4aq11c exp703
	ren s4aq11d exp704
	ren s4aq11e exp705
	ren s4aq11f exp706
	ren s4aq11g exp707
	ren s4aq11h exp708
	ren s4bq2 exp709
	
	reshape long exp, i(hhid) j(product_code)
	drop if exp ==0
	gen agg_value_on_period=exp
	keep if agg_value_on_period > 0 & agg_value_on_period~=.

			
	*product_code 
	replace product_code = 1051 if agg_value_on_period!=. 
	tostring product_code, replace
	gen product_code_label = "Education"
	gen product_code_original = 9998			

	
	*TOR_original
	gen TOR_original = . 
	replace TOR_original = 9 if TOR_original == . 
	
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == .
	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code  product_code_label product_code_original
	gen module_tracker="Education"
	tempfile education
	save `education'
	
	*TRANSFERS 1
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s6b_employement_6c_salaried_s6d_business.dta", clear

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight 							hh_weight

	
			
	*We need to construct/modify some of them	
	*agg_value_on_period
	keep hhid hh_weight s6cq25a s6cq25b s6cq27a s6cq27b s6cq29a s6cq29b
	// s6cq25a - Payment received in kind as food, agricultural produce, and livestock products
	// s6cq27a - Benefit provided by employer - subsidize housing
	// s6cq29a - Benefit received as transportation, communication allowances
	
	summ s6cq25a s6cq27a s6cq29a, detail
	recode s6cq25a s6cq27a s6cq29a (0=.)
	
	bys s6cq25b: summ s6cq25a, detail
	bys s6cq27b: summ s6cq27a, detail
	bys s6cq29b: summ s6cq29a, detail
	
	// Payment received in kind as food, agricultural produce, and livestock products
	gen cons901 = s6cq25a * 365 if s6cq25b==1 // daily
	replace cons901 = s6cq25a * 52 if s6cq25b==2 // weekly
	replace cons901 = s6cq25a * 12 if s6cq25b==3 // monthly
	replace cons901 = s6cq25a if s6cq25b==4 // year
	
	// Benefit provided by employer - subsidize housing
	gen cons902 = s6cq27a * 365 if s6cq27b==1 // daily
	replace cons902 = s6cq27a * 52 if s6cq27b==2 // weekly
	replace cons902 = s6cq27a * 12 if s6cq27b==3 // monthly
	replace cons902 = s6cq27a if s6cq27b==4 // year
	
	// Benefit received as transportation, communication allowances
	gen cons903 = s6cq29a * 365 if s6cq29b==1 // daily
	replace cons903 = s6cq29a * 52 if s6cq29b==2 // weekly
	replace cons903 = s6cq29a * 12 if s6cq29b==3 // monthly
	replace cons903 = s6cq29a if s6cq29b==4 // year
	
	collapse (sum) cons901 cons902 cons903, by(hhid hh_weight)
	
	reshape long cons, i(hhid) j(product_code)
	
	ren cons agg_value_on_period
	keep if agg_value_on_period > 0 & agg_value_on_period~=.
	
	*product_code
	tostring product_code , replace force
	replace product_code = "1200" if agg_value_on_period!=.
	tostring product_code, replace
	ta product_code
	gen product_code_label = "Education"
	gen product_code_original = 9998
			

	*TOR_original
	gen TOR_original = . 
	replace TOR_original = 9 if TOR_original == . 
	
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == .

	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code  product_code_label product_code_original
	gen module_tracker="Transfers 1"
	tempfile transfers1
	save `transfers1'
	
	*TRANSFERS 2
	clear 
	set more off
	use "$main/data/$country_fullname/cs_s9b_transfers_in.dta", clear

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight 							hh_weight
	
			
	*We need to construct/modify some of them
	*agg_value_on_period
	summ s9bq10 s9bq12, detail
	recode s9bq10 (9999999 0=.)
	recode s9bq12 (99999999 0=.)
	summ s9bq10 s9bq12, detail
	// S10BQ10 - Transfer received - food product
	gen cons904 = s9bq10
	
	// S10BQ11 - Transfer received - other in-kind transfer
	gen cons905 = s9bq12
	
	collapse (sum) cons904 cons905, by(hhid hh_weight)
	reshape long cons, i(hhid) j(product_code)
	drop if cons==0
	
	gen agg_value_on_period=cons
	keep if agg_value_on_period > 0 & agg_value_on_period~=.
				
	*product_code
	tostring product_code , replace force
	replace product_code = "0111" if agg_value_on_period!=. 
	// code all as "food" (from what appears in the questionnaires / documentation?)
	gen product_code_label = ""
	replace product_code_label = "Transfers"
	gen product_code_original = 9997
	tostring product_code, replace

	*TOR_original
	gen TOR_original = . 
	replace TOR_original = 12 //from a household
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == .
	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_code_label product_code_original
	gen module_tracker="Transfers 2"
	tempfile transfers2
	save `transfers2'
	
	*DURABLES (Inspired by GCD dofile)
	********************************************************************************
	** Calculating durables use values
	** Article 1
	use "$main/data/$country_fullname/cs_s10b_goods.dta", clear
	* check duplicates durable items within each households
		order hhid, first
		rename weight 							hh_weight
	
	summ s10bq4a s10bq4b s10bq4c s10bq5a s10bq5b s10bq5c
	recode s10bq4b s10bq4c s10bq5b s10bq5c (999999=0)
	recode s10bq4a s10bq5a (99999999=0)
	
	keep hhid hh_weight s10bq1 s0q19y s10bq3ay s10bq4a s10bq5a
	drop if inlist(s10bq3ay,0,.,9999) 
	/* Input data: Value of item when purchased =s10bq4a (old value)
				current value of the durable goods =s10bq5a (current vlaue)
				Age of the durable =s10bq3ay
	*/
	* age of first item
	gen age=(2000+s0q19y)-s10bq3ay
	replace age =0 if age == -1
	
	gen oldval=s10bq4a
	gen curval=s10bq5a
	* update old value with 2013 current price
	* Generate an inflator variable to make past value real (for 1985 to 2013)
	* (2010=100 ; source = World Bank DDP database, as of 8/16/2016)
	
	gen realval =oldval if age == 0	
	replace realval =oldval * 117.0527278 / 112.2971888 if age == 1
	replace realval =oldval * 117.0527278 / 105.6706827 if age == 2
	replace realval =oldval * 117.0527278 / 100 if age == 3
	replace realval =oldval * 117.0527278 / 97.74297189 if age == 4
	replace realval =oldval * 117.0527278 / 88.53996364 if age == 5
	replace realval =oldval * 117.0527278 / 76.69454409 if age == 6
	replace realval =oldval * 117.0527278 / 70.3098977 if age == 7
	replace realval =oldval * 117.0527278 / 64.57390934 if age == 8
	replace realval =oldval * 117.0527278 / 59.2344621 if age == 9
	replace realval =oldval * 117.0527278 / 52.76978823 if age == 10
	replace realval =oldval * 117.0527278 / 49.11115448 if age == 11
	replace realval =oldval * 117.0527278 / 48.15169091 if age == 12
	replace realval =oldval * 117.0527278 / 46.5941171 if age == 13
	replace realval =oldval * 117.0527278 / 44.84535896 if age == 14
	replace realval =oldval * 117.0527278 / 45.95090657 if age == 15
	replace realval =oldval * 117.0527278 / 43.26417244 if age == 16
	replace realval =oldval * 117.0527278 / 38.62340691 if age == 17
	replace realval =oldval * 117.0527278 / 35.95839647 if age == 18
	replace realval =oldval * 117.0527278 / 27.01692795 if age == 19
	replace realval =oldval * 117.0527278 / 18.07545943 if age == 20
	replace realval =oldval * 117.0527278 / 16.08789797 if age == 21
	replace realval =oldval * 117.0527278 / 14.68404298 if age == 22
	replace realval =oldval * 117.0527278 / 12.27381381 if age == 23
	replace realval =oldval * 117.0527278 / 11.78070148 if age == 24
	replace realval =oldval * 117.0527278 / 11.662874 if age == 25
	replace realval =oldval * 117.0527278 / 11.32552693 if age == 26
	replace realval =oldval * 117.0527278 / 10.87601942 if age == 27
	replace realval =oldval * 117.0527278 / 10.99888428 if age == 28
	
	* calculating depreciating rate of each type of durables
	gen deprate=1-(curval/realval)^(1/age)
	sum deprate, d
	sort s10bq1
	egen meddepr=median(deprate), by(s10bq1)
	tab s10bq1, summ(meddepr)
	*assumes real interest rate of 5 %
	gen useValue1 = (meddepr+0.05)*curval/(1-meddepr)
	drop if useValue1 < 0
	
	keep hhid hh_weight s10bq1 useValue1
	sort hhid s10bq1
	tempfile durables
	save `durables', replace
	
	** Article 2
	use "$main/data/$country_fullname/cs_s10b_goods.dta", clear
	* check duplicates durable items within each households
		order hhid, first
		rename weight 							hh_weight
	
	summ s10bq4a s10bq4b s10bq4c s10bq5a s10bq5b s10bq5c
	recode s10bq4b s10bq4c s10bq5b s10bq5c (999999=0)
	recode s10bq4a s10bq5a (99999999=0)
	
	keep hhid hh_weight s10bq1 s0q19y s10bq3by s10bq4b s10bq5b
	drop if inlist(s10bq3by,0,.,9999) 
	/* Input data: Value of item when purchased =s10bq4b (old value)
				current value of the durable goods =s10bq5b (current vlaue)
				Age of the durable =s10bq3by
	*/
	* age of second item
	gen age=(2000+s0q19y)-s10bq3by
	replace age =0 if age == -1
	
	gen oldval=s10bq4b
	gen curval=s10bq5b
	* update old value with 2013 current price
	* Generate an inflator variable to make past value real (for 1985 to 2013)
	* (2010=100 ; source = World Bank DDP database, as of 8/16/2016)
	
	gen realval =oldval if age == 0	
	replace realval =oldval * 117.0527278 / 112.2971888 if age == 1
	replace realval =oldval * 117.0527278 / 105.6706827 if age == 2
	replace realval =oldval * 117.0527278 / 100 if age == 3
	replace realval =oldval * 117.0527278 / 97.74297189 if age == 4
	replace realval =oldval * 117.0527278 / 88.53996364 if age == 5
	replace realval =oldval * 117.0527278 / 76.69454409 if age == 6
	replace realval =oldval * 117.0527278 / 70.3098977 if age == 7
	replace realval =oldval * 117.0527278 / 64.57390934 if age == 8
	replace realval =oldval * 117.0527278 / 59.2344621 if age == 9
	replace realval =oldval * 117.0527278 / 52.76978823 if age == 10
	replace realval =oldval * 117.0527278 / 49.11115448 if age == 11
	replace realval =oldval * 117.0527278 / 48.15169091 if age == 12
	replace realval =oldval * 117.0527278 / 46.5941171 if age == 13
	replace realval =oldval * 117.0527278 / 44.84535896 if age == 14
	replace realval =oldval * 117.0527278 / 45.95090657 if age == 15
	replace realval =oldval * 117.0527278 / 43.26417244 if age == 16
	replace realval =oldval * 117.0527278 / 38.62340691 if age == 17
	replace realval =oldval * 117.0527278 / 35.95839647 if age == 18
	replace realval =oldval * 117.0527278 / 27.01692795 if age == 19
	replace realval =oldval * 117.0527278 / 18.07545943 if age == 20
	replace realval =oldval * 117.0527278 / 16.08789797 if age == 21
	replace realval =oldval * 117.0527278 / 14.68404298 if age == 22
	replace realval =oldval * 117.0527278 / 12.27381381 if age == 23
	replace realval =oldval * 117.0527278 / 11.78070148 if age == 24
	replace realval =oldval * 117.0527278 / 11.662874 if age == 25
	replace realval =oldval * 117.0527278 / 11.32552693 if age == 26
	replace realval =oldval * 117.0527278 / 10.87601942 if age == 27
	replace realval =oldval * 117.0527278 / 10.99888428 if age == 28
	
	* calculating depreciating rate of each type of durables
	gen deprate=1-(curval/realval)^(1/age)
	sum deprate, d
	sort s10bq1
	egen meddepr=median(deprate), by(s10bq1)
	tab s10bq1, summ(meddepr)
	*assumes real interest rate of 5 %
	gen useValue2 = (meddepr+0.05)*curval/(1-meddepr)
	drop if useValue2 < 0
	
	keep hhid hh_weight s10bq1 useValue2
	sort hhid hh_weight s10bq1
	
	sort hhid s10bq1 
	merge 1:1 hhid s10bq1 using `durables'
	tab _
	drop _
	sort hhid s10bq1
	save `durables', replace
	
	** Article 3
	use "$main/data/$country_fullname/cs_s10b_goods.dta", clear
	* check duplicates durable items within each households
		order hhid, first
		rename weight 							hh_weight
	
	
	summ s10bq4a s10bq4b s10bq4c s10bq5a s10bq5b s10bq5c
	recode s10bq4b s10bq4c s10bq5b s10bq5c (999999=0)
	recode s10bq4a s10bq5a (99999999=0)
	
	keep hhid hh_weight s10bq1 s0q19y s10bq3cy s10bq4c s10bq5c
	drop if inlist(s10bq3cy,0,.,9999) 
	/* Input data: Value of item when purchased =s10bq4c (old value)
				current value of the durable goods =s10bq5c (current vlaue)
				Age of the durable =s10bq3by
	*/
	* age of third item
	gen age=(2000+s0q19y)-s10bq3cy
	replace age =0 if age == -1
	
	gen oldval=s10bq4c
	gen curval=s10bq5c
	* update old value with 2013 current price
	* Generate an inflator variable to make past value real (for 1985 to 2013)
	* (2010=100 ; source = World Bank DDP database, as of 8/16/2016)
	
	gen realval =oldval if age == 0	
	replace realval =oldval * 117.0527278 / 112.2971888 if age == 1
	replace realval =oldval * 117.0527278 / 105.6706827 if age == 2
	replace realval =oldval * 117.0527278 / 100 if age == 3
	replace realval =oldval * 117.0527278 / 97.74297189 if age == 4
	replace realval =oldval * 117.0527278 / 88.53996364 if age == 5
	replace realval =oldval * 117.0527278 / 76.69454409 if age == 6
	replace realval =oldval * 117.0527278 / 70.3098977 if age == 7
	replace realval =oldval * 117.0527278 / 64.57390934 if age == 8
	replace realval =oldval * 117.0527278 / 59.2344621 if age == 9
	replace realval =oldval * 117.0527278 / 52.76978823 if age == 10
	replace realval =oldval * 117.0527278 / 49.11115448 if age == 11
	replace realval =oldval * 117.0527278 / 48.15169091 if age == 12
	replace realval =oldval * 117.0527278 / 46.5941171 if age == 13
	replace realval =oldval * 117.0527278 / 44.84535896 if age == 14
	replace realval =oldval * 117.0527278 / 45.95090657 if age == 15
	replace realval =oldval * 117.0527278 / 43.26417244 if age == 16
	replace realval =oldval * 117.0527278 / 38.62340691 if age == 17
	replace realval =oldval * 117.0527278 / 35.95839647 if age == 18
	replace realval =oldval * 117.0527278 / 27.01692795 if age == 19
	replace realval =oldval * 117.0527278 / 18.07545943 if age == 20
	replace realval =oldval * 117.0527278 / 16.08789797 if age == 21
	replace realval =oldval * 117.0527278 / 14.68404298 if age == 22
	replace realval =oldval * 117.0527278 / 12.27381381 if age == 23
	replace realval =oldval * 117.0527278 / 11.78070148 if age == 24
	replace realval =oldval * 117.0527278 / 11.662874 if age == 25
	replace realval =oldval * 117.0527278 / 11.32552693 if age == 26
	replace realval =oldval * 117.0527278 / 10.87601942 if age == 27
	replace realval =oldval * 117.0527278 / 10.99888428 if age == 28
	
	* calculating depreciating rate of each type of durables
	gen deprate=1-(curval/realval)^(1/age)
	sum deprate, d
	sort s10bq1
	egen meddepr=median(deprate), by(s10bq1)
	tab s10bq1, summ(meddepr)
	*assumes real interest rate of 5 %
	gen useValue3 = (meddepr+0.05)*curval/(1-meddepr)
	drop if useValue3 < 0
	
	keep hhid hh_weight  s10bq1 useValue3
	sort hhid s10bq1 
	merge 1:1 hhid s10bq1 using `durables'
	tab _
	drop _
	sort hhid s10bq1
	
	egen totdur = rsum(useValue1 useValue2 useValue3)
	
	ren s10bq1 product_code
	replace product_code=600 + product_code
	* Map source item codes to COICOP
	tostring product_code, replace force
	replace product_code="0911" if product_code=="605"
	replace product_code="0830" if product_code=="606"
	replace product_code="0911" if product_code=="607"
	replace product_code="0911" if product_code=="608"
	replace product_code="0911" if product_code=="609"
	replace product_code="0911" if product_code=="610"
	replace product_code="0911" if product_code=="611"
	replace product_code="0913" if product_code=="612"
	replace product_code="0511" if product_code=="613"
	replace product_code="0530" if product_code=="614"
	replace product_code="0530" if product_code=="615"
	replace product_code="0530" if product_code=="616"
	replace product_code="0530" if product_code=="617"
	replace product_code="0530" if product_code=="618"
	replace product_code="0530" if product_code=="619"
	replace product_code="0530" if product_code=="620"
	replace product_code="0530" if product_code=="621"
	replace product_code="0530" if product_code=="622"
	replace product_code="0530" if product_code=="623"
	replace product_code="0530" if product_code=="624"
	replace product_code="0912" if product_code=="625"
	replace product_code="0912" if product_code=="626"
	
	
	gen agg_value_on_period =totdur
	
	keep if agg_value_on_period > 0 & agg_value_on_period~=.
	tostring product_code, replace
	ta product_code

	gen TOR_original = . 
	replace TOR_original = 9 if TOR_original == . 
	
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Small shop/boutique" 2 "Supermarket/big shop" 3 "Specialized shop"
	4 "Market" 5 "Mobile seller" 6 "Individual"
	7 "Service provider" 8 "Bar/restaurant" 9 "Other" 10 "Do not ever buy" 11 "Self Production" 12 "From a household" 98 "Don't know" 99 "Missing" 
	;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == . 
	
	gen product_code_label = "Housing"
	gen product_code_original = 9995
	
	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code  product_code_label product_code_original
	tostring product_code, replace force
	
	tempfile durables_final
	save `durables_final'
	
	*Append all the modules
	use `diary', clear 
	append using `diary2'
	append using `recall_month'
	append using `recall_year'
	append using `housing'
	append using `self_conso'
	append using `education'
	append using `transfers1'
	append using `transfers2'
	append using `durables_final'

	
	*coicop_2dig
	replace product_code = subinstr(product_code, ".", "",.) 
	destring product_code, replace
	gen str6 new_product_code = substr(string(product_code,"%04.0f"), 1,4) if product_code<=1270
	replace new_product_code = substr(string(product_code,"%07.0f"), 1,4) if product_code>1270
	drop product_code
	rename new_product_code product_code
	destring product_code, replace
	tostring product_code, replace
	gen coicop_2dig = substr(product_code,1,2)  //extract first 2-digits of product code to identify housing expenses ,
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code TOR_original TOR_original_name  agg_value_on_period TOR_original_name coicop_2dig housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace



***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

// Not needed

************************************************************
*   Step 3: Generating total expenditures and total income *
************************************************************
**********************************
*   Step 3.1: Total expenditures *
**********************************
	*We construct the necessary variables and use the same names for all countries : exp_total, exp_housing, exp_noh
	*exp_total
	by hhid: egen exp_total = sum(agg_value_on_period) 
	
	*exp_housing
	by hhid: egen exp_rent = sum(agg_value_on_period) if coicop_2dig == "41" // actual rent as expenses
	by hhid: egen exp_ir = sum(agg_value_on_period) if coicop_2dig == "42" // imputed rent as expenses
	gen exp_ir_withzeros = exp_ir
	replace exp_ir_withzeros = 0 if exp_ir_withzeros == .
	gen exp_rent_withzeros = exp_rent
	replace exp_rent_withzeros = 0 if exp_rent_withzeros == .
	gen exp_housing = exp_ir_withzeros + exp_rent_withzeros
	
	*exp_noh
	gen exp_noh = exp_total - exp_housing	// Expenses without imputed rent and without actual rent
	
	*We keep only the relevant variables
	keep hhid exp_total exp_housing exp_noh
	
***************************
*   Step 3.2 Total income *
***************************

	* This step will require to investigate the following datafiles : 
	
************************************************************
*   Step 3.3: Merge with the household covariates datafile *
************************************************************

	collapse (mean) exp_total exp_housing exp_noh  , by(hhid)
	merge 1:1 hhid using "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	keep if _merge ==3
	drop _merge
	
	save "$main/proc/$country_fullname/${country_code}_household_cov.dta", replace


*******************************************************************
* Step 4: Crosswalk between places of purchase and classification *
*******************************************************************
*[Output = Note in country report explaining choices]
   
	clear 
	set more off
	use "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	*We have decided to not take housing into account
	drop if housing == 1
	
	set more off
	label list
	capture label drop TOR_original_label
	collapse (sum) agg_value_on_period, by (TOR_original TOR_original_name)
	rename agg_value_on_period expenses_value_aggregate
	egen total_exp = sum(expenses_value_aggregate)  
	gen pct_expenses = expenses_value_aggregate / total_exp 
	order TOR_original_name TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,11,12)
	replace detailed_classification=2 if inlist(TOR_original,4,5,6)
	replace detailed_classification=3 if inlist(TOR_original,1)
	replace detailed_classification=4 if inlist(TOR_original,3)
	replace detailed_classification=5 if inlist(TOR_original,2)
	replace detailed_classification=7 if inlist(TOR_original,7)
	replace detailed_classification=8 if inlist(TOR_original,8)
	replace detailed_classification=99 if inlist(TOR_original,9,98,10,99)




	export excel using "$main/tables/$country_fullname/${country_fullname}_TOR_stats_for_crosswalk.xls", replace firstrow(variables) sheet("TOR_codes")
	*Note: This table is exported to keep track of the crosswalk between the original places of purchases and our classification 
	
	*We remove mising values, destring and label some variables for clarity/uniformity 
	#delim ; 
	label define detailed_classification_label 
	1 "1: non-market" 2 "2: no store front" 3 "3: convenience and corner shops"
	4 "4: specialized shops" 5 "5: large stores" 6 "6: institutions" 
	7 "7: service from individual" 8 "8: entertainment" 9 "9: informal entertainment" 
	99 "99: unspecified" ;
	#delim cr
	label list detailed_classification_label
	label values detailed_classification detailed_classification_label // assign it
	ta detailed_classification
	
	*We merge with expenditures dataset
	merge 1:m TOR_original using "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"

	*We keep all household expenditures and relevant variables
    keep hhid product_code TOR_original TOR_original_name agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	destring product_code, replace
	gen str6 COICOP_2dig = substr(string(product_code,"%04.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(product_code,"%04.0f"), 1,3) 
	gen str6 COICOP_4dig = substr(string(product_code,"%04.0f"), 1,4) 

	*We destring and label some variables for clarity/uniformity 
	destring COICOP_2dig, force replace											
	destring COICOP_3dig, force replace											
	destring COICOP_4dig, force replace											

	merge m:1 COICOP_2dig using "$main/proc/COICOP_label_2dig.dta"
	drop if _merge == 2
	drop _merge
	drop COICOP_2dig
	ren COICOP_Name2 COICOP_2dig
	
	merge m:1 COICOP_3dig using "$main/proc/COICOP_label_3dig.dta"
	drop if _merge == 2
	drop _merge
	drop COICOP_3dig
	ren COICOP_Name3 COICOP_3dig
	
	merge m:1 COICOP_4dig using "$main/proc/COICOP_label_4dig.dta"	
	drop if _merge == 2	
	drop _merge
	drop COICOP_4dig
	ren COICOP_Name4 COICOP_4dig
	
	
	*We save the database with all expenditures for the price/unit analysis
	save "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" , replace

	*We create the final database at the COICOP_4dig level of analysis
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig  detailed_classification) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item  TOR_original detailed_classification  housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
