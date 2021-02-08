

					*************************************
					* 			Main DO FILE			*
					* 	        BENIN 2015	 			*
					*************************************

* Template 


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

	
	global country_fullname "Benin2015"
	global country_code "BJ"
	
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
	individu.dta
	Individual level general statistics, one line per individual. 	
	
	fichier RM 11 a 23 + AL +FE.dta
	All expenditures, sources of income, debts, transfers,... with one line per economic activity.
*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear
	set more off
	use "$main/data/$country_fullname/individu.dta", clear	


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename weight_final		 					hh_weight 
	rename m00_depa								geo_loc 
	ren m00_comm								geo_loc_2
	ren m00_vill								geo_loc_3
	ren m00_arro 								geo_loc_min 
	rename v01									census_block
	rename m01_04								head_sex
	rename m01_07								head_age 
	rename m01_17n								head_edu  
	rename m00_type								urban
	
	

	
	*We need to construct/modify some of them
	*hhid 
	gen v01_str = string(census_block,"%03.0f") if census_block<=9
	replace v01_str = string(census_block,"%03.0f") if census_block>=10 & census_block<=99
	replace v01_str = string(census_block,"%03.0f") if census_block>=100
	
	gen v02_str = string(v02,"%03.0f") if v02<=9
	replace v02_str = string(v02,"%03.0f") if v02>=10 & v02<=99
	replace v02_str = string(v02,"%03.0f") if v02>=100
	
	gen v03_str = string(v03,"%02.0f") if v03<=9
	replace v03_str = string(v03,"%02.0f") if v03>=10
	
	gen hhid = v01_str+v02_str+v03_str
	
	*hh_size
	bys hhid : egen hh_size= max(m01_01)
	
	*exp_agg_tot inc_agg_tot // This file does not have these variables but they may exist in another datafile (peut-etre fichier_emplois_toute_personne) that we should merge here
	
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
 	duplicates drop hhid , force //4954
	destring hhid , replace
 
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc geo_loc_2 geo_loc_3 geo_loc_min census_block 
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

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	local file_num "RM11 RMAL RM12 RM12a RM13 RM13a RM14 RM14a RM15 RM15a RM16 RM16a RM17 RM17a RM18 RM18a RM19 RM19a RM20 RM20a RM21 RM21a" 
	local annualization_factor "365/15 2 2 1 2 1 2 1 2 1 4 2 2 1 2 1 4 2 2 1 1 1/2"
	local file_qt_mont " 11 al 12 12a 13 13a 14 14a 15 15a 16 16a 17 17a 18 18a 19 19a 20 20a 21 21a" 
	local file_qt " 11 al 12 12a 13 13a 14 14a 15 15a 16 16a 17 17a 18 18a 19 19a 20 20a 21 21a" 
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

		gen agg_value_on_period = . 
		replace agg_value_on_period = m`: word `i' of `file_qt_mont''_mont *$annualization_factor
		gen amount_paid=m`: word `i' of `file_qt_mont''_mont
		gen TOR_original= m`: word `i' of `file_qt''_lieu						// Type of retailer
		gen product_code=m`: word `i' of `file_qt''_prod						// COICOP
		gen quantity=m`: word `i' of `file_qt''_quan
		gen unit=m`: word `i' of `file_qt''_unit
		gen TOR_reason_for_purchase=m`: word `i' of `file_qt''_rais
		gen country_of_prod=m`: word `i' of `file_qt''_orig
		gen product_label=m`: word `i' of `file_qt''_prod_txt1
		
		gen module_tracker = "$file_num"
		save "$main/data/$country_fullname/expenses/adj_$file_num.dta", replace
	
}
	
	*We append all the expense files together
	
	cd "$main/data/$country_fullname/expenses"
	fs "*.dta"
	append using `r(files)'

	
	*We need to construct/modify some of them
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	*reason_recode
	gen reason_recode = . 
	replace reason_recode = 1 if TOR_reason == 4 | TOR_reason == 6 // "access" (proximity, "vendeur proche/pratique", necessitiy "specialise/pas ailleurs") 
	replace reason_recode = 2 if TOR_reason == 1 // "price" (cheaper, "bien/service moins cher")
	replace reason_recode = 3 if TOR_reason == 2 // "quality" (better quality, "meilleure qualite") 
	replace reason_recode = 4 if TOR_reason == 3  | TOR_reason == 5   // "attributes of TOR" (seller does credit "vendeur fait du credit", family/friend connection "accuillant/ami famille")
	replace reason_recode = 5 if reason_recode == . // "other" (autre raison, missing)
	
	*price
	gen price=.
	replace price=m11_prix if module_track=="RM11"
	replace price=mal_prix if module_track=="RMAL"
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	drop if product_code >230003 & module_tracker=="RM11" // drop non food from diary to avoid double counting
	drop if product_code > 1270499 // only keep monetary expenses;
	drop if product_code==.
	
	

	destring TOR_original, force replace
	ta TOR_original, m nol
	
	drop if TOR_original == 0 // do not keep Cadeau donne; not an expense 
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Cadeau Recu" 2 "Bien ou service autoproduit"
	3 "Achat chez un ambulant, ou poste fixe sur la voie publique" 4 "Achat au domicile du vendeur, dans une petite boutique ou un atelier informel (indépendant)" 5 "Achat sur un marché public"
	6 "Autre lieu d'achat informel (indépendant)" 7 "Achat dans un super marché" 8 "Achat dans un magasin ou un atelier formel (société) tenu par un étranger"
	9 "Achat dans un magasin ou un atelier formel (société) qui n'est pas tenu par un par un étranger" 10 "Achat au secteur public ou parapublic" 11 "Autre lieu d'achat formel sur le territoire" 12 "Achat à l'étranger" 13 "Housing";
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	drop if TOR_original==.
	
	destring reason_recode, force replace
	#delim ; 
	label define reason_recode_label 
	1 "Access" 2 "Price" 3 "Quality" 4 "Attributes of retailer"
	5 "Other" ;
	#delim cr
	label list reason_recode_label
	label values reason_recode reason_recode_label // assign it
	decode reason_recode, gen(reason_recode_name)
	
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code str_product TOR_original TOR_original_name TOR_reason reason_recode quantity price unit amount_paid country_of_prod agg_value_on_period coicop_2dig TOR_original_name housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace


***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

// Not needed for Comoros

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
	gen detailed_classification=1 if inlist(TOR_original,1,2,6)
	replace detailed_classification=2 if inlist(TOR_original,3,5)
	replace detailed_classification=3 if inlist(TOR_original,4)
	replace detailed_classification=4 if inlist(TOR_original,8,9)
	replace detailed_classification=5 if inlist(TOR_original,7,11)
	replace detailed_classification=6 if inlist(TOR_original,10,12)
	replace detailed_classification=99 if inlist(TOR_original,13,.)

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
    keep hhid product_code str_product TOR_original TOR_original_name TOR_reason reason_recode quantity price unit amount_paid country_of_prod agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen str6 COICOP_2dig = substr(string(product_code,"%07.0f"), 1,2) 
	replace  COICOP_2dig = substr(string(product_code,"%06.0f"), 1,2) if product_code>= 41001 & product_code<= 45329
	gen str6 COICOP_3dig = substr(string(product_code,"%07.0f"), 1,3) 
	replace  COICOP_3dig = substr(string(product_code,"%06.0f"), 1,3) if product_code>= 41001 & product_code<= 45329
	gen str6 COICOP_4dig = substr(string(product_code,"%07.0f"), 1,4) 
	replace  COICOP_4dig = substr(string(product_code,"%06.0f"), 1,4) if product_code>= 41001 & product_code<= 45329

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
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig price quantity unit detailed_classification TOR_reason reason_recode country_of_prod) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item quantity unit price TOR_original detailed_classification reason_recode country_of_prod housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
