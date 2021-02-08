

					*************************************
					* 			Main DO FILE			*
					* 	      COSTA RICA 2014				*
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

	
	global country_fullname "Costa_Rica2014"
	global country_code "CR"
	
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
	
*****************************	
	
/*
ENIGH_2013_BASE_GASTOS_EXTENDIDA_PUBLICA.dta
All expenditures, sources of income, debts, transfers,... with one line per economic activity. Extended version. Includes TOR variable.  

ENIGH_2013_BASE_GASTOS.dta
All expenditures, sources of income, debts, transfers,... with one line per economic activity.

ENIGH_2013_BASE_HOGARES.dta
Household level general statistics, one line per household. 	

ENIGH_2013_BASE_PERSONAS.dta
Individual level general statistics, one line per person. 	
*/



*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear	
	set more off
	use "$main/data/$country_fullname/ENIGH_2013_BASE_HOGARES.dta", clear


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	egen hhid = concat(UPM_CONSEC ID_VIVIENDA ID_HOGAR)
	rename FACTOR_EXPANSION 					hh_weight
	rename ID_REGION							geo_loc // region is representative geographic unit
	rename ID_ZONA 								urban // this is already defined as rural, urban
	rename H082_SEXO_JEFE						head_sex
	rename H083_EDAD_JEFE						head_age
	rename H084_ESCOLARIDAD_JEFE				head_edu
	
	rename H202_INGRESO_TOTAL_NETO_SVL 			income							// Income without imputed rent
	rename H203_INGRESO_TOTAL_NETO_CVL			income_noh						// Income with imputed rent 
		
	rename H313_GASTO_TOTAL_HOGAR_SVL 			expenses						// Expenses without imputed rent
	rename H314_GASTO_TOTAL_HOGAR_CVL			expenses_noh					// Expenses with imputed rent 
	
	rename H078_CANT_MIEMBROS_HOGAR 			hh_size
	rename H002_TENENCIA						house_owner 					// this information could be very useful if imputed rent/actual rent data is not good enough: VIVIENDAS dataset. 
	
	rename H238_GASTO_ALQUILERES 				house_rent 						// Monto de la renta mensual: VIVIENDAS dataset 
	
	rename H302_VALOR_LOCATIVO					imputed_rent_house				// Valor Locativo estimado por el hogar
	rename H303_VALOR_LOCATIVO_IMPUTADO			imputed_rent_estimate			// Valor locativo imputado
	

	*We need to construct/modify some of them
	*census_block
	gen census_block = UPM_CONSEC //best guess; this is used to make HHID	

	*geo_loc_min
	gen geo_loc_min = census_block // here there is no other variable to sort of distinguish the two? 

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
	use "$main/data/$country_fullname/ENIGH_2013_BASE_GASTOS_EXTENDIDA_PUBLICA.dta", replace
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	egen hhid = concat(UPM_CONSEC ID_VIVIENDA ID_HOGAR)
	rename DONDE_ADQU 						TOR_original  
	rename GAST_MENS 						amount_paid					// Monthly expenses on the item
	rename CANT_MENS						quantity							// cantidad adquirida convertida a mes
	rename CCIF 							product_code
	rename TIPO_GASTO						CoicopType	
	rename COMO_PAGO						payment_method
	
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period=amount_paid*12

	*product_code
	destring product_code, replace
	drop if product_code>1270
	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	destring TOR_original, force replace
	ta TOR_original

	decode TOR_original , gen(TOR_original_name)

	
	*We keep all household expenditures and relevant variables
	keep hhid product_code TOR_original TOR_original_name   quantity  amount_paid agg_value_on_period   coicop_2dig housing
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
	collapse (sum) agg_value_on_period, by (TOR_original TOR_original_name)
	rename agg_value_on_period expenses_value_aggregate
	egen total_exp = sum(expenses_value_aggregate)  
	gen pct_expenses = expenses_value_aggregate / total_exp 
	order TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,25,26,27,28)
	replace detailed_classification=2 if inlist(TOR_original,5,7,29,15,24)
	replace detailed_classification=3 if inlist(TOR_original,8)
	replace detailed_classification=4 if inlist(TOR_original,4,6,19,22,30,14,21,16,18)
	replace detailed_classification=5 if inlist(TOR_original,1,2,20)
	replace detailed_classification=6 if inlist(TOR_original,32,37,36,38,39,40,34,23,35,17,31)
	replace detailed_classification=8 if inlist(TOR_original,9,10,11,13,14,15,26,41)
	replace detailed_classification=9 if inlist(TOR_original,3,12)
	replace detailed_classification=99 if inlist(TOR_original,33,49,50,0)




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
    keep hhid product_code TOR_original  agg_value_on_period coicop_2dig  housing detailed_classification TOR_original  pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
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
	
	
