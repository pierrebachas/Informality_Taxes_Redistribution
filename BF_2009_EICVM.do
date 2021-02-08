

					*************************************
					* 			Main DO FILE			*
					* 	      Burkkina Faso 2013		*
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

	
	global country_fullname "BurkinaFaso2009"
	global country_code "BF"
	
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
	EICVM_fichier_menage_produit.dta

This single data file includes almost everything we need: household-level general statistics,
expenses, place of purchase, urban/rural etc - with one line per economic activity. 

	Menage.dta

This file might be useful b/c it has a variable (g15) "estimation du loyer mensuel"
in case housing data is missing from the first dataset. 

hhid - 8404 unique cases
HHID appears to be constructed as a concatenation of v01 and v02. 
However v02 (which is values 1 - 15), needs a 0 added in from of 1-9 for this concatenation to work.

For Burkina Faso, we will use expenses to construct the deciles.
	
*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear
	set more off
	use "$main/data/$country_fullname/EICVM_fichier_menage_produit.dta", clear	


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename hhweight 							hh_weight
	rename region								geo_loc
	rename v01									census_block // zd; 605 unique values; best guess
	rename hgender								head_sex
	rename hage									head_age
	rename heduc								head_edu
	rename hhsize 								hh_size
	rename milieu								urban
	
	

	
	*We need to construct/modify some of them
	*geo_loc_min
	gen geo_loc_min = geo_loc // there isn't another smaller geographic variable

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

	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	*Note that here we don't take into account CQ03 which is the module gathering events expenses (in the questionnaire it is the module CQ23 but it appears as CQ03 in the microdata)
	
	local file_num "CQ02	CQ04	CQ05	CQ06	CQ07	CQ08	CQ09	CQ10	CQ11	CQ12	CQ13	CQ14	CQ15	CQ16	CQ17	CQ18	CQ19	CQ20	CQ21	CQ22	CQ23"
	local annualization_factor "365/15 1 2 2 1 2 1 4 1 4 1 4 1 2 1 1 4 2 1 1 1"
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
		replace agg_value_on_period =q8*$annualization_factor
		gen module_tracker = "$file_num"
		save "$main/data/$country_fullname/expenses/adj_$file_num.dta", replace
	
}
	
	*We append all the expense files together
	
	cd "$main/data/$country_fullname/expenses"
	fs "*.dta"
	append using `r(files)'
	

	rename q10		 						TOR_original 
	rename q8		 						amount_paid							// montant total
	rename q5								quantity 							// quantite
	rename q6								unit								// unite
	rename q7								price								// prix unitaire
	rename q11								modep
	rename q12								country_of_prod						// origine de produit
	rename q4								product_code 						// NOT COICOP - only 76 categories
	ren q13									etat

	

	
	
	*We need to construct/modify some of them
	*hhid
	tostring zd, replace 
	gen menage_str = string(menage,"%02.0f") 
	egen hhid = concat(zd menage_str)

	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	drop if product_code > 1270499 // only keep monetary expenses;
	drop if product_code==.
	

	drop if TOR_original==1 // cadeau donne
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
	
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code str_product TOR_original TOR_original_name  quantity price unit amount_paid country_of_prod agg_value_on_period coicop_2dig TOR_original_name housing
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
	gen detailed_classification=1 if inlist(TOR_original,0,2,38,45)
	replace detailed_classification=2 if inlist(TOR_original,41,11,10,9,36,43)
	replace detailed_classification=3 if inlist(TOR_original,7,40,5,12)
	replace detailed_classification=4 if inlist(TOR_original,44,26,27,28,14,34,6,31,23,22,21,13)
	replace detailed_classification=5 if inlist(TOR_original,4,8,3)
	replace detailed_classification=6 if inlist(TOR_original,37,42,32,19,29,33,25,18,20,30,15,16)
	replace detailed_classification=7 if inlist(TOR_original,24,35)
	replace detailed_classification=8 if inlist(TOR_original,17)
	replace detailed_classification=99 if inlist(TOR_original,39)

	



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
    keep hhid product_code str_product TOR_original TOR_original_name  quantity price unit amount_paid country_of_prod agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
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
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig price quantity unit detailed_classification  country_of_prod) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item quantity unit price TOR_original detailed_classification  country_of_prod housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
