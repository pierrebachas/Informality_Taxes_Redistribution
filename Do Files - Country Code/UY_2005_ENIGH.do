

					*************************************
					* 			Main DO FILE			*
					* 	      URUGUAY 2005				*
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

	
	global country_fullname "Uruguay2005"
	global country_code "UY"
	
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
*Weight variable is called facexp [the expansion factor]
1. persona.dta: Contains info of all people that make up households, with demographic, educational, etc. variables
2. consumos.dta: diary of consumption, with the place of purchase, etc. 
3. hogar.dta: contains variable on hh size
4. mpersona.dta: contains aggregate info on income, benefits, etc. 
*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear
	set more off
	use "$main/data/$country_fullname/persona.dta", clear
	egen hhid = concat(viv hog)
	drop if d21 != "1"
	duplicates drop hhid, force
	tempfile demo_indiv
	save `demo_indiv'
	
	clear	
	set more off
	use "$main/data/$country_fullname/hogar.dta", clear
	*hhid
	egen hhid = concat(viv hog)
	merge m:1 hhid using `demo_indiv' 	
	destring *, replace


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename facexp 								hh_weight
	rename dpto									geo_loc // 19 unique values
	rename loc									geo_loc_min // 55 unique values
	rename d22									head_sex
	rename d23									head_age
	rename d271									head_edu
	rename totpers_h2 							hh_size
	
	

	
	*We need to construct/modify some of them
	
	*exp_agg_tot // This file does not have these variables but they may exist in another datafile (peut-etre fichier_emplois_toute_personne) that we should merge here
	
	*inc_agg_tot
*	clear
*	set more off 
*	use "$main/data/$country_fullname/mpersona.dta"	
*	egen hhid = concat(viv hog)
*	destring * , replace
*	bys hhid: egen income_monthly = sum(i1)
*	gen income = 12*income_monthly
*	save "$main/waste/$country_fullname/income.dta", replace
	
	*urban
	gen urban = .
	replace urban = 1 if inrange(est, 1, 4)
	replace urban = 1 if inrange(est, 8, 28)
	replace urban = 0 if inrange(est, 5, 7)
	replace urban = 0 if inrange(est, 29, 36)
	
	*census_block
	egen census_block = concat(geo_loc geo_loc_min)
	
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
 
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc census_block geo_loc_min  
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
	use "$main/data/$country_fullname/consumos.dta", clear

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	*Note that here we don't take into account CQ03 which is the module gathering events expenses (in the questionnaire it is the module CQ23 but it appears as CQ03 in the microdata)
	

	rename FACEXP 							hh_weight
	rename DONDE 							TOR_original 
	rename CCIFDEF							product_code //COICOP
	rename COMO								payment_method

	

	
	
	*We need to construct/modify some of them
	*hhid
	egen hhid = concat(VIV HOG)
	

	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	*agg_value_on_period
	gen agg_value_on_period = VALORCONTM*12 

	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0

	drop if product_code > 1270499 // only keep monetary expenses;
	drop if product_code==.
	

	destring TOR_original, force replace	
	replace TOR_original = 42 if TOR_original == 98 | TOR_original == 99
	#delim ; 
	label define TOR_original_label 
0 "No corresponde " 1 "Almacen" 2 "Autoservicio, Cadena de Supermercados" 
5 "Panaderia, Confiteria" 6 "Carniceria, Polleria, Pescaderia"
7 "Rotiseria" 8 "Fabrica de pastas" 9 "Feria vecinal"
10 "Verduleria, Puesto, Fruteria" 11 "Distribuidor o repartidor a domicilio" 
12 "Vendedor ambulante, Puesto callejero, Carrito"
13 "Agropecuaria, semilleria" 14 "Farmacia, Perfumeria, Panalera" 15 "Quiosco, Salon" 16 "Fabrica, Mayorista"
17 "Papeleria, Libreria" 18 "Merceria, Tienda" 19 "Cibercafe" 20 "Estacion de servicio" 21 "Bar, Pizzeria" 22 "Restaurante, Parrillada" 23 "Comida rapida, Plaza de comidas" 24 "Heladeria" 25 "Cantina, Trabajo, Colegio"
26 "Boliches nocturnos" 27 "Jugueteria" 28 "Zapateria, Marroquineria, Talabarteria" 29 "Muebleria" 30 "Casa de electrodomesticos, telefonos"
31 "Casa de computacion" 32 "Casa de musica" 33 "Casa de remates" 34 "Shopping o galeria" 35 "Expoferia" 36 "Casa de articulos usados" 37 "Veterinaria" 
38 "Barraca, ferreteria, vidrieria" 39 "Fuera del pais" 40 "Internet"
41 "Almacen de ramos generales" 42 "Missing" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original
	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name


	
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code str_product TOR_original TOR_original_name  agg_value_on_period coicop_2dig TOR_original_name housing
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
	gen detailed_classification=1 if inlist(TOR_original,13,36,11)
	replace detailed_classification=2 if inlist(TOR_original,15,35,12,9)
	replace detailed_classification=3 if inlist(TOR_original,1,41)
	replace detailed_classification=4 if inlist(TOR_original,38,20,31,32,33,37,14,30,29,28,27,18,17,10,8,7,6,5)
	replace detailed_classification=5 if inlist(TOR_original,2,16,34)
	replace detailed_classification=6 if inlist(TOR_original,39,40)
	replace detailed_classification=8 if inlist(TOR_original,22,25)
	replace detailed_classification=9 if inlist(TOR_original,19,26,21,23,24)
	replace detailed_classification=99 if inlist(TOR_original,0,42)




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
    keep hhid product_code str_product TOR_original TOR_original_name agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen str6 COICOP_2dig = substr(string(product_code,"%07.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(product_code,"%07.0f"), 1,3) 
	gen str6 COICOP_4dig = substr(string(product_code,"%07.0f"), 1,4) 

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
	
	
