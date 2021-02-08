

					*************************************
					* 			Main DO FILE			*
					* 	      	 Niger 2007				*
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

	
	global country_fullname "Niger2007"
	global country_code "NE"
	
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
* IMPORTANT NOTE 		   *
*****************************

*Imputed TOR for durables good 
	
*****************************
* Step 0:  Data overview    *
*****************************	
	
/*
	*r01.dta: Individual and household level general characteristics
	*r02.dta: q02_13 is the highest level of education variable,  q00_19 is hh_size
	*r07.dta: Informaion on rent, housing (but very sparse data points)
	*r09.dta: information on access to social services and transport
	*menageidentifiant.dta: has the hhweight variable
	*r12a.dta: non-alimentaire spending within last month (mostly housing, housing equipment it seems), no TOR
	*r12b.dta: non-alimentaire spending within last 3 months (basically just health, a little educ), no TOR
	*r12c.dta: non-alimentaire spending within last 6 months (basically just clothing), no TOR
	*r12d.dta: non-alimentaire spending within last 12 months (some transport, gas), no TOR
	*r13.dta: transfers
	*r15.dta: daily spending (has TOR)
	*enbc2007pivot.dta might have self production, but its a bit unclear [need to revisit this]
	
	*each of these files need to have the hhid created through a concatenation of grappe and menage
*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear
	set more off
	use "$main/data/$country_fullname/r02.dta", clear
	drop hhid
	gen hhid=enbc_id1*10^2 + enbc_id2
	drop if pid != 1 //keep only household heads and single-person households
	duplicates drop hhid, force
	tempfile edu
	save `edu'
	
	clear
	set more off
	use "$main/data/$country_fullname/menageidentifiant.dta", clear
	drop hhid
	gen hhid=enbc_id1*10^2 + enbc_id2
	tempfile geo
	save `geo'
	
	clear
	set more off
	use "$main/data/$country_fullname/r01.dta", clear
	gen hhid=enbc_id1*10^2 + enbc_id2
	
	*hhid
	merge m:1 hhid using `edu'
 	keep if _merge == 3
	drop _merge
	merge m:1 hhid using `geo'
 	keep if _merge == 3
	drop _merge


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename hhweight 							hh_weight
	rename region								geo_loc
	rename urru 								urban 
	rename milieu								ur_ru_sem
	rename q01_01								head_sex
	rename q01_07a								head_age
	rename q02_13								head_edu
	rename q00_19 								hh_size 
	rename q00_09 								geo_loc_min
	rename enbc_id1								census_block


	*We need to construct/modify some of them
	
	*exp_agg_tot, inc_agg_tot : look at enbc2007welfare



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
	keep if q01_03==1
	
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block 
	destring hhid, replace
	order hhid, first 
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , replace
	


************************************************************
* Step 2: Renaming and labelling the expenditures database *
************************************************************

**********************
* IMPORTANT COMMENTS *
**********************

/* 
At first, we thought we could find the right way to annualize the product looking at the dataset pivot (used by GCD, already standardized but no TOR) and apply it to the dataset r15 (diary with TOR). Looking at both carefully, we realized that many products in pivot were not in r15 (in green), and that we couldn’t multiply amounts in r15 by a single annualization factor to obtain the amounts in the pivot dataset r18 (Ail 10019/100=100,19 while beignet 3789.69/50=75). Particularly two kinds of products were not in r15, but appeared in pivot:
-	Non food product (which make sense as durables good are in modules 12a, 12b, 12c et 12d which datasets do not include a TOR)
-	Food products 
From the methodology document, (Profil-PauvreteNigerDraft2_INS_161208.pdf) our guess is that Food products that are in pivot but not in r15 have been imputed from module 18c on consummation. (see more details in Country with questions>Niger>Note on modulesNiger.docx)

Investigating this idea further we found that indeed, when the product was also listed on module r18 the differences in the amount listed in dataset r15 and pivot were odd (Ail 10019/100=100,19 or Beignet 3789.69/50=75) while when the product was not in r18, the difference between was just a factor 52, (Eau 73461.7/1400=52.47) revealing that expenses in r15 are weekly expenses, that have been annualized in pivot. (see Excel, sheet “Niger_pivot_r15_obsv”)
We decided that we couldn’t infer the expenditures values from the dataset r15, although it is the only one including the TOR. We therefore imputed these TOR to the pivot dataset. 

We first tried to impute a TOR by hhid and product_code ( meaning if a specific hh had purchased a specific durable good and was reporting it in the diary with a TOR, we would then assign the same TOR to that specific hh and good in the durable dataset. 
Yet, this leaves us with still a very large unspecified category. 
We then decide to do the imputation at the COICOP_2dig and decile level. In other words, we looked at the weights of all non missing TOR within a decile and COICOP_2dig category and assigned proportionaly TOR to the expenditures of that same decile and COICOP_@dig category with missing TOR. 
This left us with a bit more than 15% of expenditures in unspecified categories. 
Yet, all the expenses where either coming from the categories "other" or "g&s, recreation" . 



It was likely to be a problem because in some COICOP_2dig category the imputation was relying on a very few ammount of people. 
We therefore decided to put a threshold:  the imputation could be done if at least 15% of the COICOP_2dig category had an assigned TOR (Less than 85% assigned to "other"). 
This lead us to not impute a TOR for the following COICOP_2dig categories :  4 (Utilities) 6(Health) 7(Transports) 10(Education) 11(Hotel and restaurant). 
Finally, the unspecified category represents a bit less than 30% of the total expenditures, whcih seems reasoonable, comparing it to similar countries ( see graph missing_bycoicop_stackedbar in appendix B).

*/


