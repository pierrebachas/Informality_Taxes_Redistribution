

					*************************************
					* 			Main DO FILE			*
					* 	       CAMEROON 2014			*
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

	
	global country_fullname "Cameroon2014"
	global country_code "CM"
	
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
	*ECAM4MEN.dta: Household level general statistics, one line per household. 
	*ECAM4IND.dta: Individual level general statistics, looks as if it should have info on salary.
	*ECAM4_Weight_12052015.dta: The survey weight 
	*ECAM4LOG.dta: Informaion on rent and type of housing
	*ECAM4S14.dta: Daily household expense diary 
	*ECAM4S12L.dta: Information on self production and home consumption 
	*ECAM4S12B.dta: Information on livestock both sold and consumed by a household
*/

**********************
* IMPORTANT NOTE *
**********************

/*
Cameroon analysis was odd because taking into account the diary only we obtained a very wide spread distribution.
Taking aggregates expenses values already computed in the dataset we found a much less spread distribution
We therfore performed a number of change following the guidelines found on the following document p.11 (which explain how they computed the aggregates expenses) :
https://slmp-550-104.slc.westdc.net/~stat54/downloads/2016/Rapport_tendances_profil_determiants_pauvrete_2001_2014.pdfhttps://slmp-550-104.slc.westdc.net/~stat54/downloads/2016/Rapport_tendances_profil_determiants_pauvrete_2001_2014.pdf
We didn't have the informations to follow the exact same methodology they followed but we conducted different changes:
- We first change the annualization for the diary to (365/15) for urban households and to (365/10) for rural households
- We then applied a deflator to the diary values depending on the household region of residency
- We took the max of self consumption between the amount declared in the diary and the one included in the self-consumption modules
- We removed non food items from the diary and added the items from the retroactive module. Yet, items from this recall modules do not have TOR so we had to impute them at the decile and COICOP_2dig level, based on the non food expenses from the diary (that we have removed from total expenses)
The TOR imputation is detailed below:

We impute TOR to the durables goods because the "nonfood items" dataset does not have TOR, which bring the unspecified categories to more than xx% of the expenditure. 
Yet there is also a diary that has both durables and non durables good and has TOR. 
We first tried to use the analysis only with the diary, but we ended up with an over represented food consumption.
We then decided to include the nonfooditems/durables dataset.
To reduce the huge unspecified TOR category that was coming from this durable dataset we therefore imputed the TOR based on the TOR that were reported for the small ammount of durables goods present in the dairy. 
We first tried to impute a TOR by hhid and product_code ( meaning if a specific hh had purchased a specific durable good and was reporting it in the diary with a TOR, we would then assign the same TOR to that specific hh and good in the durable dataset. 
Yet, this leaves us with still a very large unspecified category. (Code in the draft section at the end of the do file).
Contrary to Niger and Montenegro we decided to do the entire imputation at the COICOP_2dig and decile level. In other words, we looked at the weights of all non missing TOR within a decile and COICOP_2dig category and assigned proportionaly TOR to the expenditures of that same decile and COICOP_2dig category with missing TOR. 
This left us with a very small amount of expenditures in unspecified categories. We carefully construct expenses decile with the diary food item only, and the items from the retroactive module. We however, imputed the TOR from the non food item of the diary that we did not take into account in total expenses.
It was likely to be a problem because in some COICOP_2dig category the imputation was relying on a very few ammount of people. 
We therefore decided to put a threshold:  the imputation could be done if at least 15% of the COICOP_2dig category had an assigned TOR (Less than 85% assigned to "other"). 
This lead us to not impute a TOR for the following COICOP_2dig categories :  3 (Clothing) 9(Recreation) 10(Education). 
Finally, the unspecified category represents a bit less than 4.77% of the total expenditures, whcih seems reasoonable, comparing it to similar countries ( see graph missing_bycoicop_stackedbar in appendix B).

*/

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear
	set more off
	use "$main/data/$country_fullname/ECAM4IND.dta", clear
	egen hhid = concat(S0Q2 S0Q5)
	ren DEPTOTF expenses
	ren S03Q4N head_edu
	keep if S01Q3==1
	duplicates drop hhid, force	
	keep hhid expenses head_edu
	tempfile demo_indiv
	save `demo_indiv'
	
	clear
	set more off
	use "$main/data/$country_fullname/ECAM4MEN.dta", clear
	egen hhid = concat(S0Q2 S0Q5)
	merge m:1 S0Q2 using "$main/data/$country_fullname/ECAM4_Weight_12052015.dta" 
	keep if _merge==3 // 1 obs dropped
	drop _merge
	
	merge m:1 hhid using "$main/data/$country_fullname/ECAM4LOG.dta" 
	drop _merge // all matched
	
	merge m:1 hhid using "$main/data/$country_fullname/hh_income.dta"
	drop _merge
	
	merge 1:m hhid using `demo_indiv'


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename COEFEXTR 							hh_weight
	rename S0Q1									geo_loc // region = 12 unique values
	rename MILIEU 								urban 
	rename S01Q2								head_sex
	rename S01Q4								head_age
	rename S07Q04 								hh_size    						// Nombre de personnes dans le menage il y a 12 mois
	rename S06Q4  								house_rent 	
	
	

	
	*We need to construct/modify some of them
	*geo_loc_min
	gen geo_loc_min = geo_loc

	*census_block
	gen census_block = S0Q2 // Numero sequentiel de la Zones de Dénombrement; best guess - 1017 unique values

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

	
	*SELF CONSO
	clear all 
	set more off
	use "$main/data/$country_fullname/ECAM4S12L.dta", clear

	egen hhid = concat(S0Q2 S0Q5)
	order hhid, first
	sort hhid
	
	* In this survey, we need to import some variables from housing, weight, and HH income datasets
	merge m:1 S0Q2 using "$main/data/$country_fullname/ECAM4_Weight_12052015.dta" 
	keep if _merge==3 // 1 obs dropped
	drop _merge
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename COEFEXTR 							hh_weight
	keep if S12Q87==1 // keep only if consumed
	
	*We need to construct/modify some of them
	*Agg_value_on_period
	gen agg_value_on_period = . 
	replace agg_value_on_period = S12Q88*365 if S12Q88P==1
	replace agg_value_on_period = S12Q88*52 if S12Q88P==2
	replace agg_value_on_period = S12Q88*26 if S12Q88P==3
	replace agg_value_on_period = S12Q88*12 if S12Q88P==4
	replace agg_value_on_period = S12Q88*3 if S12Q88P==5
	replace agg_value_on_period = S12Q88*2 if S12Q88P==6
	replace agg_value_on_period = S12Q88 if S12Q88P==7

	*Product_code
	gen product_code = . 
	replace product_code = 121 if S12Q84==1 //cacao
	replace product_code = 121 if S12Q84==2 //coffee
	replace product_code = 314 if S12Q84==3 //cotton
	replace product_code = 116 if S12Q84==4 //peanuts
	replace product_code = 220 if S12Q84==5 //tobacco
	replace product_code = 116 if S12Q84==6 //plaintain
	replace product_code = 116 if S12Q84==7 //banana
	replace product_code = 117 if S12Q84==8 //tomatoes
	replace product_code = 115 if S12Q84==9 //palm oil
	replace product_code = 117 if S12Q84==10 //cassava
	replace product_code = 117 if S12Q84==11 //taro
	replace product_code = 117 if S12Q84==12 //yam
	replace product_code = 117 if S12Q84==13 //potatoes
	replace product_code = 117 if S12Q84==14 //other potatoes
	replace product_code = 117 if S12Q84==15 //corn
	replace product_code = 111 if S12Q84==16 //rice
	replace product_code = 111 if S12Q84==17 //sorghum
	replace product_code = 116 if S12Q84==18 //pineapple
	replace product_code = 117 if S12Q84==19 //onion
	replace product_code = 117 if S12Q84==20 //beans
	replace product_code = 117 if S12Q84==21 //garlic
	replace product_code = 116 if S12Q84==22 //citrus
	replace product_code = 116 if S12Q84==23 //plum
	replace product_code = 116 if S12Q84==24 //avocados
	replace product_code = 116 if S12Q84==25 //mangos
	replace product_code = 119 if S12Q84==27 //ginger
	replace product_code = 117 if S12Q84==28 //cabbage
	replace product_code = 117 if S12Q84==29 //carrot
	replace product_code = 117 if S12Q84==30 //okra
	replace product_code = 117 if S12Q84==31 //chili peppers
	replace product_code = 116 if S12Q84==32 //pistachios
	replace product_code = 117 if S12Q84==33 //spinach
	replace product_code = 119 if S12Q84==34 //other
	drop if product_code == . 

	*product_name
	gen product_name = "" 
	replace product_name = "Coffee and cacao" if product_code == 121
	replace product_name = "Cotton" if product_code == 314
	replace product_name = "Peanuts, plaintains, bananas other fruits" if product_code == 116
	replace product_name = "Vegetables" if product_code == 117
	replace product_name = "Palm oil" if product_code == 115
	replace product_name = "Other food products" if product_code == 119

	*TOR_original
	gen TOR_original = . 
	replace TOR_original = 1 if TOR_original == . 
	
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
0 "Not applicable" 1 "Auto production" 2 "Supermarche/Grand magasin" 3 "Magasin specialistes"
4 "Vendeurs specialises hors magasins" 5 "Epiceries/Boutiques/Echoppes" 6 "Marches"
7 "Hotels/bars/restaurants" 8 "Secteur transport" 9 "Prestation de services individuels"
10 "Presetation de services publics" 11 "Cliniques" 
12 "Vente ambulante"
13 "Domicile de vendeur" 14 "Kiosque de jeux et Call Box" 15 "Don, cadeau recu" 16 "Dans la nature/forit/brousse"
17 "Autre" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == . 

	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_name
		
	saveold "$main/waste/$country_fullname/${country_code}_all_lines_raw_selfprod_agro.dta", replace

	*SELF-CONS 2
	use "$main/data/$country_fullname/ECAM4S12B.dta", clear
	
	egen hhid = concat(S0Q2 S0Q5)
	order hhid, first
	sort hhid
	
	* In this survey, we need to import some variables from housing, weight, and HH income datasets
	merge m:1 S0Q2 using "$main/data/$country_fullname/ECAM4_Weight_12052015.dta" 
	keep if _merge==3 // 1 obs dropped
	drop _merge

	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename COEFEXTR 							hh_weight
	keep if S12Q5 == 1 // keep only if consumed
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = . 
	replace agg_value_on_period = S12Q6*365 if S12Q6P==1
	replace agg_value_on_period = S12Q6*52 if S12Q6P==2
	replace agg_value_on_period = S12Q6*26 if S12Q6P==3
	replace agg_value_on_period = S12Q6*12 if S12Q6P==4
	replace agg_value_on_period = S12Q6*3 if S12Q6P==5
	replace agg_value_on_period = S12Q6*2 if S12Q6P==6
	replace agg_value_on_period = S12Q6 if S12Q6P==7
	
	*product_code
	gen product_code = . 
	replace product_code = 112 if S12Q2!=. //all meat products: beef, chicken, etc. 

	*Product_name
	gen product_name = "" 
	replace product_name = "Beef, chicken, rabbit, mutton" if product_code == 112
	
	*TOR_original
	gen TOR_original = . 
	replace TOR_original = 1 if TOR_original == . 
	
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
0 "Not applicable" 1 "Auto production" 2 "Supermarche/Grand magasin" 3 "Magasin specialistes"
4 "Vendeurs specialises hors magasins" 5 "Epiceries/Boutiques/Echoppes" 6 "Marches"
7 "Hotels/bars/restaurants" 8 "Secteur transport" 9 "Prestation de services individuels"
10 "Presetation de services publics" 11 "Cliniques" 
12 "Vente ambulante"
13 "Domicile de vendeur" 14 "Kiosque de jeux et Call Box" 15 "Don, cadeau recu" 16 "Dans la nature/forit/brousse"
17 "Autre" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == . 

	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_name
		
	saveold "$main/waste/$country_fullname/${country_code}_all_lines_raw_selfprod_livestock.dta", replace

	*SELF-CONSO 3
	use "$main/data/$country_fullname/ECAM4S12E.dta", clear
	egen hhid = concat(S0Q2 S0Q5)
	order hhid, first
	sort hhid
	
	* In this survey, we need to import the weight variables 
	merge m:1 S0Q2 using "$main/data/$country_fullname/ECAM4_Weight_12052015.dta" 
	keep if _merge==3 // 1 obs dropped
	drop _merge
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	rename COEFEXTR 							hh_weight
	keep if S12Q65 == 1 // Keep consumed
	
	*agg_value_on_period
	gen agg_value_on_period = . 
	replace agg_value_on_period = S12Q66*365 if S12Q68P==1
	replace agg_value_on_period = S12Q66*52 if S12Q68P==2
	replace agg_value_on_period = S12Q66*26 if S12Q68P==3
	replace agg_value_on_period = S12Q66*12 if S12Q68P==4
	replace agg_value_on_period = S12Q66*3 if S12Q68P==5
	replace agg_value_on_period = S12Q66*2 if S12Q68P==6
	replace agg_value_on_period = S12Q66 if S12Q68P==7
	
	*product_code
	gen product_code =  .
	replace product_code = 117 if inlist(S12Q64,1,2,3,4,6)
	replace product_code = 212 if inlist(S12Q64,5)
	replace product_code = 115 if inlist(S12Q64,7)
	//all meat products: beef, chicken, etc. 

	*product_name
	gen product_name = "" 
	replace product_name = "Okock/Eru, Champignon, Djansang, Mangoe, Baobab" if product_code == 117
	replace product_name = "Vin blanc (Raphia/Palmier)" if product_code == 212
	replace product_name = "Karite" if product_code == 115

	*TOR_original
	gen TOR_original =1 
	
	destring TOR_original, force replace
	ta TOR_original
	
	#delim ; // create the label
	label define TOR_original_label 
