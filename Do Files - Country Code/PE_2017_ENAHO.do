

					*************************************
					* 			Main DO FILE			*
					* 	      	PERU 2017				*
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

	
	global country_fullname "Peru2017"
	global country_code "PE"
	
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
   
*********************************************************************
* IMPORTANT NOTEs:
* The section 2.1 was inspired by the GCD dofiles 
* Crosswalk datasets are attached							  
*********************************************************************	
	
*****************************
* Step 0:  Data overview    *
*****************************	
	
/*

Demographics : enaho01-2017-100.dta, enaho01-2017-200.dta, enaho01-2017-300.dta

Expenses : enaho01-2017-601.dta, enaho01-2017-601.dta, enaho01-2017-602.dta, enaho01-2017-603.dta
enaho01-2017-604.dta, enaho01-2017-605.dta, enaho01-2017-606.dta, enaho01-2017-606d.dta, enaho01-2017-607.dta
enaho01-2017-610.dta, enaho01-2017-611.dta, enaho01-2017-612.dta enaho01-2017-300.dta, enaho01-2017-400.dta
enaho01-2017-100.dta

*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]

	clear
	set more off	
	use "$main/data/$country_fullname/enaho01-2017-200.dta", clear
	egen hhid = concat(conglome vivienda hogar)
	order hhid, first															//  34584 households 
	gen person = 1
	bysort hhid: egen hh_size = count(person) 									// We generate the household size variable
	drop if p203 != 1
	tempfile head
	save `head'
	

	clear
	set more off	
	use "$main/data/$country_fullname/enaho01a-2017-300.dta", clear	
	egen hhid = concat(conglome vivienda hogar)
	order hhid, first															//  34584 households 
	drop if codperso != "01"		 												// We keep only houshold heads. P200 == 1 (Jefe de hogar)
	tempfile edu
	save `edu'

	
	
	clear	
	set more off
	use "$main/data/$country_fullname/enaho01-2017-100.dta", clear	
	
	*hhid
	egen hhid = concat(conglome vivienda hogar)
	order hhid, first

	* In this survey, we need to import some variables from the DWELLINGS (VIVIENDA) AND PERSONS (PERSONA) datasets 
	
	* (1) Heads
	merge m:1 hhid using `head', /// 
	keepusing(p208a p207 hh_size) nogen  
	
	* (2) Education
	merge m:1 hhid using `edu',  /// 
	keepusing(p301a) nogen 


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	rename factor07 							hh_weight
	rename dominio								geo_loc // 8 unique values
	rename conglome								census_block // primary sampling unit? is this right? 5359 unique values [used to build HHID
	rename ubigeo								geo_loc_min // 1262 unique values
	rename estrato 								density 
	rename p207									head_sex
	rename p208a								head_age
	rename p301a								head_edu
	rename p105a	 							house_owner 					// this information could be very useful if imputed rent/actual rent data is not good enough: VIVIENDAS dataset. 
	rename d105b  								house_rent 						// Monto de la renta mensual: VIVIENDAS dataset 
	rename d106		 							house_est_rent 					// Estimación del pago de renta: VIVIENDAS dataset (GOOD FOR IMPUTED RENT)

	*We need to construct/modify some of them
	
	*exp_agg_tot

	*inc_agg_tot: Look at enaho01-2017-500.dta
	
	*urban 
	gen urban = 0
	replace urban = 1 if density == 1 | density == 2 | density == 3 | density == 4 | density == 5	// Called Settlement_type for South Africa	
	


	*We destring and label some variables for clarity/uniformity 
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace					// Some of these variables are already numeric
	
	replace head_sex = 3 if head_sex == . 
	ta head_sex, missing
	label define head_sex_lab 1 "Male" 2 "Female"  3 "Missing"
	label values head_sex head_sex_lab
	
	ta urban
	ta urban, nol
	replace urban = 0 if urban == 2
	label define urban_lab 0 "Rural" 1 "Urban"
	label values urban urban_lab
	
	
	*We keep only one line by household and necessary covariates 
 	duplicates drop hhid , force 
 
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block 
	destring hhid, replace
	order hhid, first 
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , replace
	


************************************************************
* Step 2: Renaming and labelling the expenditures database *
************************************************************


************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************

*FOOD CONSUMPTION (SECTION 601)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-601.dta", clear
egen hhid=concat(conglome vivienda hogar)
drop if p601b~=1 // drop if not daily
drop if produc61==.
destring p601a,replace 

keep hhid conglome vivienda hogar factor07 p601a i601e p601a1 i601c p601a2 p601a3 p601a4 p601a5 p601a6 p601a7 p601a1 p601b4 p601b2 p601b3 p601c

gen cons_csh=i601e if p601a1==1 & i601c==.
gen one=i601e if p601a2==1 | p601a3==1
gen two=i601e if p601a4==1
recode one two (.=0)
gen cons_hmp=one+two
gen cons_gft=i601e if p601a5==1 | p601a6==1 | p601a7==1

replace cons_csh=i601c if cons_csh==. & i601c~=. & (p601a1==1 | p601a4==1)
replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft

ren p601a INEI_code
keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft p601b4 p601b2 p601b3 p601c
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code p601b4 p601b2 p601b3 p601c) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
gen TOR_original_raw=p601b4
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift


***TOR_ORIGINAL_RAW??? + What do we do with all the missing??

ren p601b2 quantity
ren p601b3 unit
ren p601c  amount_paid
ren factor07 hh_weight
gen price = agg_value_on_period / quantity
gen module=7
keep hhid conglome vivienda hogar INEI_code price quantity unit amount_paid TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	
tab INEI_code if TOR_original_raw==. // only round INEI_code (100 200 300..) Total per hhid of the product category!
drop if TOR_original_raw==.
gen COICOP_2dig=1 
replace COICOP_2dig=2 if inlist(INEI_code, 4406,4407,4403,4402,4401,4405,4404)
replace COICOP_2dig=11 if inlist(INEI_code, 4603,4604,4606,4701,4703,4704,4705,4706,4707,4708,5001,5002,5003,5004,5005,5006,5007,5008,5009,5010,5011,5012,5016)
tempfile food
save `food' 

*FOOD CONSUMPTION: SECTION 602 (MEALS TAKEN AWAY FFROM HOME)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-602.dta", clear
egen hhid=concat(conglome vivienda hogar)
gen INEI_code=1001
keep if p602==1
gen cons_csh=i602e1
replace cons_csh=i602e2 if cons_csh==.
gen cons_hmp=0
gen cons_gft=0
gen cons_tot=cons_csh+cons_hmp+cons_gft

gen agg_value_on_period=cons_tot
gen TOR_original_raw=31 // autre o no aplica
ren factor07 hh_weight
gen module=8
keep hhid conglome vivienda hogar INEI_code  TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	

gen COICOP_2dig=11 
tempfile takeaway
save `takeaway'

*NON-FOOD CONSUMPTION: SECTION 603 (HOUSEHOLD NON DURABLE)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-603.dta", clear
egen hhid=concat(conglome vivienda hogar)
*select if consumed
keep if p603==1
*assigning according to the nature of the consumption (see COMMENTS above)
gen cons_csh=i603c if p603a1==1 & i603b==.
gen one=i603c if p603a2==1 | p603a3==1
gen two=i603c if p603a4==1
recode one two (.=0)
gen cons_hmp=one+two
gen cons_gft=i603c if p603a5==1 | p603a6==1 | p603a7==1 | p603a8==1
replace cons_csh=i603b if cons_csh==. & p603a1==1

replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft

ren p603n INEI_code
*adding 100 to distinguish other products that are also sequential in subsequent files.
*replace INEI_code=INEI_code+100
ren p603aa TOR_original_raw

keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift

/*

  �d�nde lo compr�? |      Freq.     Percent        Cum.
--------------------+-----------------------------------
          ambulante |      5,318        2.48        2.48
 bodega (por menor) |     89,205       41.62       44.10
 bodega (por mayor) |      7,287        3.40       47.50
         ferreter�a |      2,190        1.02       48.52
mercado (por menor) |     58,066       27.09       75.61
mercado (por mayor) |      7,305        3.41       79.02
       supermercado |     12,851        6.00       85.01
  camioneta, cami�n |        304        0.14       85.16
              feria |      6,121        2.86       88.01
              bazar |        352        0.16       88.18
               otro |      1,695        0.79       88.97
                 41 |     10,036        4.68       93.65
                 42 |     13,612        6.35      100.00
--------------------+-----------------------------------
              Total |    214,342      100.00

*/


