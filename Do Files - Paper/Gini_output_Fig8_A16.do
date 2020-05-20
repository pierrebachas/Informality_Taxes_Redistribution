
***************************   Outline    ***************************************
/*


This do-file calculates the change in Gini coefficients from applying direct/
indirect tax systems, using CEQ and OECD data-bases

Structure
- A: Load CEQ data-set, calculate required income concepts and Gini coefs
	 collapse to country-level
- B: Append OECD data-set, at country-level with Gini coefficients

The constructed data-set is then appended with Gini coefficients calculated
under different scenarios in our primary data-set


*/
********************************************************************************



***************
* DIRECTORIES *
***************

if "`c(username)'"=="ajensen" { 													// Anders's computer 
	global main "C:\Users\ajensen\Dropbox (CID)\Research\projects\Regressivity_VAT\Stata\data\CEQ_data_June2019.dta"	
}	
else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}	
	


*********************************
* STEP 0 : Prepare GDP dataset  *
*********************************
	

import excel "$main\data\GDP_gini.xlsx", sheet("Data") firstrow clear 
ren CountryName country_fullname
ren CountryCode country_3let
ren GDPpercapitaconstant2010US GDP_pc_constantUS2010
replace country_fullname="Iran" if country_fullname=="Iran, Islamic Rep." 
replace country_fullname="Russia" if country_fullname=="Russian Federation"
replace country_fullname="Venezuela" if country_fullname=="Venezuela, RB"

