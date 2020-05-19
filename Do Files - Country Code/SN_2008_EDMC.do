

					*************************************
					* 			Main DO FILE			*
					* 	        SENEGAL - DAKAR 2008	*
					*************************************

* Template 


***************
* DIRECTORIES *
***************

if "`c(username)'"=="wb520324" { 													// Eva's WB computer 
	global main "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata"		
}	
 else if "`c(username)'"=="" { 										
	global main ""
	}

********************************************************************************
********************************************************************************

	
	global country_fullname "Senegal_Dakar2008"
	global country_code "SN"
	
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
CQ02Aan.dta
Household level general statistics, one line per household. 	

CQ04Aan.dta
Information on rent

CQ06Aan.dta
All expenditures, place of purchase,... with one line per economic activity.

Current problems
-an absence of geography variables (though, probably makes sense because it is just Dakr)
-I do not think we were given all possible expense modules - only the 15 day diary (but there are many more in questionnaire)
-Question about frequency of purchase vs. questionnaire period (which to use?)
*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	*DEMOGRAPHICS
	clear	
	set more off
	use "$main/data/$country_fullname/CQ02Aan.dta", clear
	
	*hhid
	gen str6 GRAPPE_str = substr(string(GRAPPE,"%02.0f"), 1,2) 
	gen str6 MENAGE_str = substr(string(MENAGE,"%02.0f"), 1,2) 
	egen hhid = concat(GRAPPE_str MENAGE_str)

	*hh_size
	sort hhid
	by hhid: gen _nval = _n
	by hhid: egen hh_size = max(_nval)
	drop _nval

	keep if M5==1
	duplicates drop hhid, force
	tempfile demographics
	save `demographics'
	
	*WEIGHT
	clear	
	set more off
	use "$main/data/$country_fullname/CQ06Aan.dta", clear
	
	*hhid
	gen str6 GRAPPE_str = substr(string(GRAPPE,"%02.0f"), 1,2) 
	gen str6 MENAGE_str = substr(string(MENAGE,"%02.0f"), 1,2) 
	egen hhid = concat(GRAPPE_str MENAGE_str)
	duplicates drop hhid, force 
	
	*merge
	merge m:1 hhid using `demographics'
	keep if _merge ==3 
	drop _merge 

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent iformation is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	rename poids	 							hh_weight
	rename M3									head_sex
	rename M4									head_age
	rename M14									head_edu
	
	*We need to construct/modify some of them
	*geo_loc
	gen geo_loc = .
	gen geo_loc_min = .
	gen census_block = GRAPPE 
	
	*urban
	gen urban = 1
	
	*exp_agg_tot inc_agg_tot // This file does not have these variables but they may exist in another datafile (peut-etre ...) that we should merge here
	
	*We destring and label some variables for clarity/uniformity 
	destring geo_loc, force replace
	destring geo_loc_min, force replace
	destring census_block, force replace
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace							// Some of these variables are already numeric
	
	ta head_sex, missing
	label define head_sex_lab 1 "Male" 2 "Female"
	label values head_sex head_sex_lab
	
	
	*We keep only one line by household and necessary covariates 
 	duplicates drop hhid , force 
 
	keep hhid hh_weight geo_loc geo_loc_min census_block head_sex head_age head_edu hh_size urban    
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
	use "$main/data/$country_fullname/CQ06Aan.dta", clear
	
	*We select the necessary variables and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	rename poids	 						hh_weight
	rename Q10		 						TOR_original 
	rename Q8		 						amount_paid							// Quel est le montant total de cette dépense ?
	rename Q4								product_code						// Follows COICOP (max = 6dig)!
	rename Q5								quantity 							// Quantité payée
	rename Q6								unit								// Unité
	rename Q7								price								// Prix unitaire (en francs CFA)
	rename Q9								frequency							// should trust questionnaire or this variable? 
	
	
	*We need to construct/modify some of them
	*hhid 
	gen str6 GRAPPE_str = substr(string(GRAPPE,"%02.0f"), 1,2) 
	gen str6 MENAGE_str = substr(string(MENAGE,"%02.0f"), 1,2) 
	egen hhid = concat(GRAPPE_str MENAGE_str)

	*agg_value_on_period
	gen agg_value_on_period = V51


	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	*We remove mising values, destring and label some variables for clarity/uniformity 
	drop if agg_value_on_period == .
	drop if product_code > 1270499 // only keep monetary expenses; 118 deleted

	#delim ; // create the label
	label define TOR_original_label 
	0 "Cadeau reçu en nature" 1 "Cadeau versé en nature" 2 "Bien ou service autoproduit" 3 "Grand magasin"
	4 "Supermarché" 5 "Mini-marchés et autres magasin non-spécialisés et divers" 6 "Boutique de station service"
	7 "Boutique de quartier" 8 "Magasins de gros ou à prix réduits" 9 "Marchés"
	10 "Kiosque ou échoppe au marché" 11 "Kiosque ou échoppe au quartier" 
	12 "Quincaillerie (petite taille)" 13 "Poissonnerie" 14 "Boucherie" 15 "Boulangerie, pâtisserie" 16 "Pressing, blanchisserie et assimilés"
	17 "Service de transport privé" 18 "Service de transport public" 19 "Vendeur de véhicules,concessionnaire"
	20 "Atelier et service de réparation" 21 "Station service (carburants, lubrifiants,etc.)" 22 "Clinique, laboratoire médical, hôpital privés" 
	23 "Clinique, laboratoire médical, hôpital publics" 24 "Pharmacies" 25 "Ecole, lycée, université privés" 26 "Ecole, lycée, université publics" 
	27 "Librairie, papeterie" 28 "Service de soins personnels" 29 "Société de téléphonie et de distribution d’eau, d’électricité" 
	30 "Service postal" 31 "Bar, café, restaurant, hôtel" 32 "Cabine téléphonique publique" 33 "Cabine téléphonique privée" 34 "Autres services publics"  
	35 "Autres services privés" 36 "Marchand Ambulant" 37 "Points de vente sur Internet" 38 "Ménage" 39 "Autre lieu d’achat dans le pays" 40 "Etranger" 99 "Missing" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	decode TOR_original, gen(TOR_original_name)
	drop if TOR_original == 38 | TOR_original == 1
	
	
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code str_product TOR_original TOR_original_name quantity price unit amount_paid  agg_value_on_period coicop_2dig TOR_original_name housing
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
	gen detailed_classification=1 if inlist(TOR_original,0,2)
	replace detailed_classification=2 if inlist(TOR_original,11,10,9,36)
	replace detailed_classification=3 if inlist(TOR_original,7,5)
	replace detailed_classification=4 if inlist(TOR_original,19,20,21,28,27,6,24,16,15,14,13,12)
	replace detailed_classification=5 if inlist(TOR_original,4,8,3)
	replace detailed_classification=6 if inlist(TOR_original,37,40,25,33,22,26,18,32,34,23,29,30)
	replace detailed_classification=7 if inlist(TOR_original,17,35)
	replace detailed_classification=8 if inlist(TOR_original,31) 
	replace detailed_classification=99 if inlist(TOR_original,39,99)

	
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
    keep hhid product_code str_product TOR_original TOR_original_name  quantity price unit amount_paid  agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen str6 COICOP_2dig = substr(string(product_code,"%06.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(product_code,"%06.0f"), 1,3) 
	gen str6 COICOP_4dig = substr(string(product_code,"%06.0f"), 1,4) 

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
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig price quantity unit detailed_classification) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item quantity unit price TOR_original detailed_classification   housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
