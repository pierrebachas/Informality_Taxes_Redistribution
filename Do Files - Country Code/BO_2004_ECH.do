

					*************************************
					* 			Main DO FILE			*
					* 	      BOLIVIA 2004				*
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

	
	global country_fullname "Bolivia2004"
	global country_code "BO"
	
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
	PublicPoblacionyVivienda.dta
Household level general statistics, one line per household. There is rent info here. 	
	
	PublicGastoCorriente.dta
All expenditures, place of purchase info ... with one line per economic activity. 
Product codes do not seem to follow COICOP, need crosswalk?

*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear
	set more off
	use "$main/data/$country_fullname/PublicPoblacionyVivienda.dta", clear
	
	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	rename folio 								hhid	
	rename fe4_red 								hh_weight		//  household weight is computed from population in upm
	rename a1_02								head_sex
	rename a1_03								head_age
	rename nivedu								head_edu
	rename miembros 							hh_size
	rename urb_rur								urban
	rename dpto									geo_loc			// departamento 
	rename upm									census_block


	
	*We need to construct/modify some of them
	
	*geo_loc_min
	egen geo_loc_min = group(geo_loc decena)


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
 
	keep hhid hh_weight geo_loc geo_loc_min census_block urban head_sex head_age head_edu hh_size
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

	clear 
	set more off
	use "$main/data/$country_fullname/PublicGastoCorriente.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename folio 							hhid
	rename clucobo	 						TOR_original_nonagg //  365 categories, need to aggregate
	rename ccifbo							product_code // not COICOP - Clasificación del consumo individual por finalidades CCIF
	rename gpperiod							amount_paid // not sure this is correct, documentation not good, should check
	rename periodo							frequency 
	rename cumbo 							unit
	decode product_code, gen(product_code_label)


	
	
	*We need to construct/modify some of them
	*agg_value_on_period
	rename qperiod quantity
	gen agg_value_on_period	= . 
	replace agg_value_on_period = amount_paid*52 if frequency == 1 // semanal
	replace agg_value_on_period = amount_paid*12 if frequency == 2 // mensual
	replace agg_value_on_period = amount_paid*3  if frequency == 3 // trimestral
	replace agg_value_on_period = amount_paid 	  if frequency == 4 // anual
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	tempfile all_lines_no_TOR
	save `all_lines_no_TOR'
	
	*There is more than 365 TOR categories, we use a crosswalk to aggregate them
	egen exp_total = sum(agg_value_on_period)									// Total expenses (monetary only)
	sort TOR_original_nonagg
	by TOR_original_nonagg: egen exp_by_TOR = sum(agg_value_on_period)
	
	keep TOR_original_nonagg exp_total exp_by_TOR
	decode(TOR_original_nonagg), generate(TOR)
	tostring TOR_original_nonagg, force replace
	destring TOR_original_nonagg, replace
	
	
	duplicates drop TOR_original_nonagg, force
	sort TOR_original_nonagg
	gen share_exp = exp_by_TOR/exp_total
	
	keep TOR_original_nonagg TOR share_exp
	
	export excel using "$main/tables/$country_fullname/TOR_raw.xlsx", firstrow(variables) replace

	*merge in the TOR crosswalk
	
	import excel using "$main/tables/$country_fullname/BO_ECH_crosswalk_TOR.xlsx", firstrow clear
	destring TOR_original_nonagg, replace
	
	merge 1:m TOR_original_nonagg using `all_lines_no_TOR', nogen 
	
	sort recode recode_label
	ta recode_label
			
	ren recode TOR_original 
	destring TOR_original, force replace
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "auto consumo" 2 "tienda especializada" 3 "otros"
	4 "mercado" 5 "feria" 6 "puesto/kiosco"
	7 "vendedor ambulante" 8 "hotel, bar, restaurante" 9 "utilidades"
	10 "transporte" 11 "taller" 
	12 "supermercado" 13 "tienda de conveniencia" 14 "cantina" 15 "institución de salud" 16 "instituto educativo"
	17 "recreación" 18 "internet" 19 "institución religiosa" 20 "instituciones financieras" 21 "missing" 22 "de un hogar / transferencia" 23 "comunicación" 24 "servicio individual";
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	
	*We keep all household expenditures and relevant variables
	keep hhid product_code product_code_label TOR_original TOR_original_name  quantity unit amount_paid agg_value_on_period Estr2dig Estr3dig Estr4dig  
	
	decode Estr2dig, gen(Estr2dig_name)
	decode Estr3dig, gen(Estr3dig_name)
	decode Estr4dig, gen(Estr4dig_name)
	
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw_before_crosswalk.dta", replace



