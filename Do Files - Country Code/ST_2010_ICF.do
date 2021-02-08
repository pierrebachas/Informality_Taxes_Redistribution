

					*************************************
					* 			Main DO FILE			*
					* 	      SAO TOME & PRINCIPE 2010	*
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

	
	global country_fullname "SaoTome2010"
	global country_code "ST"
	
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
*Weight variable is called fexp_cen2010 [the expansion factor]
1. Miebros del Hogar (Personas).dta: Contains info of all people that make up households, with demographic, educational, etc. variables
2. Indentificacion.dta - has weight variable as well as total household income, total spending, and some variable called relation
   which is described as relation income-expenditure (I imagine its some sort of variable for savings)?
3. Gastos Diarios Seccion II: daily monetary and non-monetary expenses in food, beverages, and tobacco. 
4. Gastos Diarios Seccion III: daily monetary and non-monetary expenses. 
5. Gastos Diarios Seccion IV: daily monetary and non-monetary expenses. 
6. Gastos Mensuales: monthly expenses
7. Gastos Trimenstrales: quarterly expenses
8. Gastos Semestrales: half year expenses
9. Gastos Anuales: annual expenses

*additional modules on benefits but maybe the total income variable is okay? 
*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear
	set more off
	use "$main/data/$country_fullname/CQ01.dta", clear
	ren IDENT hhid
	tostring hhid , replace
	tempfile geo
	save `geo'
	
	clear
	set more off
	use "$main/data/$country_fullname/CQ05.dta", clear
	tostring IDENT, replace
	gen hhid=substr(IDENT,1,6)
	keep if V07_Q05 == 1
	tempfile demo_indiv
	save `demo_indiv'
	
	
	clear
	set more off
	use "$main/data/$country_fullname/CQ06.dta", clear
	
	*hhid
	tostring IDENT, replace
	gen hhid=substr(IDENT,1,6)
	merge m:1 IDENT using `demo_indiv'
	merge m:1 hhid using `geo' , gen(mgeo)
	keep if _merge==3
	keep if mgeo==3

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	
	ren ID_3 geo_loc
	ren ID_5 geo_loc_min // 82 unique values
	ren ID_6 census_block // 104 unique values
	ren V05_Q05 head_age
	ren V04_Q05 head_sex
	ren V04A_Q06 head_edu
	ren NBL06 hh_size // nb membros


	*We need to construct/modify some of them
	
	*exp_agg_tot, *inc_agg_tot
	
	*hh_weight
	gen hh_weight =1
	

	*urban
	gen urban = 1 if ID_4 == 1 | ID_4 == 2 | ID_4 == 3 | ID_4 == 8 | ID_4 == 12 | ID_4 == 14 | ID_4 == 15 | ID_4 == 18
	replace urban = 0 if ID_4 == 4 | ID_4 == 5 | ID_4 == 6 | ID_4 == 7 | ID_4 == 9 | ID_4 == 10 | ID_4 == 11 | ID_4 == 13 | ID_4 == 16 | ID_4 == 17
	

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
	keep if V07_Q05 == 1

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


	
************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************

	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	
	*DIARY
	clear
	set more off
	use "$main/data/$country_fullname/CQ09.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	tostring IDENT, replace
	gen hhid=substr(IDENT,1,6)
	
	rename V08_Q09							TOR_original 
	rename V02_Q09							product_code 						// COICOP 
	rename V04_Q09							quantity 							// Quantidade
	rename V05_Q09							price								// Unit price
	rename V03_Q09							unit
	rename V06_Q09							amount_paid
	
	gen agg_value_on_period = (365/15)*amount_paid
	keep hhid TOR_original product_code price quantity agg_value_on_period amount_paid unit
	save "$main/data/$country_fullname/expenses/adj_CQ09.dta", replace
	
	*DIARY ANNUAL
	
	clear
	set more off
	use "$main/data/$country_fullname/CQ11.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	tostring IDENT, replace
	gen hhid=substr(IDENT,1,6)
	
	rename V07_Q11							TOR_original 
	rename V03_Q11							product_code 						// COICOP 
	rename V05_Q11							quantity 	// Quantidade
	rename V04_Q11							unit 
	rename V06_Q11							amount_paid
	
	gen agg_value_on_period = amount_paid
	gen price = agg_value_on_period/quantity
	keep hhid TOR_original product_code price quantity agg_value_on_period amount_paid unit
	save "$main/data/$country_fullname/expenses/adj_CQ11.dta", replace
	

	*RECALL
	
	local file_num "CQ12 CQ12C CQ13 CQ14 CQ15 CQ15C CQ16 CQ17 CQ18 CQ19 CQ20 CQ21 CQ22 CQ23 CQ24 CQ25 CQ26 CQ27 CQ28" 
	local annualization_factor "2 2 2 2 1 1 4 1 2 1 2 1 2 1 1 4 1 2 1"
