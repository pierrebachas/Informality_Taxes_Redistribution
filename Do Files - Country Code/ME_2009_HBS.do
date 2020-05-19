

					*************************************
					* 			Main DO FILE			*
					* 	      Montenegro 2009 			*
					*************************************

* Template 


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

	
	global country_fullname "Montenegro2009"
	global country_code "ME"
	
/* SUMMARY:
   Step 0:  Data overview
   Step 1:  Prepare covariates at the household level
   Step 2: Preparing the expenditures database 
   Step 2.1: Harmonization of names, introduction of labels
   Step 2.1.1.: TOR Imputation for durables module
   Step 3: Generating total expenditures and total income
   Step 3.1: Total expenditures
   Step 3.2 Total income
   Step 3.3: Merge with the household covariates datafile
   Step 4: Crosswalk between places of purchase and classification
   Step 5: Creation of database at the COICOP_4dig level
   */
	
**********************
* IMPORTANT COMMENTS *
**********************

/* This file impute TOR to the durables goods because the "nonfood items" dataset does not have TOR, which bring the unspecified categories to more than 60% of the expenditure. 
Yet there is also a diary that has both durables and non durables good and has TOR. 
We first tried to use the analysis only with the diary, but we ended up with an over represented food consumption (70% of total exp while it should be around 40 for Montenegro)
We then decided to include the nonfooditems/durables dataset ( which appended to the food part of the dairy gave us the right proportion of food expenditure, i.e. 40%).
To reduce the huge unspecified TOR category that was coming from this durable dataset we therefore imputed the TOR based on the TOR that were reported for the small ammount of durables goods present in the dairy. 
We first tried to impute a TOR by hhid and product_code ( meaning if a specific hh had purchased a specific durable good and was reporting it in the diary with a TOR, we would then assign the same TOR to that specific hh and good in the durable dataset. 
Yet, this leaves us with still a very large unspecified category. 
We then decide to do the imputation at the COICOP_2dig and decile level. In other words, we looked at the weights of all non missing TOR within a decile and COICOP_2dig category and assigned proportionaly TOR to the expenditures of that same decile and COICOP_@dig category with missing TOR. 
This left us with a very small amount of expenditures in unspecified categories. 
It was likely to be a problem because in some COICOP_2dig category the imputation was relying on a very few ammount of people. 
We therefore decided to put a threshold:  the imputation could be done if at least 15% of the COICOP_2dig category had an assigned TOR (Less than 85% assigned to "other"). 
This lead us to not impute a TOR for the following COICOP_2dig categories :  4 (Utilities) 6(Health) 7(Transports) 10(Education) 11(Hotel and restaurant). 
Finally, the unspecified category represents a bit less than 30% of the total expenditures, whcih seems reasoonable, comparing it to similar countries ( see graph missing_bycoicop_stackedbar in appendix B).

*/	
*****************************
* Step 0:  Data overview    *
*****************************	
	
	
/*
	indiv_labelled.dta
	Household and individual level general statistics (+education), one line per individual. 	
	
	general_info.dta
	Information on geographic variables, household weight, household size, and head of household variables
	
	diary_labelled.dta
	consumption diary, with place of purchase, one line per consumption item
	it was kept over the course of one month, so anualize by multiplying by 12
*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	
	clear
	set more off
	use "$main/data/$country_fullname/indiv_labelled.dta", clear
	merge m:1 hhid using "$main/data/$country_fullname/general_info.dta", nogen
	

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
	rename weight  								hh_weight
	rename municipality							geo_loc_min
	rename psu 									census_block
	rename region								geo_loc
	rename urban 								urban 
	rename p1_5									head_sex
	rename hhdage								head_age
	rename hhdeduc								head_edu
	rename hhsize								hh_size
	
	*We need to construct/modify some of them
	

	*exp_agg_tot inc_agg_tot // This file does not have these variables but they may exist in another datafile (peut-etre fichier_emplois_toute_personne) that we should merge here
	
	
	*We destring and label some variables for clarity/uniformity 
	destring geo_loc, force replace
	destring geo_loc_min, force replace
	destring census_block, force replace
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
	drop if p1_4 !=1
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

	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	*DIARY
	clear 
	set more off
	use "$main/data/$country_fullname/diary_labelled.dta", clear
	merge m:1 hhid using "$main/data/$country_fullname/general_info"
	drop _merge
	
	rename grupa_robe						product_code //COICOP
	rename d6 								TOR_original // purchased in
	rename d7								CoicopType	// module category		
	rename d3								quantity
	rename d5								amount_paid
	rename d4 								unit
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen     daysinmon = 31 if month==1 | month==3 | month==5 | month==7 | month==8 | month==10 | month==12
	replace daysinmon = 30 if month==4 | month==6 | month==9 | month==11 
	replace daysinmon = 28 if month==2 
	
	foreach x of varlist quantity amount_paid { 
	replace `x' = `x'*365/daysinmon 
	}
	
	gen xfood    = amount_paid if d9>=2111
	gen xalcohol = amount_paid if d9>=2011 & d9<=2041
	gen xtobacco = amount_paid if d9>=2071 & d9<=2081
	
	gen agg_value_on_period =xfood  //annualize
	replace agg_value_on_period=xalcohol if agg_value_on_period==.
	replace agg_value_on_period=xtobacco if agg_value_on_period==.
	
	
	
	*coicop_2dig
	replace product_code = subinstr(product_code, ".", "",.) 
	drop if product_code=="000000"
	replace product_code = subinstr(product_code, ".", "",.) 
	gen coicop_2dig = substr(product_code,2,2)  //extract first 2-digits of product code to identify housing expenses ,
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	*** keep only the food items (consumed within the household) & alcohol & tobacco
	keep if (d9>=2011 & d9<=2997)
	*** keep only those quantities for personal use
	keep if d8==1


	replace TOR_original = 6 if CoicopType == 2
	replace TOR_original = 7 if CoicopType == 4 
	destring TOR_original, force replace
	ta TOR_original, missing
	drop if TOR_original == 0 //(that is CoicopType 6, which is income)
	
	#delim ; // create the label
	label define TOR_original_label 
	1 "Supermarket" 2 "Store"
	3 "Stall" 4 "Other" 5 "Abroad"
	6 "Own production" 7 "Gifts received/transfers" ;
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	
	*	drop if product_code > "022130" //test with just food, bev, alc
	gen module_tracker="diary"
	tempfile diary 
	save `diary'
	
	*DURABLES
	*** durables , help from Step 5 coicop_3_12_2015.do
	tempfile hhold_exp firewood dur_purch checks checks1 p12 p21 p22
	use "$main/data/$country_fullname/p2izdaci", clear
	drop if sifra=="Ukupno"
	destring, replace
	
	gen double hhid=opstina*10^4+pop_krug*10+rbr_dom
	replace hhid = hhid*100 + mjesec
	format hhid %15.0g
	rename mjesec month
	drop sifra_istraz sifra_regiona stratum opstina naselje pop_krug kontigent rbr_dom socio_ekon godina 
	
	rename sifra code
	rename iznos exp
	gen agg_value_on_period=exp
	
	
	*keep rents on a separate file 
	//modified by JaY
	preserve 
	keep if code=="04.1.1.1" | code=="04.2.1.1" 
	********************************************************
	*** correct for the number of days in the reporting month
	
	*gen     daysinmon = 31 if month==1 | month==3 | month==5 | month==7 | month==8 | month==10 | month==12
	*replace daysinmon = 30 if month==4 | month==6 | month==9 | month==11 
	*replace daysinmon = 28 if month==2 
	*
	*replace exp=exp/3
	*replace exp=exp*365/daysinmon
	
	*** expenditures on rent from the 3-months questionnaire, in yearly terms
	*collapse (sum) exp_rent=exp, by(hhid)
	sort hhid
	gen module_tracker="rent"
	
	gen TOR_original=4
	
	#delim ; // create the label
		label define TOR_original_label 
		1 "Supermarket" 2 "Store"
		3 "Stall" 4 "Other" 5 "Abroad"
		6 "Own production" 7 "Gifts received/transfers" ;
		#delim cr
		label list TOR_original_label
		label values TOR_original TOR_original_label // assign it
		ta TOR_original
	
		decode TOR_original, gen(TOR_original_name)
		ta TOR_original_name
	
	ren code product_code
	replace product_code = subinstr(product_code, ".", "",.) 
		
	drop if product_code=="000000"
	destring product_code, replace

	gen housing=1
	tempfile rent
	save `rent'
	restore
	
	
	
	*drop the rents and durables
	
	cap gen coicop_4d=substr(code , 1, 6)
	drop if  coicop_4d=="04.1.1" | coicop_4d=="04.1.2" | coicop_4d=="04.2.1" | coicop_4d=="04.2.2" | /// /*rent*/
			coicop_4d=="05.1.1" | coicop_4d=="05.1.2" | coicop_4d=="05.3.1" | coicop_4d=="05.5.1" | /// /*all durables*/
			coicop_4d=="06.1.3" | ///
			coicop_4d=="07.1.1"| coicop_4d=="07.1.2"| coicop_4d=="07.1.3"| coicop_4d=="07.1.4" | ///
			coicop_4d=="08.2.0" | ///
			coicop_4d=="09.1.1"| coicop_4d=="09.1.2"| coicop_4d=="09.1.3" | coicop_4d=="09.2.1"  | coicop_4d=="09.2.2" | ///
			coicop_4d=="12.3.1"
			
	drop if code=="04.1.1.1" | code=="04.2.1.1" | code=="06.1.3.1" | code=="12.3.1.1" 
	//modified by JaY
	
	order hhid month 
	qui compress
	sort hhid
	tempfile hhold_exp
	save `hhold_exp'
	
	
	
	*******************************
	*2. P2 - Dwelling
	
	
	use "$main/data/$country_fullname/p2stan", clear
	destring, replace
	
	gen double hhid=opstina*10^4+pop_krug*10+rbr_dom
	replace hhid = hhid*100 + mjesec
	format hhid %15.0g
	rename mjesec month
	drop sifra_istraz sifra_regiona stratum opstina naselje pop_krug kontigent rbr_dom socio_ekon godina 
	
	forvalues x=1/18 {
		rename p`x' p2_`x'
		}
	rename p5opis p2_5opis
	rename p12m1 p2_12m1
	rename p12m2 p2_12m2
	rename p12m3 p2_12m3
	rename p12m4 p2_12m4
	drop p12opis
	
	order hhid month 
	qui compress
	sort hhid
	
	save `p21'
	
	* keep the record on the use of firewood from own plot in last 12 months (ogrijevno drvo) 
	keep hhid p2_11
	drop if p2_11==0
	rename p2_11 firewd12
	gen code="04.5.4.1.1"
	sort hhid
	save `firewood'
	
	*******************************
	*3. P3 - Purchases of durables
	use "$main/data/$country_fullname/p3kupovina", clear
	drop if sifra=="Ukupno"
	destring, replace
	
	gen double hhid=opstina*10^4+pop_krug*10+rbr_dom
	replace hhid = hhid*100 + mjesec
	format hhid %15.0g
	rename mjesec month
	drop sifra_istraz sifra_regiona stratum opstina naselje pop_krug kontigent rbr_dom socio_ekon godina 
	
	rename sifra code
	rename iznos exp
	/*
	//modified by JaY
	sort hhid month  
	order hhid month
	merge hhid month using `durable'   
	//modified by jay
	*/
	qui compress
	sort hhid
	save `dur_purch'
	
	***********************************************************
	*** EXPENDITURES LAST 3 MONTHS (EXCL. RENTS)
	***********************************************************
	use `hhold_exp', clear
	
	gen group = substr(code,1,8)
	tab group, m
	
	* drop the rents
	*drop if group=="04.1.1.1" | group=="04.2.1.1"
	
	********************************************************
	*** correct for the number of days in the reporting month
	
	gen     daysinmon = 31 if month==1 | month==3 | month==5 | month==7 | month==8 | month==10 | month==12
	replace daysinmon = 30 if month==4 | month==6 | month==9 | month==11 
	replace daysinmon = 28 if month==2 
	
	replace exp=exp/3
	replace exp=exp*365/daysinmon
	
	*** expenditures on non-durables from the 3-months questionnaire, in yearly terms
	collapse (sum) exp_3mo=exp, by(hhid group)
	
	qui compress
	sort hhid group
	save `checks', replace
	
	*************************************************************************
	*** CONSUMPTION OF FIREWOOD FROM OWN PLOT IN LAST 12 MONTHS 
	*************************************************************************
	use `firewood', clear
	
	gen group = substr(code,1,8)
	tab group, m
	drop code
	
	gen firewd_12mo = firewd12
	
	qui compress
	sort hhid group
	save `checks1', replace
	
	***********************************************************
	*** EXPENDITURES LAST 12 MONTHS 
	***********************************************************
	use `dur_purch', clear
	
	gen group = substr(code,1,8)
	tab group, m
	
	*** keep the non-durables by dropping the durables
	cap gen coicop_4d=substr(group, 1, 6)
	drop if  coicop_4d=="04.1.1" | coicop_4d=="04.1.2" | coicop_4d=="04.2.1" | coicop_4d=="04.2.2" | /// /*rent*/
			coicop_4d=="05.1.1" | coicop_4d=="05.1.2" | coicop_4d=="05.3.1" | coicop_4d=="05.5.1" | /// /*all durables*/
			coicop_4d=="06.1.3" | ///
			coicop_4d=="07.1.1"| coicop_4d=="07.1.2"| coicop_4d=="07.1.3"| coicop_4d=="07.1.4" | ///
			coicop_4d=="08.2.0" | ///
			coicop_4d=="09.1.1"| coicop_4d=="09.1.2"| coicop_4d=="09.1.3" | coicop_4d=="09.2.1"  | coicop_4d=="09.2.2" | ///
			coicop_4d=="12.3.1"
	
	/*
	#delimit;
	keep if group=="05.1.3.1" | group=="05.2.1.1" | group=="05.3.2.1" | group=="05.3.2.2"| group=="05.3.2.3"| group=="05.3.2.4" | group=="05.3.2.9"
			group=="05.3.3.1" | 
			group=="05.4.0.2" |   group=="05.4.0.3" |group=="05.4.0.4"     
			group=="05.4.1.1" | group=="05.4.1.2" | 
			group=="05.4.1.3" | group=="05.4.1.4" | group=="05.5.2.1" | 
			group=="08.1.2.1" | group=="09.1.5.1" | group=="09.2.3.1" //Modified by JaY & Xinxin
	#delimit cr
	*/
	*** expenditures on non-durables from the 12-months questionnaire, in yearly terms
	collapse (sum) exp_12mo=exp, by(hhid group)
	
	***********************************************************
	*** put the above files together (they contain different items)
	***********************************************************
	
	append using `checks'
	append using `checks1'
	egen exp_3or12mo = rsum(exp_3mo exp_12mo firewd_12mo)
	/* Xinxin's check: no duplicates at allm, for hhid group
	egen exp_3or12mo_d = rmax(exp_3mo exp_12mo )
	replace exp_3or12mo_d=0 if exp_3or12mo_d==.
	egen exp_3or12mo = rsum( exp_3or12mo_d firewd_12mo)
	*/
	drop exp_3mo exp_12mo firewd_12mo 
	
	sort hhid group
	cap gen coicop_4d=substr(group, 1, 6)
	drop if  coicop_4d=="04.1.1" | coicop_4d=="04.1.2" | coicop_4d=="04.2.1" | coicop_4d=="04.2.2" | /// /*rent*/
			coicop_4d=="05.1.1" | coicop_4d=="05.1.2" | coicop_4d=="05.3.1" | coicop_4d=="05.5.1" | /// /*all durables*/
			coicop_4d=="06.1.3" | ///
			coicop_4d=="07.1.1"| coicop_4d=="07.1.2"| coicop_4d=="07.1.3"| coicop_4d=="07.1.4" | ///
			coicop_4d=="08.2.0" | ///
			coicop_4d=="09.1.1"| coicop_4d=="09.1.2"| coicop_4d=="09.1.3" | coicop_4d=="09.2.1"  | coicop_4d=="09.2.2" | ///
			coicop_4d=="12.3.1"
	
	save `checks', replace
	
	***********************************************************
	*** compare these expenditures (from P2/P3 modules) with the ones in the diary
	***********************************************************
	use "$main/data/$country_fullname/diary_labelled", clear
	
	drop if grupa_robe=="00.0.0.0.0"
	
	gen group  = substr(grupa_robe,1,8)
	tab group, m
	
	
	* keep items for personal use
	tab d8, m
	keep if d8==1
	
	* drop transfers for other households
	tab group if d7==5
	drop if d7==5
	
	********************************************************
	*** correct for the number of days in the reporting month
	
	gen     daysinmon = 31 if month==1 | month==3 | month==5 | month==7 | month==8 | month==10 | month==12
	replace daysinmon = 30 if month==4 | month==6 | month==9 | month==11 
	replace daysinmon = 28 if month==2 
	
	replace d5 = d5*365/daysinmon
	
	*Here we have the dairy, need to only keep all non-durable things 
	gen coicop_4d=substr(group, 1, 6)
	
	drop if  coicop_4d=="04.1.1" | coicop_4d=="04.1.2" | coicop_4d=="04.2.1" | coicop_4d=="04.2.2" | /// /*rent*/
			coicop_4d=="05.1.1" | coicop_4d=="05.1.2" | coicop_4d=="05.3.1" | coicop_4d=="05.5.1" | /// /*all durables*/
			coicop_4d=="06.1.3" | ///
			coicop_4d=="07.1.1"| coicop_4d=="07.1.2"| coicop_4d=="07.1.3"| coicop_4d=="07.1.4" | ///
			coicop_4d=="08.2.0" | ///
			coicop_4d=="09.1.1"| coicop_4d=="09.1.2"| coicop_4d=="09.1.3" | coicop_4d=="09.2.1"  | coicop_4d=="09.2.2" | ///
			coicop_4d=="12.3.1"
	
	/*		group=="12.3.1.1" |group=="05.1.1.1" | group=="05.1.2.1" | group=="05.3.1.1" |  ///
			group=="05.3.1.2" | group=="05.3.1.3" |group=="05.3.1.4" | group=="05.3.1.5" | group=="05.5.1.1"|   ///
			group=="06.1.3.1" | group=="07.1.2.1" | group=="07.1.3.1" | group=="08.2.1.1" | group=="09.1.1.1"|   ///
			group=="09.1.1.2" | group=="09.1.3.1" | group=="09.2.1.1" 
	//modified by jay*/
			
	collapse (sum) exp_diary=d5, by(hhid group)
	sort hhid group
	merge 1:m hhid group using `checks'
	tab _merge
	*5921 merged, same group happened in dairy and questionnaire
	drop _merge
	
	sort group
	
	* keep only the items common w/ the "3 months" or "12 months" (drop food items)
	sort group
	merge m:m group using "$main/data/$country_fullname/nonfood items.dta"
	
	/*there is one duplicate in using data, should be fine, try not to change the original dataset*/
	tab _merge
	tab group if _merge==1
	
	split group, p(.)
	replace source_nf = 3 if group1=="10" & source_nf==.
	replace source_nf = 3 if group1=="09" & source_nf==.
	
	
	*replace exp_3or12mo = exp_diary/3 if exp_3or12mo == . & group1=="10"
	drop if hhid == .
	
	*keep if _merge==3
	drop _merge
	
	egen    exp_mis = rmax(exp_3or12mo exp_diary)
	gen     exp_mne = exp_3or12mo if source_nf==3 | source_nf==12
	replace exp_mne = exp_diary   if source_nf==30
	replace exp_mne = exp_mis     if exp_mne==.
	
	***********************************************************
	*** create COICOP sub-components and label
	cap gen coicop_4d=substr(group, 1, 6)
	drop if  coicop_4d=="04.1.1" | coicop_4d=="04.1.2" | coicop_4d=="04.2.1" | coicop_4d=="04.2.2" | /// /*rent*/
			coicop_4d=="05.1.1" | coicop_4d=="05.1.2" | coicop_4d=="05.3.1" | coicop_4d=="05.5.1" | /// /*all durables*/
			coicop_4d=="06.1.3" | ///
			coicop_4d=="07.1.1"| coicop_4d=="07.1.2"| coicop_4d=="07.1.3"| coicop_4d=="07.1.4" | ///
			coicop_4d=="08.2.0" | ///
			coicop_4d=="09.1.1"| coicop_4d=="09.1.2"| coicop_4d=="09.1.3" | coicop_4d=="09.2.1"  | coicop_4d=="09.2.2" | ///
			coicop_4d=="12.3.1"
	
	gen coicop = real(substr(group,1,2))
	drop if coicop==1 | coicop==2
	
	forvalues i = 3/12 {
		gen cons`i' = exp_mne if coicop==`i'
		}
	
	drop cons11
	gen cons111 = exp_mne if substr(group,1,4)=="11.1"
	gen cons112 = exp_mne if substr(group,1,4)=="11.2"
	
	* 
	gen agg_value_on_period =cons3
	replace agg_value_on_period=cons4 if agg_value_on_period==.
	replace agg_value_on_period=cons5 if agg_value_on_period==.
	replace agg_value_on_period=cons6 if agg_value_on_period==.
	replace agg_value_on_period=cons7 if agg_value_on_period==.
	replace agg_value_on_period=cons8 if agg_value_on_period==.
	replace agg_value_on_period=cons9 if agg_value_on_period==.
	replace agg_value_on_period=cons10 if agg_value_on_period==.
	replace agg_value_on_period=cons12 if agg_value_on_period==.
	replace agg_value_on_period=cons111 if agg_value_on_period==.
	replace agg_value_on_period=cons112 if agg_value_on_period==.
	
	gen TOR_original=4
	
	#delim ; // create the label
		label define TOR_original_label 
		1 "Supermarket" 2 "Store"
		3 "Stall" 4 "Other" 5 "Abroad"
		6 "Own production" 7 "Gifts received/transfers" ;
		#delim cr
		label list TOR_original_label
		label values TOR_original TOR_original_label // assign it
		ta TOR_original
	
		decode TOR_original, gen(TOR_original_name)
		ta TOR_original_name
	
	gen module_tracker="durables"
	
	ren group product_code
	replace product_code = subinstr(product_code, ".", "",.) 
		
	drop if product_code=="000000"
		
	tostring product_code, generate(str_product_code)
	gen coicop_2dig = substr(product_code,1,3) //extract first 2-digits of product code
	
	
	tempfile durables
	save `durables'
	save "$main/waste/$country_fullname/${country_code}_durables.dta", replace
	
	***************************************************************
	* Step 2.1.1.: TOR Imputation for durables module			  * 
	***************************************************************
		
	clear
	set more off 
	use "$main/data/$country_fullname/diary_labelled.dta", clear
	drop if grupa_robe=="00.0.0.0.0"
	replace grupa_robe = subinstr(grupa_robe, ".", "",.)
	destring grupa_robe, replace
	gen str6 product_code = substr(string(grupa_robe,"%06.0f"), 1,5)
	keep if d8==1
	
	unique hhid // 1233
		
		rename d6 								TOR_original // purchased in
		rename d7								CoicopType	// module category		
		rename d3								quantity
		rename d5								amount_paid
		rename d4 								unit
	
	
	by product_code hhid ( TOR_original ), sort: gen desired = _N // see how many codpr by hhid have been bought in more than one TOR category 
	by product_code hhid ( TOR_original ): replace desired = 1 if TOR_original[1] == TOR_original[_N] // product by hhid that have been bought in the same TOR
	
	collapse (sum) amount_paid, by(hhid product_code desired TOR_original)
	egen  hhid_codpr = concat(hhid product_code) ,  format(%15.0f)  // to merge
	
	tempfile diary_to_merge
	save `diary_to_merge'
	
	clear 
	set more off
	use "$main/waste/$country_fullname/${country_code}_durables.dta" , clear
	collapse (sum) agg_value_on_period, by(hhid product_code)
	
	egen hhid_codpr = concat(hhid product_code) ,  format(%15.0f) // to merge
	
	merge 1:m hhid_codpr using `diary_to_merge'
	
	
	/*
		Result                           # of obs.
		-----------------------------------------
		not matched                        52,712
			from master                     9,389  (_merge==1) // not in diary, so no TOR for these
			from using                     43,323  (_merge==2) // not in durables, all the food items
	
		matched                            12,225  (_merge==3) // We will be able to impute TOR perfectly for these goods
		-----------------------------------------
	
	*/
	ta product_code if _merge==2 // COICOP 1 and 2 is more than 99%
	
	drop if _merge==2 
	
	replace TOR_original=4 if _merge==1  
	
	
	* When several TOR for one product for the same hhid put weight on the value 
	bys hhid product_code: egen sum_cons_distinct=total(amount_paid) if desired>1
	gen fraction_cons_distinct=amount_paid/sum_cons_distinct
	replace agg_value_on_period= agg_value_on_period*fraction_cons_distinct if fraction_cons_distinct!=.
	
	
	ta TOR_original, m
	*70% de autre
	/*
	
	
	TOR_imputed |      Freq.     Percent        Cum.
	------------+-----------------------------------
			0 |         59        0.27        0.27
			1 |      2,038        9.43        9.70
			2 |      4,154       19.22       28.92
			3 |        348        1.61       30.53
			4 |      5,619       26.00       56.53
			5 |          7        0.03       56.56
			99 |      9,389       43.44      100.00
	------------+-----------------------------------
		Total |     21,614      100.00
	
	
	*/
	tempfile durables_with_TOR
	save `durables_with_TOR'
	
	
		
		ta TOR_original,m
	
		
	
	* we are gonna drop non food item as they did in the poverty report to avoid double count - Eva 10/28
	*and no include other modules. 
		destring product_code, replace
		gen str6 COICOP_2dig = substr(string(product_code,"%05.0f"), 1,2) 
		ta COICOP_2dig, m
		
		
		bysort COICOP_2dig: tab TOR_original
	
		*Let's do this part by decile 11/27
	egen total_exp = sum(agg_value_on_period), by(hhid)
	
	merge m:1 hhid using "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"	, gen(mhhid)
	keep if mhhid==3
	xtile decile = total_exp [weight=hh_weight], nq(10) 
	
		*count how many not missing by decile
		bys COICOP_2dig: ta TOR_original // COICOP categories 4,6,7, 10 11 have more than 85% of missing TOR
	
		gen impute=(COICOP_2dig!="04" & COICOP_2dig!="06"  & COICOP_2dig!="07"  & COICOP_2dig!="10" & COICOP_2dig!="11")
	
	
		*assign weight 
	bys decile COICOP_2dig: egen sum_cons_COICOP=total(agg_value_on_period) if TOR_original!=4 & impute==1
	bys decile COICOP_2dig TOR_original: egen sum_cons_TOR=total(agg_value_on_period) if TOR_original!=4 & impute==1
	gen share_cons_TOR_COICOP=sum_cons_TOR/sum_cons_COICOP if TOR_original!=4 & impute==1
	
	
	
	forval i = 1/3 {
	bys decile COICOP_2dig TOR_original: egen share_`i'prep=mean(share_cons_TOR_COICOP) if TOR_original==`i' 
	bys decile COICOP_2dig: egen share`i'=mean(share_`i'prep) 
	}
	
	bys decile COICOP_2dig TOR_original: egen share_5prep=mean(share_cons_TOR_COICOP) if TOR_original==5 
	bys decile COICOP_2dig: egen share5=mean(share_5prep)
	tempfile durables_with_TOR_dec
	save `durables_with_TOR_dec'
	
	*test
	keep if TOR_original==4
	keep decile hhid  hh_weight product_code agg_value COICOP_2dig share1 share2 share3 share5
	reshape long share, i(hhid decile product_code agg_value_on_period COICOP_2dig hh_weight) j(TOR_original)
	gen new_agg_value_on_period= agg_value_on_period*share
	drop if new_agg_value_on_period==.
	tempfile durables_autre_dec
	save `durables_autre_dec'
	
	use `durables_with_TOR_dec' , clear 
	drop if TOR_original==4 & (share1!=. | share2!=. | share3!=. | share5!=.) & impute==1
	append using `durables_autre_dec'
	
	replace agg_value_on_period=new_agg_value_on_period if new_agg_value_on_period!=.
	
	#delim ; // create the label
		label define TOR_original_label 
		1 "Supermarket" 2 "Store"
		3 "Stall" 4 "Other" 5 "Abroad"
		6 "Own production" 7 "Gifts received/transfers" ;
		#delim cr
		label list TOR_original_label
		label values TOR_original TOR_original_label // assign it
		ta TOR_original
	
		decode TOR_original, gen(TOR_original_name)
		ta TOR_original_name
	
		drop if TOR_original==0
	
	
	keep decile hhid hh_weight  TOR_original  agg_value_on_period product_code    TOR_original_name 
	save "$main/waste/$country_fullname/${country_code}_durables_with_imputed_TOR.dta", replace

	
	
		
	*We keep all household expenditures and relevant variables
	
	use `diary', clear 
	append using `rent'
	append using "$main/waste/$country_fullname/${country_code}_durables_with_imputed_TOR.dta"
	drop if TOR_original==0
	destring product_code , replace 
	gen product_code_tmp = substr(string(product_code,"%06.0f"), 1,5) if module_tracker=="diary"
	replace product_code_tmp = substr(string(product_code,"%05.0f"), 1,5) if module_tracker=="rent"
	replace product_code_tmp = substr(string(product_code,"%05.0f"), 1,5) if module_tracker==""
	tostring product_code , replace
	replace product_code=product_code_tmp 
	
	keep hhid product_code TOR_original TOR_original_name  quantity  unit amount_paid  agg_value_on_period coicop_2dig TOR_original_name housing
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
	by hhid: egen exp_rent = sum(agg_value_on_period) if housing == 1 // actual rent as expenses
	by hhid: egen exp_ir = sum(agg_value_on_period) if housing == 1 // imputed rent as expenses
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
	gen detailed_classification=1 if inlist(TOR_original,7,6)
	replace detailed_classification=2 if inlist(TOR_original,3)
	replace detailed_classification=4 if inlist(TOR_original,2)
	replace detailed_classification=5 if inlist(TOR_original,1,5)
	replace detailed_classification=99 if inlist(TOR_original,4)


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
    keep hhid product_code  TOR_original TOR_original_name   quantity  unit amount_paid  agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	destring product_code, replace
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
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig quantity unit detailed_classification) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item quantity unit TOR_original detailed_classification  housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