ren factor07 hh_weight

gen module=9
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	


gen COICOP_2dig=5
tempfile non_food_non_durable
save `non_food_non_durable'

*NON-FOOD CONSUMPTION: SECTION 604 (TRANSPORT)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-604.dta", clear
egen hhid=concat(conglome vivienda hogar)

*select if consumed
keep if p604==1
*assigning according to the nature of the consumption (see COMMENTS above)


 
gen cons_csh=i604c if p604a1==1 & i604b==. 
gen one=i604c if p604a2==1 | p604a3==1
gen two=i604c if p604a4==1
recode one two (.=0)
gen cons_hmp=one+two
gen cons_gft=i604c if p604a5==1 | p604a6==1 | p604a7==1 | p604a8==1
replace cons_gft=i604b if cons_gft==. & (p604a5==1 | p604a6==1 | p604a7==1 | p604a8==1)
replace cons_csh=i604b if cons_csh==. & p604a1==1


replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft

rename p604n INEI_code
ren p604aa TOR_original_raw



keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift

/*            

                �d�nde lo compr�? |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
               grifos de empresas |      6,172       17.96       17.96
                grifos informales |        744        2.16       20.12
                talleres formales |      1,713        4.98       25.10
              talleres informales |        446        1.30       26.40
  empresas de transporte formales |     14,713       42.80       69.20
empresas de transporte informales |      5,278       15.35       84.56
                 tel�fono p�blico |        153        0.45       85.00
                             otro |      3,697       10.76       95.76
                               41 |        118        0.34       96.10
                               42 |      1,340        3.90      100.00
----------------------------------+-----------------------------------
                            Total |     34,374      100.00


*/
ren factor07 hh_weight
gen module=10
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	

gen COICOP_2dig=7 if inlist(INEI_code,1,2,3,4,5,6,7,8,9)
replace COICOP_2dig=8 if inlist(INEI_code,10,11,13)
tempfile transport
save `transport'
*NON-FOOD CONSUMPTION: SECTION 605 (HOUSEHOLD SERVICES)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-605.dta", clear
egen hhid=concat(conglome vivienda hogar)
keep if p605==1

gen cons_csh=i605b if p605a1==1 & i605c==.
gen cons_hmp=i605b if p605a4==1
gen cons_gft=i605b if p605a2==1 | p605a3==1 | p605a5==1 | p605a6==1

replace cons_gft=i605c if p605a2==1 | p605a3==1 | p605a5==1 | p605a6==1
replace cons_csh=i605c if cons_csh==. & p605a1==1 

replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft

rename p605n INEI_code
*replace INEI_code=INEI_code+300
gen TOR_original_raw=31 //NO TOR, but we can say housign?

keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift


ren factor07 hh_weight
gen module=11
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	

gen COICOP_2dig=5
tempfile services
save `services'
*NON-FOOD CONSUMPTION: SECTION 606 (ENTERTAINMENT)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-606.dta", clear
egen hhid=concat(conglome vivienda hogar)
*select if consumed
keep if p606==1

*assigning according to the nature of the consumption (see COMMENTS above)
gen cons_csh=i606b if p606a1==1 
gen cons_hmp=i606c if p606a2==1 | p606a3==1 | p606a4==1
gen cons_gft=i606c if p606a5==1 | p606a6==1 | p606a7==1 | p606a8==1

replace cons_csh=i606c if cons_csh==. & (p606a1==1 | p606a4==1) &i606b==.

rename p606n INEI_code
*replace INEI_code=INEI_code+400
replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft


ren p606aa TOR_original_raw
/*  �d�nde lo compr�? |      Freq.     Percent        Cum.
--------------------+-----------------------------------
          ambulante |      8,694       27.59       27.59
 bodega (por menor) |      4,514       14.32       41.91
 bodega (por mayor) |        168        0.53       42.45
mercado (por menor) |      3,250       10.31       52.76
mercado (por mayor) |        256        0.81       53.57
       supermercado |        474        1.50       55.08
           librer�a |        782        2.48       57.56
              feria |        998        3.17       60.72
  club / asociaci�n |      1,101        3.49       64.22
             kiosco |      4,616       14.65       78.87
               otro |      4,775       15.15       94.02
                  . |      1,885        5.98      100.00
--------------------+-----------------------------------
              Total |     31,513      100.00

*/ 

keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift

/*
  �d�nde lo compr�? |      Freq.     Percent        Cum.
--------------------+-----------------------------------
          ambulante |      8,694       27.11       27.11
 bodega (por menor) |      4,514       14.07       41.18
 bodega (por mayor) |        168        0.52       41.70
mercado (por menor) |      3,250       10.13       51.84
mercado (por mayor) |        256        0.80       52.63
       supermercado |        474        1.48       54.11
           librer�a |        782        2.44       56.55
              feria |        998        3.11       59.66
  club / asociaci�n |      1,101        3.43       63.09
             kiosco |      4,616       14.39       77.49
               otro |      4,775       14.89       92.37
                 41 |        178        0.55       92.93
                 42 |      2,251        7.02       99.95
                  . |         17        0.05      100.00
--------------------+-----------------------------------
              Total |     32,074      100.00
*/
drop if TOR_original_raw==.
ren factor07 hh_weight
gen module=12
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	


gen COICOP_2dig=9 
tempfile entertainment
save `entertainment'
*NON-FOOD CONSUMPTION: SECTION 606D (PERSONAL CARE)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-606d.dta", clear
egen hhid=concat(conglome vivienda hogar)

