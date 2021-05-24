

					*************************************
					* 			Main DO FILE			*
					* 	      	BRAZIL 2009				*
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
	

********************************************************************************
********************************************************************************

	
	global country_fullname "Brazil2009"
	global country_code "BR"
	
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
	pes.dta (dataset called MORADOR in the website) 
	dom.dta
	Household level general statistics, one line per household. 	
	
	desp_12m.dta
	desp_90d.dta
	desp_veic.dta
	cadern_desp.dta
	desp.dta
	outras_desp.dta
	serv_dom.dta
	alug_est.dta
	All expenditures, sources of income, debts, transfers,... with one line per economic activity.
*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************


	clear
	set more off
	use "$main/data/$country_fullname/pes.dta", clear
	
	merge m:1 COD_UF NUM_SEQ NUM_DV COD_DOMC using "$main/data/$country_fullname/dom.dta"
	drop _merge

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	
	rename COD_COR_RACA 		head_ethnicity
	rename COD_NIVEL_INSTR 		head_edu
	rename ANOS_DE_ESTUDO 		head_years_of_study
	rename COD_SEXO 			head_sex
	rename IDADE_ANOS 			head_age

	
	*We need to construct/modify some of them
	*hhid
	egen hhid = concat(COD_UF NUM_SEQ NUM_DV COD_DOMC NUM_UC)
	distinct hhid					// Number of households (CONSUMPTION UNIT) : 56 091 
	
	
	*hh_size
	sort hhid
	by hhid: gen _nval = _n
	by hhid: egen hh_size = max(_nval)
	drop _nval
	
	*urban 
	destring NUM_EXT_RENDA, replace
	destring COD_UF, replace

	gen urban = 0
	replace urban = 1 if COD_UF == 11 & NUM_EXT_RENDA < 7
	replace urban = 1 if COD_UF == 12 & NUM_EXT_RENDA < 3
	replace urban = 1 if COD_UF == 13 & NUM_EXT_RENDA < 9
	replace urban = 1 if COD_UF == 14 & NUM_EXT_RENDA < 3
	replace urban = 1 if COD_UF == 15 & NUM_EXT_RENDA < 9
	replace urban = 1 if COD_UF == 16 & NUM_EXT_RENDA < 4
	replace urban = 1 if COD_UF == 17 & NUM_EXT_RENDA < 6
	replace urban = 1 if COD_UF == 21 & NUM_EXT_RENDA < 13
	replace urban = 1 if COD_UF == 22 & NUM_EXT_RENDA < 10
	replace urban = 1 if COD_UF == 23 & NUM_EXT_RENDA < 24
	replace urban = 1 if COD_UF == 24 & NUM_EXT_RENDA < 9
	replace urban = 1 if COD_UF == 25 & NUM_EXT_RENDA < 10
	replace urban = 1 if COD_UF == 26 & NUM_EXT_RENDA < 16
	replace urban = 1 if COD_UF == 27 & NUM_EXT_RENDA < 9
	replace urban = 1 if COD_UF == 28 & NUM_EXT_RENDA < 8
	replace urban = 1 if COD_UF == 29 & NUM_EXT_RENDA < 22
	replace urban = 1 if COD_UF == 31 & NUM_EXT_RENDA < 28
	replace urban = 1 if COD_UF == 32 & NUM_EXT_RENDA < 10
	replace urban = 1 if COD_UF == 33 & NUM_EXT_RENDA < 31
	replace urban = 1 if COD_UF == 35 & NUM_EXT_RENDA < 31
	replace urban = 1 if COD_UF == 41 & NUM_EXT_RENDA < 19
	replace urban = 1 if COD_UF == 42 & NUM_EXT_RENDA < 14
	replace urban = 1 if COD_UF == 43 & NUM_EXT_RENDA < 19
	replace urban = 1 if COD_UF == 50 & NUM_EXT_RENDA < 9
	replace urban = 1 if COD_UF == 51 & NUM_EXT_RENDA < 11
	replace urban = 1 if COD_UF == 52 & NUM_EXT_RENDA < 18
	replace urban = 1 if COD_UF == 53 & NUM_EXT_RENDA < 8
	
	*geo_loc
	gen geo_loc=COD_UF 	
	
	*geo_loc_min
	gen x = "XX"
	tostring NUM_EXT_RENDA, replace
	egen region2 = concat(geo_loc x NUM_EXT_RENDA )
	drop x
	gen geo_loc_min = region2

	*census_block
	egen census_block = concat(NUM_SEQ NUM_DV)	// 2405 unique values
	
	*hh_weight
	egen total_weight = sum(FATOR_EXPANSAO2)
	gen expansion_coeff = total_weight / 56076
	gen hh_weight = FATOR_EXPANSAO2 / expansion_coeff



	*We destring and label some variables for clarity/uniformity 
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace					// Some of these variables are already numeric
	
	ta head_sex, missing
	label define head_sex_lab 1 "Male" 2 "Female"
	label values head_sex head_sex_lab

	ta urban, nol
	label define urban_lab 0 "Rural" 1 "Urban"
	label values urban urban_lab
	
	
	*We keep only one line by household and necessary covariates 
	destring COD_REL_PESS_REFE_UC, force replace
	keep if COD_REL_PESS_REFE_UC == 1
	duplicates drop hhid , force 

	destring hhid, replace
	order hhid, first 
	sort hhid
	
	keep hhid hh_weight urban geo_loc geo_loc_min census_block  head_sex head_age head_edu   hh_size  head_ethnicity 
	save "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , replace
	


