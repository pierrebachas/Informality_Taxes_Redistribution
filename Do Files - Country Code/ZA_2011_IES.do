

					*************************************
					* 			Main DO FILE			*
					* 	      South Africa 2011			*
					*************************************



***************
* DIRECTORIES *
***************

if "`c(username)'"=="wb520324" { 													// Eva's WB computer 
	global main "C:/Users/wb520324/Dropbox/Regressivity_VAT/Stata"		
}	

else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath
	display "`c(current_date)' `c(current_time)'"


********************************************************************************
********************************************************************************

	
	global country_fullname "SouthAfrica2011"
	global country_code "ZA"
	
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
	IES 2010-2011 House_info_v1
Household level general statistics, one line per household. 	
	
	Total v1
All expenditures, sources of income, debts, transfers,... with one line per economic activity.

	Person_info_v1 has information on the individual level. We need it for the age of household head for example. 

*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear	
	set more off
	use "$main/data/$country_fullname/IES 2010-2011 Person_info_v1.dta", clear
	rename UQNO hhid
	bysort hhid: egen head_age = max(Q14AGE) if Q15RELATIONSHIP == 1
	bysort hhid: egen head_edu = max(Q21HIGHESTLEVEL) if Q15RELATIONSHIP == 1
	keep if Q15RELATIONSHIP == 1
	duplicates drop hhid, force
	tempfile demo
	save `demo'

	clear	
	set more off
	use "$main/data/$country_fullname/IES 2010-2011 House_info_v1.dta", clear
	rename UQNO 				hhid

	merge 1:1 hhid using `demo'	
	

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename Full_calwgt 			hh_weight
	rename Income 				income
	rename Consumptions			expenses
	rename Hsize 				hh_size 
	rename Q52MAINDWELLING  	house_owner 
	rename Q554VALUEDU			house_est_num
	rename Q555ESTIMATEDVALUE 	house_est_cat
	rename GenderOfHead 		head_sex
	rename PopGrpOfHead 		head_ethnicity
	rename Province 			geo_loc
	rename Settlement_type		density
	

	*We need to construct/modify some of them
	
	*geo_loc_min
	egen geo_loc_min = concat(geo_loc density)

	*census_block
	gen census_block = substr(hhid, 1,11)	
	
	*urban
	gen urban = 0
	replace urban = 1 if density == 1 | density ==2	

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
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block 
	order hhid, first 
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , replace
	


************************************************************
* Step 2: Renaming and labelling the expenditures database *
************************************************************

************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************


	clear 
	set more off
	use "$main/data/$country_fullname/IES 2010-2011 Total_v1.dta", replace
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename UQNO 							hhid
	rename Full_calwgt 						hh_weight
	rename TOR 								TOR_original 
	rename Valueannualized					agg_value_on_period
	
	
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	destring TOR_original, force replace
	ta TOR_original
	ta TOR_original, nolabel
	replace TOR_original = 8 if TOR_original == 9
	replace TOR_original = 9 if Coicop == 99111202 | Coicop == 99111212

	#delim ; // create the label
	label define TOR_original_label 
	1 "Chain store" 2 "Internet"
	3 "Other retailer" 4 "Street trading" 5 "Other"
	6 "Not applicable" 7 "Do not know" 8 "Unspecified" 9 "From a household";
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	tempfile all_lines
	save `all_lines'


***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

* Some codes are unique to the South African survey
* Taking the first four digits leads to 4 digits codes which do not belong to the COICOP classification
* Solution: use the product codes table from the data files where are the corresponding COICOP_4dig codes

	import excel using "$main/data/$country_fullname/ZA_IES_crosswalk_COICOP.xls", firstrow clear
	rename COICOP_code Coicop
	destring Coicop, replace
	rename ThirdGroup COICOP_4dig
	keep Coicop COICOP_4dig Item
	
	tempfile coicop
	save `coicop'


	use `all_lines', clear
	merge m:1 Coicop using `coicop' ,  keepusing(COICOP_4dig Item)

	*Some corrections are needed 
	destring COICOP_4dig, replace
	replace COICOP_4dig = 0119 if COICOP_4dig == 0199	// Unclassified expenditures on Food
	replace COICOP_4dig = 0220 if COICOP_4dig == 0221	// Other items smoked
	replace COICOP_4dig = 0441 if COICOP_4dig == 0440	// Water and Electricity moved to Water (approximation)
	replace COICOP_4dig = 0520 if COICOP_4dig == 0521	// Other household textiles
	replace COICOP_4dig = 0540 if COICOP_4dig == 0541 //	Kitchen and domestic utensils
	replace COICOP_4dig = 0630 if COICOP_4dig == 0631 //	Hospital service fees (eg wards; beds and theatre fees) in private institutions
	replace COICOP_4dig = 0810 if COICOP_4dig == 0811 //	Other postage
	replace COICOP_4dig = 0820 if COICOP_4dig == 0821 //	Cellular phones
	replace COICOP_4dig = 0830 if COICOP_4dig == 0831 //	Private calls
	replace COICOP_4dig = 0960 if COICOP_4dig == 0961 //	Holiday tour package
	replace COICOP_4dig = 1010 if COICOP_4dig == 1011 //	Pre-primary education in public institutions
	replace COICOP_4dig = 1020 if COICOP_4dig == 1021 //	Secondary education (includes out-of-school secondary education for adults and young people) in public institution
	replace COICOP_4dig = 1040 if COICOP_4dig == 1041 //	Tertiary education Education not definable by level (excluding driving and music lessons; sport etc) in public institutions
	replace COICOP_4dig = 1050 if COICOP_4dig == 1051 //	Vocational training in public institutions
	replace COICOP_4dig = 1120 if COICOP_4dig == 1121 //	Boarding and lodging
	replace COICOP_4dig = 1240 if COICOP_4dig == 1241 //	Day-care mothers; creches and playgrounds in public institutions
	replace COICOP_4dig = 1270 if COICOP_4dig == 1271 //	Other expenditure
	replace COICOP_4dig = 1270 if COICOP_4dig == 8888 //	Unclassified Diary Items except food
	replace COICOP_4dig = 1270 if COICOP_4dig == 9911 //	Other expenditure/transfers


	*coicop_2dig
	tostring COICOP_4dig, generate(str_COICOP_4dig) 
	gen coicop_2dig = substr(str_COICOP_4dig,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring COICOP_4dig, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	* We keep only the consumption
	keep if CoicopType == 1	| Coicop == 99111202 | Coicop == 99111212		// We eliminate income and other lines from the dataset

	
	
	*We keep all household expenditures and relevant variables
	keep hhid COICOP_4dig TOR_original TOR_original_name agg_value_on_period coicop_2dig housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace


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
	gen detailed_classification=1 if inlist(TOR_original,9)
	replace detailed_classification=2 if inlist(TOR_original,4,5)
	replace detailed_classification=4 if inlist(TOR_original,3)
	replace detailed_classification=5 if inlist(TOR_original,1)
	replace detailed_classification=6 if inlist(TOR_original,2)
	replace detailed_classification=99 if inlist(TOR_original,6,7,8)



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
    keep hhid COICOP_4dig TOR_original TOR_original_name agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen str6 COICOP_2dig = substr(string(COICOP_4dig,"%04.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(COICOP_4dig,"%04.0f"), 1,3) 

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
	
	