*select if consumed
keep if p606d==1

*assigning according to the nature of the consumption (see COMMENTS above)
gen cons_csh=i606f if p606e1==1
gen cons_hmp=i606g if p606e2==1 | p606e3==1 | p606e4==1
gen cons_gft=i606g if p606e5==1 | p606e6==1 | p606e7==1 | p606e8==1

rename p606n INEI_code 
*replace INEI_code=INEI_code+500
replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft
gen agg_value_on_period=cons_tot
ren p606ee TOR_original_raw

/*

   �d�nde lo compr�? |      Freq.     Percent        Cum.
---------------------+-----------------------------------
           ambulante |     13,727        3.61        3.61
 bodega (por menor ) |     61,857       16.26       19.87
 bodega (por mayor ) |      3,347        0.88       20.75
mercado (por menor ) |     24,060        6.32       27.07
mercado (por mayor ) |      3,385        0.89       27.96
        supermercado |      9,690        2.55       30.51
   camioneta, cami�n |         59        0.02       30.53
               feria |      2,240        0.59       31.11
            farmacia |     11,326        2.98       34.09
          peluquer�a |     19,621        5.16       39.25
                otro |      3,792        1.00       40.25
                   . |    227,320       59.75      100.00
---------------------+-----------------------------------
               Total |    380,424      100.00

*/
keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift
/*

   �d�nde lo compr�? |      Freq.     Percent        Cum.
---------------------+-----------------------------------
           ambulante |     13,727        8.21        8.21
 bodega (por menor ) |     61,857       37.01       45.23
 bodega (por mayor ) |      3,347        2.00       47.23
mercado (por menor ) |     24,060       14.40       61.63
mercado (por mayor ) |      3,385        2.03       63.65
        supermercado |      9,690        5.80       69.45
   camioneta, cami�n |         59        0.04       69.49
               feria |      2,240        1.34       70.83
            farmacia |     11,326        6.78       77.61
          peluquer�a |     19,621       11.74       89.35
                otro |      3,792        2.27       91.62
                  41 |      6,480        3.88       95.49
                  42 |      7,531        4.51      100.00
---------------------+-----------------------------------
               Total |    167,115      100.00

*/

ren factor07 hh_weight
gen module=78
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	


gen COICOP_2dig=12 
tempfile personal_care
save `personal_care'
*NON-FOOD CONSUMPTION: SECTION 607 (CLOTHING)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-607.dta", clear
egen hhid=concat(conglome vivienda hogar)
*select if consumed
keep if p607==1

*assigning according to the nature of the consumption (see COMMENTS above)
gen cons_csh=i607b if p607a1==1
gen cons_hmp=i607c if p607a2==1 | p607a3==1 | p607a4==1
gen cons_gft=i607c if p607a5==1 | p607a6==1 | p607a7==1 | p607a8==1

rename p607n INEI_code
*replace INEI_code=INEI_code+600
replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft


ren p607aa TOR_original_raw
/*
                �d�nde lo compr�? |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
                        ambulante |      3,818        1.58        1.58
              bodega (por menor ) |      2,776        1.15        2.72
             bodega (por  mayor ) |        141        0.06        2.78
tienda especializada al por mayor |      2,095        0.87        3.65
tienda especializada al por menor |     26,416       10.91       14.56
                            bazar |      1,482        0.61       15.17
             mercado (por menor ) |     16,485        6.81       21.98
             mercado (por mayor ) |      1,282        0.53       22.51
                     supermercado |        834        0.34       22.85
                camioneta, cami�n |         13        0.01       22.86
                            feria |      4,824        1.99       24.85
                             otro |      3,787        1.56       26.42
                                . |    178,135       73.58      100.00
----------------------------------+-----------------------------------
                            Total |    242,088      100.00

*/

keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift

/*

                �d�nde lo compr�? |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
                        ambulante |      3,818        5.05        5.05
              bodega (por menor ) |      2,776        3.67        8.72
             bodega (por  mayor ) |        141        0.19        8.91
tienda especializada al por mayor |      2,095        2.77       11.68
tienda especializada al por menor |     26,416       34.95       46.64
                            bazar |      1,482        1.96       48.60
             mercado (por menor ) |     16,485       21.81       70.41
             mercado (por mayor ) |      1,282        1.70       72.11
                     supermercado |        834        1.10       73.21
                camioneta, cami�n |         13        0.02       73.23
                            feria |      4,824        6.38       79.61
                             otro |      3,787        5.01       84.62
                               41 |        493        0.65       85.27
                               42 |     11,131       14.73      100.00
----------------------------------+-----------------------------------
                            Total |     75,577      100.00

*/
ren factor07 hh_weight
gen module=13
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	

gen COICOP_2dig=3
tempfile clothing
save `clothing'
*NON-FOOD CONSUMPTION: SECTION 609 (TRANSFERS) is excluded.  This has infomation
*on donations, taxes and transfers out.  Since these are not welfare measurements they are excluded.
*NON-FOOD CONSUMPTION: SECTION 610 (HOME REPAIRS AND MAINTENANCE)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-610.dta", clear
egen hhid=concat(conglome vivienda hogar)