************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************
*************************************************
*	TOR Imputation  *
*************************************************

	*DIARY
	clear
	set more off 
	use "$main/data/$country_fullname/r15.dta" ,clear
	gen hhid=enbc_id1*10^2 + enbc_id2
	drop if q15_03==.
	
	
	gen str6 codpr_tmp = substr(string(codpr,"%07.0f"), 1,5) // cut the code product so that it match the one from pivot for categories such as clothing
	drop codpr
	ren codpr_tmp codpr
	
	by codpr hhid ( q15_05 ), sort: gen desired = _N // see how many codpr by hhid have been bought in more than one TOR category 
	by codpr hhid ( q15_05 ): replace desired = 1 if q15_05[1] == q15_05[_N] // product by hhid that have een bought in the same TOR
	
	collapse (sum) q15_04, by(hhid codpr desired q15_05)
	egen hhid_codpr = concat(hhid codpr) // to merge
	gen module_tracker="r15"
	tostring hhid, replace
	tempfile r15_to_merge
	save `r15_to_merge'
		
	clear 
	set more off
	use "$main/data/$country_fullname/enbc2007pivot.dta", clear
	gen enbc_id2_str = string(enbc_id2,"%02.0f") 
	egen hhid = concat(enbc_id1 enbc_id2_str)
	keep if modep==1 // keep only "achat"
	
	
	
	gen str6 codpr_tmp = substr(string(codpr,"%07.0f"), 1,5)
	drop codpr
	ren codpr_tmp codpr
	
	
	gen module_tracker="pivot"
	collapse (sum) montant, by(hhid codpr)
	egen hhid_codpr = concat(hhid codpr) // to merge
	tostring hhid_codpr, replace
	merge 1:m hhid_codpr using `r15_to_merge'
	
	drop if _merge==2 // in r15 but not in pivot (GCD take into account only pivot!)
	
	gen TOR_original=.
	replace TOR_original=99 if _merge==1 // in pivot but not in r15  
	replace TOR_original=q15_05 if _merge==3 // codpr with only one TOR
	
	* When several TOR for one product for the same hhid put weight on the value 
	bys hhid codpr: egen sum_cons_distinct=total(q15_04) if desired>1
	gen fraction_cons_distinct=q15_04/sum_cons_distinct
	replace montant= montant*fraction_cons_distinct if fraction_cons_distinct!=.
	
	destring codpr, replace
	gen str6 COICOP_2dig = substr(string(codpr,"%05.0f"), 1,2)
	ta COICOP_2dig
	
	
	
	ta TOR, m
	drop if COICOP_2dig=="13"
	tempfile pivot2007_with_TOR
	save `pivot2007_with_TOR'
	
	
	*Now we need to add the other expenditures that are not in the category "Achat"
	use "$main/data/$country_fullname/enbc2007pivot.dta", clear
	gen enbc_id2_str = string(enbc_id2,"%02.0f") 
	egen hhid = concat(enbc_id1 enbc_id2_str)
	drop if modep==1 // keep all modep except "achat"
	
	
	gen str6 codpr_tmp = substr(string(codpr,"%07.0f"), 1,5)
	drop codpr
	ren codpr_tmp codpr
	destring codpr, replace
	append using `pivot2007_with_TOR'
	merge m:1 hhid using "$main/data/$country_fullname/menageidentifiant.dta" , gen (mweight)
	keep if mweight==3
	drop mweight
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	ren montant 			agg_value_on_period
	ren codpr 				product_code
	ren hhweight			hh_weight
	
	*TOR_original 
	
	replace TOR_original=1 if modep==2 // Auto consommation
	replace TOR_original=13 if modep==3 // Cadeau
	replace TOR_original=13 if modep==4 //Don
	replace TOR_original=14 if modep==5 // loyer impute
	replace TOR_original=14 if modep==6 // usage bien durable (9%)
	replace TOR_original=14 if TOR_original==99
	
	#delim ; // create the label
		label define TOR_original_label 
	1 "Auto production" 2 "Supermarche/Grand magasin" 3 "Magasin specialistes"
	4 "Epicerie, boutique" 5 "Marche" 6 "Hotel, bar restaurant"
	7 "Secteur transport" 8 "Prestation service individuels" 9 "Prestation services publiques"
	10 "Clinique, laboratoire, ecole" 11 "Vente ambulante" 
	12 "Etranger"
	13 "Cadeau recu" 14 "Autre" 15 "Transfers" ;
		#delim cr
		label list TOR_original_label
		label values TOR_original TOR_original_label // assign it
		ta TOR_original,m
	
	
		decode TOR_original, gen(TOR_original_name)
		ta TOR_original_name
	
	* We are gonna drop non food item as they did in the poverty report to avoid double count and won't include other modules. 
	*Decile Imputation
	egen total_exp = sum(agg_value_on_period), by(hhid)	
	xtile decile = total_exp [weight=hh_weight], nq(10) 

	bys COICOP_2dig: ta TOR_original // COICOP categories 3,4,5,6,7,8,9,10 11 have more than 85% of missing TOR

	gen impute=(COICOP_2dig!="04" & COICOP_2dig!="06"  & COICOP_2dig!="07"  & COICOP_2dig!="10" & COICOP_2dig!="11")


	* We assign weight 
	bys decile COICOP_2dig: egen sum_cons_COICOP=total(agg_value_on_period) if TOR_original!=14
	bys decile COICOP_2dig TOR_original: egen sum_cons_TOR=total(agg_value_on_period) if TOR_original!=14
	gen share_cons_TOR_COICOP=sum_cons_TOR/sum_cons_COICOP if TOR_original!=14
	
	
	forval i = 1/13 {
	bys decile COICOP_2dig TOR_original: egen share_`i'prep=mean(share_cons_TOR_COICOP) if TOR_original==`i'
	bys decile COICOP_2dig: egen share`i'=mean(share_`i'prep)
	}
	tempfile all_lines_raw_r15_assign_TOR
	save `all_lines_raw_r15_assign_TOR'
	
	*test
	keep if TOR_original==14
	keep decile hhid  hh_weight product_code agg_value COICOP_2dig share1 share2 share3 share4 share5 share6 share7 share8 share9 share10 share11 share12 share13
	duplicates drop
	reshape long share, i(hhid decile product_code agg_value_on_period COICOP_2dig hh_weight) j(TOR_original)
	gen new_agg_value_on_period= agg_value_on_period*share
	drop if new_agg_value_on_period==.
	
	tempfile raw_r15_assign_TOR_autre
	save `raw_r15_assign_TOR_autre'
	
	use `all_lines_raw_r15_assign_TOR', replace
	drop if TOR_original==14 & (share1!=. | share2!=. | share3!=. | share4!=. | share5!=. | share6!=. |share7!=. | share8!=. |share9!=. |share10!=. |share11!=. |share12!=. |share13!=.)
	append using `raw_r15_assign_TOR_autre'
	
	replace agg_value_on_period=new_agg_value_on_period if new_agg_value_on_period!=.
	drop TOR_original_name
	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	
	keep decile hhid hh_weight  TOR_original TOR_original_name agg_value_on_period ///
			product_code     
	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	destring hhid, replace
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
	bys hhid: egen exp_rent = sum(agg_value_on_period) if coicop_2dig == "41" // actual rent as expenses
	bys hhid: egen exp_ir = sum(agg_value_on_period) if coicop_2dig == "42" // imputed rent as expenses
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
	gen detailed_classification=1 if inlist(TOR_original,1,9,13)
	replace detailed_classification=2 if inlist(TOR_original,11,5)
	replace detailed_classification=3 if inlist(TOR_original,4)
	replace detailed_classification=4 if inlist(TOR_original,3)
	replace detailed_classification=5 if inlist(TOR_original,2)
	replace detailed_classification=6 if inlist(TOR_original,7,10,12)
	replace detailed_classification=7 if inlist(TOR_original,8)
	replace detailed_classification=8 if inlist(TOR_original,6)
	replace detailed_classification=99 if inlist(TOR_original,14)

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
    keep hhid product_code TOR_original TOR_original_name agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen str6 COICOP_2dig = substr(string(product_code,"%05.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(product_code,"%05.0f"), 1,3) 
	gen str6 COICOP_4dig = substr(string(product_code,"%05.0f"), 1,4) 

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
	
	
