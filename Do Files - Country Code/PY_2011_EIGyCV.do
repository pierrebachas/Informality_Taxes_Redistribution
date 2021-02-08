
					*************************************
					* 			Main DO FILE			*
					* 	      	PARAGUAY 2011			*
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

	
	global country_fullname "Paraguay2011"
	global country_code "PY"
	
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
1. Datos de la vivienda y del Hogar reg01.dta: Contains info at the households level
2. Datos de la poblacion reg02t.dta: Contains info at the individual level
3. Agregado a nivel de transaccion  agregado.dta: daily monetary and non-monetary expenses in food, beverages, and tobacco. 
*/

*Il reste a coder le auto produccion et regarder si meilleurevaleur pour aggreagt total
*envoyer a pierre le IEC + lui dire que jai les données enterprise
*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

	clear
	set more off
	use "$main/data/$country_fullname/Datos de la poblacion reg02t.dta", clear
	
	*hhid
	gen str6 str_upm = substr(string(upm,"%03.0f"), 1,3) 
	gen str6 str_nvivi = substr(string(nvivi,"%03.0f"), 1,3)
	gen str6 str_nhoga = substr(string(nhoga,"%02.0f"), 1,2)
	egen hhid = concat(str_upm str_nvivi str_nhoga ) //5417
	
	drop if p02 != 1 //keep only household heads and single-person households
	duplicates drop hhid, force
	tempfile demo_indiv
	save `demo_indiv'
	
	clear	
	set more off
	use "$main/data/$country_fullname/Datos de la vivienda y del Hogar reg01.dta", clear
	
	*hhid
	gen str6 str_upm = substr(string(upm,"%03.0f"), 1,3) 
	gen str6 str_nvivi = substr(string(nvivi,"%03.0f"), 1,3)
	gen str6 str_nhoga = substr(string(nhoga,"%02.0f"), 1,2)
	egen hhid = concat(str_upm str_nvivi str_nhoga ) //5417
	merge m:1 hhid using `demo_indiv'
 	keep if _merge == 3


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename fex			 						hh_weight
	rename dptorep								geo_loc //7
	rename stratomuestral						geo_loc_min // 13
	rename upm									census_block
	rename area 								urban 
	rename p05									head_sex
	rename edad									head_age
	rename ed04									head_edu
	rename total 								hh_size
	*rename p07									head_ethnicity
	

	*We need to construct/modify some of them
	
	*exp_agg_tot
	*gen expenses = gasto*12 // This info can be found in Gastos a nivel de hogar sumaria_hogar.dta

	*inc_agg_tot
	*gen income = ingreso*12 // This info can be found in Gastos a nivel de hogar sumaria_hogar.dta
	

	*We destring and label some variables for clarity/uniformity 
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace					// Some of these variables are already numeric
	
	ta head_sex, missing
	replace head_sex=2 if head_sex==6
	label define head_sex_lab 1 "Male" 2 "Female"
	label values head_sex head_sex_lab
	
	ta urban
	ta urban, nol
	replace urban = 0 if urban == 6
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


	* GASTOS ALIMENTARIOS DEL HOGAR
	clear 
	set more off
	use "$main/data/$country_fullname/Agregado a nivel de transaccion  agregado.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename fex								hh_weight
	rename ga03d 							TOR_original 
	rename ga01c							product_code
	rename ga01e							product_name
	rename ga03f							frequency // Need to take into account ? 
	rename iga03c							quantity_comprando
	rename iga05c							quantity_auto_prod
	rename ga03u							unit 
	rename idga04_ri						amount_paid_comprando 
	rename idga05g_ri						amount_paid_auto_prod  
	rename ga02a							mean // 
	rename divisionIPC						coicop_2dig
	*It's a prefilled diary
	keep if ga01==1 // Keep if the hh has the good
	drop if excluidos==1 // Not taken into account in aggregates 
	*We need to construct/modify some of them
	*hhid
	gen str6 str_upm = substr(string(upm,"%03.0f"), 1,3) 
	gen str6 str_nvivi = substr(string(nvivi,"%03.0f"), 1,3)
	gen str6 str_nhoga = substr(string(nhoga,"%02.0f"), 1,2)
	egen hhid = concat(str_upm str_nvivi str_nhoga ) //5417
	
	*agg_value_on_period
	replace amount_paid_comprando=0 if amount_paid_comprando==.
	replace amount_paid_auto_prod=0 if amount_paid_auto_prod==.
	
	gen agg_value_on_period = (amount_paid_comprando+amount_paid_auto_prod)*12
	
	*coicop_2dig
	gen housing = 1 if product_code == 301101001 |  product_code == 301101003 //rent
	replace housing = 1 if product_code == 303101001	//imputado			
	replace housing = 1 if product_code == 301101002				
	


	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	
	ta TOR_original
	replace TOR_original=47 if mean==2 
	replace TOR_original=48 if mean==3
	replace TOR_original=49 if mean==4 
	replace TOR_original=50 if mean==5 
	replace TOR_original=51 if mean==6 
	replace TOR_original=52 if mean==7 
	replace TOR_original=53 if mean==8 
	replace TOR_original=54 if mean==9 


	replace TOR_original=99 if TOR_original==88
	replace TOR_original=99 if TOR_original==.

	
	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name 
	
	replace TOR_original_name="Producido por el hogar" if mean==2 
	replace TOR_original_name="Retirado del negocio" if mean==3
	replace TOR_original_name="Como parte de pago a un miembro del hogar" if mean==4 
	replace TOR_original_name="Regalado o pagado por algún miembro de otro hogar" if mean==5 
	replace TOR_original_name="Regalado o donado por algún programa social público" if mean==6 
	replace TOR_original_name="Otra institución (ONG’S), iglesia" if mean==7 
	replace TOR_original_name="Otro (Especifique)" if mean==8 
	replace TOR_original_name="Cubierto por el seguro" if mean==9 
	replace TOR_original_name="Other" if TOR_original==99
	label val TOR_original
	
	

	
	*We keep all household expenditures and relevant variables
	keep hhid product_code TOR_original TOR_original_name  quantity_comprando quantity_auto_prod unit amount_paid_comprando amount_paid_auto_prod agg_value_on_period  TOR_original_name coicop_2dig housing
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
	by hhid: egen exp_rent = sum(agg_value_on_period) if housing ==1 // actual rent as expenses
	by hhid: egen exp_ir = sum(agg_value_on_period) if housing ==1 // imputed rent as expenses
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