0 "Not applicable" 1 "Auto production" 2 "Supermarche/Grand magasin" 3 "Magasin specialistes"
4 "Vendeurs specialises hors magasins" 5 "Epiceries/Boutiques/Echoppes" 6 "Marches"
7 "Hotels/bars/restaurants" 8 "Secteur transport" 9 "Prestation de services individuels"
10 "Presetation de services publics" 11 "Cliniques" 
12 "Vente ambulante"
13 "Domicile de vendeur" 14 "Kiosque de jeux et Call Box" 15 "Don, cadeau recu" 16 "Dans la nature/forit/brousse"
17 "Autre" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	drop if TOR_original == . 

	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_name
		
	saveold "$main/waste/$country_fullname/${country_code}_all_lines_raw_selfprod_cueillette.dta", replace
	
	*DIARY
	clear 
	set more off
	use "$main/data/$country_fullname/ECAM4S14.dta", clear
	
	* This survey separates households from dwellings. Therefore it is necessary to create a unique variable that combines both of them. 
	egen hhid = concat(S0Q2 S0Q5)
	order hhid, first

	merge m:1 S0Q2 using "$main/data/$country_fullname/ECAM4_Weight_12052015.dta" 
	keep if _merge==3 // 1 obs dropped
	merge m:1 hhid using "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , gen (murban)
	keep if murban==3 // 1 obs dropped
	drop murban
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename S14Q10 							TOR_original 
	rename S14Q5							product_code
	rename S14Q5N							product_name 

	

	*We need to modify/construct some of them
	*agg_value_on_period
	gen agg_value_on_period = S14Q7*(365/15) if urban==1 //annualize 15-day expense diary
	replace agg_value_on_period = S14Q7*(365/10) if urban==2


	gen deflateur=0.87 if geo_loc==5
	replace deflateur=0.88 if geo_loc==10
	replace deflateur=0.94 if geo_loc==3
	replace deflateur=0.96 if geo_loc==6
	replace deflateur=0.98 if geo_loc==7
	replace deflateur=0.99 if geo_loc==8
	replace deflateur=0.99 if geo_loc==12
	replace deflateur=1.00 if geo_loc==2
	replace deflateur=1.00 if geo_loc==9
	replace deflateur=1.00 if geo_loc==4
	replace deflateur=1.02 if geo_loc==11
	replace deflateur=1.04 if geo_loc==1
	
	replace agg_value_on_period = agg_value_on_period/deflateur 
	
	*TOR_original
	destring TOR_original, force replace
	ta TOR_original
	replace TOR_original = 15 if TOR_original == . &  S14Q9==2 //some of "gift" category missing from TOR but are in mode of acquisition
	replace TOR_original = 15 if TOR_original == . &  S14Q9==7 //some of "gift" category missing from TOR but are in mode of acquisition
	replace TOR_original = 17 if TOR_original == . //put other missing TOR into "other" category.
	drop if product_code > 1270705 
	
	#delim ; // create the label
	label define TOR_original_label 
