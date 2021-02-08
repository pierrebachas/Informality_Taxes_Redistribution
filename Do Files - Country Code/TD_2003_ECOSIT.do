

					*************************************
					* 			Main DO FILE			*
					* 	        CHAD 2003 				*
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

	
	global country_fullname "Chad2003"
	global country_code "TD"
	
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
ECOSITINDG2.dta
Individual level general statistics, one line per individual

	ECOSITMENG1.dta
Household level general statistics, one line per household
	
	data.dta and c17.dta to c45.dta
All expenditures, sources of income, debts, transfers,... with one line per economic activity.


ECOSIT_LOYER_IMPUTE.dta
Housing expenditures
*/


import excel "/Users/evadavoine/Dropbox/Regressivity_VAT/Surveys_consumption/Countries_with_questions/Chad/TCD_2003_ECOSIT_v01_M/NOMENCLATURE.xls", sheet("Produit") firstrow clear
gen product_code_4dig = subinstr(NOMENCLATUREDESPRODUITSdespa,".","",.)
gen countvar = strlen(product_code_4dig)
keep if countvar==4
drop if product_code_4dig=="CODE"
drop NOMENCLATUREDESPRODUITSdespa
drop countvar
ren B product_lab
tempfile crosswalk_4dig
save `crosswalk_4dig'

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear
	set more off
	use "$main/data/$country_fullname/ECOSITMENG1.dta", clear

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	rename hhweight 								hh_weight
	rename region									geo_loc	
	rename strate									geo_loc_min 
	rename numzd									census_block 
	rename milieu									urban 
	rename sexecm									head_sex
	rename agecm									head_age
	rename hhsize									hh_size
	rename instcm									head_edu
	
	*We need to construct/modify some of them
	*hhid
	gen numzd_str = string(census_block,"%03.0f")
	gen numen_str = string(numen,"%03.0f") 
	egen hhid = concat(numzd_str numen_str )

	*exp_agg_tot inc_agg_tot // This file does not have these variables but they may exist in another datafile that we should merge here
	
	*We destring and label some variables for clarity/uniformity 
	destring geo_loc, force replace
	destring geo_loc_min, force replace
	destring census_block, force replace
	destring urban, force replace
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace				// Some of these variables are already numeric

	
	ta head_sex, missing
	label define head_sex_lab 1 "Male" 2 "Female"
	label values head_sex head_sex_lab
	
	replace urban=0 if urban==2
	label define urban_lab 0 "Rural" 1 "Urban"
	label values urban urban_lab
	
	*We keep only one line by household and necessary covariates 
 	duplicates drop hhid , force 
 
	keep hhid hh_weight geo_loc geo_loc_min census_block urban head_sex head_age head_edu hh_size 
	order hhid, first 
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , replace
	


************************************************************
* Step 2: Renaming and labelling the expenditures database *
************************************************************

************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************

	*SELF CONSUMPTION MODULE
	clear 
	set more off
	use "$main/data/$country_fullname/ECOSITPRCONSO_STAND.dta" 
	
	*We select the necessary variables and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	
	
	ren produit 								product_code 					// Not COICOP!
	ren poste									coicop_2dig
	ren modep									modep							
	ren depan 									agg_value_on_period
	

	*We need to construct/modify some of them
	*hhid
	gen numzd_str = string(numzd,"%03.0f")
	gen numen_str = string(numen,"%03.0f") 
	egen hhid = concat(numzd_str numen_str )
	
	
	*TOR_original
	gen TOR_original=22
	
	*Only module with crosswalk for coicop_2dig
	preserve 
	keep product_code coicop_2dig
	duplicates drop 
	tempfile coicop_2dig_crosswalk
	save `coicop_2dig_crosswalk'
	restore
	
	*We remove mising or unnecessary observations, destring and label some variables for clarity/uniformity 
	keep if modep==2
	

		#delim ; // create the label
	label define TOR_original_label 
	1 "Supermarche" 2 "Magasins"
	3 "Boutique" 4 "Marché centraux" 5 "Marché de quartier ou spécialisé"
	6 "Echoppe" 7 "Marchand ambulant" 8 "	Tablier"
	9 "Transport privé" 10 "Transport public" 11 "Prestataire service santé privé" 12 "Prestataire service santé public" 13 "Enseignement privé"
	14 "Enseignement public" 15 "Hôtel, Restaurant, .." 16 "Autre prestataire de service privé" 17 "Autre prestataire de service public"
	18 "Dans un pays de la zone franc" 19 "Pays africain hors zone franc" 20 "Ailleurs dans le monde" 21 "Autre" 22 "Self-Consumption"
	;#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	decode TOR_original, gen(TOR_original_name)
	
	
	
	tempfile self_conso
	save `self_conso'
	
	*DIARY MODULE
	clear 
	set more off
	use "$main/data/$country_fullname/data.dta" , clear
	
	*We select the necessary variables and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	*We need to construct/modify some of them
	*hhid
	gen numzd_str = string(numzd,"%03.0f")
	gen numen_str = string(numen,"%03.0f") 
	egen hhid = concat(numzd_str numen_str )
	destring hhid, replace

	*agg_value_on_period
	gen agg_value_on_period = . 
	replace agg_value_on_period = MONT*(365/15)
	
	
	save "$main/data/$country_fullname/expenses/adj_CQ07.dta", replace

	
	*RECALL MODULES
	clear 
	set more off
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	local file_num "cq17 cq19 cq23 cq25 cq27 cq29 cq31 cq33 cq35a cq35b cq37a cq37b cq39a cq39b cq41 cq43" 
	local annualization_factor "3 12 3 3 3 3 3 3 3 3 3 3 3 3 3 12"
	
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
		
		gen numzd_str = string(NumZD,"%03.0f")
		gen numen_str = string(Numen,"%03.0f") 
		egen hhid = concat(numzd_str numen_str )

		destring hhid, replace
		order hhid, first

		gen agg_value_on_period = . 
		replace agg_value_on_period = MONT*$annualization_factor
		gen module_tracker = "$file_num"

		save "$main/data/$country_fullname/expenses/adj_$file_num.dta", replace
	
}

	*We append all the expense files together
	cd "$main/data/$country_fullname/expenses"
	fs "*.dta"
	append using `r(files)'
	
	
	rename LIEUACH		 						TOR_original 
	rename MONT		 							amount_paid							
	rename QTE									quantity 							
	rename UNITE								unit								
	rename ORIGINE								country_of_prod						
	rename PRODUIT								product_code 						
	rename TYPDEP								type_expense
	
	
	
	*We need to construct/modify some of them
	*TOR_original
	destring TOR_original, force replace
	replace TOR_original = 21 if TOR_original == . | TOR_original ==30 |  TOR_original==99 |  TOR_original==0 // autre

	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	drop if agg_value_on_period == . 
	drop if product_code > 1270499 // only keep monetary expenses; 189 deleted
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Supermarche" 2 "Magasins"
	3 "Boutique" 4 "Marché centraux" 5 "Marché de quartier ou spécialisé"
	6 "Echoppe" 7 "Marchand ambulant" 8 "	Tablier"
	9 "Transport privé" 10 "Transport public" 11 "Prestataire service santé privé" 12 "Prestataire service santé public" 13 "Enseignement privé"
	14 "Enseignement public" 15 "Hôtel, Restaurant, .." 16 "Autre prestataire de service privé" 17 "Autre prestataire de service public"
	18 "Dans un pays de la zone franc" 19 "Pays africain hors zone franc" 20 "Ailleurs dans le monde" 21 "Autre" 22 "Self-Consumption"
	;#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	decode TOR_original, gen(TOR_original_name)
	
	tostring hhid, replace
	
	tempfile all_modules_with_TOR
	save `all_modules_with_TOR'
	
	*RENT MODULE
	clear 
	set more off
	use "$main/data/$country_fullname/ECOSIT_LOYER_IMPUTE.dta"  
	
	*We select the necessary variables and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	

	*We need to construct/modify some of them
	*hhid
	gen numzd_str = string(numzd,"%03.0f")
	gen numen_str = string(numen,"%03.0f") 
	egen hhid = concat(numzd_str numen_str )
	
	*agg_value_on_period
	gen loyer_real=(loyerd>0) // flag those who really pay a rent with 1 and those for which we have imputed a value 0
	gen product_code=4100 if loyer_real==1
	replace product_code=4200 if loyer_real==0 // loyer imputé
	gen agg_value_on_period=loyerd if loyer_real==1 
	replace agg_value_on_period=loyimp if loyer_real==0
	
	*coicop_2dig
	gen housing=1
	
	*TOR_original
	gen TOR_original=21
	
		#delim ; // create the label
	label define TOR_original_label 
	1 "Supermarche" 2 "Magasins"
	3 "Boutique" 4 "Marché centraux" 5 "Marché de quartier ou spécialisé"
	6 "Echoppe" 7 "Marchand ambulant" 8 "	Tablier"
	9 "Transport privé" 10 "Transport public" 11 "Prestataire service santé privé" 12 "Prestataire service santé public" 13 "Enseignement privé"
	14 "Enseignement public" 15 "Hôtel, Restaurant, .." 16 "Autre prestataire de service privé" 17 "Autre prestataire de service public"
	18 "Dans un pays de la zone franc" 19 "Pays africain hors zone franc" 20 "Ailleurs dans le monde" 21 "Autre" 22 "Self-Consumption"
	;#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	decode TOR_original, gen(TOR_original_name)
	
	tempfile rent
	save `rent'
	
	*add coicop_2dig
	use `all_modules_with_TOR' , clear
	append using `rent' 
	merge m:1 product_code using `coicop_2dig_crosswalk' 
	 
	*correct the missing by hand 
	replace coicop_2dig=4 if housing==1 
	replace coicop_2dig=1 if product_code<=15850
	replace coicop_2dig=2 if product_code>15850 & product_code<=16003

	
	tempfile modules_with_coicop_2dig
	save `modules_with_coicop_2dig'
	
	use `self_conso', clear
	append using `modules_with_coicop_2dig'
	
	*product_code
	drop if product_code==99999 // fetes et évenements 

	*We keep all household expenditures and relevant variables
	keep hhid product_code  TOR_original TOR_original_name  quantity  unit amount_paid agg_value_on_period coicop_2dig  housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace


***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

// Not COICOP but can't do a crosswalk, so we'll use their product_code

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
	by hhid: egen exp_rent = sum(agg_value_on_period) if product_code == 4100 // actual rent as expenses
	by hhid: egen exp_ir = sum(agg_value_on_period) if product_code == 4200 // imputed rent as expenses
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
	gen detailed_classification=1 if inlist(TOR_original,22)
	replace detailed_classification=2 if inlist(TOR_original,8,7,5,4)
	replace detailed_classification=3 if inlist(TOR_original,6)
	replace detailed_classification=4 if inlist(TOR_original,2,3)
	replace detailed_classification=5 if inlist(TOR_original,1)
	replace detailed_classification=6 if inlist(TOR_original,16,13,11,9,17,14,12,10,18,19,20)
	replace detailed_classification=8 if inlist(TOR_original,15)
	replace detailed_classification=99 if inlist(TOR_original,21)

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
    keep hhid product_code  TOR_original TOR_original_name   quantity  unit amount_paid  agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig product_code_2dig product_code_3dig product_code_4dig
	ren coicop_2dig COICOP_2dig
	*Modify a littl bit by hand 
	replace COICOP_2dig=4 if inlist(product_code, 20221, 23107, 36232)
	replace COICOP_2dig=5 if inlist(product_code, 24321,28201,28202,28203,29207,31004,31005,31006,31007)
	drop if COICOP_2dig==. // 0.25% des goods...
	
	gen product_code_2dig = substr(string(product_code,"%05.0f"),1,2)
	gen product_code_3dig = substr(string(product_code,"%05.0f"),1,3)
	gen product_code_4dig = substr(string(product_code,"%05.0f"),1,4)

	merge m:1 COICOP_2dig using "$main/proc/COICOP_label_2dig.dta"
	drop if _merge == 2
	drop _merge
	drop COICOP_2dig
	ren COICOP_Name2 COICOP_2dig
	
	merge m:1 product_code_4dig using `crosswalk_4dig'
	drop if _merge == 2
	drop _merge
	

	*We destring and label some variables for clarity/uniformity 
	destring COICOP_2dig, replace
	destring product_code_2dig, force replace											
	destring product_code_3dig, force replace											
	destring product_code_4dig, force replace											

	labmask product_code_4dig , values(product_lab)

	
	*We save the database with all expenditures for the price/unit analysis
	save "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" , replace

	*We create the final database at the COICOP_4dig level of analysis
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_2dig product_code_4dig product_code_3dig product_code_2dig  quantity unit detailed_classification) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	drop if TOR_original==.
	order hhid COICOP_2dig product_code_4dig product_code_3dig product_code_2dig exp_TOR_item quantity unit  TOR_original detailed_classification  housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_product_code_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