************************************************************
* Step 2: Renaming and labelling the expenditures database *
************************************************************
********************
* Cleaning steps   *
********************
	
*****************************
	* import of retailer codes

	/* one time should be enough */ 
	insheet using "$main/data/$country_fullname/BR_POF_crosswalk_TOR_all.csv" , ///
	clear names delimiter(";")
	//change first code which included an A for the variable to be recognized as text
	replace codigo = "00101" if codigo == "A00101"
		rename codigo COD_LOCAL_COMPRA
	save "$main/data/$country_fullname/all_retailers_codes.dta", replace

	* import of product codes
	
	insheet using "$main/data/$country_fullname/BR_POF_crosswalk_product_code.csv" , clear names delimiter(";")
	drop if v2==""
	ren v2 grupo
	ren v3 quadro_2dig_txt
	ren v4 codigo
	ren v5 coodig_txt
	ren v6 complete_item_code
	ren v7 PRODUTO
	duplicates report complete_item_code 
	duplicates list complete_item_code
	duplicates drop complete_item_code, force
	save "$main/data/$country_fullname/product_codes.dta", replace
************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************

	*Append 8 databases
	clear 
	set more off
	use "$main/data/$country_fullname/desp_12m.dta", clear // 76 761
	append using "$main/data/$country_fullname/desp_90d.dta" // 192 813
	append using "$main/data/$country_fullname/desp_veic.dta" // 16 560
	append using  "$main/data/$country_fullname/cadern_desp.dta"
	append using "$main/data/$country_fullname/desp.dta"
	append using "$main/data/$country_fullname/outras_desp.dta"
	append using "$main/data/$country_fullname/serv_dom.dta"
	append using "$main/data/$country_fullname/alug_est.dta"
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	egen hhid = concat(COD_UF NUM_SEQ NUM_DV COD_DOMC NUM_UC)
	rename FATOR_EXPANSAO2				hh_weight 
	rename VAL_DESPESA_CORRIGIDO		amount_paid	

	*We need to construct/modify some of them
	
	*agg_value_on_period
	gen agg_value_on_period = amount_paid * FATOR_ANUAL

	*product_code
	gen x_char = "X"
	egen complete_item_code = concat(x_char NUM_QUADRO COD_ITEM)

	egen complete_item_code_bis = concat(x_char PROD_NUM_QUADRO_GRUPO_PRO COD_ITEM) //different product code for the diary (cadern_desp)
	replace complete_item_code = complete_item_code_bis if TIPO_REG == "11"
	merge m:1 complete_item_code using "$main/data/$country_fullname/product_codes.dta"
	keep if _merge==3
	drop _merge
	gen item_code = substr(complete_item_code, 1, 6)
	gen code = substr(item_code, 2,5)
	destring code, replace
	merge m:1 code using "$main/data/$country_fullname/BR_POF_crosswalk_COICOP_all_category_codes.dta"
	keep if _merge==3
	drop _merge
	
	capture drop code_category_1char code_category_2char code_category_3char
	gen code_category_1char = substr(code_category, 1, 1)
	gen code_category_2char = substr(code_category, 1, 2)
	gen code_category_3char = substr(code_category, 1, 3)
	ta code_category_3char
	// most alcohol is in grupo 83 (and 24 if for restaurants)

	gen coicop_2dig = .
	
	replace coicop_2dig = 1 if code_category == "1" & code != 41006 & ///
	NUM_QUADRO != "24" & PROD_NUM_QUADRO_GRUPO_PRO != "83" // food from the diary without alcohol

	replace coicop_2dig = 2 if code_category == "9" // smoking
	replace coicop_2dig = 2 if PROD_NUM_QUADRO_GRUPO_PRO == "83" // alcohol
	
	replace coicop_2dig = 3 if inlist(code_category, "3.1", "3.2", "3.3", "3.4", "3.6") // clothing

	replace coicop_2dig = 4 if inlist(code_category_3char, "2.1", "2.2", "2.3", "2.4") // housing
	replace coicop_2dig = 4 if code_category == "11.5" // secondary housing
	replace coicop_2dig = 4 if code_category == "13.2" // maintenance
	
	replace coicop_2dig = 5 if inlist(code_category_3char, "2.5", "2.6", "2.7", "2.8") // house appliances, cleaning

	replace coicop_2dig = 6 if code_category_1char == "6" // health

	replace coicop_2dig = 7 if code_category_1char == "4" // transport*
	// move pacotes = 40040 40041 40042 TO 9
	
	replace coicop_2dig = 8 if code_category == "11.2" | code_category == "8.2" // communication
	
	replace coicop_2dig = 9 if inlist(code_category_3char, "8.1", "8.3", "8.4", "8.5") // recreation & culture
	replace coicop_2dig = 9 if code_category == "11.1" // games and gambling 
	replace coicop_2dig = 9 if code_category == "11.3" // ceremonies and parties 
	replace coicop_2dig = 9 if NUM_QUADRO == "16" // durables for recreation/culture
	replace coicop_2dig = 9 if code == 40040 | code == 40041 | code == 40042 // package holidays

	replace coicop_2dig = 10 if code_category_1char == "7" // education
	
	replace coicop_2dig = 11 if code == 41006 | code == 41007 // restaurants and hotels
	replace coicop_2dig = 11 if  NUM_QUADRO == "24"
	// 41006 was in alimentation and 41007 was in 11.6 Other
	
	replace coicop_2dig = 12 if inlist(code_category_3char, "5.1", "5.2", "5.3", "5.4") // personal care
	replace coicop_2dig = 12 if code_category == "3.5" // jewelry
	replace coicop_2dig = 12 if code_category_3char == "10." // personal services and products
	replace coicop_2dig = 12 if code_category == "11.4" // diverse services
	replace coicop_2dig = 12 if code_category == "12.3" // banking services
	replace coicop_2dig = 12 if code_category == "11.6" & NUM_QUADRO != "16" // other minus recreation goods

	//2dig
	gen brazil_2dig = code_category_1char
	replace brazil_2dig = code_category_2char if inlist(code_category_2char, "10", "11", "12")
	destring brazil_2dig, replace
	ta brazil_2dig, missing

	//3dig

	gen brazil_3dig = code_category	// 3 digits: we use the lowest level of the classification for food, the category is unfortunately very broad
	ta brazil_3dig, missing
	distinct brazil_3dig // 67
	rename brazil_3dig brazil_3digstr
	egen brazil_3dig = group(brazil_3digstr)
	ta name_category, missing

	
	xtset brazil_3dig // some category names were missing so we need to add them (we have already changed category code)
	xfill name_category, i(brazil_3dig)
	labmask brazil_3dig, values(name_category)
	
	// 4 dig
	gen products_group = NUM_QUADRO
	replace products_group = PROD_NUM_QUADRO_GRUPO_PRO if PROD_NUM_QUADRO_GRUPO_PRO != ""
	ta products_group, missing
	gen x_char_2 = "XX"
	egen brazil_4digstr = concat(code_category x_char_2 products_group)
	
	set more off
	ta brazil_4digstr, missing
	distinct brazil_4dig // 138
	// classification is not very good: some categories are very small, other too large
	// but we have the approximate number of different categories we were looking for
	
	egen brazil_4dig = group(brazil_4digstr)
	gen string_for_label = " SECTION = " 
	egen brazil_4dig_label = concat(name_category x_char_2 string_for_label products_group)
	labmask brazil_4dig, values(brazil_4dig_label)
	ta brazil_4dig, missing

	
	*TOR_original
	merge m:1 COD_LOCAL_COMPRA using "$main/data/$country_fullname/all_retailers_codes.dta"
	keep if _merge == 3 // 22 obs deleted
	drop _merge 
	
		* what is not serv_dom in COD_LOCAL_COMPRA == "" corresponds to NUM_QUADRO == "10", that is to say rent&cie
	* that should go to unspecified
	
	replace COD_LOCAL_COMPRA = "99903" if COD_LOCAL_COMPRA == "00000"
	replace COD_LOCAL_COMPRA = "99904" if COD_LOCAL_COMPRA == "" & NUM_QUADRO == "19"
	replace COD_LOCAL_COMPRA = "99903" if COD_LOCAL_COMPRA == "" & NUM_QUADRO != "19"
	gen local_3dig = substr(COD_LOCAL_COMPRA, 1, 3)

	
	tempfile all_lines_no_TOR
	save `all_lines_no_TOR'
	
	import excel "$main/tables/$country_fullname/BR_POF_crosswalk_TOR_3dig.xlsx" , clear firstrow
	merge 1:m local_3dig using `all_lines_no_TOR'
	
	gen housing=1 if brazil_3dig ==23
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
	bys hhid: egen exp_rent = sum(agg_value_on_period) if brazil_3dig == 23 // actual rent as expenses
	*by hhid: egen exp_ir = sum(agg_value_on_period) if brazil_4dig == "68" // imputed rent as expenses
	*gen exp_ir_withzeros = exp_ir
	*replace exp_ir_withzeros = 0 if exp_ir_withzeros == .
	gen exp_rent_withzeros = exp_rent
	replace exp_rent_withzeros = 0 if exp_rent_withzeros == .
	gen exp_housing =  exp_rent_withzeros
	
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
	destring hhid, replace
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
	gen detailed_classification=1 if inlist(TOR_original,18,7,17,16)
	replace detailed_classification=2 if inlist(TOR_original,29,26,14,6,27)
	replace detailed_classification=3 if inlist(TOR_original,8)
	replace detailed_classification=4 if inlist(TOR_original,28,33,19)
	replace detailed_classification=5 if inlist(TOR_original,30,4)
	replace detailed_classification=6 if inlist(TOR_original,21,22,15,13,5,1,23,9,3,12)
	replace detailed_classification=7 if inlist(TOR_original,20)
	replace detailed_classification=8 if inlist(TOR_original,25,10)
	replace detailed_classification=9 if inlist(TOR_original,2,24)
	replace detailed_classification=99 if inlist(TOR_original,31,32)




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
	merge 1:m TOR_original using "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta" , nogen

	*We keep all household expenditures and relevant variables
    keep hhid coicop_2dig brazil_2dig brazil_3dig brazil_4dig TOR_original TOR_original_name agg_value_on_period  detailed_classification TOR_original  pct_expenses housing
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	ren brazil_2dig product_code_2dig 
	ren brazil_3dig product_code_3dig
	ren brazil_4dig product_code_4dig
	
	gen COICOP_2dig=coicop_2dig
	
	merge m:1 COICOP_2dig using "$main/proc/COICOP_label_2dig.dta"
	drop if _merge == 2
	drop _merge
	drop COICOP_2dig
	ren COICOP_Name2 COICOP_2dig
	
	
	*We save the database with all expenditures for the price/unit analysis
	save "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" , replace

	*We create the final database at the COICOP_4dig level of analysis
	collapse (sum) agg_value_on_period, by(hhid TOR_original COICOP_2dig product_code_2dig product_code_3dig product_code_4dig  detailed_classification housing) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_2dig product_code_2dig product_code_3dig product_code_4dig exp_TOR_item  TOR_original detailed_classification  housing , first
	destring hhid, replace
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_product_code_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