*select if consumed
keep if p610==1

*assigning according to the nature of the consumption (see COMMENTS above)
gen cons_csh=i610b if p610a1==1
gen cons_hmp=i610c if p610a2==1 | p610a3==1 | p610a4==1
gen cons_gft=i610c if p610a5==1 | p610a6==1 | p610a7==1 | p610a8==1

rename p610n INEI_code
*replace INEI_code=INEI_code+700
replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft

ren p610aa TOR_original_raw
/*

                �d�nde lo compr�? |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
                        ambulante |      6,768        3.26        3.26
tienda especializada al por mayor |      1,141        0.55        3.81
tienda especializada al por menor |     17,363        8.37       12.18
              mercado (por menor) |     15,864        7.65       19.82
              mercado (por mayor) |      1,642        0.79       20.62
                     supermercado |      1,312        0.63       21.25
                camioneta, cami�n |        143        0.07       21.32
                            feria |      4,027        1.94       23.26
                             otro |      5,229        2.52       25.78
                                . |    154,015       74.22      100.00
----------------------------------+-----------------------------------
                            Total |    207,504      100.00


*/

keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift

/*
                �d�nde lo compr�? |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
                        ambulante |      6,768        8.14        8.14
tienda especializada al por mayor |      1,141        1.37        9.52
tienda especializada al por menor |     17,363       20.89       30.41
              mercado (por menor) |     15,864       19.09       49.50
              mercado (por mayor) |      1,642        1.98       51.48
                     supermercado |      1,312        1.58       53.05
                camioneta, cami�n |        143        0.17       53.23
                            feria |      4,027        4.85       58.07
                             otro |      5,229        6.29       64.36
                               41 |        445        0.54       64.90
                               42 |     29,169       35.10      100.00
----------------------------------+-----------------------------------
                            Total |     83,103      100.00
*/
ren factor07 hh_weight
gen module=16
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	


gen COICOP_2dig=5
tempfile home_repairs
save `home_repairs'
*NON-FOOD CONSUMPTION: SECTION 611 (OTHER)
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-611.dta", clear
egen hhid=concat(conglome vivienda hogar)

*select if consumed
keep if p611==1

*assigning according to the nature of the consumption (see COMMENTS above)
gen cons_csh=i611b if p611a1==1
gen cons_hmp=i611c if p611a2==1 | p611a3==1 | p611a4==1
gen cons_gft=i611c if p611a5==1 | p611a6==1 | p611a7==1

rename p611n INEI_code
*replace INEI_code=INEI_code+800
replace cons_csh=0 if cons_csh==.
replace cons_hmp=0 if cons_hmp==.
replace cons_gft=0 if cons_gft==.
gen cons_tot=cons_csh+cons_hmp+cons_gft


ren p611aa TOR_original_raw
/*

                �d�nde lo compr�? |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
                        ambulante |     16,338        4.29        4.29
              bodega (por menor ) |      8,195        2.15        6.45
              bodega (por mayor ) |        205        0.05        6.50
tienda especializada al por mayor |        649        0.17        6.67
tienda especializada al por menor |     10,603        2.79        9.46
             mercado (por menor ) |     14,108        3.71       13.17
             mercado (por mayor ) |      1,152        0.30       13.47
                     supermercado |        480        0.13       13.60
               banco de la naci�n |      3,823        1.00       14.60
                            feria |      3,158        0.83       15.43
                    municipalidad |      3,238        0.85       16.28
                             otro |      8,921        2.35       18.63
                                . |    309,554       81.37      100.00
----------------------------------+-----------------------------------
                            Total |    380,424      100.00

*/

keep INEI_code conglome vivienda hogar hhid factor07 cons_csh cons_hmp cons_gft TOR_original_raw 
//RESHAPE! because some goods appear both in auto conso and comprado
ren cons_csh cons_1
ren cons_hmp cons_2
ren cons_gft cons_3
reshape long cons_ , i(hhid factor07 INEI_code TOR_original_raw) j(modep)
gen agg_value_on_period=cons_
drop if agg_value_on_period==0
replace TOR_original_raw=41 if modep==2 // self_conso
replace TOR_original_raw=42 if modep==3 // gift

/*

                �d�nde lo compr�? |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
                        ambulante |     16,338       19.41       19.41
              bodega (por menor ) |      8,195        9.73       29.14
              bodega (por mayor ) |        205        0.24       29.38
tienda especializada al por mayor |        649        0.77       30.15
tienda especializada al por menor |     10,603       12.59       42.75
             mercado (por menor ) |     14,108       16.76       59.51
             mercado (por mayor ) |      1,152        1.37       60.87
                     supermercado |        480        0.57       61.44
               banco de la naci�n |      3,823        4.54       65.98
                            feria |      3,158        3.75       69.74
                    municipalidad |      3,238        3.85       73.58
                             otro |      8,921       10.60       84.18
                               41 |      9,736       11.56       95.74
                               42 |      3,585        4.26      100.00
----------------------------------+-----------------------------------
                            Total |     84,191      100.00
*/

ren factor07 hh_weight
gen module=17
keep hhid conglome vivienda hogar INEI_code TOR_original_raw agg_value_on_period hh_weight module 

	
	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	


gen COICOP_2dig=12
tempfile other
save `other'

*=======================DURABLES================================ 
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-612.dta", clear
egen hhid=concat(conglome vivienda hogar)

keep if p612==1
**keep those that are used for household purposes.  "3" is used for both business and household
**since the assets used for both is relatively small, they will be retained.  
keep if p612c>="1999" & p612c~=""
gen val1=p612g if p612g<999999
gen val2=p612h if p612h<999999
replace val1=val2 if (val1==0 | val1==.) & val2>0

gen year=p612c
destring year, replace
gen mult=100 if year==2010
replace mult=97.1475237312855 if year==2008
replace mult=91.834115720599 if year==2007
replace mult=90.2280683051021 if year==2006
replace mult=88.45693230154 if year==2005
replace mult=87.0499423956515 if year==2004
replace mult=83.974402414311 if year==2003
replace mult=82.1190236374676 if year==2002
replace mult=81.9607287806368 if year==2001
replace mult=80.3717008592796 if year==2000
replace mult=77.461220726347 if year==1999
replace mult=74.8637047316375 if year==1998
replace mult=100/mult
gen     value= val1*mult
bysort  dominio p612n: egen valmd=median(value)
replace value =valmd if value==.
drop if value==.
rename value cons_csh


