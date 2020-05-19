

					*************************************
					* 			Main DO FILE			*
					* 	      Eswatini 2010				*
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

	
	global country_fullname "Eswatini2010"
	global country_code "SZ"
	
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
R000_Identification: geographic indicators (EA code, urban/rural, HHID, region, sub-areas)
R1_Individual: hhid, relationshio to hh, sex, age, highest level school, expenses on schooling
R2_Dwelling: hhid, monthly actual rent + imputed rent; has car/bicycle questions
R9_Regular_payment: total cost for medical expenditures in the last month + year [good if not in other expense module]
R12_Income + R12_Income2: a ton of income variables

income data is not great though. I think better to use expenses. Only data is 
income from pension, remittances, property, etc. No a regular salary. 

R16_Purchase: diary of expenses, with place of purchase, quantity, amount paid, product code (not COICOP) - need to check time span
R19_GS_received: transfers/gifts recived, code, quantity, estimated value
R21_Own_produced: extract self-production
SWZ2010_Poverty: household size, sample weight
*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear	
	set more off
	use "$main/data/$country_fullname/R000_Identification.dta", clear
	merge 1:m hhid using "$main/data/$country_fullname/R1_Individual.dta"
	keep if _merge==3
	drop _merge
	merge m:1 hhid using "$main/data/$country_fullname/R2_Dwelling.dta", nogen
	merge m:1 hhid using "$main/data/$country_fullname/SWZ2010_Poverty.dta"
	keep if _merge ==3 
	drop _merge
	
	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename weight	 							hh_weight
	rename region								geo_loc	
	rename inkhundla							geo_loc_min						// administrative subdivision smaller than a district but larger than chiefdom
	rename clust								census_block					// enumeration area code
	rename area 								urban 
	rename sex									head_sex
	rename age									head_age
	rename edlevel								head_edu
	rename rentpaid 							house_rent 						// HH rent actual (monthly)
	rename rentimp 								house_est_rent 					// HH rent estimate (monthly)
	rename hhsize	 							hh_size

	

	
	*We need to construct/modify some of them

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
	keep if rel == 1
 	duplicates drop hhid , force 
 
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block house_rent house_est_rent
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
	use "$main/data/$country_fullname/R16_Purchase.dta", clear
	merge m:1 hhid using "$main/data/$country_fullname/SWZ2010_Poverty.dta", keepusing(weight)
	keep if _merge == 3
	drop _merge
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing

	rename weight	 						hh_weight
	rename where	 						TOR_original 
	rename code								product_code // 456 unique product codes, not COICOP
	rename qty								quantity 							
	rename value							amount_paid


	
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = (365/15)*amount_paid
	
	*price
	gen price = amount_paid/quantity 				// unit price

	gen module_tracker="diary"
	tempfile diary
	save `diary'
	
	*SELF CONSUMPTION
	
	clear 
	set more off

	use "$main/data/$country_fullname/R21_Own_produced.dta", clear
	merge m:1 hhid using "$main/data/$country_fullname/SWZ2010_Poverty.dta", keepusing(weight)
	keep if _merge == 3
	drop _merge
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight	 						hh_weight
	rename code								product_code
	rename value 							amount_paid
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = (365/15)*amount_paid							
	
	*price
	gen price = amount_paid/quantity  // unit price
	
	*TOR_original
	gen TOR_original = 10 
	
	gen module_tracker="self_conso"
	tempfile self_conso
	save `self_conso'
	
	*TRANSFERS
	clear 
	set more off

	use "$main/data/$country_fullname/R19_GS_received.dta", clear
	merge m:1 hhid using "$main/data/$country_fullname/SWZ2010_Poverty.dta", keepusing(weight)
	keep if _merge == 3
	drop _merge
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight	 						hh_weight
	rename code								product_code
	rename value 							amount_paid
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = 12*amount_paid							
	
	*price
	gen price = amount_paid/quantity  // unit price
	
	*TOR_original
	gen TOR_original = 11
	
	gen module_tracker="transfers"
	tempfile transfers
	save `transfers'
	
	
	
	*EDUCATION
	clear
	set more off
	use "$main/data/$country_fullname/R1_Individual.dta", clear
	merge m:1 hhid using "$main/data/$country_fullname/SWZ2010_Poverty.dta", keepusing(weight)
	keep if _merge == 3
	drop _merge
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename weight							hh_weight
	
	*We need to construct/modify some of them
	*agg_value_on_period
	sort hhid
	by hhid: egen tuition = sum(edexptui), missing
	by hhid: egen books = sum(edexpboo), missing
	by hhid: egen uniform = sum(edexpuni), missing
	by hhid: egen boarding = sum(edexpboa), missing
	by hhid: egen fees = sum(edexpexa), missing

	keep if rel == 1	
	duplicates report hhid
	duplicates drop hhid, force

	keep hhid hh_weight tuition books uniform boarding fees 
	egen schooling = rowtotal(tuition - fees), missing
	
	keep hhid hh_weight schooling
	drop if schooling == .
	rename schooling agg_value_on_period 

	*TOR_original
	gen TOR_original = 16
	
	*product_code, create arbitrary product_code that will be addressed in crosswalk
	gen int product_code = 999
	label define product_code_lab 999 "education"
	label values product_code product_code_lab
	
	gen module_tracker="education"
	tempfile education
	save `education'
	
	*HOUSING
	use "$main/waste/$country_fullname/${country_code}_household_cov_original.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	keep hhid hh_weight house_rent house_est_rent
	
	*We need to construct/modify some of them
	*product_code
	gen int product_code = . 
	replace product_code = 4100 if house_rent!=0
	replace product_code = 4200 if house_est_rent!=0
	label define product_code_lab 4100 "actual rent" 4200 "imputed rent"
	label values product_code product_code_lab
	
	*coicop_2dig
	gen coicop_2dig="41" if product_code==4100
	replace coicop_2dig="42" if product_code==4200
	
	*agg_value_on_period 
	egen rent = rowtotal(house_rent house_est_rent)
	gen agg_value_on_period = 12*rent
	
	*TOR_original
	gen TOR_original = 16

	*Housing
	gen housing=1
	
	tempfile housing
	save `housing'
	
	
	*Append all the modules
	use `diary', clear 
	append using `self_conso'
	append using `transfers'
	append using `education'
	append using `housing'

	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	replace TOR_original=16 if TOR_original==.

	destring TOR_original, force replace
	ta TOR_original
	#delim ; // create the label
	label define TOR_original_label 
