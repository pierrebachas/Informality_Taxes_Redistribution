

					*************************************
					* 			Main DO FILE			*
					* 	        COMOROS 2013 			*
					*************************************

* Template 


***************
* DIRECTORIES *
***************

if "`c(username)'"=="wb520324" { 													// Eva's WB computer 
	global main "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata"		
}	
	else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}	
		

********************************************************************************
********************************************************************************

	
	global country_fullname "Comoros2013"
	global country_code "KM"
	
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
	demo.dta
	Individual level general statistics, one line per individual. 	
	
	fichier apcq 03 à 21.dta
All expenditures, sources of income, debts, transfers,... with one line per economic activity.
*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear
	set more off
	use "$main/data/$country_fullname/demo.dta", clear	


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent iformation is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	rename idmen 								hhid // starte + zd %03.0 + menage %02.0
	rename pond		 							hh_weight //survey weights
	rename strate								geo_loc // region
	rename zd									census_block // zd, 338 unique values
	rename cmsex								head_sex
	rename taille 								hh_size
	rename milieu								urban
	
	*We need to construct/modify some of them
	*hh_age
	gen head_age= m4 if m5==1
	qui bysort hhid (head_age): replace head_age=head_age[1]
	
	*head_edu
	gen head_edu= niv if m5==1
	qui bysort hhid (head_edu): replace head_edu=head_edu[1]
	
	*geo_loc_min
	gen geo_loc_min = geo_loc // there isn't another smaller geographic variable except from the census blocks
	
	*urban
	ta urban
	replace urban = 0 if urban == 2  //Create a dummy equals to 1 if urban 
	
	*exp_agg_tot inc_agg_tot // This file does not have these variables but they may exist in another datafile (peut-etre fichier_emplois_toute_personne) that we should merge here
	
	*We destring and label some variables for clarity/uniformity 
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace					// Some of these variables are already numeric
	
	ta head_sex, missing
	label define head_sex_lab 1 "Male" 2 "Female"
	label values head_sex head_sex_lab
	
	
	*We keep only one line by household and necessary covariates 
	keep if m5==1
	
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc geo_loc_min census_block
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
	use "$main/data/$country_fullname/apcq03 à 21.dta", clear
	
	*We select the necessary variables and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	
	rename q10		 						TOR_original 						// Type of retailer
	rename q08		 						amount_paid							// total amount paid
	rename q05								quantity 							// quantity
	rename q06								unit								// unit
	rename q07								price								// unit price
	rename q11								TOR_reason							// reason type of retailer
	rename q12								country_of_prod						// product origin
	rename q04								product_code 						// COICOP
	
	
	*We need to construct/modify some of them
	*hhid,  constructed in the household covariates dataset as: strate + zd %03.0 + menage %02.0 
	tostring strate, replace force 
	gen str6 str_zd = substr(string(zd,"%03.0f"), 1,3) 
	gen str6 str_menage = substr(string(menage,"%02.0f"), 1,2) 
	egen hhid = concat(strate str_zd str_menage) // 3236 unique values
	
	*agg_value_on_period, here different annualization factor for each module
	gen annualization_factor=365/9 if q100==3
	replace annualization_factor=1 if q100==4
	replace annualization_factor=2 if q100==5
	replace annualization_factor=2 if q100==6
	replace annualization_factor=1 if q100==7
	replace annualization_factor=2 if q100==8
	replace annualization_factor=1 if q100==9
	replace annualization_factor=4 if q100==10
	replace annualization_factor=1 if q100==11
	replace annualization_factor=4 if q100==12
	replace annualization_factor=1 if q100==13
	replace annualization_factor=4 if q100==14
	replace annualization_factor=1 if q100==15
	replace annualization_factor=2 if q100==16
	replace annualization_factor=1 if q100==17
	replace annualization_factor=1 if q100==18
	replace annualization_factor=4 if q100==19
	replace annualization_factor=1 if q100==20
	replace annualization_factor=2 if q100==21
	
	gen agg_value_on_period = amount_paid*annualization_factor
	
	*reason_recode 
	
	gen reason_recode = . 
	replace reason_recode = 1 if TOR_reason == 4 | TOR_reason == 6 // "access" (proximity, "vendeur proche/pratique", necessitiy "specialise/pas ailleurs") 
	replace reason_recode = 2 if TOR_reason == 1 // "price" (cheaper, "bien/service moins cher")
	replace reason_recode = 3 if TOR_reason == 2 // "quality" (better quality, "meilleure qualite") 
	replace reason_recode = 4 if TOR_reason == 3  | TOR_reason == 5   // "attributes of TOR" (seller does credit "vendeur fait du credit", family/friend connection "accuillant/ami famille")
	replace reason_recode = 5 if reason_recode == . // "other" (autre raison, missing)

	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	*We remove mising values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	drop if agg_value_on_period == .
	drop if product_code > 1270499 // only keep monetary expenses; 118 deleted
	drop if product_code == 0 

	destring TOR_original, force replace
	ta TOR_original
	ta TOR_original, m nol
	drop if TOR_original == 0 // do not keep Cadeau donne; not an expense 
	replace TOR_original = 13 if TOR_original == . 
	#delim ; // create the label
	label define TOR_original_label 
	1 "Cadeau Recu" 2 "Bien ou service autoproduit"
	3 "Vendeur ambulant ou poste fixe sur voie" 4 "Domicile du vendeur, petite boutique" 5 "Marche public"
	6 "Autre lieu d'achat informel" 7 "Supermarche" 8 "Magasin ou atelier formel (societe)"
	9 "Magasin, atelier formel (societe) tenu" 10 "Secteur public ou parapublic" 11 "Autre lieu d'achat formel" 12 "Hors lieu de residence ou a l'etranger" 13 "Housing";
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	decode TOR_original, gen(TOR_original_name)
	
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

	* This step will require to investigate the following datafiles : revenu.dta, emplois_fichier_toute_personne
	
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
	
	