gen cons_gft=0
gen cons_hmp=0

gen cons_tot=cons_csh+cons_hmp+cons_gft
ren p612n INEI_code
ren factor07 hh_weight
gen TOR_original_raw=31 // no hay

gen agg_value_on_period=cons_tot

	foreach var in conglome vivienda hogar INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	
gen COICOP_2dig=9 if inlist(INEI_code,1,2,3,4,5,6,7)
replace COICOP_2dig=5 if inlist(INEI_code,8,9,10,11,12,13,14,15)
replace COICOP_2dig=7 if inlist(INEI_code,16,17,18,19,20,21)
replace COICOP_2dig=12 if inlist(INEI_code,21,22,23,24,25,26)



tempfile durables
save `durables'

*=======================EDUCATION ================================  
clear
set more off
use "$main/data/$country_fullname/enaho01a-2017-300.dta", clear
egen hhid=concat(conglome vivienda hogar)
keep hhid codperso i311b_1 i311b_2 i311b_3 i311b_4 i311b_5 i311b_6 i311b_7 i311b_8 p311c_1-p311c_8 factor07
reshape long i311b_ p311c_, i(hhid factor07 codperso) j(p 1-8)
ren i311b_ agg_value_on_period
drop if agg_value_on_period==.

ren p311c_ TOR_original_raw
/*

                 TOR_original_raw |      Freq.     Percent        Cum.
----------------------------------+-----------------------------------
                        ambulante |      3,499        2.15        2.15
                         librer�a |     19,789       12.16       14.32
               centro de estudios |     34,905       21.46       35.77
                            feria |      7,626        4.69       40.46
                puesto de mercado |     21,932       13.48       53.94
                            bazar |      2,797        1.72       55.66
             bodega, tienda, etc. |      8,355        5.14       60.80
tienda especializada al por mayor |      1,627        1.00       61.80
tienda especializada al por menor |     27,722       17.04       78.84
                             otro |      1,660        1.02       79.86
                                . |     32,767       20.14      100.00
----------------------------------+-----------------------------------
                            Total |    162,679      100.00

*/

							
tempfile education_cash
save `education_cash'

*Education non cash expenses
clear
set more off
use "$main/data/$country_fullname/enaho01a-2017-300.dta", clear

*computing education gifts and own produce (supply).  The following is noted
*a1=cash=>cons_csh
*a2=own produce=>cons_hmp
*a3=own supply=>cons_hmp
*a4=cash purchase=>cons_gft
*a5=other household=>cons_gft
*a6=social program=>cons_gft
*a7=other=>cons_gft
egen hhid=concat(conglome vivienda hogar)

gen own=1 if (p311a2_1==1|p311a2_2==1|p311a2_3==1|p311a2_4==1|p311a2_5==1|p311a2_6==1|p311a2_7==1)
replace own=1 if (p311a3_1==1| p311a3_2==1|p311a3_3==1| p311a3_4==1|p311a3_5==1|p311a3_6==1|p311a3_7==1)
egen cons_hmp=rsum(i311d_1 i311d_2 i311d_3 i311d_4 i311d_5 i311d_6 i311d_7 i311d_8) if own==1
egen cons_gft=rsum(i311d_1 i311d_2 i311d_3 i311d_4 i311d_5 i311d_6 i311d_7 i311d_8) if cons_hmp==.
keep hhid codperso i311d_1 i311d_2 i311d_3 i311d_4 i311d_5 i311d_6 i311d_7 i311d_8 cons_hmp cons_gft factor07
reshape long i311d_, i(hhid factor07 codperso) j(p 1-8)
replace cons_hmp=. if i311d_==.
replace cons_gft=. if i311d_==.
drop if i311d_==.
*replacing the aggregate value in the cons_ column with the original expenditure amount (value)
replace cons_gft=i311d if cons_gft>0 & cons_gft~=.
replace cons_hmp=i311d if cons_hmp>0 & cons_hmp~=.

gen agg_value_on_period=cons_gft if cons_gft>0 & cons_gft~=.
replace agg_value_on_period=cons_hmp if cons_hmp>0 & cons_hmp~=.

gen TOR_original_raw=41 if cons_gft>0 & cons_gft~=.
replace TOR_original_raw=42 if cons_hmp>0 & cons_hmp~=.


append using `education_cash'
ren p INEI_code
ren factor07 hh_weight

	foreach var in   INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	
	gen module=3
	replace TOR_original_raw=31 if TOR_original_raw==.
gen COICOP_2dig=10
tempfile education
save `education'

*=======================HEALTH ======================================  
clear
set more off
use "$main/data/$country_fullname/enaho01a-2017-400.dta", clear
egen hhid=concat(conglome vivienda hogar)
*there are some duplicate blank records that need to be eliminated for the person. test is for cash and test1 is for non cash
egen test=rsum(p41601 p41602 p41603 p41604 p41605 p41606 p41607 p41608 p41609 p41610 p41611 p41612 p41613)
egen test2=rsum(p41801 p41802 p41803 p41804 p41805 p41806 p41807 p41808 p41809 p41810 p41811 p41812 p41813)

tempfile health_base
save `health_base'

*eliminating 0 expenditure items to resolve duplicate problem.
drop if test==0


*there are still 20 people with duplicate observations.  Duplicate records will be collapsed.
collapse (sum)i41601 i41602 i41603 i41604 i41605 i41606 i41607 i41608 i41609 i41610 i41611 i41612 i41613 i41614 i41615 i41616 p417_01-p417_16, by (hhid codperso factor07)


ren i41610 i416010
ren i41611 i416011
ren i41612 i416012
ren i41613 i416013
ren i41614 i416014
ren i41615 i416015
ren i41616 i416016

	

ren p417_01 p417_1
ren p417_02 p417_2
ren p417_03 p417_3
ren p417_04 p417_4
ren p417_05 p417_5
ren p417_06 p417_6
ren p417_07 p417_7
ren p417_08 p417_8
ren p417_09 p417_9




reshape long i4160 p417_, i(hhid factor07 codperso) j(p 1-16)
ren i4160 agg_value_on_period
drop if agg_value_on_period==.
drop if agg_value_on_period==0
ren p417_ TOR_original_raw

/*

TOR_origina |
      l_raw |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     19,045       22.34       22.34
          1 |      3,117        3.66       25.99
          2 |        190        0.22       26.22
          3 |         45        0.05       26.27
          4 |        168        0.20       26.47
          5 |     49,656       58.24       84.71
          6 |      2,284        2.68       87.39
          7 |        595        0.70       88.08
          8 |         36        0.04       88.13
          9 |         13        0.02       88.14
         10 |      2,426        2.85       90.99
         11 |      4,558        5.35       96.33
         12 |        451        0.53       96.86
         13 |      2,055        2.41       99.27
         14 |        620        0.73      100.00
------------+-----------------------------------
      Total |     85,259      100.00

*/
	replace TOR_original_raw=31 if TOR_original_raw==0

tempfile health_cash
save `health_cash'