*	local file_qt_mont " 11 al 12 12a 13 13a 14 14a 15 15a 16 16a 17 17a 18 18a 19 19a 20 20a 21 21a" 
	local file_qt "12 12C 13 14 15 15C 16 17 18 19 20 21 22 23 24 25 26 27 28" 
	local n_models : word count `file_num'	
	
forval i=1/`n_models' {
	
		***************
		* GLOBALS	 *
		***************	

		global file_num `: word `i' of `file_num''	
		global annualization_factor `: word `i' of `annualization_factor''

		**********************
		* LOAD SURVEY 	 *
		**********************	
		
		use "$main/data/$country_fullname/$file_num.dta", clear
		tostring IDENT, replace
		gen hhid=substr(IDENT,1,6)
		gen agg_value_on_period = . 
		replace agg_value_on_period = V07_Q`: word `i' of `file_qt'' *$annualization_factor
		gen amount_paid=V07_Q`: word `i' of `file_qt_t''
		gen TOR_original= V05_Q`: word `i' of `file_qt''						// Type of retailer
		gen product_code=V02_Q`: word `i' of `file_qt''						// COICOP
		gen quantity=V04_Q`: word `i' of `file_qt''
		gen unit=V03_Q`: word `i' of `file_qt''
		gen module_tracker = "$file_num"
		save "$main/data/$country_fullname/expenses/adj_$file_num.dta", replace
	
}
	
	*We append all the expense files together
	
	cd "$main/data/$country_fullname/expenses"
	fs "*.dta"
	append using `r(files)'
	
	
	
	*We need to construct/modify some of them
	
	*coicop_2dig
	gen str_product_code= product_code 
	gen coicop_2dig = substr(str_product_code,2,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	replace agg_value_on_period=agg_value_on_period*0.001

	
	drop if product_code > 13000000 // only keep monetary expenses;
	drop if product_code==.
	

	destring TOR_original, force replace
	ta TOR_original
	
	replace TOR_original = 22 if TOR_original == . 
	drop if TOR_original==1 // Vetement donné
	
	#delim ; // create the label
	label define TOR_original_label 
1 "Prendas Dadas" 2 "Prendas Recebidas" 3 "Auto Consumo"
4 "Autoabastecimento" 5 "Mercado" 6 "Quiosque / Quitanda"
7 "Candongueiro" 8 "Vendedor Ambulante" 9 "Grandes Lojas"
10 "Lojas modernas" 11 "Outros comercios modernos" 
12 "Hotels, restaurantes, bares, cafes"
13 "Prestates de servicios individuais" 14 "Prestates de servicios publicos" 15 "Sector de transportes" 16 "Clinicas laboratorios medicos Hospitais"
17 "Agregados" 18 "Estrangeiros" 19 "Supermercado" 20 "Campo, mato" 21 "Praia" 22 "Missing" 23 "Other" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	*sort hhid
	*egen food = min(coicop_2dig), by(hhid)
	*keep if food == 1
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code str_product TOR_original TOR_original_name   quantity price unit amount_paid  agg_value_on_period coicop_2dig TOR_original_name housing
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
	gen detailed_classification=1 if inlist(TOR_original,2,20,4,3,14,21,17)
	replace detailed_classification=2 if inlist(TOR_original,8,5)
	replace detailed_classification=3 if inlist(TOR_original,6)
	replace detailed_classification=4 if inlist(TOR_original,11)
	replace detailed_classification=5 if inlist(TOR_original,9,10,19)
	replace detailed_classification=6 if inlist(TOR_original,18,16,15)
	replace detailed_classification=7 if inlist(TOR_original,13,7)
	replace detailed_classification=8 if inlist(TOR_original,12)
	replace detailed_classification=99 if inlist(TOR_original,22)


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
    keep hhid product_code str_product TOR_original TOR_original_name  quantity price unit amount_paid agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen str6 COICOP_2dig = substr(string(product_code,"%08.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(product_code,"%08.0f"), 1,3) 
	gen str6 COICOP_4dig = substr(string(product_code,"%08.0f"), 1,4) 

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
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig  detailed_classification  quantity price unit amount_paid) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item  TOR_original detailed_classification  housing  quantity price unit amount_paid , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
