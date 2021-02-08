

					*************************************
					* 			Main DO FILE			*
					* 	      TANZANIA 2012				*
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

	
	global country_fullname "Tanzania2012"
	global country_code "TZ"
	
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

Ig_gsdu_gas_dia.dta
En este capítulo se recoge la información del artículo, cantidad, la unidad de medida expresada en cm3 o gramos, 
cantidad, forma de adquisición, lugar de compra, valor pagado o estimado del bien o servicio.

Ig_ml_vivienda.dta
En este capítulo se dan a conocer las características físicas de la vivienda que permitan determinar 
la calidad de la misma coomo tambien se determina el acceso a servicios públicos domiciliarios.

Ig_ml_hogar.dta
Esta tabla contiene información acerca de las condiciones generales de la vivienda habitada por el hogar.

Ig_ml_persona.dta
la tabla contiene información de las personas del hogar sobre educación, afiliación a salud, 
subsidios de alimentación en instituciones educativas para menores de 3 años y mayores de 3 años.

*/

*********************
* IMPORTANT NOTE    *
*********************

*The step has been inspired by the GCD do file, we also had to impute TOR 	

*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	
	clear
	set more off
	use "$main/data/$country_fullname/from_SECT1.dta", clear
	

	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	
	rename weight	 							hh_weight


	*We need to construct/modify some of them
	*geo_loc_min
	egen geo_loc_min = group(region district)

	*geo_loc
	gen geo_loc = region  // # = 21

	*census_block
	egen small_region_ward = group(geo_loc_min wardn)
	egen census_block = group(small_region_ward ea)


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




	*DIARY 
	clear
	set more off 
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 2 OF 3/SECTA1.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	
	rename SA1Q7		 						TOR_original 
	rename SA1Q6		 						amount_paid							// montant total
	rename SA1Q5								quantity 							// quantite
	rename SA1Q4								unit								// unite
	rename SA1Q2								product_code 						// COICOP
	rename weight 								hh_weight							//weight
		
	*We need to construct/modify some of them
	*product_code
	drop if product_code > 1270499
	
	*amount_paid
	drop if amount_paid==.
	
	gen module_trackerA ="SECTA1"
		
	sort hhid
	
	*TOR_imputation
	by product_code hhid ( TOR_original ), sort: gen desired = _N // see how many codpr by hhid have been bought in more than one TOR category 
	by product_code hhid ( TOR_original ): replace desired = 1 if TOR_original[1] == TOR_original[_N] // product by hhid that have een bought in the same TOR
	
	collapse (sum) amount_paid, by(hhid hh_weight product_code desired TOR_original module_tracker)
	save "$main/waste/$country_fullname/SECTA1_to_merge.dta" ,replace
	
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 2 OF 3/SECTA2.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename SA2Q7		 						TOR_original 
	rename SA2Q6		 						amount_paid							// montant total
	rename SA2Q5								quantity 							// quantite
	rename SA2Q4								unit								// unite
	rename SA2Q2								product_code 						// COICOP
	ren weight 									hh_weight							//weight
	
	*We need to construct/modify some of them
	*product_code
	drop if product_code > 1270499
	
	*amount_paid
	drop if amount_paid==.
	
	gen module_trackerA ="SECTA2"
		
	sort hhid
	
	by product_code hhid ( TOR_original ), sort: gen desired = _N // see how many codpr by hhid have been bought in more than one TOR category 
	by product_code hhid ( TOR_original ): replace desired = 1 if TOR_original[1] == TOR_original[_N] // product by hhid that have een bought in the same TOR
	
	collapse (sum) amount_paid, by(hhid hh_weight product_code desired TOR_original module_tracker)
	save "$main/waste/$country_fullname/SECTA2_to_merge.dta" ,replace
	
	use "$main/waste/$country_fullname/SECTA1_to_merge.dta" ,clear
	append using "$main/waste/$country_fullname/SECTA2_to_merge.dta" 
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	save "$main/waste/$country_fullname/diary_with_TOR.dta" , replace
	
	*DIARY
	clear 
	set more off
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 2 OF 3/SECTB1.dta", clear

	* drop NA cases
	drop if SB1Q13==100000000
	drop if SB1Q13==.
	
	* drop outliers
	drop if inlist(SB1Q9,114101,114301) & SB1Q13 >=133000
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename SB1Q13		 						amount_paid							// montant total
	rename SB1Q12								quantity 							// quantite
	rename SB1Q11								unit								// unite
	rename SB1Q9								product_code 						// COICOP
	ren weight 									hh_weight							//weight
		

	drop if product_code > 1270499
	
	//Annualization
	gen agg_value_on_period=amount_paid*365/28 // based on GCD
	drop if agg_value_on_period==.
	
		
	sort hhid
	
	
	keep if SB1Q14==1 // keep only "achat" , what we are gonna try to match
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	gen module_tracker ="SB1Q9"
	tempfile diary
	save `diary', replace
	
	clear
	set more off 
	use  "$main/data/$country_fullname/2011-12 HBS DATA SET 3 OF 3/SECTB3.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
		rename SB3Q21		 						amount_paid							// montant total
		rename SB3Q18								product_code 						// COICOP
		ren weight 									hh_weight							//weight
		
		gen price=. 
		*gen TOR_original=7 //others as no TOR 
		gen quantity=.
		gen unit=.
		drop if product_code > 1270499
		//Annualization
		gen agg_value_on_period=amount_paid*365/28 // based on GCD
		drop if agg_value_on_period==.
	
		
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	gen module_tracker ="SECTB3"
	tempfile takeaway
	save `takeaway', replace
	
	
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT2.dta", clear
	* check duplicates households in the data
	duplicates report hhid
	assert r(unique_value)==r(N)
	# delimit ;
	keep hhid weight S2Q06A S2Q08A S2Q10A S2Q10B S2Q10C S2Q10D S2Q10E S2Q10F S2Q10G S2Q10H S2Q10I S2Q10J 
		S2Q11A S2Q11B S2Q11C S2Q11D S2Q11E S2Q15A S2Q15B S2Q15C S2Q15D S2Q15E S2Q15F S2Q20A
		S2Q20B S2Q20C S2Q21A S2Q21B S2Q21C S2Q21D S2Q21E S2Q21F S2Q21G S2Q21H S2Q21I S2Q22A
		S2Q22B S2Q22C S2Q22D S2Q22E S2Q26A S2Q26B S2Q26C S2Q26D S2Q26E S3Q2A S3Q2B S3Q2C
		S3Q2D S3Q2E S3Q2F S3Q3A S3Q3B S3Q3C S6Q4A S6Q4B S6Q4C S6Q4D S6Q4E S6Q4F S6Q4G
		S6Q5A S6Q5B S6Q5C S6Q5D S6Q5E S6Q5F S6Q5G S6Q12A S6Q12B S6Q12C S6Q12D S6Q12E S6Q12F
		S6Q14A S6Q14B S6Q14C S6Q14D S7Q7A S7Q7B S7Q7C S7Q7D S7Q7E S7Q7F S7Q7G S7Q7H S7Q7I S7Q7J
		S7Q7K S7Q7L S7Q7M S7Q7N S7Q8A S7Q8B S7Q8C S7Q8D S7Q8E S7Q8F S7Q8G S7Q25AA S7Q25AB S7Q25AC
		S7Q25AD S7Q25AE S7Q25AF S7Q25BA S7Q25BB S7Q25BC S7Q25BD S7Q25BE S7Q25BF S7Q26AA S7Q26AB
		S7Q26AC S7Q26AD S7Q26AE S7Q26AF S7Q26AG S7Q26BA S7Q26BB S7Q26BC S7Q26BD S7Q26BE S7Q26BF
		S7Q26BG S8Q1A S8Q1B S8Q1C S8Q1D S8Q1E S8Q1F S8Q1G;
	
		ren S2Q06A exp_411101; ren S2Q08A exp_421101;
		ren S2Q10A exp_451101;ren S2Q10B exp_831101;ren S2Q10C exp_831103;ren S2Q10D exp_942301;
		ren S2Q10E exp_831106;ren S2Q10F exp_441101;ren S2Q10G exp_443101;ren S2Q10H exp_444101;
		ren S2Q10I exp_442101;ren S2Q10J exp_444103;ren S2Q11A exp_452201;ren S2Q11B exp_454101;
		ren S2Q11C exp_454301;ren S2Q11D exp_454102;ren S2Q11E exp_454103;ren S2Q15A exp_431101;
		ren S2Q15B exp_431103;ren S2Q15C exp_431104;ren S2Q15D exp_431105;ren S2Q15E exp_431107;
		ren S2Q15F exp_431109;ren S2Q20A  exp_422201;ren S2Q20B exp_412101;ren S2Q20C exp_422101;
		ren S2Q21A exp_451102;ren S2Q21B exp_831102;ren S2Q21C exp_942302;ren S2Q21D exp_831104;
		ren S2Q21E exp_441102;ren S2Q21F exp_443102;ren S2Q21G exp_444102;ren S2Q21H exp_442102;
		ren S2Q21I exp_444104;ren S2Q22A exp_452202;ren S2Q22B exp_454100;ren S2Q22C exp_454302;
		ren S2Q22D exp_454001;ren S2Q22E exp_454104;ren S2Q26A exp_432102;ren S2Q26B exp_432104;
		ren S2Q26C exp_432106;ren S2Q26D exp_432108;ren S2Q26E exp_432110;ren S3Q2A exp_532103;
		ren S3Q2B exp_541201;ren S3Q2C exp_541101;ren S3Q2D exp_541102;ren S3Q2E exp_542301;
		ren S3Q2F exp_541302;ren S3Q3A exp_562101;ren S3Q3B exp_562102;ren S3Q3C exp_1241101;
		ren S6Q4A exp_711101;ren S6Q4B exp_711102;ren S6Q4C exp_712101;ren S6Q4D exp_712102;
		ren S6Q4E exp_712103;ren S6Q4F exp_921101;ren S6Q4G exp_713101;ren S6Q5A exp_711201;
		ren S6Q5B exp_711202;ren S6Q5C exp_712201;ren S6Q5D exp_712202;ren S6Q5E exp_712203;
		ren S6Q5F exp_921102;ren S6Q5G exp_713201;ren S6Q12A exp_1254101;ren S6Q12B exp_721101;
		ren S6Q12C exp_721102;ren S6Q12D exp_722101;ren S6Q12E exp_723101;ren S6Q12F exp_724102;
		ren S6Q14A exp_732101;ren S6Q14B exp_731101;ren S6Q14C exp_733101;ren S6Q14D exp_734101;
		ren S7Q7A exp_932101;ren S7Q7B exp_941101;ren S7Q7C exp_941102;ren S7Q7D exp_942101;
		ren S7Q7E exp_942201;ren S7Q7F exp_943101;ren S7Q7G exp_912101;ren S7Q7H exp_922101;
		ren S7Q7I exp_923101;ren S7Q7J exp_914101;ren S7Q7K exp_941103;ren S7Q7L exp_922201;
		ren S7Q7M exp_931101;ren S7Q7N exp_934101;ren S7Q8A exp_1011101;ren S7Q8B exp_1051101;
		ren S7Q8C exp_732104;ren S7Q8D exp_951101;ren S7Q8E exp_1051102;ren S7Q8F exp_1121101;
		ren S7Q8G exp_1121102;ren S7Q25AA exp_961101;ren S7Q25AB exp_961102;ren S7Q25AC exp_961103;
		ren S7Q25AD exp_961104;ren S7Q25AE exp_961105;ren S7Q25AF exp_961106;ren S7Q25BA exp_961107;
		ren S7Q25BB exp_961108;ren S7Q25BC exp_961109;ren S7Q25BD exp_961110;ren S7Q25BE exp_961111;
		ren S7Q25BF exp_961112;ren S7Q26AA exp_961113;ren S7Q26AB exp_961114;ren S7Q26AC exp_961115;
		ren S7Q26AD exp_961116;ren S7Q26AE exp_961117;ren S7Q26AF exp_961118;ren S7Q26AG exp_961119;
		ren S7Q26BA exp_961120;ren S7Q26BB exp_961121;ren S7Q26BC exp_961122;ren S7Q26BD exp_961123;
		ren S7Q26BE exp_961124;ren S7Q26BF exp_961125;ren S7Q26BG exp_961126;ren S8Q1A exp_1232101;
		ren S8Q1B exp_1231102;ren S8Q1C exp_1231103;ren S8Q1D exp_1232201;ren S8Q1E exp_1232202;
		ren S8Q1F exp_1212101;ren S8Q1G exp_1232203;ren weight hh_weight;
	# delimit cr
	
	
	reshape long exp_, i(hhid) j(product_code)
	drop if product_code==.
	gen agg_value=exp_
	
	
	*Annualization
	#delimit;
	gen agg_value_on_period =agg_value * 12 if inlist(product_code,411101,421101,451101,831101,831103,942301,
		831106,441101,443101,444101,442101,444103,
		422201,412101,422101,451102,831102,942302,831104,441102,443101,444102,
		442102,444104,562101,562102,1241101,721101,721102,722101,723101,724102,
		732101,731101,733101,734101,1232101,1231102,1231103,1232201,1232202,
		1212101,1232203);
	
	replace agg_value_on_period=agg_value * 4 if inlist(product_code,452201,454101,454301,454102,
		454103,452202,454101,454302,
		454001,454104,532103,541201,541101,541102,542301,541302,932101,941101,
		941102,942101,942201,943101,912101,922101,923101,914101,941103,922201,
		931101,934101,1011101,1051101,732104,951101,1051102,1121101,1121102);
	#delimit cr
	
	drop if  agg_value_on_period==0 |  agg_value_on_period==. 
	gen module_tracker ="section2"
	sort hhid
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd1
	save `nfd1', replace
	
	* DURABLE GOODS: recall periods - 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT2Q27.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	ren weight hh_weight
	*map to COICOP 
	# delimit;
	recode S2Q27A (1=531301)(2=531302)(3=531303)(4=531101)(5=511101)(6=511102)(7=511103)
		(8=511104)(9=511105)(10=511106)(11=532102)(12=531402)(13=521102)(14=531401)
		(15=531601)(16=1231101)(17=532101)(18=541301), gen(product_code);
	# delimit cr 
	
	gen agg_value_on_period=S2Q29
	drop if agg_value_on_period==.
	gen module_tracker="S2Q27A"
	
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd2
	save `nfd2', replace
	
	
	*New garments and footwear - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT4A.dta", clear
	*map coicop
	
	# delimit;
	recode S4AQ1A (1=312101)(2=312102)(3=312103)(4=312104)(5=312105)(6=312106)
		(7=312107)(8=312201)(9=312202)(10=312203)(11=312204)(12=312205)(13=312206)
		(14=312207)(15=312208)(16=312301)(17=312302)(18=312303)(19=312304)(20=312305)
		(21=312306)(22=312307)(23=313105)(24=311101)(25=321101)(26=321102)(27=321103)
		(28=321201)(29=321202)(30=321203)(31=321301)(32=321302)(33=321303)(34=321304)
		(35=321305), gen(product_code);
	# delimit cr
	
	
	gen agg_value_on_period =S4AQ2
	drop if agg_value_on_period==.
	gen module_tracker ="S4AQ1A"
	
	sort hhid
	ren weight hh_weight
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd3
	save `nfd3', replace
	
	* Second hand garments and footwear - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT4B.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	*map to COICOP 
	# delimit;
	recode S4BQ1A (1=312108)(2=312109)(3=312110)(4=312111)(5=312112)(6=312113)
		(7=312114)(8=312209)(9=312210)(10=312211)(11=312212)(12=312213)(13=312214)
		(14=312215)(15=312216)(16=312308)(17=312309)(18=312310)(19=312311)(20=312312)
		(21=312313)(22=312314)(23=313106)(24=311102)(25=321104)(26=321105)(27=321106)
		(28=321204)(29=321205)(30=321206)(31=321306)(32=321307)(33=321308)(34=321309)
		(35=321310), gen(product_code);
	# delimit cr
	
	gen agg_value_on_period =S4BQ4
	drop if agg_value_on_period==.
	gen module_tracker="S4BQ1A"
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd4
	save `nfd4', replace
	
	
	* Health expenditures - recall period is one month
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT5.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	# delimit;
	recode S5Q2A (1=611101)(2=612101)(3=631101)(4=631102)(5=621101)(6=622101)
		(7=623101)(8=623102)(9=623201)(10=623301)(11=613101)(12=613102)(13=613103)
		(14=613104)(15=613105), gen(product_code);
	# delimit cr
	
	
	
	gen agg_value_on_period =total
	drop if agg_value_on_period==.
	gen module_tracker="S5Q2A"
	
	*Annualization
	replace agg_value_on_period = agg_value_on_period * 12
	
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd5
	save `nfd5', replace
	
	* Goods bought in the last 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT6Q15.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	recode S6Q15A (1=821101)(2=821102)(3=911203)(4=821104)(5=911205), gen(product_code)
	ren weight hh_weight
	
	
	gen agg_value_on_period =S6Q17
	drop if agg_value_on_period==.
	gen module_tracker="S6Q15A"
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd6
	save `nfd6', replace
	
	
	* Goods bought in the last 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT7Q1.dta", clear
	
	
	recode S7Q1A (1=911201)(2=911202)(3=911101)(4=911102)(5=911103)(6=951102), gen(product_code)
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	
	gen agg_value_on_period =S7Q3
	drop if agg_value_on_period==.
	gen module_tracker="S7Q1A"
	
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd7
	save `nfd7', replace
	
	
	
	* Any formal expenditures for registration fees for private schools - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT7Q9.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	recode S7Q9A (1=1011102)(2=1011103)(3=1021101)(4=1041101)(5=1051103), gen(product_code)
	
	gen agg_value_on_period =S7Q10
	drop if agg_value_on_period==.
	gen module_tracker="S7Q9A"
	
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd8
	save `nfd8', replace
	
	* Any informal expenditures for registration fees for private schools - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT7Q11.dta", clear
	
	recode S7Q11A (1=1011104)(2=1011105)(3=1021102)(4=1041102)(5=1051104), gen(product_code)
	ren weight hh_weight
	gen agg_value_on_period =S7Q12
	drop if agg_value_on_period==.
	gen module_tracker="S7Q11A"
	
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd9
	save `nfd9', replace
	
	* Any formal expenditures for registration fees for public schools - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT7Q13.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	
	recode S7Q13A (1=1011106)(2=1011107)(3=1021103)(4=1041103)(5=1051105), gen(product_code)
	
	
	gen agg_value_on_period =S7Q14
	drop if agg_value_on_period==.
	gen module_tracker ="S7Q13A"
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd10
	save `nfd10', replace
	
	
	* Any informal expenditures for registration fees for public schools - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT7Q15.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	
	recode S7Q15A (1=1011108)(2=1011109)(3=1021104)(4=1041104)(5=1051106), gen(product_code)
	
	gen agg_value_on_period =S7Q16
	drop if agg_value_on_period==.
	gen module_tracker ="S7Q15A"
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd11
	save `nfd11', replace
	
	* Expenditures on services - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT8Q2.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	
	# delimit;
	recode S8Q2A (1=1271101)(2=1271102)(3=1253101)(4=1253102)(5=1253103)(6=1253104)
		(7=1253105)(8=1253106)(9=1252101)(10=1254102)(11=724103)(12=1271103)(13=736101)
		(14=1271104)(15=1271105), gen(product_code);
	# delimit cr
	
	
	gen agg_value_on_period =S8Q3
	drop if agg_value_on_period==.
	
	gen module_tracker ="S8Q2A"
	
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd12
	save `nfd12', replace
	
	* Other expenditure - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT8Q4.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	
	recode S8Q4A (1=1262101)(2=1262102)(3=1262103)(4=1262104)(5=1262105), gen(product_code)
	
	
	gen agg_value_on_period =S8Q5
	drop if agg_value_on_period==.
	gen module_tracker ="S8Q4A"
	
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd13
	save `nfd13', replace
	
	* Other articles and services - recall period is 12 months
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 1 OF 3/SECT8Q6.dta", clear
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
		
	ren weight hh_weight
	
	keep if inlist(S8Q6A,1,4)
	recode S8Q6A (1=1253100)(4=1271100), gen(product_code)
	
	
	gen agg_value_on_period =S8Q8
	drop if agg_value_on_period==.
	gen module_tracker ="S8Q6A"
	sort hhid
	
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	
	
		
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	tempfile nfd14
	save `nfd14', replace
	
	
	****MERGING FILES*********
	use `diary', clear
	append using `takeaway'
	append using `nfd1'
	append using `nfd2'
	append using `nfd3'
	append using `nfd4'
	append using `nfd5'
	append using `nfd6'
	append using `nfd7'
	append using `nfd8'
	append using `nfd9'
	append using `nfd10'
	append using `nfd11'
	append using `nfd12'
	append using `nfd13'
	append using `nfd14'
	
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code)
	egen hhid_2 = group(hhid) // to merge
	gen str8 COICOP_7dig =substr(string(product_code,"%07.0f"), 1,8) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
	replace COICOP_7dig = substr(string(product_code,"%07.0f"), 1,8) if product_code > 954200 
	egen hhid_codpr = concat(hhid_2 COICOP_7dig) // to merge 
	
	merge 1:m hhid_codpr using "$main/waste/$country_fullname/diary_with_TOR.dta"
	
	
	/*
	
		Result                           # of obs.
		-----------------------------------------
		not matched                       722,970
			from master                   472,199  (_merge==1)
			from using                    250,771  (_merge==2)
	
		matched                           175,650  (_merge==3)
		-----------------------------------------
	
	*/
	
	drop if _merge==2 // in SECTA1 but not in the modules without TOR that GCD takes into account 
	replace TOR_original=99 if _merge==1 // in the GCD modules but not in SECTA and we will impute  
	replace TOR_original=TOR_original if _merge==3 // impute TOR
	replace TOR_original=13 if product_code==411101 |product_code==421101 // corresponds to rent and  imputed rent
	
	* When several TOR for one product for the same hhid put weight on the value 
	bys hhid product_code: egen sum_cons_distinct=total(amount_paid) if desired>1
	gen fraction_cons_distinct=amount_paid/sum_cons_distinct
	replace agg_value_on_period= agg_value_on_period*fraction_cons_distinct if fraction_cons_distinct!=.
	
	
	ta TOR, m
	*71% de Not stated qui sont les expenditure des modules GCD pas present dans SECTA + 3% de "Other" deja danst sectA 
	/*
	
	
						7. Outlets |      Freq.     Percent        Cum.
	--------------------------------+-----------------------------------
							Market |     64,994       10.03       10.03
							Shop |     59,271        9.15       19.18
					Street vendor |      6,094        0.94       20.12
						Supermarket |        167        0.03       20.15
	Duka kubwa(Department stores) |        358        0.06       20.20
					Other household |      7,722        1.19       21.39
							Other |     20,866        3.22       24.62
			Produced by household |     11,397        1.76       26.37
		Gift from other household |      2,101        0.32       26.70
					Gift or free |      2,270        0.35       27.05
	Aid from different institutions |        388        0.06       27.11
								12 |          3        0.00       27.11
								13 |     10,179        1.57       28.68
						Not stated |    462,039       71.32      100.00
	--------------------------------+-----------------------------------
							Total |    647,849      100.00
	
	
	. 
	
	*/
	tempfile GCD_modules_with_TOR
	save `GCD_modules_with_TOR.dta'
	
	*Now we need to add the other expenditures that are not in the category "Achat" in the diary file (SECTB1)
	clear 
	set more off
	use "$main/data/$country_fullname/2011-12 HBS DATA SET 2 OF 3/SECTB1.dta", clear
	* drop NA cases
	drop if SB1Q13==100000000
	drop if SB1Q13==.
	
	* drop outliers
	drop if inlist(SB1Q9,114101,114301) & SB1Q13 >=133000
	
		rename SB1Q13		 						amount_paid							// montant total
		rename SB1Q12								quantity 							// quantite
		rename SB1Q11								unit								// unite
		rename SB1Q9								product_code 						// COICOP
		ren weight 									hh_weight							//weight
		
	gen price=. 
	drop if product_code > 1270499
	
	//Annualization
	gen agg_value_on_period=amount_paid*365/28 // based on GCD
	drop if agg_value_on_period==.
	
	gen module_tracker ="SB1Q9"
		
	sort hhid
	
	
	drop if SB1Q14==1 // keep all modep except "achat"
	ren SB1Q14 modep
	collapse (sum) agg_value_on_period, by (hhid hh_weight product_code modep)
	append using `GCD_modules_with_TOR.dta'
	
	
	
	replace TOR_original=8 if modep==2 //own production
	replace TOR_original=9 if modep==3 //received as payment in kind
	replace TOR_original=10 if modep==4 // received free as a gift
	replace TOR_original=11 if modep==5 //food aid
	replace TOR_original=8 if modep==6 //gathered ?? own production?
	replace TOR_original=7 if modep==7 | modep==8 | modep==9 | modep==10 | TOR_original==12 | TOR_original==99  // other
	ta TOR, m
	* autre devient 70% 
	
	#delim ; // create the label
		label define TOR_original_label 
	1 "Market" 2 "Shop" 3 "Street vendor" 4 "Supermarket"
	5 "Duka kubwa(Department stores)" 6 "Other household" 7 "Other"
	8 "Produced by household" 9 "Gift from other household" 10 "Gift or free"
	11 "Aid from different institutions" 12 "From the bush" 13 "Dwelling owner"  ;
		#delim cr
		label list TOR_original_label
		label values TOR_original TOR_original_label // assign it
		ta TOR_original
	
		decode TOR_original, gen(TOR_original_name)
		ta TOR_original_name
		drop if TOR_original == . // 0 obs deleted
	
		gen housing = 0 
		replace housing=1 if TOR_original==13
		gen quantity=.
		gen unit=. 
		gen price=. 
		keep hhid hh_weight modep TOR_original TOR_original_name agg_value_on_period ///
			product_code  quantity unit price 
			
			order hhid, first
			
			drop if product_code > 1270499 //only keep monetary expenses; 13,338 deleted
		
	
	
	gen str6 COICOP_2dig = substr(string(product_code,"%07.0f"), 1,2) if product_code <= 954200  // add 0 in front of 5-dig code to account for 1-9
		replace COICOP_2dig = substr(string(product_code,"%07.0f"), 1,2) if product_code > 954200 
		ta COICOP_2dig, m
		
		gen coicop2dig = COICOP_2dig
		destring coicop2dig, replace
		
		bysort COICOP_2dig: tab TOR_original
	
	*11/27 do it by decile
	egen total_exp = sum(agg_value_on_period), by(hhid)	
	xtile decile = total_exp [weight=hh_weight], nq(10) 
	
	bys decile COICOP_2dig: egen sum_cons_COICOP=total(agg_value_on_period) if TOR_original!=7
	bys decile COICOP_2dig TOR_original: egen sum_cons_TOR=total(agg_value_on_period) if TOR_original!=7
	gen share_cons_TOR_COICOP=sum_cons_TOR/sum_cons_COICOP if TOR_original!=7
	
	forval i = 1/6 {
	bys decile COICOP_2dig TOR_original: egen share_`i'prep=mean(share_cons_TOR_COICOP) if TOR_original==`i'
	bys decile COICOP_2dig: egen share`i'=mean(share_`i'prep)
	}
	
	forval i = 8/11 {
	bys decile COICOP_2dig TOR_original: egen share_`i'prep=mean(share_cons_TOR_COICOP) if TOR_original==`i'
	bys decile COICOP_2dig: egen share`i'=mean(share_`i'prep)
	}
	
	bys decile COICOP_2dig TOR_original: egen share_13prep=mean(share_cons_TOR_COICOP) if TOR_original==13
	bys decile COICOP_2dig: egen share13=mean(share_13prep)
	save "$main/waste/$country_fullname/${country_code}_all_lines_diary_assign_TOR.dta", replace
	
	*Keep only the expenditures that are others ( it should be product that are present only once per hhid to which we couldn't impute a TOR based on expenses of the same product)
	keep if TOR_original==7
	keep hhid decile  hh_weight product_code agg_value COICOP_2dig share1 share2 share3 share4 share5 share6 share8 share9 share10 share11 share13
	duplicates drop hhid decile product_code agg_value_on_period COICOP_2dig hh_weight , force
	reshape long share, i(hhid decile product_code agg_value_on_period COICOP_2dig hh_weight) j(TOR_original)
	gen new_agg_value_on_period= agg_value_on_period*share
	drop if new_agg_value_on_period==.
	
	save "$main/waste/$country_fullname/${country_code}_all_lines_diary_assign_TOR_autre.dta", replace
	
	use "$main/waste/$country_fullname/${country_code}_all_lines_diary_assign_TOR.dta", clear
	drop if TOR_original==7 & (share1!=. | share2!=. | share3!=. | share4!=. | share5!=. | share6!=. | share8!=. |share9!=. |share10!=. |share11!=.)
	append using "$main/waste/$country_fullname/${country_code}_all_lines_diary_assign_TOR_autre.dta"
	
	replace agg_value_on_period=new_agg_value_on_period if new_agg_value_on_period!=.
	drop TOR_original_name
	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name
	*only 0.85% of autre!
	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
		
	*We keep all household expenditures and relevant variables
	keep hhid product_code TOR_original TOR_original_name quantity unit agg_value_on_period housing coicop_2dig   
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
	order  TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,10,6,9,8,11,12)
	replace detailed_classification=2 if inlist(TOR_original,1,3)
	replace detailed_classification=4 if inlist(TOR_original,2)
	replace detailed_classification=5 if inlist(TOR_original,4,5)
	replace detailed_classification=99 if inlist(TOR_original,7)

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
    keep hhid product_code TOR_original agg_value_on_period coicop_2dig  housing detailed_classification TOR_original  pct_expenses 
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
	
	