*computing other health care declarations.

use `health_base', clear
*dropping cash outlays
drop test
*dropping 0 value other health
drop if test2==0
*computing education gifts and own produce (supply).  The following is noted
*p4151=cash=>cons_csh
*p4152=own produce=>cons_hmp
*p4153=own supply=>cons_hmp
*p4514=other household=>cons_gft
*p4515=charity=>cons_gft
*p4516=private institutional contribution=>cons_gft
*p4517=insurance=>cons_gft (not sure about this....perhaps this should be included in cash)
*p4518=other=>cons_gft

egen own1=rsum(p4152_01 p4152_02 p4152_03 p4152_04 p4152_05 p4152_06 p4152_07 p4152_08 p4152_09 p4152_10 p4152_11 p4152_12 p4152_13 p4152_14 p4152_15 p4152_16)
egen own2=rsum(p4153_01 p4153_02 p4153_03 p4153_04 p4153_05 p4153_06 p4153_07 p4153_08 p4153_09 p4153_10 p4153_11 p4153_12 p4153_13 p4152_14 p4152_15 p4152_16)
gen type=1 if own1>0 | own2>0
egen insu=rsum(p4157_01 p4157_02 p4157_03 p4157_04 p4157_05 p4157_06 p4157_07 p4157_08 p4157_09 p4157_10 p4157_11 p4157_12 p4157_13 p4152_14 p4152_15 p4152_16)
replace type=2 if insu>0
replace type=3 if type==.
*for examination purposes the following have been labeled under the variable TYPE.
*1 are own consumption (assume they are providing their own medicine or herbs or treatment)
*2 all insurance coverage
*3 all others assume they are mostly provided by other private or public
table type

*For the purposes of this exercise, the insurance are classified as gift.  If necessary they can be reclassified as cash (see below at the **)


egen cons_hmp=rsum(i41801 i41802 i41803 i41804 i41805 i41806 i41807 i41808 i41809 i41810 i41811 i41812 i41813) if type==1
egen cons_gft=rsum(i41801 i41802 i41803 i41804 i41805 i41806 i41807 i41808 i41809 i41810 i41811 i41812 i41813) if type==3
egen cons_csh=rsum(i41801 i41802 i41803 i41804 i41805 i41806 i41807 i41808 i41809 i41810 i41811 i41812 i41813) if type==2

keep hhid codperso i41801 i41802 i41803 i41804 i41805 i41806 i41807 i41808 i41809 i41810 i41811 i41812 i41813 i41814 i41815 i41816 p417_01-p417_16 cons_hmp cons_gft factor07
ren i41810 i418010
ren i41811 i418011
ren i41812 i418012
ren i41813 i418013
ren i41814 i418014
ren i41815 i418015
ren i41816 i418016



*there are 13 duplicate persons.  These will be collapsed.
collapse (sum)i41801 i41802 i41803 i41804 i41805 i41806 i41807 i41808 i41809 i418010 i418011 i418012 i418013 i418014 i418015 i418016 p417_01-p417_16 cons_hmp cons_gft, by (hhid codperso factor07)
ren p417_01 p417_1
ren p417_02 p417_2
ren p417_03 p417_3
ren p417_04 p417_4
ren p417_05 p417_5
ren p417_06 p417_6
ren p417_07 p417_7
ren p417_08 p417_8
ren p417_09 p417_9

reshape long i4180 p417_, i(hhid factor07 codperso) j(p 1-16)
replace cons_gft=i4180 if cons_gft>0 & cons_gft~=.
replace cons_hmp=i4180 if cons_hmp>0 & cons_hmp~=.
replace cons_hmp=. if i4180==0 
replace cons_gft=. if i4180==0
drop if i4180==0
drop i4180

gen agg_value_on_period=cons_gft if cons_gft>0 & cons_gft~=.
replace agg_value_on_period=cons_hmp if cons_hmp>0 & cons_hmp~=.
drop if agg_value_on_period==.

gen TOR_original_raw=41 if cons_gft>0 & cons_gft~=.
replace TOR_original_raw=42 if cons_hmp>0 & cons_hmp~=.


append using `health_cash'
ren p INEI_code
ren factor07 hh_weight
keep hhid INEI_code  TOR_original TOR_original_raw agg_value_on_period hh_weight

*adding 9000 to distinguish other products that are also sequential in subsequent files.


compress

	foreach var in    INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	
	gen module=4
		replace TOR_original_raw=31 if TOR_original_raw==.
		
gen COICOP_2dig=6 
tempfile health
save `health'
*=======================RENT================================ 
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-100.dta", clear
egen hhid=concat(conglome vivienda hogar)

keep hhid i105b i106 factor07
gen cons_csh = i105b
replace cons_csh=i106 if cons_csh==.
gen cons_hmp=0
gen cons_gft=0
gen cons_tot=cons_csh+cons_hmp+cons_gft
gen icp_seq=.
gen src_var="p105b-p106"

gen agg_value_on_period=cons_csh
gen TOR_original_raw=31 //otro  
ren factor07 hh_weight
gen INEI_code=970
keep hhid cons_csh cons_hmp cons_gft cons_tot src_var INEI_code hh_weight TOR_original_raw agg_value_on_period

	foreach var in   INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	
	gen module=1
	gen housing=1
		replace TOR_original_raw=31 if TOR_original_raw==.
		
gen COICOP_2dig=4
tempfile rent
save `rent'
*=======================UTILITIES================================   
clear
set more off
use "$main/data/$country_fullname/enaho01-2017-100.dta", clear
egen hhid=concat(conglome vivienda hogar)