1 "Supermarket" 2 "Grocery" 3 "Butchery"
4 "Hardware store" 5 "Market" 6 "Street Vendor"
7 "Book Store" 8 "Spaza" 9 "Clothes/Footwear/Linen"
10 "Self production" 11 "Gifts/transfers" 
12 "Missing" 16 "Other" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	*We keep all household expenditures and relevant variables
	keep hhid product_code  TOR_original TOR_original_name  quantity price unit amount_paid agg_value_on_period  TOR_original_name coicop_2dig housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace


***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

	use "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", clear
	
	decode product_code, gen(product_code_label)
	gen str_product_code = product_code
	duplicates drop str_product_code, force // 491 unique products

	export excel product_code_label str_product_code using "$main/tables/$country_fullname/SZ_productcode_crosswalk.xlsx", replace
	
	*by hand crosswalk
	
	import excel "$main/tables/$country_fullname/SZ_HIES_crosswalk_COICOP.xlsx", sheet("crosswalk") firstrow clear
	merge m:m product_code using "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	keep if _merge==3
	drop _merge
	drop if COICOP == ""
	
	gen str8 COICOP_8dig = substr(COICOP,1,8)
	gen str7 COICOP_7dig = substr(COICOP,1,7)
	gen str6 COICOP_6dig = substr(COICOP,1,6)
	gen str5 COICOP_5dig = substr(COICOP,1,5)
	gen str4 COICOP_4dig = substr(COICOP,1,4)
	gen str3 COICOP_3dig = substr(COICOP,1,3)
	gen str2 COICOP_2dig = substr(COICOP,1,2)

	drop if COICOP > "12711301" // only keep consumption expenditures
	sort hhid 
	save "$main/waste/$country_fullname/${country_code}_all_lines_COICOP_crosswalk.dta" , replace


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
	use "$main/waste/$country_fullname/${country_code}_all_lines_COICOP_crosswalk.dta"
	
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
	gen detailed_classification=1 if inlist(TOR_original,10,11)
	replace detailed_classification=2 if inlist(TOR_original,5,6)
	replace detailed_classification=3 if inlist(TOR_original,2,8)
	replace detailed_classification=4 if inlist(TOR_original,3,4,7,9)
	replace detailed_classification=5 if inlist(TOR_original,1)
	replace detailed_classification=99 if inlist(TOR_original,12,16)




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
	merge 1:m TOR_original using  "$main/waste/$country_fullname/${country_code}_all_lines_COICOP_crosswalk.dta"

	*We keep all household expenditures and relevant variables
    keep hhid product_code  TOR_original TOR_original_name  quantity price unit amount_paid  agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses COICOP_2dig COICOP_3dig COICOP_4dig
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	


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
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item quantity unit price TOR_original detailed_classification  housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	erase  "$main/waste/$country_fullname/${country_code}_all_lines_COICOP_crosswalk.dta"
	
