

					*************************************
					* 			Main DO FILE			*
					* 	        MOROCCO: 2001			*
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

	
	global country_fullname "Morocco2001"
	global country_code "MA"
	
/* SUMMARY:
   Step 0:  Data overview
   Step 1:  Prepare covariates at the household level
   Step 2: Preparing the expenditures database 
   Step 2.1: Harmonization of names, introduction of labels
   Step 2.2: Product crosswalk if product codes are not COICOP
   Step 2.3: Place of purchase (Pop) imputation if some modules have missing Pop
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
Demographics:
fichier_individu_encdm2000_01.dta

Consumption:
expenses_and_totals.dta


*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear	
	set more off
	use "$main/data/$country_fullname/fichier_individu_encdm2000_01.dta", clear

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename r_gion								geo_loc
	rename sexe									head_sex
	rename age									head_age
	rename nivscol								head_edu
	rename numup								census_block // this is just a best guess "N? de l'unite primaire" (1249 unique values)
	
	
	*We need to construct/modify some of them
	*hhid
	egen hhid = concat(ident1 ident2)
	
	*hh_size
	sort hhid 
	by hhid: gen _nval = _n
	by hhid: egen hh_size = max(_nval)
	drop _nval

	*geo_loc_min
	gen geo_loc_min = geo_loc

	*urban
	gen urban = 0
	replace urban = 1 if milieu == 1
	
	*hh_weight
	merge m:1 hhid using "$main/data/$country_fullname/BM_with_hhid.dta", nogen
	rename V777  								hh_weight

	
	*exp_agg_tot inc_agg_tot // This file does not have these variables but they may exist in another datafile (peut-etre fichier_emplois_toute_personne) that we should merge here
	
	*We destring and label some variables for clarity/uniformity 
	destring lien_par, replace
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
	drop if lien_par !=1	
 	duplicates drop hhid , force 
 
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block 
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
	use "$main/data/Morocco2001/expenses_and_totals.dta" 
	

	
	rename V777  								hh_weight
	rename place								TOR_original
	rename annualized_170						agg_value_on_period //this value is already annualized
	rename code									item //product code, not coicop // there is coicop 2dig
	rename purchase_mode						purchase_method //mode of acquisition
	rename unit_052								unit 
	rename quantity_051							quantity
	rename price_unit 							unit_price
	rename value								raw_value // no transformation
	rename reason 								TOR_reason
	
	
	*We need to construct/modify some of them
	*code_infourdigits // for crosswalk
	destring item, replace
	gen str4 code_infourdigits = string(item, "%04.0f")

	
	**reason_recode
	replace TOR_reason = 99 if TOR_reason > 12
	replace TOR_reason = 99 if TOR_reason == .
	gen reason_recode = . 
	replace reason_recode = 1 if TOR_reason == 4 | TOR_reason == 5 | TOR_reason == 8 // "access" (proximity + practicality+ necessity) 
	replace reason_recode = 2 if TOR_reason == 1 // "price" (cheaper)
	replace reason_recode = 3 if TOR_reason == 2 // "quality" (better quality) 
	replace reason_recode = 4 if TOR_reason == 6 | reason == 3 // "attributes of TOR" ( better reception, deals on basis of deferred payments)
	replace reason_recode = 5 if reason_recode == . // "other" (irrelevant, mere chance, is not in place of residence, not another place, friends advice, others, 13-99)
	
	*housing
	gen housing=1 if inlist(item,3111,3112,3113)
	
	*COICOP_2dig
	replace COICOP_2dig=12 if COICOP_2dig==99
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	replace agg_value_on_period=agg_value_on_period*0.12

	
	
	replace TOR_original = 999 if TOR_original == .
	replace TOR_original = 47 if TOR_original > 47 & TOR_original < 100
	replace TOR_original = 48 if purchase_method == 4 | purchase_method == 5
	#delim ; // create the label
	label define TOR_original_label 
0 "Cadeau recu en nature ou en espace" 2 "Bien ou service autoproduit" 3 "Grands magasin"
4 "Supermarche" 5 "Mini marche, autre magasin non specialise" 6 "Boutique de station service"
7 "Boutique de quartier" 8 "Magasin de gros a petits prix" 9 "Marche"
10 "Kiosque ou echoppe marche" 11 "Kiosque ou echoppe quartier" 
12 "Quincallerie (petite taille)"
13 "Poissonnerie" 14 "Service de soins personnels" 15 "Telephone, eau, electricite" 16 "Service postal" 
17 "Bar, cafe, restaurant, hotel" 18 "Cabine telephone publique" 19 "Cabine telephone privee" 20 "Autres services publics" 
21 "Boucherie" 22 "Boulangerie, patisserie" 23 "Pressing, blanchisserie" 24 "Service de transport prive" 
25 "Service de transport public" 26 "Vendeur vehicules concessionaire" 27 "Atelier, service reparation" 
28 "Station service (lubrifiants)" 29 "Clinique, laboratoire medical prive" 30 "Clinique, laboratoire medical public"
31 "Pharmacie" 32 "Ecole, lycees, universite privas" 33 "Ecole, lycee, universite publics" 34 "Librairie, papeterie" 
35 "Autres service prives" 36 "Marchant ambulants" 37 "Pointe vente internet" 38 "Menage" 39 "Autre lieux d'achat dans lepays" 
40 "Petit marche boutique (ecole, universite)" 41 "Foire, salon, festival" 42 "Etranger" 43 "Rue" 
44 "Vente de piece de rechange pour moto" 45 "Moulin" 46 "Housing" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
		destring reason_recode, force replace
	ta reason_recode
	
	#delim ; 
	label define reason_recode_label 
1 "Access" 2 "Price" 3 "Quality" 4 "Attributes of retailer"
5 "Other" ;
	#delim cr
	label list reason_recode_label
	label values reason_recode reason_recode_label // assign it
	decode reason_recode, gen(reason_recode_name)
		
	*We keep all household expenditures and relevant variables
	keep hhid   TOR_original TOR_original_name COICOP_2dig  quantity  unit   agg_value_on_period code_infourdigits TOR_original_name reason_recode TOR_reason housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace


***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

	import delimited using "$main/data/$country_fullname/MA_ENCDM_crosswalk_COICOP.csv", delimiters(";") varnames(1) clear
	// first code has to to contain a letter for the variable to be coded by Stata as a string
	replace code = "0" if code == "0A"
	// if the zeros have disappeared from the csv (which did not save the code variable was text), 
	// put them back with CONCAT("0";A?) for the first category (about 380 lines to 0939 code).
	
	duplicates report
	duplicates list
	duplicates drop
	
	// remove useless spaces around labels
	replace label = rtrim(label)
	
	//gen str4 code_4char = substr(code, 1, 4)
	gen str2 code_char1 = substr(code, 1, 1)
	gen str2 code_char2 = substr(code, 2, 1)
	gen str2 code_char3 = substr(code, 3, 1)
	gen str2 code_char4 = substr(code, 4, 1)

	gen level1 = 0
	replace level1 = 1 if code_char2 == "" | code_char2 == "."
	gen level2 = 0
	replace level2 = 1 if level1 == 0 & code_char3 == "" & code_char4 == ""
	gen level3 = 0
	replace level3 = 1 if level1 == 0 & level2 == 0 & code_char4 == ""
	gen level4 = 0
	replace level4 = 1 if level1 == 0 & level2 == 0 & level3 == 0 & code_char4 != ""

	gen level = .
	replace level = 1 if level1 == 1
	replace level = 2 if level2 == 1
	replace level = 3 if level3 == 1
	replace level = 4 if level4 == 1
	ta level, missing
	
	drop level1 level2 level3 level4
	
	order level code label
	
	// make clean codes
	gen code_1char = code_char1
	egen code_2char = concat(code_char1 code_char2) if level > 1
	egen code_3char = concat(code_char1 code_char2 code_char3) if level > 2	
	egen code_4char = concat(code_char1 code_char2 code_char3 code_char4) if level > 3	
	
	preserve
	keep if level == 1
	keep code_1char label
	rename label label_1dig
	save "$main/proc/$country_fullname/Morocco_codes_1dig.dta", replace
	restore
	preserve
	keep if level == 2
	keep code_2char label
	rename label label_2dig
	save "$main/proc/$country_fullname/Morocco_codes_2dig.dta", replace
	restore
	preserve
	keep if level == 3
	keep code_3char label
	rename label label_3dig
	duplicates report code_3char
	duplicates list code_3char
	duplicates drop code_3char, force
	save "$main/proc/$country_fullname/Morocco_codes_3dig.dta", replace
	restore
	preserve
	keep if level == 4
	keep code label
	rename code code_4char
	rename label label_4dig
	save "$main/proc/$country_fullname/Morocco_codes_4dig.dta", replace
	restore
	
	* now let's merge the labels of superior categories

	merge m:1 code_1char using "$main/proc/$country_fullname/Morocco_codes_1dig.dta", nogen
	merge m:1 code_2char using "$main/proc/$country_fullname/Morocco_codes_2dig.dta", nogen
	merge m:1 code_3char using "$main/proc/$country_fullname/Morocco_codes_3dig.dta"
	
	ta level if _merge == 1 // looks good
	drop _merge
	
	save "$main/proc/$country_fullname/product_codes.dta", replace

	**************************
	/* Crosswalk at the 2-digit level by hand
	
	gen COICOP_2dig = .
	
	* approximation at 1-character level
	replace COICOP_2dig = 1 if code_1char == "0" 
	replace COICOP_2dig = 2 if code_1char == "1" 
		* 2-characters correction for other food categories and non-alcoholic beverages
		replace COICOP_2dig = 1 if code_2char == "10"
		replace COICOP_2dig = 1 if code_2char == "11"
		replace COICOP_2dig = 1 if code_2char == "12"
		replace COICOP_2dig = 1 if code_2char == "13"
		replace COICOP_2dig = 1 if code_2char == "18"
	
	replace COICOP_2dig = 3 if code_1char == "2" // perfect match clothing&footwear
	replace COICOP_2dig = 4 if code_1char == "3" // includes maintenance and repair! (32) which is normal
	replace COICOP_2dig = 5 if code_1char == "4" // includes maintenance goods
	replace COICOP_2dig = 6 if code_1char == "5" // health
	replace COICOP_2dig = 7 if code_2char == "61" | code_2char == "62" // transport
	replace COICOP_2dig = 8 if code_2char == "63" // communication
	replace COICOP_2dig = 9 if code_2char == "71" | code_2char == "72" | code_2char == "73" //recreation&culture
	replace COICOP_2dig = 10 if code_2char == "75" | code_2char == "76"  // education
	replace COICOP_2dig = 11 if code_2char == "15"  // 15 = food consumed outside
	
	replace COICOP_2dig = 12 if code_1char == "8" // includes travel goods and stationery articles together with jewels/insurance
		// stationery should go into recreation and culture
		replace COICOP_2dig = 9 if code_2char == "82" 
		
	* special case: does not exist in COICOP
	replace COICOP_2dig = 99 if code_1char == "9" // cash transfers, taxes, loans...
	
	* specific treatment for code_2char == "74"
	// 74 = week-ends and holidays, transport + hotel + foodcode
		* transport
	replace COICOP_2dig = 7 if inlist(code_4char, "7411", "7412", "7413", "7414")
	replace COICOP_2dig = 7 if inlist(code_4char, "7421", "7422", "7423", "7424", "7431", "7441")
		* food/beverages
	replace COICOP_2dig = 11 if inlist(code_4char, "7416", "7426", "7433", "7443")
		* accomodation
	replace COICOP_2dig = 11 if inlist(code_4char, "7415", "7425", "7432", "7442")
		* package holidays -> recreation and culture
	replace COICOP_2dig = 9 if inlist(code_4char, "7418", "7428")
		* other -> recreation and culture ??
	replace COICOP_2dig = 9 if inlist(code_4char, "7417", "7419", "7427", "7429", "7434", "7435", "7444", "7445", "7446")
	
	save "$main/proc/$country_fullname/product_codes.dta", replace
	ta COICOP_2dig, missing
	// a few missing values for the nine 1_char groups
	
	keep if level == 3 | level == 4
	save "$main/proc/$country_fullname/product_codes_levels_3_4.dta", replace
	
	use  "$main/proc/$country_fullname/product_codes_levels_3_4.dta", clear
	duplicates report code
	duplicates list code
*/
	use "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", clear
	
	rename code_infourdigits code
	* we do it for the main categories only here
	replace code = "0319" if code == "0318"
	replace code = "2444" if code == "2445"
	replace code = "2613" if code == "2619"
	replace code = "4241" if code == "4242"
	replace code = "4241" if code == "4243"
	replace code = "4241" if code == "4244"
	replace code = "4241" if code == "4249"
	replace code = "4634" if code == "4635"

	* the last missing codes can be spot by a merge with the labels
	merge m:1 code using "$main/proc/$country_fullname/product_codes_levels_3_4.dta"

	preserve
	keep if _merge == 1
	save "$main/waste/$country_fullname/codes_from_data_not_in_list.dta", replace
	restore
	
	drop if label == "" // products codes we do not know
	drop if _merge == 2 // products from the list not in the db
	count if hhid == ""

	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace

	use "$main/waste/$country_fullname/codes_from_data_not_in_list.dta", clear

	ta code, missing

	* For these codes we can guess some categories are missing, they can be recoded as "other products nos" within their 
	* 3-digit category
	* They do not seem to be 3-digit codes to which we would have wrongly added a zero.

	* we do it for the main categories only here
	replace code = "0319" if code == "0318"
	replace code = "2444" if code == "2445"
	replace code = "2613" if code == "2619"
	replace code = "4241" if code == "4242"
	replace code = "4241" if code == "4243"
	replace code = "4241" if code == "4244"
	replace code = "4241" if code == "4249"
	replace code = "4634" if code == "4635"

	drop level label* code_char* code_1char code_2char code_3char code_4char COICOP_2dig _merge
	* beware to keep code_rent

	* do the merge again
	merge m:1 code using "$main/proc/$country_fullname/product_codes_levels_3_4.dta"
	drop _merge
	append using "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"

	drop if COICOP_2dig == 99 | COICOP_2dig == .

	save "$main/waste/$country_fullname/${country_code}_all_lines_with_crosswalk.dta", replace


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
	bys hhid: egen exp_rent = sum(agg_value_on_period) if code == "3112" | code == "3113"  // actual rent as expenses
	bys hhid: egen exp_ir = sum(agg_value_on_period) if code == "3111" // imputed rent as expenses
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
	gen detailed_classification=1 if inlist(TOR_original,15,28,48)
	replace detailed_classification=2 if inlist(TOR_original,1,2,3,4,5,7,13,22,24)
	replace detailed_classification=3 if inlist(TOR_original,8,9,14)
	replace detailed_classification=4 if inlist(TOR_original,10,11,12,20,16,25,19,27,42,23,26,43,18,21,17)
	replace detailed_classification=5 if inlist(TOR_original,6)
	replace detailed_classification=6 if inlist(TOR_original,37,40,33,35,44,38,36,39,34,45)
	replace detailed_classification=7 if inlist(TOR_original,41)
	replace detailed_classification=8 if inlist(TOR_original,31,29)
	replace detailed_classification=9 if inlist(TOR_original,30,32)
	replace detailed_classification=99 if inlist(TOR_original,0,46,47,999)




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
	merge 1:m TOR_original using "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta" , gen (_merge2)

	*We keep all household expenditures and relevant variables
	keep hhid TOR_original TOR_original_name quantity unit agg_value_on_period housing detailed_classification TOR_original TOR_original_name pct_expenses TOR_reason reason_recode	code_4char COICOP_2dig
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen COICOP_4dig = substr(code_4char, 1,4)
	gen COICOP_3dig = substr(code_4char, 1,3)
	drop if COICOP_2dig==.

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
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig quantity unit detailed_classification  reason_recode) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item quantity unit  TOR_original detailed_classification  reason_recode housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