ren i1172_10 i1172_010
ren i1172_11 i1172_011
ren i1172_12 i1172_012
ren i1172_13 i1172_013
ren i1172_14 i1172_014
ren i1173_10 i1173_010
ren i1173_11 i1173_011
ren i1173_12 i1173_012
ren i1173_13 i1173_013
ren i1173_14 i1173_014
ren i1174_10 i1174_010
ren i1174_11 i1174_011
ren i1174_12 i1174_012
ren i1174_13 i1174_013
ren i1174_14 i1174_014
ren factor07 hh_weight

reshape long i1172_0 i1173_0 i1174_0, i(hhid hh_weight) j(p 1-14)
ren i1172_0 cons_csh
ren i1173_0 cons_gft
ren i1174_0 cons_hmp


replace cons_csh=0 if cons_csh==.
replace cons_gft=0 if cons_gft==.
replace cons_hmp=0 if cons_hmp==.
gen cons_tot=cons_csh+cons_hmp+cons_gft
drop if cons_tot==0
*setting the source code to a unique value so that it will match the item id with the label.
gen src_var="p1172_"+string(p) if cons_csh>0
replace src_var="p1173_"+string(p) if cons_gft>0
replace src_var="p1174_"+string(p) if cons_hmp>0

ren p INEI_code
*adding 970 to differentiate codes
*replace product_code=product_code+970

gen agg_value_on_period=cons_csh if cons_csh>0
replace agg_value_on_period=cons_gft if cons_gft>0
replace agg_value_on_period=cons_hmp if cons_hmp>0
 