/*test
	use "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata/data/Paraguay2011/Gastos a nivel de hogar sumaria_hogar.dta" , clear 
	gen str6 str_upm = substr(string(upm,"%03.0f"), 1,3) 
	gen str6 str_nvivi = substr(string(nvivi,"%03.0f"), 1,3)
	gen str6 str_nhoga = substr(string(nhoga,"%02.0f"), 1,2)
	egen hhid = concat(str_upm str_nvivi str_nhoga ) //5417
	destring hhid, replace

	merge 1:1 hhid using "$main/proc/$country_fullname/${country_code}_household_cov.dta"
	keep if _merge ==3
*/
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
	gen detailed_classification=1 if inlist(TOR_original,47,48,49,50,51,52,53)
	replace detailed_classification=2 if inlist(TOR_original,3,6)
	replace detailed_classification=3 if inlist(TOR_original,4,10,26)
	replace detailed_classification=4 if inlist(TOR_original,5,8,9,11,12,13,17,18,21,22,23,24,25,27,29,34,35,36,37,45,46)
	replace detailed_classification=5 if inlist(TOR_original,1)
	replace detailed_classification=6 if inlist(TOR_original,30,31,32,33,38,39,40,41,42,54)
	replace detailed_classification=7 if inlist(TOR_original,16,28,44)
	replace detailed_classification=8 if inlist(TOR_original,2,7,14,15,19)
	replace detailed_classification=99 if inlist(TOR_original,20,99)



	export excel using "$main/tables/$country_fullname/${country_fullname}_TOR_stats_for_crosswalk.xls", replace firstrow(variables) sheet("TOR_codes") locale(C)
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
	gen  COICOP_2dig = coicop_2dig
	gen str6 product_code_3dig = substr(string(product_code,"%09.0f"), 1,3) 
	gen str6 product_code_4dig = substr(string(product_code,"%09.0f"), 1,4) 

	*We destring and label some variables for clarity/uniformity 
	destring COICOP_2dig, force replace											
	destring product_code_3dig, force replace											
	destring product_code_4dig, force replace	
	
	gen product_code_2dig = COICOP_2dig

	/*
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
*/	
	
	*We save the database with all expenditures for the price/unit analysis
	save "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" , replace

	*We create the final database at the COICOP_4dig level of analysis
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original product_code_4dig product_code_3dig product_code_2dig COICOP_2dig  detailed_classification) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid product_code_4dig product_code_3dig product_code_2dig COICOP_2dig exp_TOR_item  TOR_original detailed_classification  housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_product_code_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