tempfile gdp
save `gdp'


***********************************
* STEP 1.1 : Prepare CEQ dataset  *
***********************************

	*clear
	* change path here, as needed
	*use "C:\Users\ajensen\Dropbox (CID)\Research\projects\Regressivity_VAT\Stata\data\CEQ_data_June2019.dta"
	
	clear
	use "$main/data/CEQ_data_June2019.dta"
	
	drop if decile=="Total"
	* This drops the total row at the country level, to keep only the 10 deciles
	
	rename country country_year
	
	drop marketincome directtaxes_2 contributions_2 contributorypensions_2 directtransfersincludingcontribu disposableincome_2 indirecttaxes_2 indirectsubsidies_2 consumableincome_2 education_2 health_2 otherinkind_2 fees_2 finalincome_2
	* We are going to be using the income measures where pension is part of market income, we do this to increase the sample-size;
	
	destring decile, replace
	
	drop if marketincomepluspensions==.
	drop if directtransferswocontributorypen==.
	drop if directtaxes==.
	* Keep only countries which have marketincome, direct taxes, and direct transfers
	
	* Calculate gross income = market income, post direct transfers pre direct taxes
	
	egen directtax=rowtotal(directtaxes contributions)
	
	gen direct_transfer=disposableincome-directtax
	sum direct_transfer
	
	gen income_gross=marketincome*(1+direct_transfer)
	
	* calculate disposable income = market income, post direct transfers and direct taxes
	
	
	gen income_disposable=marketincome*(1+disposableincome)
	
	gen check1=(income_disposable/marketincome - 1)/disposableincome
	sum check1
	
	* calculate income_consumable_pretax = market income, post direct transfers and direct taxes and indirect subsidies

	replace indirectsubsidies=0 if indirectsubsidies==.
	
	gen check_alt=(disposableincome+indirecttaxes+indirectsubsidies)/consumableincome
	sum check_alt
	* this works perfectly, as it should, in all countries except Sri Lanka --> drop SL for the moment
	drop if country_year == "Sri Lanka (2009)"
	
	gen income_consu_pretax=marketincome*(1+disposableincome+indirectsubsidies)
	
	* calculate income_cons_posttax = market income, post direct transfers and direct taxes and indirect subsidies and indirect taxes
	gen income_consu_posttax=marketincome*(1+consumableincome)
	
	gen check2=(income_consu_posttax/marketincome - 1)/consumableincome
	sum check2
	
	** calculating Gini coefficients
	sort country_year decile
	egen group_country = group(country_year)
	
	* Gini for income_gross
	ineqdeco income_gross, bygroup(group_country)
	
	gen gini_gross=.
	forvalues i = 1(1)31{
	replace gini_gross = `r(gini_`i')' if group_country == `i'
	}
	
	* Gini for income_disp
	gen gini_disp=.
	ineqdeco income_disposable, bygroup(group_country)
	forvalues i = 1(1)31{
	replace gini_disp = `r(gini_`i')' if group_country ==`i'
	}
	
	
	* Gini for income_cons_pretax
	gen gini_cons_pretax=.
	ineqdeco income_consu_pretax, bygroup(group_country)
	forvalues i = 1(1)31{
	replace gini_cons_pretax = `r(gini_`i')' if group_country == `i'
	}
	
	* Gini for income_cons_posttax
	gen gini_cons_posttax=.
	ineqdeco income_consu_posttax, bygroup(group_country)
	forvalues i = 1(1)31{
	replace gini_cons_posttax = `r(gini_`i')' if group_country == `i'
	}
	collapse (mean) gini_gross gini_disp gini_cons_pretax gini_cons_posttax group_country, by(country_year)
	gen source="CEQ"
	
	*Drop countries that appears twice, keeping the most recent year
	drop if country_year=="Colombia (2010)" | country_year=="Mexico (2010)" | country_year=="Mexico (2012)" | country_year=="Peru (2009)" 
	
	*Harmonize the country names to merge with GDP datasets
	gen country_fullname = substr(country_year,1, strlen(country_year) - 7) if source=="CEQ"
	replace country_fullname = substr(country_year,1, strlen(country_year) - 8) if country_year=="Paraguay (2014) "
	
	
	merge 1:m country_fullname using `gdp'
	keep if _merge==3
	drop _merge
	
	keep if Time=="2011" // May change this later to have country year to match the gdp year
	
	tempfile CEQ_gini
	save `CEQ_gini'



************************************
* STEP 1.2 : Prepare OECD dataset  *
************************************


*************** B : Append with OECD country-level data-set ********************

*Data Prep : OECD data on indirect taxes 
import excel "$main/data/gini_oecd_indirect_taxes.xlsx", sheet("Feuil1 (2)") firstrow clear
ren A country_fullname
ren post gini_cons_posttax
ren income_disp gini_cons_pretax
ren gini  gini_delta2
tempfile gini_oecd_indirect_taxes
replace country_fullname="Czech Republic" if country_fullname=="Czech Rep."
destring gini_cons_pretax gini_delta2 gini_cons_posttax , replace
save `gini_oecd_indirect_taxes'

	*GINI DISP
	
	clear 
	import excel "$main/data/gini_disp_oecd.xls", sheet("OECD.Stat export") firstrow clear
	
	*Clean the Dataset
	ren Country country
	drop if Methodology=="Income definition until 2011"
	drop if D==""
	
	foreach var of varlist D-S {
	replace `var'="" if `var'==".."
	}
	
	destring D-S , replace
	drop D-J
	
	*Keep the most recent income measure for each country (for most of them it is 2017)
	ren K year2011
	ren M year2013
	ren N year2014
	ren O year2015
	ren P year2016
	ren Q year2017
	ren R year2018
	ren S year2019
	
	gen year=2017 
	gen gini_disp= year2017
	
	
	* Some countries have less/more recent gini disp measures
	replace year=2011 if country=="China (People's Republic of)" | country=="India"  
	replace year=2013 if country=="Brazil" 
	replace year=2014 if country=="New Zealand" 
	replace year=2015 if country=="Iceland" | country=="Japan" | country=="Switzerland" | country=="Turkey" | country=="South Africa" 
	replace year=2016 if country=="Denmark" | country=="Mexico" | country=="Netherlands" | country=="Slovak Republic" | country=="Russia"
	replace year=2018 if country=="Australia" | country=="Israel" 
	replace year=2019 if country=="Costa Rica"
	
	replace gini_disp=year2011 if country=="China (People's Republic of)" | country=="India"  
	replace gini_disp=year2013 if country=="Brazil" 
	replace gini_disp=year2014 if country=="New Zealand" 
	replace gini_disp=year2015 if country=="Iceland" | country=="Japan" | country=="Switzerland" | country=="Turkey" | country=="South Africa" 
	replace gini_disp=year2016 if country=="Denmark" | country=="Mexico" | country=="Netherlands" | country=="Slovak Republic" | country=="Russia"
	replace gini_disp=year2018 if country=="Australia" | country=="Israel" 
	replace gini_disp=year2019 if country=="Costa Rica"
	
	*Create country_year
	tostring year, replace
	gen country_year=country+year
	
	*Harmonize country names to be able to merge with the GDP_capita.dta (data on GDP) and the indirect taxes dataset
	gen country_fullname = substr(country_year,1, strlen(country_year) - 4) 
	
	keep country_year gini_disp
	tempfile OECD_gini_disp
	save `OECD_gini_disp'
	
	
	*GINI GROSS
	clear 
	import excel "$main/data/gini_gross_oecd.xls", sheet("OECD.Stat export") firstrow clear
	
	*Clean the Dataset
	ren Country country
	drop if Methodology=="Income definition until 2011"
	
	foreach var of varlist D-S {
	replace `var'="" if `var'==".."
	}
	
	destring D-S , replace
	drop D-J
	
	*Keep the most recent income measure for each country (for most of them it is 2017)
	ren K year2011
	ren M year2013
	ren N year2014
	ren O year2015
	ren P year2016
	ren Q year2017
	ren R year2018
	ren S year2019
	
	gen year=2017 
	gen gini_gross= year2017
	
	
	* Some countries have less/more recent gini disp measures
	replace year=2011 if country=="China (People's Republic of)" | country=="India"  
	replace year=2013 if country=="Brazil" 
	replace year=2014 if country=="New Zealand" 
	replace year=2015 if country=="Iceland" | country=="Japan" | country=="Switzerland" | country=="Turkey" | country=="South Africa" 
	replace year=2016 if country=="Denmark" | country=="Mexico" | country=="Netherlands" | country=="Slovak Republic" | country=="Russia"
	replace year=2018 if country=="Australia" | country=="Israel" 
	replace year=2019 if country=="Costa Rica"
	
	replace gini_gross=year2011 if country=="China (People's Republic of)" | country=="India"  
	replace gini_gross=year2013 if country=="Brazil" 
	replace gini_gross=year2014 if country=="New Zealand" 
	replace gini_gross=year2015 if country=="Iceland" | country=="Japan" | country=="Switzerland" | country=="Turkey" | country=="South Africa" 
	replace gini_gross=year2016 if country=="Denmark" | country=="Mexico" | country=="Netherlands" | country=="Slovak Republic" | country=="Russia"
	replace gini_gross=year2018 if country=="Australia" | country=="Israel" 
	replace gini_gross=year2019 if country=="Costa Rica"
	
	
	*Create country_year
	tostring year, replace
	gen country_year=country+year
	
	keep country_year gini_gross
	
	*Harmonize country names to be able to merge with the GDP_capita.dta (data on GDP) and the indirect taxes dataset
	gen country_fullname = substr(country_year,1, strlen(country_year) - 4)
	
	*Merge gini_disp, gini_gross, indirect taxes dataset (gini_cons_pretax, gini_cons_postax)  datasets
	
	merge 1:1 country_year using `OECD_gini_disp'
	drop _merge
	merge 1:1 country_fullname using `gini_oecd_indirect_taxes'
	keep if _merge==3
	drop _merge
	
	order country_year, first
	gen source="OECD"
	
	*NOTE: 4 countries have missing gini_gross income measures : China, Turkey, Mexico, Korea we are gonna drop them
	drop if gini_gross==.
	
	*Drop non OECD countries according to the official definition of OECD countries
	
	gen oecd_non_official=(country_year=="Brazil2013" | country_year=="Bulgaria2017" | country_year=="China (People's Republic of)2011" | country_year=="Costa Rica2019" | country_year=="India2011" | country_year=="Romania2017" | country_year=="Russia2016" | country_year=="South Africa2015")
	drop if oecd_non_official==1
	
	
	
	
	merge 1:m country_fullname using `gdp'
	keep if _merge==3
	drop _merge
	
	keep if Time=="2017" // May change this later to have country year to match the gdp year
	
	
	
	*Append CEQ dataset 
	append using `CEQ_gini'
	order  source, last
	destring GDP_pc_constantUS2010 , replace
	gen ln_GDP = log(GDP_pc_constantUS2010)
	********************************************************************************
	
	
	
	*********************** NB: for analysis do-file *******************************
	
	* Calculation of comparison #1: Gini change from applying direct tax system in CEQ
	gen dif_gini_5=gini_disp-gini_gross if source== "CEQ"
	sum dif_gini_5
	gen pct_dif_gini_5 = 100 *(gini_disp - gini_gross) / gini_gross if source== "CEQ"
	
	
	// --> average drop of 1.2 points in Gini
	
	* Calculation of comparison #2: Gini change from applying indirect tax system in CEQ
	gen dif_gini_6=gini_cons_posttax-gini_cons_pretax if source== "CEQ"
	sum dif_gini_6
	gen pct_dif_gini_6 = 100 *(gini_cons_posttax - gini_cons_pretax) / gini_cons_pretax if source== "CEQ"
	
	// --> average nill impact
	
	* Calculation of comparison #1: Gini change from applying direct tax system in OECD
	gen dif_gini_7=gini_disp-gini_gross if source== "OECD"
	sum dif_gini_7
	gen pct_dif_gini_7 = 100 *(gini_disp - gini_gross) / gini_gross if source== "OECD"
	
	
	destring GDP_pc_constantUS2010 , replace
	tempfile gini_ceq_oecd
	save `gini_ceq_oecd'

	
	**********************************************************
	* STEP 2 : Append to the gini dataset of our core sample *
	**********************************************************
	
	use "$main/waste/cross_country/gini_central_baseline.dta", clear 
	append using `gini_ceq_oecd' 

	** Changes in GINI coefficients: Average whole sample and separated for Low vs Middle Income countries 	
	
	** Drop from CEQ upper middle (Argentina and Russia) 
	drop if country_3let == "ARG" |  country_3let == "RUS" 
	
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 dif_gini_5 pct_dif_gini_5 dif_gini_6 pct_dif_gini_6 dif_gini_7 pct_dif_gini_7 
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 dif_gini_5 dif_gini_6 dif_gini_7 if ln_GDP>7.65
	sum gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 dif_gini_5 dif_gini_6 dif_gini_7 if ln_GDP<7.65
	
	* Results to outsheet for figure
	global statdesc  gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 dif_gini_5 pct_dif_gini_5 dif_gini_6  pct_dif_gini_6 dif_gini_7 pct_dif_gini_7
	version 14.2: outreg2 using "$main/tables/gini_$scenario.cvs", replace sum(log) keep($statdesc)  afmt(g) dta
	
	preserve
	keep if ln_GDP>7.65
	global statdesc_middle  gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 dif_gini_5 pct_dif_gini_5 dif_gini_6 pct_dif_gini_6 dif_gini_7  
	version 14.2: outreg2 using "$main/tables/gini_middle_$scenario.cvs", replace sum(log) keep($statdesc_middle)  afmt(g) dta
	restore
	
	preserve
	keep if ln_GDP<7.65
	global statdesc_low  gini_pre dif_gini_1 pct_dif_gini_1 dif_gini_2 pct_dif_gini_2 dif_gini_3 pct_dif_gini_3 dif_gini_5 pct_dif_gini_5 dif_gini_6 pct_dif_gini_6 dif_gini_7  
	version 14.2: outreg2 using "$main/tables/gini_low_$scenario.cvs", replace sum(log) keep($statdesc_low)  afmt(g) dta
	restore
	
	local export_to_csv = 1
	if `export_to_csv' { 
		clear 
		use "$main/tables/gini_${scenario}_dta.dta", clear
		drop in 1/3
		ren v1 var 
		ren v2 Obs
		ren v3 mean 
		ren v4 se
		ren v5 min
		ren v6 max
		destring Obs-max , replace
		
		drop if var=="dif_gini_1" | var=="dif_gini_2" | var=="dif_gini_3" | var=="dif_gini_5" | var=="dif_gini_6" | var=="dif_gini_7" | var=="pct_dif_gini_7" | var=="gini_pre"
		gen ci_low = mean - 1.96*se
		gen ci_high = mean + 1.96*se
		gen scenario="Food subsidy, formal and informal taxed" 		if var=="pct_dif_gini_1"
		replace scenario="Uniform rate, only formal taxed" 			if var=="pct_dif_gini_2"
		replace scenario="Food subsidy, only formal taxed" 			if var=="pct_dif_gini_3"
		replace scenario="Direct taxes: PIT & Social Security" 			if var=="pct_dif_gini_5"
		replace scenario="Indirect taxes: General consumption & excise" if var=="pct_dif_gini_6"
	
		
		drop if var=="" 
		
		gen color="red" if  scenario=="Uniform rate, only formal taxed" 	
		replace color ="green" if  scenario=="Food subsidy, formal and informal taxed" 
		replace color ="orange" if scenario=="Food subsidy, only formal taxed"
		replace color ="black" if scenario=="Indirect taxes: General consumption & excise"
		replace color ="black" if scenario=="Direct taxes: PIT & Social Security"
		
		
		gen other_sample= ( var=="pct_dif_gini_5" | var=="pct_dif_gini_6" )
		
		gen order = substr(var,-1, 1) 
		gen new_order=order
		replace new_order="1" if var==""
		replace new_order="3" if order=="1"
		replace new_order="2" if order=="2"
		replace new_order="4" if order=="3"
		replace new_order="7" if order=="5"
		replace new_order="6" if order=="6"
		drop order
		ren new_order order
		export delimited using "$main/tables/gini_$scenario.csv", replace
		}

		
local export_middle_low_csv_v2 = 1
	if `export_middle_low_csv_v2' { 
	
		clear 
		use "$main/tables/gini_middle_${scenario}_dta.dta", clear
		drop in 1/3
		ren v1 var 
		ren v2 Obs
		ren v3 mean 
		ren v4 se
		ren v5 min
		ren v6 max
		destring Obs-max , replace
		gen source="middle"
		tempfile middle
		save `middle'
		
		clear 
		use "$main/tables/gini_low_${scenario}_dta.dta", clear
		drop in 1/3
		ren v1 var 
		ren v2 Obs
		ren v3 mean
		ren v4 se
		ren v5 min
		ren v6 max
		destring Obs-max , replace
		gen source="lower"
		append using `middle'
		
		
		
		// drop all unnecessary variables, OECD as well because all rich countries
		drop if var=="dif_gini_1" | var=="dif_gini_2" | var=="dif_gini_3" | var=="gini_pre" | var=="dif_gini_7" | var=="dif_gini_8"  | var=="pct_dif_gini_7" | var=="pct_dif_gini_8"  | var=="dif_gini_5" | var=="dif_gini_6" 
		drop if var==""
		gen ci_low = mean - 1.96*se
		gen ci_high = mean + 1.96*se
		
		gen scenario="Food subsidy, formal and informal taxed" 		if var=="pct_dif_gini_1"
		replace scenario="Uniform rate, only formal taxed" 			if var=="pct_dif_gini_2"
		replace scenario="Food subsidy, only formal taxed" 			if var=="pct_dif_gini_3"
		replace scenario="Direct taxes: PIT & Social Security" 			if var=="pct_dif_gini_5"
		replace scenario="Indirect taxes: General consumption & excise" if var=="pct_dif_gini_6"
	
		gen sample="This paper N=16" 		if var=="pct_dif_gini_1" & source=="lower"
		replace sample="This paper N=16" 	if var=="pct_dif_gini_2" & source=="lower"
		replace sample="This paper N=16" 	if var=="pct_dif_gini_3" & source=="lower"
		replace sample="CEQ N=6" 			if var=="pct_dif_gini_5" & source=="lower"
		replace sample="CEQ N=6" 			if var=="pct_dif_gini_6" & source=="lower"
		replace sample="This paper N=15" 	if var=="pct_dif_gini_1" & source=="middle"
		replace sample="This paper N=15" 	if var=="pct_dif_gini_2" & source=="middle"
		replace sample="This paper N=15" 	if var=="pct_dif_gini_3" & source=="middle"
		replace sample="CEQ N=19" 			if var=="pct_dif_gini_5" & source=="middle"
		replace sample="CEQ N=19" 			if var=="pct_dif_gini_6" & source=="middle"
	
		

		gen order = 1 if var=="pct_dif_gini_2" & source=="lower"
		replace order = 2 if var=="pct_dif_gini_1" & source=="lower"
		replace order = 3 if var=="pct_dif_gini_3" & source=="lower"
		replace order = 4 if var=="pct_dif_gini_6" & source=="lower"
		replace order = 5 if var=="pct_dif_gini_5" & source=="lower"
		replace order = 6 if var=="pct_dif_gini_2" & source=="middle"
		replace order = 7 if var=="pct_dif_gini_1" & source=="middle"
		replace order = 8 if var=="pct_dif_gini_3" & source=="middle"
		replace order = 9  if var=="pct_dif_gini_6" & source=="middle"
		replace order = 10 if var=="pct_dif_gini_5"   & source=="middle"
		
		gen color="red" if  var=="pct_dif_gini_2" 	
		replace color ="green" if  var=="pct_dif_gini_1" 
		replace color ="orange" if var=="pct_dif_gini_3"
		replace color ="black" if var=="pct_dif_gini_6"
		replace color ="black" if var=="pct_dif_gini_5"
		
		
		sort order
		
		export delimited using "$main/tables/gini_middle_low_inc_$scenario.csv", replace
		}
	
	*We delete unnecessary files
	erase "$main/tables/gini_central_dta.dta"
	erase "$main/tables/gini_low_central_dta.dta"
	erase "$main/tables/gini_middle_central_dta.dta"
		






