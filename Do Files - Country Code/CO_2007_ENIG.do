

					*************************************
					* 			Main DO FILE			*
					* 	      COLOMBIA 2007				*
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

	
	global country_fullname "Colombia2007"
	global country_code "CO"
	
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

Ig_gsdu_gas_dia.dta
En este capítulo se recoge la información del artículo, cantidad, la unidad de medida expresada en cm3 o gramos, 
cantidad, forma de adquisición, lugar de compra, valor pagado o estimado del bien o servicio.

Ig_ml_vivienda.dta
En este capítulo se dan a conocer las características físicas de la vivienda que permitan determinar 
la calidad de la misma coomo tambien se determina el acceso a servicios públicos domiciliarios.

Ig_ml_hogar.dta
Esta tabla contiene información acerca de las condiciones generales de la vivienda habitada por el hogar.

Ig_ml_persona.dta
la tabla contiene información de las personas del hogar sobre educación, afiliación a salud, 
subsidios de alimentación en instituciones educativas para menores de 3 años y mayores de 3 años.

*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear
	set more off
	use "$main/data/$country_fullname/Ig_ml_persona.dta", clear
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	order hhid, first
	bysort hhid : gen hh_size = _N
	order hh_size, before(P200)
	drop if P200 != 01			 												// We keep only houshold heads. P200 == 1 (Jefe de hogar)
	tempfile demo_indiv
	save `demo_indiv'
	
	clear
	set more off
	use "$main/data/$country_fullname/Ig_gsdu_gas_dia.dta", clear
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	gen urban=1
	keep hhid urban
	duplicates drop hhid , force
	tempfile urban
	save `urban'
	
	clear
	set more off
	use "$main/data/$country_fullname/Ig_gssr_gas_sem.dta", clear
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	gen urban=0
	keep hhid urban
	duplicates drop hhid , force
	append using `urban'

	tempfile geo
	save `geo'
	
	clear	
	set more off
	use "$main/data/$country_fullname/Ig_ml_hogar.dta", clear
	
	*hhid
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop HOGAR_st 
	order hhid, first

	* In this survey, we need to import some variables from the DWELLINGS (VIVIENDA) AND PERSONS (PERSONA) datasets 
	
	* (1) Household heads
	merge m:1 hhid using `demo_indiv', keepusing(P6020 P6040 P6210S1 P6080S1 hh_size) nogen  
	merge  m:1 hhid using `geo' , nogen


	* (2) Dwellings 
	merge m:1 VIVIENDA_st using "$main/waste/$country_fullname/${country_code}_dwellings_original.dta", nogen  
	order geo_loc geo_loc_min census_block departamento dominio clase estrato, after(hhid)
	drop VIVIENDA_st

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	rename FACTOR_EXPANSION_EC_E1 				hh_weight
	rename P6020								head_sex						// Ig_ml_persona
	rename P6040								head_age						// Ig_ml_persona
	rename P6210S1								head_edu						// Ig_ml_persona
	rename P6080S1								head_ethnicity 					// Ig_ml_persona dataset: (Autoadscripción étnica)   							
	rename P5120								house_owner 					// Ig_ml_hogar: this information could be very useful if imputed rent/actual rent data is not good enough. (¿Algún miembro de este hogar tiene titulo de propiedad de esta vivienda?) 
	rename P5090								house_status					// Ig_ml_hogar: La vivienda ocupada por este hogar es:
	rename P5140				 				house_rent 						// Ig_ml_hogar: ¿Cuánto pagan mensualmente por arriendo?: 	
	rename P5130								imputed_rent_estimate			// Ig_ml_hogar: Si tuviera que pagar el arriendo por esta vivienda, ¿cuánto estima que tendria que pagar mensualmente?
	

	*We need to construct/modify some of them
	
	*exp_agg_tot

	*inc_agg_tot
	
	*census_block
	

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


	*DIARY
	clear 
	set more off
	use "$main/data/$country_fullname/Ig_gsdp_gas_dia.dta", clear
	
	*hhid 
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename GDP_LUGAR_CMPRA					TOR_original		
	rename GDP_ARTCLO						product_code	
	rename GDP_VALOR_PGDO_ESTMDO_MES_AJST	agg_value_on_period
	rename GDP_VALOR_PGDO_ESTMDO			amount_paid
	rename GDP_FORMA_ADQSCION 				CoicopType
	rename GDP_CNTDAD_ADQURDA_MES_AJST		quantity // quantity acquired
	
	
	decode product_code, gen(product_code_st)
	drop product_code
	rename product_code_st product_code
	destring product_code,replace	
	

	gen module_tracker = "Diary 1"
	tempfile diary
	save `diary'
	
	*DIARY 2
	
	clear 
	set more off

	use "$main/data/$country_fullname/Ig_gsmf_compra.dta", clear
	
	*hhid 
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename GMF_CMPRA_LUGAR					TOR_original		
	rename GMF_CMPRA_ARTCLO					product_code	
	rename GMF_CMPRA_VLR_PAGO_MES			agg_value_on_period
	rename GMF_CMPRA_VLR_PAGO				amount_paid

	
	decode product_code, gen(product_code_st)
	drop product_code
	rename product_code_st product_code
	destring product_code,replace	
	
	gen module_tracker = "Diary 2"
	tempfile diary2
	save `diary2'
	
	*DIARY 3
	clear 
	set more off

	use "$main/data/$country_fullname/Ig_gsmf_serv_pub.dta", clear
	
	*hhid 
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename GMF_SERV_PUBLICO					product_code	
	rename GMF_PAGO_SERV_PUB_VALOR_MES		agg_value_on_period	
	keep if NUMERO_ENCUESTA==67

	
	*We need to construct/modify some of them
	*TOR_original
	gen TOR_original = 0														// This data set do not have place of purchase

	
	decode product_code, gen(product_code_st)
	drop product_code
	rename product_code_st product_code
	destring product_code,replace	
	
	gen module_tracker="Diary 3"
	tempfile diary3
	save `diary3'
	
	
	
	*DIARY 4
	clear
	set more off
	use "$main/data/$country_fullname/Ig_gsdu_gas_dia.dta", clear
	
	*hhid 
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename GDU_LUGAR_CMPRA					TOR_original		
	rename GDU_ARTCLO						product_code	
	rename GDU_VALOR_PGDO_ESTMDO_MES_AJST	agg_value_on_period
	rename GDU_FORMA_ADQSCION				CoicopType
	rename GDU_CNTDAD_ADQURDA_MES_AJST		quantity // I think?
	rename GDU_VALOR_PGDO_ESTMDO			amount_paid
	rename GDU_UDM_ESTANDAR					unit
	keep if NUMERO_ENCUESTA==18

	
	decode product_code, gen(product_code_st)
	drop product_code
	rename product_code_st product_code
	destring product_code,replace	
	
	*We need to construct/modify some of them
	
	gen module_tracker="Diary 4"
	tempfile diary4
	save `diary4'
	
	*DIARY 5
	clear
	set more off
	use "$main/data/$country_fullname/Ig_gssr_gas_sem.dta", clear
	
	*hhid 
	decode VIVIENDA, gen(VIVIENDA_st)
	decode HOGAR, gen(HOGAR_st)
	egen hhid = concat(VIVIENDA_st HOGAR_st)									// 42.733 hogares
	drop VIVIENDA_st HOGAR_st 
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename GSR_LUGAR_CMPRA					TOR_original		
	rename GSR_ARTCLO						product_code	
	rename GSR_VALOR_PGDO_ESTMDO_MES		agg_value_on_period
	rename GSR_FORMA_ADQSCION				CoicopType
	rename GSR_CNTDAD_UDM_ESTANDAR			quantity // I think?
	rename GSR_VALOR_PGDO_ESTMDO			amount_paid
	rename GSR_UDM_ESTANDAR					unit
	keep if inrange(NUMERO_ENCUESTA,146,183)

	
	decode product_code, gen(product_code_st)
	drop product_code
	rename product_code_st product_code
	destring product_code,replace	
	
	gen module_tracker="Diary 5"
	tempfile diary5
	save `diary5'
	
	
	*Append all the modules
	use `diary', clear 
	append using `diary2'
	append using `diary3'
	append using `diary4'
	append using `diary5'
	
	
													// This makes the files lighter
	


	*product_code
	replace product_code = 12711700 if product_code == 99999999
	replace product_code = 12711700 if product_code == 9999
	replace product_code = 12711700 if product_code == 0000
	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	replace agg_value_on_period = 12 * agg_value_on_period
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	
	replace TOR_original = 25 if CoicopType == 3
	replace TOR_original = 25 if CoicopType == 1 & TOR_original == . //self production category
	replace TOR_original = 26 if CoicopType == 4 | CoicopType == 5	//transfers category
	replace TOR_original = 999 if TOR_original == . 
	destring TOR_original, force replace
	ta TOR_original

	
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code TOR_original   quantity unit amount_paid agg_value_on_period   coicop_2dig housing
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
	collapse (sum) agg_value_on_period, by (TOR_original )
	rename agg_value_on_period expenses_value_aggregate
	egen total_exp = sum(expenses_value_aggregate)  
	gen pct_expenses = expenses_value_aggregate / total_exp 
	order  TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,25,20,26)
	replace detailed_classification=2 if inlist(TOR_original,14,21,13,12)
	replace detailed_classification=3 if inlist(TOR_original,15,9,7,6)
	replace detailed_classification=4 if inlist(TOR_original,8,17,16)
	replace detailed_classification=5 if inlist(TOR_original,1,2,3,4,5,10,11)
	replace detailed_classification=6 if inlist(TOR_original,22,23)
	replace detailed_classification=8 if inlist(TOR_original,18)
	replace detailed_classification=9 if inlist(TOR_original,19)
	replace detailed_classification=99 if inlist(TOR_original,0,24,99,999)




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
    keep hhid product_code TOR_original agg_value_on_period coicop_2dig  housing detailed_classification TOR_original  pct_expenses 
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
	
	