***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

	use "$main/waste/$country_fullname/${country_code}_all_lines_raw_before_crosswalk.dta", clear
	
	gen str_product_code = product_code
	
	duplicates report str_product_code 
	duplicates drop str_product_code, force // 999 unique products
	export excel product_code_label str_product_code using "$main/tables/$country_fullname/${country_code}_productcode_crosswalk.xlsx", replace
	*by hand crosswalk - copy cells from the file above into the file called product_code_crosswalk_2dig 
	*and then make an additional column with the 2dig-level crosswalk
	
	
	* Full Crosswalk
	use "$main/waste/$country_fullname/${country_code}_all_lines_raw_before_crosswalk.dta", clear
	
	sort Estr2dig Estr3dig Estr4dig
	egen tag_COICOP_4dig = tag(Estr4dig)
	keep Estr2dig Estr3dig Estr4dig Estr2dig_name Estr3dig_name  Estr4dig_name 
	export excel using "$main/tables/$country_fullname/${country_code}BO_ECH_crosswalk_COICOP.xlsx", replace firstrow(variables)
	

	import excel using "$main/tables/$country_fullname/${country_code}_productcode_raw_data_Estr4dig_level_crosswalk.xlsx", clear firstrow
	
	drop Estr2dig Estr3dig Estr2dig_name Estr3dig_name Estr4dig
	tostring COICOP_2dig, replace
	tostring COICOP_3dig, replace
	tostring COICOP_4dig, replace
	merge 1:m Estr4dig_name using "$main/waste/$country_fullname/${country_code}_all_lines_raw_before_crosswalk.dta", nogen 

	* Note: specific code for "monthalized health expenditures"
	* Not easy to classify but retailer is almost always "health institutions so I assume it is close to health services
	* very few obs anyway
	

	decode hhid, gen(str_hhid)
	drop hhid
	ren str_hhid hhid
	destring hhid, replace

	*housing
	gen housing = 1 if COICOP_3dig == "41"				// Actual rent
	replace housing = 1 if COICOP_3dig == "42"				// Imputed rent as expense
	
	
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace


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
	by hhid: egen exp_rent = sum(agg_value_on_period) if COICOP_3dig == "41" // actual rent as expenses
	by hhid: egen exp_ir = sum(agg_value_on_period) if COICOP_3dig == "42" // imputed rent as expenses
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
	gen detailed_classification=1 if inlist(TOR_original,22,1)
	replace detailed_classification=2 if inlist(TOR_original,7,6,5,4)
	replace detailed_classification=3 if inlist(TOR_original,11,13)
	replace detailed_classification=4 if inlist(TOR_original,2)
	replace detailed_classification=5 if inlist(TOR_original,12)
	replace detailed_classification=6 if inlist(TOR_original,23,10,9,20,19,16,15)
	replace detailed_classification=7 if inlist(TOR_original,24)
	replace detailed_classification=8 if inlist(TOR_original,18,8)
	replace detailed_classification=9 if inlist(TOR_original,14,17)
	replace detailed_classification=99 if inlist(TOR_original,3,21)




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
    keep hhid product_code COICOP_2dig COICOP_3dig COICOP_4dig TOR_original TOR_original_name agg_value_on_period  TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
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
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw_before_crosswalk.dta"

	
	
