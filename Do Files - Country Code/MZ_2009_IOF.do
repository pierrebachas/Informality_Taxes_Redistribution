

					*************************************
					* 			Main DO FILE			*
					* 	      MOZAMBIQUE 2009			*
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

	
	global country_fullname "Mozambique2009"
	global country_code "MZ"
	
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
* agregado_v3.dta , controle_v3.dta : demographics datasets 
* despesas_diarias_v3.dta, despesas_mensais_v3.dta bens_duraveis_v3.dta, autoconsumo_v3.dta, receita_v3.dta : consumption datasets 

*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear
	set more off
	use "$main/data/$country_fullname/agregado_v3.dta", clear
	rename id00			hhid																// Add household id
	drop if af03 != 1 	// We keep only houshold heads and single-person households
	duplicates drop hhid, force
	tempfile aggregates
	save `aggregates'
	
	
	clear	
	set more off
	use "$main/data/$country_fullname/controle_v3.dta", clear
	rename id00			hhid																// Add household id

	merge m:1 hhid using `aggregates'
 	keep if _merge == 3
	drop _merge
	
	merge m:1 id07 using "$main/data/$country_fullname/iof_ponderadores3.dta"
	keep if _merge == 3
	drop _merge
	


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename pond_final 							hh_weight						// From the iof_ponderadores3 dataset 
	rename id06 								urban 							// Urbano/Rural
	rename af04									head_sex
	rename af05									head_age
	rename af23b								head_edu
	rename total	 							hh_size							// From the controle_v3 dataset
	rename religiao								head_ethnicity 					// From the controle_v3 dataset
	rename id01									geo_loc // 11
	rename id02c								geo_loc_min //145

	*We need to construct/modify some of them
	
	*exp_agg_tot : Look in agregado_v3.dta
	*inc_agg_tot
	egen personal_income = rowtotal(af53 af55 af65 af66) 
	bysort hhid: egen inc_agg_tot = total(personal_income)	
	
	*census_block
	gen str2 id01_st = string(geo_loc,"%02.0f")
	gen str2 id02_st = string(id02,"%02.0f")
	gen str2 id04_st = string(id04,"%02.0f")
	egen census_block = concat(id01_st id02_st id04_st)

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
 	drop if af03 != 1

	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block 
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
	use "$main/data/$country_fullname/despesas_diarias_v3.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename id00		    					hhid
	rename dd12 							TOR_original 
	rename dd10								product_code
	rename dd2								product_name
	rename dd4								quantity
	rename dd9								unit 
	rename dd5								amount_paid 

	
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = amount_paid* 365/7
	
	*product_code
	drop if product_code==1111371 | product_code==561291
	

	gen module_tracker = "Diary 1"
	tempfile diary
	save `diary'
	
	*DIARY 2
	
	clear 
	set more off

	use "$main/data/$country_fullname/despesas_mensais_v3.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename id00		    					hhid
	rename dm7 								TOR_original 
	rename dm1								product_code
	rename dm2								product_name
	rename dm4								quantity
	rename dm8								unit 
	rename dm5								amount_paid 
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = amount_paid* 12
	


	gen module_tracker = "Diary 2"
	tempfile diary2
	save `diary2'
	
	*DURABLES
	clear 
	set more off
	use "$main/data/$country_fullname/bens_duraveis_v3.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename id00		    					hhid
	rename bd3								product_code
	rename bd2								product_name
	rename bd5								quantity
	rename bd6								amount_paid // Cuanto pago?
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = amount_paid	
	
	*TOR_original
	gen TOR_original=4
	
	gen module_tracker="Durables"
	tempfile durables
	save `durables'
	
	
	
	*SELF CONSO
	clear
	set more off
	use "$main/data/$country_fullname/autoconsumo_v3.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename id00		    					hhid
	rename ac9								product_code
	rename ac2								product_name
	rename ac4								quantity
	rename ac11								unit 
	rename ac8								amount_paid // cuanto pago o tendra que pagar?

	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = amount_paid* 365/7
	
	*TOR_original
	gen TOR_original=5

	gen module_tracker="Self-Consumption"
	tempfile self_conso
	save `self_conso'
	
	*TRANSFERS
	clear
	set more off
	use "$main/data/$country_fullname/receita_v3.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename id00		    					hhid
	rename re11								product_code
	rename re6								quantity
	rename re10								amount_paid // cuanto pago o tendra que pagar?

	*We need to construct/modify some of them
	*agg_value_on_period 
	gen agg_value_on_period = amount_paid * 365/7
	
	*TOR_original
	gen TOR_original=6

	gen module_tracker="Transfers"
	tempfile transfers
	save `transfers'
	
	*
	clear
	set more off
	use "$main/data/$country_fullname/verificacao_de_produtos_v3.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename id00		    					hhid
	rename vp1								product_code
	rename vp1a								product_name
	rename vp4								quantity
	rename vp5								unit 
	rename vp7								amount_paid // cuanto pago o tendra que pagar?

	*We need to construct/modify some of them
	*agg_value_on_period 
	gen agg_value_on_period = amount_paid * 365/7

	gen module_tracker="Verif"
	tempfile verif
	save `verif'
	
	*EDUCATION
	clear
	set more off	
	use "$main/data/$country_fullname/agregado_v3.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	gen hhid = id00																// Add household id
	gen str8 hhid_st = string(hhid, "%08.0f")									// UNIQUE FOR MOZAMBIQUE
	drop hhid
	rename hhid_st hhid
	
	
	
	gen str2 pp_st = string(af01, "%02.0f")										// UNIQUE FOR MOZAMBIQU
	egen ppid = concat(hhid pp_st)												// This dataset has expenses per person. So, we need to create a person_id
	drop pp_st
 
	
	keep hhid ppid id01 id02 id02c id03 id04 id05 id06 id07 id08 af31a_1 af31b_1 af31c_1 af31d_1
	
	rename af31a_1 af31_1 
	rename af31b_1 af31_2
	rename af31c_1 af31_3
	rename af31d_1 af31_4
											
	reshape long af31_ , i(ppid) j(COICOP_code) 								// VERY IMPORTANT: it allows us to append with other modules later
	
	
	rename af31 		amount_paid
	*We need to construct/modify some of them
	*product_code
	gen product_code = 105111 if COICOP_code == 1
	replace product_code = 095111 if COICOP_code == 2
	replace product_code = 031232 if COICOP_code == 3
	replace product_code = 073211 if COICOP_code == 4
	
	*TOR_original
	gen TOR_original = 4

	*agg_value_on_period 
	gen agg_value_on_period = amount_paid 

	destring hhid, replace2.2
	
	gen module_tracker="Education"
	tempfile edu
	save `edu'
	
	*HEALTH
	clear 
	set more off
	use "$main/data/$country_fullname/agregado_v3.dta", clear
	
	gen hhid = id00																// Add household id
	gen str8 hhid_st = string(hhid, "%08.0f")									// UNIQUE FOR MOZAMBIQUE
	drop hhid
	rename hhid_st hhid
	
	gen str2 pp_st = string(af01, "%02.0f")										// UNIQUE FOR MOZAMBIQU
	egen ppid = concat(hhid pp_st)												// This dataset has expenses per person. So, we need to create a person_id
	drop pp_st
	
	order hhid ppid, first														// 10832 households
	sort hhid ppid																// 51177 persons 
	
	keep hhid ppid id00 id01 id02 id02c id03 id04 id05 id06 id07 id08 af39a af39c af39e
	
	rename af39a af39_1 
	rename af39c af39_2
	rename af39e af39_3
									
	reshape long af39_ , i(ppid) j(COICOP_code) 								// VERY IMPORTANT: it allows us to append with other modules later
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename af39_ 			amount_paid
	
	
	*We need to construct/modify some of them

	*We need to construct/modify some of them
	*product_code
	gen product_code = 062111 if COICOP_code == 1
	replace product_code = 062111 if COICOP_code == 2
	replace product_code = 062112 if COICOP_code == 3
	
	*TOR_original
	gen TOR_original = 4

	*agg_value_on_period 
	gen agg_value_on_period = amount_paid *12

	destring hhid, replace
	gen module_tracker="Health"
	tempfile health
	save `health'
	
	
	*Append all the modules
	use `diary', clear 
	append using `diary2'
	append using `durables'
	append using `self_conso'
	append using `edu'
	append using `health'
	append using `transfers'

	
	
	*coicop_2dig
	gen product_code2= substr(string(product_code,"%07.0f"), 1,6) if product_code>=312691
	gen product_code_str=product_code
	tostring product_code_str , replace
	replace product_code_str= product_code2 if product_code2!=""
	drop product_code
	ren product_code_str product_code
	destring product_code, replace
	
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	*COICOP_2dig
	gen COICOP_2dig= substr(string(product_code,"%06.0f"), 1,2) 

	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	replace TOR_original = 4 if TOR_original == 9 //change "sem informacao" to 4 which is "outro"
	replace TOR_original = 4 if TOR_original == .
	
	#delim ; // create the label
	label define TOR_original_label 
1 "loja" 2 "mercado" 3 "mercado informal"
4 "outro" 5 "auto produção" 6 "transferências" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	
	*We keep all household expenditures and relevant variables
	keep hhid id07 product_code COICOP_2dig module_tracker TOR_original TOR_original_name  quantity unit amount_paid agg_value_on_period  TOR_original_name coicop_2dig housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw_no_TOR.dta" , replace

**********************
*  IMPUTATION OF TOR * 
**********************

	use "$main/waste/$country_fullname/${country_code}_all_lines_raw_no_TOR.dta" , clear 
	
	merge m:1 id07 using "$main/data/$country_fullname/iof_ponderadores3.dta"
	keep if _merge == 3
	drop _merge
	
	ren pond_final			hh_weight
	
	egen total_exp = sum(agg_value_on_period), by(hhid)
	xtile decile = total_exp [weight=hh_weight], nq(10) 
	
	preserve
	keep if module_tracker=="Durables"
	egen dec_coicop = concat(decile COICOP_2dig)
	tempfile durable
	save `durable'
	restore
	
	drop if module_tracker=="Durables"
	tempfile all_expenses_no_durables
	save `all_expenses_no_durables' 
	
	
	*Count how many not missing by decile
	ta COICOP_2dig, m
	bys COICOP_2dig: ta TOR_original
	bys decile COICOP_2dig: egen sum_cons_COICOP=total(agg_value_on_period)  
	bys decile COICOP_2dig TOR_original: egen sum_cons_TOR=total(agg_value_on_period)  
	gen share_cons_TOR_COICOP=sum_cons_TOR/sum_cons_COICOP 
	
	
	forval i = 1/6 {
	bys decile COICOP_2dig TOR_original: egen share_`i'prep=mean(share_cons_TOR_COICOP) if TOR_original==`i' 
	bys decile COICOP_2dig: egen share`i'=mean(share_`i'prep) 
	}

	keep decile  COICOP_2dig share1 share2 share3 share4 share5 share6 
	duplicates drop COICOP_2dig decile share1 share2 share3 share4 share5 share6 , force
	egen dec_coicop = concat(decile COICOP_2dig)
	forval i = 1/6 {
	replace share`i'=0 if share`i'==.
	}
	

	
	
	
	*Merge with durable 
	
	merge 1:m dec_coicop using `durable'
	collapse (sum) agg_value_on_period , by(hhid quantity unit module  amount_paid hh_weight product_code     decile COICOP_2dig dec_coicop share1- share6)
	reshape long share, i(hhid product_code hh_weight agg_value_on_period  module decile dec_coicop COICOP_2dig ) j(TOR_original)

	gen new_agg_value_on_period= agg_value_on_period*share
	drop if new_agg_value_on_period==.
	
	replace agg_value_on_period=new_agg_value_on_period if new_agg_value_on_period!=.
	
	
	ta TOR_original, m
	append using `all_expenses_no_durables'
	
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta" , replace



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
	bys hhid: egen exp_total = sum(agg_value_on_period) 
	
	*exp_housing
	bys hhid: egen exp_rent = sum(agg_value_on_period) if coicop_2dig == "41" // actual rent as expenses
	bys hhid: egen exp_ir = sum(agg_value_on_period) if coicop_2dig == "42" // imputed rent as expenses
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
	collapse (sum) agg_value_on_period, by (TOR_original)
	rename agg_value_on_period expenses_value_aggregate
	egen total_exp = sum(expenses_value_aggregate)  
	gen pct_expenses = expenses_value_aggregate / total_exp 
	order  TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,6,5)
	replace detailed_classification=2 if inlist(TOR_original,2,3)
	replace detailed_classification=4 if inlist(TOR_original,1)
	replace detailed_classification=99 if inlist(TOR_original,4,9,999)




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
	gen str6 COICOP_2dig = substr(string(product_code,"%06.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(product_code,"%06.0f"), 1,3) 
	gen str6 COICOP_4dig = substr(string(product_code,"%06.0f"), 1,4) 

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
	save "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" 

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
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw_no_TOR.dta"

	