gen TOR_original_raw=31 if cons_csh>0 // otro
replace TOR_original_raw=42 if cons_gft>0
replace TOR_original_raw=41 if cons_hmp>0
             
			 	foreach var in  conglome vivienda hogar  INEI_code {
*	decode `var', gen(`var'_st)
*	drop `var'
*	rename `var'_st `var'
	destring `var',replace														// This makes the files lighter
	}	
	gen module=1
		replace TOR_original_raw=31 if TOR_original_raw==.

gen COICOP_2dig=4
tempfile utilities
save `utilities'

***APPEND ALL FILES 
use `food' , clear
append using `takeaway'
append using `non_food_non_durable'
append using `transport'
append using `services'
append using `entertainment'
append using `personal_care'
append using `clothing'
append using `home_repairs'
append using `other'
append using `durables'
append using `education'
append using `health'
append using `rent'
append using `utilities'
save "$main/waste/$country_fullname/${country_code}_all_modules_appended.dta", replace

	
	****************************************************************************
	****************************************************************************
	
	* We create a unique variable to identify the original TOR in each module
	use "$main/waste/$country_fullname/${country_code}_all_modules_appended.dta", clear
	gen str2 TOR_original_raw_st = string(TOR_original_raw,"%02.0f")
	replace TOR_original_raw_st = "0" if TOR_original_raw_st == "."
	
	gen str2 module_st = string(module,"%02.0f")

	
	egen TOR_raw = concat(TOR_original_raw_st module_st)						
	destring TOR_raw, replace													

	replace TOR_raw = . if TOR_original_raw ==.								// 111 TOR
	
*	decode TOR_raw, gen(TOR_original_name)								// From the main template
*	ta TOR_original_name
	
	* We merge the TOR_original_recode
	
	merge m:1 TOR_raw using "$main/tables/$country_fullname/${country_code}_ENAHO_crosswalk_TOR.dta",  /// 
	keepusing(TOR_original TOR_original_name)  
	
	
	* We create a unique variable and values to identify the INEI_codes
	
	gen str4 INEI_code_st = string(INEI_code,"%04.0f")
	replace INEI_code_st = "0" if INEI_code_st == "."
	
	egen INEI_code_recode = concat(module_st INEI_code_st)						// 635 INEI_code_recode
	
	drop TOR_original_raw_st module_st INEI_code_st
	
	
*	decode TOR_original_raw, gen(TOR_original_name)								// From the main template
*	ta TOR_original_name
	
	replace TOR_original=31 if TOR_original_raw==31 
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace
	
	

	
***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************


	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_1.dta",  /// 
	keepusing(product_code2dig_1 product_code3dig_1 product_code4dig_1) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_3.dta",  /// 
	keepusing(product_code2dig_3 product_code3dig_3 product_code4dig_3) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_4.dta",  /// 
	keepusing(product_code2dig_4 product_code3dig_4 product_code4dig_4) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_7.dta",  /// 
	keepusing( product_code2dig_7 product_code3dig_7 product_code4dig_7) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_8.dta",  /// 
	keepusing( product_code2dig_8 product_code3dig_8 product_code4dig_8) nogen	 
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_9.dta",  /// 
	keepusing(product_code2dig_9 product_code3dig_9 product_code4dig_9) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_10.dta",  /// 
	keepusing(product_code2dig_10 product_code3dig_10 product_code4dig_10) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_11.dta",  /// 
	keepusing(product_code2dig_11 product_code3dig_11 product_code4dig_11) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_12.dta",  /// 
	keepusing(product_code2dig_12 product_code3dig_12 product_code4dig_12) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_13.dta",  /// 
	keepusing(product_code2dig_13 product_code3dig_13 product_code4dig_13) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_16.dta",  /// 
	keepusing(product_code2dig_16 product_code3dig_16 product_code4dig_16) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_17.dta",  /// 
	keepusing(product_code2dig_17 product_code3dig_17 product_code4dig_17) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_18.dta",  /// 
	keepusing(product_code2dig_18 product_code3dig_18 product_code4dig_18) nogen	
	
	merge m:1 INEI_code_recode using "$main/tables/$country_fullname/${country_code}_COICOP_crosswalk_mod_78.dta",  /// 
	keepusing(product_code2dig_78 product_code3dig_78 product_code4dig_78) nogen	
	
	
	* NOTE: for the moment, only Module 7 has COICOP_4dig !!! 
	
	
	gen product_code_2dig = .
	replace product_code_2dig = product_code2dig_1 if product_code2dig_1 != .
	replace product_code_2dig = product_code2dig_3 if product_code2dig_3 != .
	replace product_code_2dig = product_code2dig_4 if product_code2dig_4 != .
	replace product_code_2dig = product_code2dig_7 if product_code2dig_7 != .
	replace product_code_2dig = product_code2dig_8 if product_code2dig_8 != .
	replace product_code_2dig = product_code2dig_9 if product_code2dig_9 != .
	replace product_code_2dig = product_code2dig_10 if product_code2dig_10 != .
	replace product_code_2dig = product_code2dig_11 if product_code2dig_11 != .
	replace product_code_2dig = product_code2dig_12 if product_code2dig_12 != .
	replace product_code_2dig = product_code2dig_13 if product_code2dig_13 != .
	replace product_code_2dig = product_code2dig_16 if product_code2dig_16 != .
	replace product_code_2dig = product_code2dig_17 if product_code2dig_17 != .
	replace product_code_2dig = product_code2dig_18 if product_code2dig_18 != .
	replace product_code_2dig = product_code2dig_78 if product_code2dig_78 != .
	
	
	gen product_code_3dig = .
	replace product_code_3dig = product_code3dig_1 if product_code3dig_1 != .
	replace product_code_3dig = product_code3dig_3 if product_code3dig_3 != .
	replace product_code_3dig = product_code3dig_4 if product_code3dig_4 != .
	replace product_code_3dig = product_code3dig_7 if product_code3dig_7 != .
	replace product_code_3dig = product_code3dig_8 if product_code3dig_8 != .
	replace product_code_3dig = product_code3dig_9 if product_code3dig_9 != .
	replace product_code_3dig = product_code3dig_10 if product_code3dig_10 != .
	replace product_code_3dig = product_code3dig_11 if product_code3dig_11 != .
	replace product_code_3dig = product_code3dig_12 if product_code3dig_12 != .
	replace product_code_3dig = product_code3dig_13 if product_code3dig_13 != .
	replace product_code_3dig = product_code3dig_16 if product_code3dig_16 != .
	replace product_code_3dig = product_code3dig_17 if product_code3dig_17 != .
	replace product_code_3dig = product_code3dig_18 if product_code3dig_18 != .
	replace product_code_3dig = product_code3dig_78 if product_code3dig_78 != .
	
	
	gen product_code_4dig = .
	replace product_code_4dig = product_code4dig_1 if product_code4dig_1 != .
	replace product_code_4dig = product_code4dig_3 if product_code4dig_3 != .
	replace product_code_4dig = product_code4dig_4 if product_code4dig_4 != .
	replace product_code_4dig = product_code4dig_7 if product_code4dig_7 != .
	replace product_code_4dig = product_code4dig_8 if product_code4dig_8 != .
	replace product_code_4dig = product_code4dig_9 if product_code4dig_9 != .
	replace product_code_4dig = product_code4dig_10 if product_code4dig_10 != .
	replace product_code_4dig = product_code4dig_11 if product_code4dig_11 != .
	replace product_code_4dig = product_code4dig_12 if product_code4dig_12 != .
	replace product_code_4dig = product_code4dig_13 if product_code4dig_13 != .
	replace product_code_4dig = product_code4dig_16 if product_code4dig_16 != .
	replace product_code_4dig = product_code4dig_17 if product_code4dig_17 != .
	replace product_code_4dig = product_code4dig_18 if product_code4dig_18 != .
	replace product_code_4dig = product_code4dig_78 if product_code4dig_78 != .
	
	
	
	
	tempfile all_lines_COICOP_crosswalk
	save `all_lines_COICOP_crosswalk' 
	
	import excel "$main/tables/Peru2017/PE_ENAHO_crosswalk_product_code.xls", sheet("INEGI_claves") firstrow clear

	drop exp_INEI_code share_exp_INEI_code_house share_exp_INEI_code INEI_code_2dig
	
	
	merge 1:m INEI_code using `all_lines_COICOP_crosswalk' , nogen		
	

	
	save "$main/waste/$country_fullname/${country_code}_all_lines_COICOP_crosswalk.dta" , replace


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
	bys hhid: egen exp_rent = sum(agg_value_on_period) if housing == 1 // actual rent as expenses
	*by hhid: egen exp_ir = sum(agg_value_on_period) if housing == 1 // imputed rent as expenses
	*gen exp_ir_withzeros = exp_ir
	*replace exp_ir_withzeros = 0 if exp_ir_withzeros == .
	gen exp_rent_withzeros = exp_rent
	replace exp_rent_withzeros = 0 if exp_rent_withzeros == .
	gen exp_housing = exp_rent_withzeros
	
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

	destring hhid, replace
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
	collapse (sum) agg_value_on_period, by (TOR_original )
	rename agg_value_on_period expenses_value_aggregate
	egen total_exp = sum(expenses_value_aggregate)  
	gen pct_expenses = expenses_value_aggregate / total_exp 
	order  TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,41,42)
	replace detailed_classification=2 if inlist(TOR_original,37,22,19,24,3,26,27,1,7)
	replace detailed_classification=3 if inlist(TOR_original,5)
	replace detailed_classification=4 if inlist(TOR_original,20,25,32,33,39,40)
	replace detailed_classification=5 if inlist(TOR_original,4,35)
	replace detailed_classification=6 if inlist(TOR_original,30,12,36,29,13,11,9,38,21,14,23,17,16,10,6,28,2)
	replace detailed_classification=7 if inlist(TOR_original,15,8)
	replace detailed_classification=8 if inlist(TOR_original,34)
	replace detailed_classification=10 if inlist(TOR_original,18)	
	replace detailed_classification=99 if inlist(TOR_original,31)




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
	merge 1:m TOR_original using "$main/waste/$country_fullname/${country_code}_all_lines_COICOP_crosswalk.dta" , nogen

	*We keep all household expenditures and relevant variables
    keep hhid  TOR_original agg_value_on_period product_code_4dig product_code_3dig product_code_2dig housing detailed_classification TOR_original  pct_expenses COICOP_2dig
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	merge m:1 COICOP_2dig using "$main/proc/COICOP_label_2dig.dta"
	drop if _merge == 2
	drop _merge
	drop COICOP_2dig
	ren COICOP_Name2 COICOP_2dig
	
		
	*We save the database with all expenditures for the price/unit analysis
	save "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" , replace
	drop if COICOP_2dig==.
	*We create the final database at the COICOP_4dig level of analysis
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_2dig product_code_4dig product_code_3dig product_code_2dig  detailed_classification) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid product_code_4dig product_code_3dig product_code_2dig exp_TOR_item  TOR_original detailed_classification  housing , first
	destring hhid, replace
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_product_code_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_COICOP_crosswalk.dta"
	