0 "Not applicable" 1 "Auto production" 2 "Supermarche/Grand magasin" 3 "Magasin specialistes"
4 "Vendeurs specialises hors magasins" 5 "Epiceries/Boutiques/Echoppes" 6 "Marches"
7 "Hotels/bars/restaurants" 8 "Secteur transport" 9 "Prestation de services individuels"
10 "Presetation de services publics" 11 "Cliniques" 
12 "Vente ambulante"
13 "Domicile de vendeur" 14 "Kiosque de jeux et Call Box" 15 "Don, cadeau recu" 16 "Dans la nature/forit/brousse"
17 "Autre" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_name

	drop if product_code ==  410001 | product_code == 410002 | product_code == 410003 //exclude redundant housing expenses?
	drop if product_code > 1270705 //keep only monetary expenses
	gen module_tracker="diary"
	//if we removed durables from diary 
	drop if product_code >= 311001
	
	preserve
	keep if TOR_original==1
	tempfile diary_self_conso_raw
	save `diary_self_conso_raw' 
	restore
	drop if TOR_original==1
	saveold "$main/waste/$country_fullname/${country_code}_all_lines_raw_diary_no_selfprod.dta", replace

	
	
	*We keep the maximum consumption between the self_production modules and the diary
	use `diary_self_conso_raw'
	keep if TOR_original==1
	gen str6 COICOP_4dig = substr(string(product_code, "%07.0f"), 1,4)
	egen hhid_COICOP_4dig = concat(hhid COICOP_4dig)
	collapse (sum) agg_value_on_period , by (hhid_COICOP_4dig hhid COICOP_4dig)
	ren agg_value_on_period agg_value_on_period_diary
	tempfile diary_self_conso
	save `diary_self_conso'
	use "$main/waste/$country_fullname/${country_code}_all_lines_raw_selfprod_agro.dta" , clear 
	append using "$main/waste/$country_fullname/${country_code}_all_lines_raw_selfprod_livestock.dta"
	append using  "$main/waste/$country_fullname/${country_code}_all_lines_raw_selfprod_cueillette.dta"
	gen str6 COICOP_4dig = substr(string(product_code, "%04.0f"), 1,4)
	egen hhid_COICOP_4dig = concat(hhid COICOP_4dig)
	collapse (sum) agg_value_on_period , by (hhid_COICOP_4dig hhid COICOP_4dig)

	merge 1:1 hhid_COICOP_4dig using `diary_self_conso'
	drop if _merge==2
	egen max_self_conso = rowmax(agg_value_on_period agg_value_on_period_diary) 
	drop agg_value_on_period agg_value_on_period_diary hhid_COICOP_4dig _merge
	ren max_self_conso agg_value_on_period
	merge m:1 hhid using "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , gen (murban)
	keep if murban==3 // 1 obs dropped
	keep hhid COICOP_4dig agg_value_on_period hh_weight
	gen TOR_original=1
	destring COICOP_4dig, replace
	gen product_code= COICOP_4dig*1000
	drop COICOP_4dig
	tempfile self_conso
	save `self_conso'
	
	*DURABLES - Need to Impute TOR from diary
	****ONLY AT THE DECILE LEVEL
	clear 
	set more off
	use "$main/data/$country_fullname/ECAM4S14.dta", clear
	
	* This survey separates households from dwellings. Therefore it is necessary to create a unique variable that combines both of them. 
	egen hhid = concat(S0Q2 S0Q5)
	order hhid, first


	merge m:1 hhid using "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , gen (murban)
	keep if murban==3 // 1 obs dropped
	drop murban
		
	rename S14Q10 							TOR_original 
	rename S14Q5							product_code
	rename S14Q5N							product_name 


	
	gen agg_value_on_period = S14Q7*(365/15) if urban==1 //annualize 15-day expense diary
	replace agg_value_on_period = S14Q7*(365/10) if urban==2
	
	gen deflateur=0.87 if geo_loc==5
	replace deflateur=0.88 if geo_loc==10
	replace deflateur=0.94 if geo_loc==3
	replace deflateur=0.96 if geo_loc==6
	replace deflateur=0.98 if geo_loc==7
	replace deflateur=0.99 if geo_loc==8
	replace deflateur=0.99 if geo_loc==12
	replace deflateur=1.00 if geo_loc==2
	replace deflateur=1.00 if geo_loc==9
	replace deflateur=1.00 if geo_loc==4
	replace deflateur=1.02 if geo_loc==11
	replace deflateur=1.04 if geo_loc==1
	
	*deflator 
	replace agg_value_on_period = agg_value_on_period/deflateur 
	
	destring TOR_original, force replace
	ta TOR_original
	replace TOR_original = 15 if TOR_original == . &  S14Q9==2 //some of "gift" category missing from TOR but are in mode of acquisition
	replace TOR_original = 15 if TOR_original == . &  S14Q9==7 //some of "gift" category missing from TOR but are in mode of acquisition
	replace TOR_original = 17 if TOR_original == . //put other missing TOR into "other" category.
	drop if product_code > 1270705 
	
	#delim ; // create the label
	label define TOR_original_label 
	0 "Not applicable" 1 "Auto production" 2 "Supermarche/Grand magasin" 3 "Magasin specialistes"
	4 "Vendeurs specialises hors magasins" 5 "Epiceries/Boutiques/Echoppes" 6 "Marches"
	7 "Hotels/bars/restaurants" 8 "Secteur transport" 9 "Prestation de services individuels"
	10 "Presetation de services publics" 11 "Cliniques" 
	12 "Vente ambulante"
	13 "Domicile de vendeur" 14 "Kiosque de jeux et Call Box" 15 "Don, cadeau recu" 16 "Dans la nature/forit/brousse"
	17 "Autre" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	keep hhid hh_weight TOR_original TOR_original_name agg_value_on_period product_code product_name

	drop if product_code > 1270705 //keep only monetary expenses

	gen module_tracker="diary - food" if product_code <= 311001
	replace module_tracker="diary - nonfood" if product_code >= 311001
	
	preserve 
	keep if module_tracker=="diary - food"
	tempfile diary_food
	save `diary_food'
	restore
	
	preserve 
	keep if module_tracker=="diary - nonfood"
	tempfile diary_nonfood
	save `diary_nonfood'
	restore
	
	
	
	*Retrospective item(no TOR)
	clear 
	set more off
	use "$main/data/$country_fullname/ECAM4S13.dta", clear
	egen hhid = concat(S0Q2 S0Q5)
	order hhid, first
	
	merge m:1 S0Q2 using "$main/data/$country_fullname/ECAM4_Weight_12052015.dta" 
	keep if _merge==3 // 1 obs dropped
	drop _merge
	

	rename COEFEXTR							hh_weight
	rename S13Q2							product_code
	rename S13Q2N							product_name
	rename S13Q3							amount_paid
	
	*annualize
	gen agg_value_on_period=amount_paid*2 if sect=="131"
	replace agg_value_on_period=amount_paid*4 if sect=="132"
	replace agg_value_on_period=amount_paid*2 if sect=="133"
	replace agg_value_on_period=amount_paid*4 if sect=="1341"
	replace agg_value_on_period=amount_paid if sect=="1342"
	replace agg_value_on_period=amount_paid if sect=="1351"
	replace agg_value_on_period=amount_paid*2 if sect=="1352"
	replace agg_value_on_period=amount_paid*4 if sect=="1353"
	replace agg_value_on_period=amount_paid if sect=="1354"
	replace agg_value_on_period=amount_paid*2 if sect=="136"
	replace agg_value_on_period=amount_paid if sect=="1371"
	replace agg_value_on_period=amount_paid if sect=="1372"
	replace agg_value_on_period=amount_paid if sect=="138"
	replace agg_value_on_period=amount_paid*4 if sect=="139"
	replace agg_value_on_period=amount_paid*2 if sect=="1310"
	
	gen TOR_original= 17 //missing
	gen module_tracker="retroactive items"
	
	tempfile retro_to_merge
	save `retro_to_merge'

	*Append	
	*Important note: The decile are construsted based on the final set of expenses we are taking into account: Diary without non food items + retroactive item module
 
	use `diary_food' ,clear 
	append using `retro_to_merge'
	
	egen total_exp = sum(agg_value_on_period), by(hhid)
	xtile decile = total_exp [weight=hh_weight], nq(10) 
	
	tempfile diary_food_recall
	save `diary_food_recall'
	
	*Append diary nonfood only after decile creation
	use `diary_nonfood', clear 

	*Count how many not missing by decile
	destring product_code, replace
	gen str6 COICOP_2dig = substr(string(product_code,"%07.0f"), 1,2) 
	ta COICOP_2dig, m
	drop if COICOP_2dig=="14"
	drop if TOR_original==0
	bys COICOP_2dig: ta TOR_original // COICOP categories 3,9,10 have more than 85% of missing TOR
		
	*As the items from the diary are not taken into account in the decile, we need to impute some 
	append using `diary_food_recall' // just to get the deciles
	gen decile_imputed=decile
	destring hhid , replace
	xfill decile_imputed, i(hhid)
	keep if module_tracker=="diary - nonfood" //drop eveything agin
	
	
	bys decile_imputed COICOP_2dig: egen sum_cons_COICOP=total(agg_value_on_period)  
	bys decile_imputed COICOP_2dig TOR_original: egen sum_cons_TOR=total(agg_value_on_period)  
	gen share_cons_TOR_COICOP=sum_cons_TOR/sum_cons_COICOP 
	
	

	
	forval i = 1/17 {
	bys decile_imputed COICOP_2dig TOR_original: egen share_`i'prep=mean(share_cons_TOR_COICOP) if TOR_original==`i' 
	bys decile_imputed COICOP_2dig: egen share`i'=mean(share_`i'prep) 
	}

	keep decile_imputed  COICOP_2dig share1 share2 share3 share4 share5 share6 share7 share8 share9 share10 share11 share12 share13 share14 share15 share16 share17
	duplicates drop COICOP_2dig decile_imputed share1 share2 share3 share4 share5 share6 share7 share8 share9 share10 share11 share12 share13 share14 share15 share16 share17 , force
	ren decile_imputed decile
	egen dec_coicop = concat(decile COICOP_2dig)
	forval i = 1/17 {
	replace share`i'=0 if share`i'==.
	}
	
	tempfile diary_nonfood_with_share
	save `diary_nonfood_with_share'
	
	
	
	*Merge with retractive item no TOR 
	use `diary_food_recall' , clear 
	keep if module_tracker=="retroactive items"
	ta module_tracker, m
	destring product_code, replace
	gen str6 COICOP_2dig = substr(string(product_code,"%07.0f"), 1,2) 
	ta COICOP_2dig, m
	drop if COICOP_2dig=="14"
	egen dec_coicop = concat(decile COICOP_2dig)
	merge m:1 dec_coicop using `diary_nonfood_with_share'
	keep hhid product_code  hh_weight agg_value_on_period module_tracker decile COICOP_2dig dec_coicop share1- share17
	collapse (sum) agg_value_on_period , by(hhid product_code  hh_weight  module_tracker decile COICOP_2dig dec_coicop share1- share17)
	reshape long share, i(hhid product_code hh_weight agg_value_on_period module_tracker decile dec_coicop COICOP_2dig ) j(TOR_original)
	gen new_agg_value_on_period= agg_value_on_period*share
	drop if new_agg_value_on_period==.
	
	replace agg_value_on_period=new_agg_value_on_period if new_agg_value_on_period!=.
	
	
	keep decile hhid hh_weight  TOR_original  agg_value_on_period product_code     
	tostring product_code , replace
	ta TOR_original, m
	tostring hhid, replace
	destring product_code, replace
	save "$main/waste/$country_fullname/${country_code}_durables_with_imputed_TOR.dta", replace
	

	*Append all the files together
	use "$main/waste/$country_fullname/${country_code}_all_lines_raw_diary_no_selfprod.dta", clear
	append using `self_conso'
	append using "$main/waste/$country_fullname/${country_code}_durables_with_imputed_TOR.dta"
	
	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
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
	collapse (sum) agg_value_on_period, by (TOR_original)
	rename agg_value_on_period expenses_value_aggregate
	egen total_exp = sum(expenses_value_aggregate)  
	gen pct_expenses = expenses_value_aggregate / total_exp 
	order  TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,13,15,16,1)
	replace detailed_classification=2 if inlist(TOR_original,4,14,12,6)
	replace detailed_classification=3 if inlist(TOR_original,5)
	replace detailed_classification=4 if inlist(TOR_original,3)
	replace detailed_classification=5 if inlist(TOR_original,2)
	replace detailed_classification=6 if inlist(TOR_original,10,8,11)
	replace detailed_classification=7 if inlist(TOR_original,9)
	replace detailed_classification=8 if inlist(TOR_original,7)
	replace detailed_classification=99 if inlist(TOR_original,0,17)




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
    keep hhid product_code str_product TOR_original agg_value_on_period coicop_2dig  housing detailed_classification TOR_original  pct_expenses 
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
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig   detailed_classification ) 
	
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
	
	
