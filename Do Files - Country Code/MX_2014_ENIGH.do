

					*************************************
					* 			Main DO FILE			*
					* 	      	MEXICO 2010				*
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

	
	global country_fullname "Mexico2014"
	global country_code "MX"
	
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
	ncv_concentrado_2014_concil_2010_stata.dta
Household level general statistics, one line per household. 	
	
	ncv_gastohogar_2014_concil_2010_stata.dta
All expenditures, sources of income, debts, transfers,... with one line per economic activity.
*/			



******************************
* Step 0:  Important Note    *
******************************

*A crosswalk is needed to assign COICOP codes, see Step 2.2 and Excel attached	

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear	
	set more off
	use "$main/data/$country_fullname/ncv_concentrado_2014_concil_2010_stata.dta", clear



	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	egen hhid = concat(folioviv foliohog)
	rename factor_hog 							hh_weight
	rename ubica_geo							geo_loc	
	rename tam_loc 								density 
	rename sexo_jefe							head_sex
	rename edad_jefe							head_age
	rename educa_jefe							head_edu
	rename ing_cor 								inc_agg_tot
	rename gasto_mon							exp_agg_tot
	rename tot_integ 							hh_size


	*We need to construct/modify some of them
	*geo_loc_min, census_block
	gen geo_loc_min = geo_loc
	gen census_block = geo_loc 
	*urban 
	gen urban = 0
	replace urban = 1 if density == "1" | density =="2"	
	
	
	*We destring and label some variables for clarity/uniformity 
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace					// Some of these variables are already numeric
	destring urban , replace 
	
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
 
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block density inc_agg_tot exp_agg_tot
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
	use "$main/data/$country_fullname/ncv_gastohogar_2014_concil_2010_stata.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	egen hhid = concat(folioviv foliohog)
	rename lugar_comp 						TOR_original 
	rename gasto_tri 						agg_value_on_period		
	rename gas_nm_tri						agg_value_on_period_nm				// non-monetary expenses 			
	rename tipo_gasto						CoicopType			
	rename cantidad							quantity 							// cantidad de articulos o servicios
	rename gasto							amount_paid

	*We need to construct/modify some of them
	
	
	*agg_value_on_period
	replace agg_value_on_period=agg_value_on_period*4
	drop if agg_value_on_period == . & agg_value_on_period_nm == .
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	
	* TOR_original
	replace TOR_original = "19" if CoicopType == "G3" //make a self-consumption category
	replace agg_value_on_period = agg_value_on_period_nm if CoicopType == "G3" 

	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
	0 "No aplica" 1 "Mercado" 2 "Tianguis o mercado sobre ruedas" 3 "Vendedores ambulantes"
	4 "Tiendas de abarrotes" 5 "Tiendas específicas del ramo" 6 "Supermercados"
	7 "Tiendas departamentales" 8 "Compras fuera del país" 9 "Tiendas con membresía"
	10 "Tiendas de conveniencia" 11 "Restaurantes" 
	12 "Loncherías, fondas, torterías , cocinas económicas, cenadurías"
	13 "Cafeterías" 14 "Pulquería, cantina o bar" 15 "Diconsa" 16 "Lechería Liconsa"
	17 "Persona particular" 18 "Internet" 19 "Self consumption";
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	
	*We keep all household expenditures and relevant variables
	keep hhid  TOR_original clave agg_value_on_period agg_value_on_period_nm TOR_original_name quantity amount_paid  CoicopType
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_no_COICOP.dta", replace



***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************


	clear
	set more off
	use "$main/waste/$country_fullname/${country_code}_all_lines_no_COICOP.dta" , clear 
	merge m:1 clave using "$main/data/$country_fullname/${country_code}_ENIGH_crosswalk_COICOP.dta"

	drop if _merge == 2	// This are codes in the crosswalk for which there is no use in the diary (2 observations deleted)
	drop _merge
	
	
	gen str4 COICOP_4st = string(COICOP_4dig,"%04.0f")
	gen str3 COICOP_3st = string(COICOP_3dig,"%03.0f")
	gen str2 COICOP_2st = string(COICOP_2dig,"%02.0f")
	
	drop COICOP_4dig COICOP_3dig COICOP_2dig
	
	rename COICOP_4st COICOP_4dig
	rename COICOP_3st COICOP_3dig
	rename COICOP_2st COICOP_2dig
	
	
	replace COICOP_3dig = substr(COICOP_4dig, 1,3) if COICOP_3dig == "."	 
	replace COICOP_2dig = substr(COICOP_3dig, 1,2) if COICOP_2dig == "."
	replace COICOP_2dig = substr(COICOP_Code, 1,2) if COICOP_2dig == "."		// The order is very important  
	replace COICOP_3dig = substr(COICOP_Code, 1,3) if COICOP_3dig == "." 
	replace COICOP_4dig = substr(COICOP_Code, 1,4) if COICOP_4dig == "." 
	
	
	*housing
	gen housing=1 if COICOP_4dig== "0411" | COICOP_4dig == "0412" |  COICOP_4dig == "0421" | COICOP_4dig=="0422"	

	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta" , replace


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
	bys hhid: egen exp_rent = sum(agg_value_on_period) if COICOP_4dig== "0411" | COICOP_4dig == "0412" // actual rent as expenses
	bys hhid: egen exp_ir = sum(agg_value_on_period_nm) if COICOP_4dig == "0421" | COICOP_4dig=="0422"	 // imputed rent as expenses
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
	gen detailed_classification=1 if inlist(TOR_original,19)
	replace detailed_classification=2 if inlist(TOR_original,17,3,2,1)
	replace detailed_classification=3 if inlist(TOR_original,10,4)
	replace detailed_classification=4 if inlist(TOR_original,5)
	replace detailed_classification=5 if inlist(TOR_original,6,7,9)
	replace detailed_classification=6 if inlist(TOR_original,16,15,18,8)
	replace detailed_classification=8 if inlist(TOR_original,11)
	replace detailed_classification=9 if inlist(TOR_original,12,13,14)
	replace detailed_classification=99 if inlist(TOR_original,0)




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
    keep hhid  TOR_original TOR_original_name agg_value_on_period COICOP_4dig COICOP_3dig  COICOP_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig


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
	erase "$main/waste/$country_fullname/${country_code}_all_lines_no_COICOP.dta"
	
	
