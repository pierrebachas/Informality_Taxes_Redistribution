

					*************************************************************************
					* 	Cross-Country Descriptive stats for Appendix tables	(and table 1)	*
					*************************************************************************
	
	
***************
* DIRECTORIES *
***************
di "`c(username)'"
 if "`c(username)'"=="wb446741" { 											    // Pierre's WB computer 
	global main "C:\Users\wb446741\Dropbox\Regressivity_VAT\Stata"
	}
	else if "`c(username)'"=="pierrebachas" { 									// Pierre's personal laptop
	global main "/Users/pierrebachas/Dropbox/Regressivity_VAT/Stata"
	}	
 else if "`c(username)'"=="elieg" { 											// Elie's laptop
	global main "C:\Users\elieg\Dropbox\Regressivity_VAT\Stata"
	}
 else if "`c(username)'"=="wb520324" { 											// Eva's WB computer 
	global main "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata"
	}
	
	else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}	

	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"
		
	
******************	
* DATA PREPARATON*
******************
	

*********************************************	
* Preliminaries
*********************************************	
		
	set more off
	*set matsize 10000	
************************************************************************	
* 0. Load Dataset 
************************************************************************	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	*keep if country_code == "CM" 		// To run on one country select its acronym  
	*drop if country_code == "MA" // | country_code == "BI"
	
	* NOTE: everything Excel cell has to be only one word
	
	qui valuesof country_code
	local country_code = r(values)
	display `"`country_code'"'
	qui valuesof country_fullname
	local country_fullname = r(values)
	display `"`country_fullname'"'
 	qui valuesof product_code
	local product_code = r(values)	
* 	qui valuesof annualization_factor
*	local annualization_factor = r(values)	


	local n_models : word count `country_code'
	assert `n_models'==`:word count `country_fullname''  // this ensures that the two lists are of the same length
 	assert `n_models'==`:word count `product_code''

	forval c=1/`n_models' {
	
		***************
		* GLOBALS	 *
		***************	
	local line = `c'+1
	global country_code `: word `c' of `country_code''		
	global country_fullname `: word `c' of `country_fullname''	
	global year `: word `c' of `year''
	global product_code `: word `c' of `product_code''	
*	global annualization_factor `: word `c' of `annualization_factor''	
	global year = substr("$country_fullname",-4,4)	
	global country_name = substr("$country_fullname",1,strlen("$country_fullname")-4)	
	
		******************************************
		* RETRIEVE GDP PER CAPITA FROM EXCEL 	 *
		******************************************
		
		display "*************** Country: $country_fullname **************************" 	
		display "*************** Country: $country_name **************************" 	

		import excel using "$main/data/Country_information.xlsx" , clear firstrow
		qui keep if CountryCode == "$country_code"	& Year == $year

		global GDP_pc_constantUS2010 = GDP_pc_constantUS2010[1] 	
		local GDP_pc_constantUS2010_disp : di %11.0f $GDP_pc_constantUS2010
		global conversion_rate = GDP_pc_currentLCU[1]/PPP_current[1]	
		display "Conversion rate = $conversion_rate"	
		global exchange_rate = GDP_pc_currentLCU[1]/GDP_pc_currentUS[1]	
		display "Exchange rate = $exchange_rate"
		tempfile country_info
		save `country_info'
		
		use "$main/proc/$country_fullname/${country_code}_household_cov.dta", replace
		unique hhid
		local nb_households = r(unique)
		
		gen exp_noh_pc = exp_noh / hh_size
		sum exp_noh_pc [aweight = hh_weight], d
		local mean_exp = r(mean)
		local mean_exp_disp : di %9.1f `mean_exp'
		local mean_exp_dollar = `mean_exp'  / $exchange_rate
		local mean_exp_dollar_disp : di %9.0f `mean_exp_dollar'
	
		
		sum urban [aweight = hh_weight], d
		local proption_urban = r(mean)
		local pct_urban = `proption_urban' * 100
		local proption_urban_disp : di %9.1f `pct_urban'
		
		sum hh_size [aweight = hh_weight], d
		local mean_hh_size = r(mean)
		local mean_hh_size_disp : di %9.1f `mean_hh_size'
		
	** Population by census block
		gen pop = hh_weight*hh_size
		bys census_block: egen popdensity_cb_new = sum(pop)
		sum popdensity_cb 
		local mean_pop_census_block = r(mean)
		
	** HH by census block 
		 bys census_block: gen hh_cb = _N
		 sum hh_cb
		 local mean_hh_cb= r(mean)
		
		tempfile hh_cov
		save `hh_cov'
		
		use "$main/proc/$country_fullname/${country_code}_exp_full_db.dta", replace
	

		* Add number of purchases by households
		drop if agg_value_on_period==0
		count
		local nb_lines = r(N) 
		local item_per_hh = `nb_lines' /  `nb_households'
		local item_per_hh_disp : di %3.0f `item_per_hh'
		
		display `item_per_hh'
		
		tempfile exp_full_db
		save `exp_full_db' 
		
*********************************************	
* 1. Tables
*********************************************
putexcel set "$main/tables/stat_des_appendix.xls", sheet("Table B1 appendix") modify
sleep 500

	putexcel A1 = "Country name"
	sleep 500
	putexcel B1 = "Survey"
	sleep 500
	putexcel C1 = "Year"
	sleep 500
	putexcel D1 = "Source"
	sleep 500
	putexcel E1 = "Sample size"
	sleep 500
	putexcel F1 = "Nb items/HH"
	sleep 500
	putexcel G1 = "Avg Exp/HH"
	sleep 500
	putexcel H1 = "Urban"
	sleep 500
	putexcel I1 = "Avg HH Size"
	sleep 500
	putexcel J1 = "# TOR"
	sleep 500
	putexcel K1 = "# Modules"
	sleep 500
	putexcel L1 = "Product Code"
	sleep 500
	putexcel M1 = "Comments"
	sleep 500
	putexcel N1 = "# HH/Census Block"
	sleep 500
	putexcel O1 = "Pop/Census Block"
	sleep 500
	
	putexcel A`line' = "$country_name"
	sleep 500
	putexcel C`line' = "$year"	
	sleep 500
	use `hh_cov' , clear
	putexcel E`line' = `nb_households'
	sleep 500
	use `exp_full_db' , clear
	putexcel F`line' = `item_per_hh_disp'
	sleep 500
	use `hh_cov' , clear
	putexcel G`line' = `mean_exp_dollar_disp'
	sleep 500
	putexcel H`line' = "`proption_urban_disp'%"
	sleep 500	
	putexcel I`line' = `mean_hh_size_disp'
	sleep 500
	putexcel N`line' = `mean_hh_cb'
	sleep 500
	putexcel N`line' = `mean_pop_census_block'
	sleep 500

putexcel set "$main/tables/stat_des_appendix.xls", sheet("Table 1 paper") modify
	sleep 1000
	putexcel A1 = "Country"
	sleep 500
	putexcel B1 = "Code"
	sleep 500
	putexcel C1 = "Survey"
	sleep 500
	putexcel D1 = "Year"
	sleep 500
	putexcel E1 = "GDP per capita"
	sleep 500
	putexcel F1 = "Sample size"
	sleep 500
	putexcel G1 = "Nb items/HH"
	sleep 500
	
	
	* From earlier computations
	putexcel A`line' = "$country_name"
	sleep 500
	putexcel B`line' = "$country_code"
	sleep 500	
	putexcel D`line' = "$year"	
	sleep 500
	use `country_info' , clear
	putexcel E`line' = `GDP_pc_constantUS2010_disp'
	sleep 500
	use `hh_cov' , clear
	putexcel F`line' = `nb_households'
	sleep 500
	use `exp_full_db' , clear
	putexcel G`line' = `item_per_hh_disp'
	sleep 500
}
**************************************************	
* 2. Summary statistics	
************************************************** 

*Total# of HH
import excel using "$main/tables/stat_des_appendix.xls", clear sheet("Table B1 appendix") firstrow
egen total_hh= sum(Sample size) 

*Average # of hh per survey block
import excel using "$main/tables/stat_des_appendix.xls", clear sheet("Table B1 appendix") firstrow
egen mean_hh_cb= mean("# HH/Census Block")

*Average # of people per survey block
import excel using "$main/tables/stat_des_appendix.xls", clear sheet("Table B1 appendix") firstrow
egen mean_popdensity_cb= mean(Pop/Census Block) 
		

}
*********************************************	
// 1. Loop Over Countries with COICOP 
*********************************************	
global sleep_time 500

*******************************
**** SELECT COUNTRY
*******************************
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
	*keep if country_code == "BR" 		// To run on one country select its acronym  
	*drop if country_code == "MA" // | country_code == "BI"
	
	* NOTE: everything Excel cell has to be only one word
	
	qui valuesof country_code
	local country_code = r(values)
	display `"`country_code'"'
	qui valuesof country_fullname
	local country_fullname = r(values)
	display `"`country_fullname'"'
 	qui valuesof product_code
	local product_code = r(values)	
* 	qui valuesof annualization_factor
*	local annualization_factor = r(values)	


	local n_models : word count `country_code'
	assert `n_models'==`:word count `country_fullname''  // this ensures that the two lists are of the same length
 	assert `n_models'==`:word count `product_code''

	forval c=1/`n_models' {
	
		***************
		* GLOBALS	 *
		***************	
	local line = `c'+1
	global country_code `: word `c' of `country_code''		
	global country_fullname `: word `c' of `country_fullname''	
	global year `: word `c' of `year''
	global product_code `: word `c' of `product_code''	
*	global annualization_factor `: word `c' of `annualization_factor''	
	global year = substr("$country_fullname",-4,4)	
	global country_name = substr("$country_fullname",1,strlen("$country_fullname")-4)	
	
		******************************************
		* RETRIEVE GDP PER CAPITA FROM EXCEL 	 *
		******************************************
		
		display "*************** Country: $country_fullname **************************" 	
		display "*************** Country: $country_name **************************" 	

		import excel using "$main/data/Country_information.xlsx" , clear firstrow
		qui keep if CountryCode == "$country_code"	& Year == $year
	
		global GDP_pc_constantUS2010 = GDP_pc_constantUS2010[1] 	
		local GDP_pc_constantUS2010_disp : di %11.0f $GDP_pc_constantUS2010
		global conversion_rate = GDP_pc_currentLCU[1]/PPP_current[1]	
		display "Conversion rate = $conversion_rate"	
		global exchange_rate = GDP_pc_currentLCU[1]/GDP_pc_currentUS[1]	
		display "Exchange rate = $exchange_rate"
		


putexcel set "$main/tables/stat_des_appendix.xls", sheet("Table B1 appendix") modify
sleep 500

	putexcel A1 = "Country name"
	sleep 500
	putexcel B1 = "Survey"
	sleep 500
	putexcel C1 = "Year"
sleep 500
	putexcel D1 = "Source"
	sleep 500
	putexcel E1 = "Sample size"
	sleep 500
	putexcel F1 = "Nb items/HH"
	sleep 500
	putexcel G1 = "Avg Exp/HH"
	sleep 500
	putexcel H1 = "Urban"
sleep 500
	putexcel I1 = "Avg HH Size"
sleep 500
	putexcel J1 = "# TOR"
sleep 500
	putexcel K1 = "# Modules"
sleep 500
	putexcel L1 = "Product Code"
sleep 500
	putexcel M1 = "Comments"
	
*	putexcel K1 = "Avg. Exp/HH PPP"
	sleep 500
	putexcel A`line' = "$country_name"
	sleep 500
	putexcel C`line' = "$year"	
	sleep 500

	putexcel F`line' = `GDP_pc_constantUS2010_disp'
	sleep 500
		use "$main/proc/$country_fullname/${country_code}_household_cov.dta", replace
	
		unique hhid
		local nb_households = r(unique)
	putexcel E`line' = `nb_households'
	sleep 500
	
*		if "$country_code" == "NE" {
*			replace exp_noh = exp_survey_provided
*		}
		gen exp_noh_pc = exp_noh / hh_size
		sum exp_noh_pc [aweight = hh_weight], d
		local mean_exp = r(mean)
		local mean_exp_disp : di %9.1f `mean_exp'
*		putexcel F`line' = `mean_exp_disp'
	count

		sleep 500
		* With conversion to dollar but no PPP to be consistent with GDP figures
	*	local mean_exp_dollar = `mean_exp' * $annualization_factor / $exchange_rate
		local mean_exp_dollar = `mean_exp'  / $exchange_rate

		local mean_exp_dollar_disp : di %9.0f `mean_exp_dollar'
	putexcel G`line' = `mean_exp_dollar_disp'
sleep 500
sum urban [aweight = hh_weight], d
		local proption_urban = r(mean)
		local pct_urban = `proption_urban' * 100
		local proption_urban_disp : di %9.1f `pct_urban'
	putexcel H`line' = "`proption_urban_disp'%"
sleep 500	

sum hh_size [aweight = hh_weight], d
		local mean_hh_size = r(mean)
		local mean_hh_size_disp : di %9.1f `mean_hh_size'
		putexcel I`line' = `mean_hh_size_disp'
sleep 500	
		* With PPP : compute and export to Excel but we do not put it in the appendix immediately
*		local mean_exp_ppp = `mean_exp' * $annualization_factor / $conversion_rate
	local mean_exp_ppp = `mean_exp' / $conversion_rate

		local mean_exp_ppp_disp : di %9.2f `mean_exp_ppp'
*	putexcel G`line' = `mean_exp_ppp_disp'
sleep 500	
		


putexcel set "$main/tables/stat_des_appendix.xls", sheet("Table 1 paper") modify
sleep 1000
	putexcel A1 = "Country"
	sleep 500
	putexcel B1 = "Code"
	sleep 500
	putexcel C1 = "Survey"
	sleep 500
	putexcel D1 = "Year"
	sleep 500
	putexcel E1 = "GDP per capita"
sleep 500
	putexcel F1 = "Sample size"
	sleep 500
	putexcel G1 = "Nb items/HH"
sleep 500

use "$main/proc/$country_fullname/${country_code}_exp_full_db.dta", replace
	

	
	* From earlier computations
	putexcel A`line' = "$country_name"
	sleep 500
	putexcel B`line' = "$country_code"
sleep 500	
	putexcel D`line' = "$year"	
	sleep 500
	putexcel E`line' = `GDP_pc_constantUS2010_disp'
	sleep 500
	putexcel F`line' = `nb_households'
sleep 500
	* Add number of purchases by households
		count
		local nb_lines = r(N)
		local item_per_hh = `nb_lines' /  `nb_households'
		local item_per_hh_disp : di %3.1f `item_per_hh'
	putexcel G`line' = `item_per_hh_disp'
sleep 500
	* the same figure is also needed in the other table


putexcel set "$main/tables/stat_des_appendix.xls", sheet("Table B1 appendix") modify
sleep 500
putexcel F`line' = `item_per_hh_disp'
sleep 500
	
}	
sleep 500
putexcel set "$main/tables/stat_des_appendix.xls", sheet("Table 1 paper") modify
putexcel C2 = "EMICOV"
sleep 500
putexcel C3	 ="ECH"
putexcel C4	 ="POF"
putexcel C5	 ="EICVM"
putexcel C6	 ="ECVM"
putexcel C7	 ="ECAM"
putexcel C8	 ="ECOSIT"
putexcel C9	 ="EPF"
putexcel C10 ="ENIG"
putexcel C11 ="EDMC"
putexcel C12 ="E123"
sleep 500
putexcel C13 ="ECOM"
putexcel C14 ="ENIGH"
putexcel C15 ="ENIGH"
putexcel C16 ="ENIGHUR"
putexcel C17 ="HIES"
putexcel C18 ="ENIGH"
putexcel C19 ="HBS"
putexcel C20 ="ENCDM"
putexcel C21 ="IOF"
putexcel C22 ="ENCBM"
putexcel C23 ="HIES"
putexcel C24 ="ENAHO"
putexcel C25 ="EICV"
sleep 500
putexcel C26 ="IOF"
putexcel C27 ="EDMC"
putexcel C28 ="HBS"
putexcel C29 ="IES"
putexcel C30 ="HBS"
putexcel C31 ="ENBCNV"
putexcel C32 ="ENIGH"


putexcel set "$main/tables/stat_des_appendix.xls", sheet("Table B1 appendix") modify
putexcel B2 = "EMICOV"
sleep 500
putexcel B3	 ="ECH"
putexcel B4	 ="POF"
putexcel B5	 ="EICVM"
putexcel B6	 ="ECVM"
putexcel B7	 ="ECAM"
putexcel B8	 ="ECOSIT"
putexcel B9	 ="EPF"
putexcel B10 ="ENIG"
putexcel B11 ="EDMC"
putexcel B12 ="E123"
putexcel B13 ="ECOM"
sleep 500
putexcel B14 ="ENIGH"
putexcel B15 ="ENIGH"
putexcel B16 ="ENIGHUR"
putexcel B17 ="HIES"
putexcel B18 ="ENIGH"
putexcel B19 ="HBS"
putexcel B20 ="ENCDM"
putexcel B21 ="IOF"
sleep 500
putexcel B22 ="ENCBM"
putexcel B23 ="HIES"
putexcel B24 ="ENAHO"
putexcel B25 ="EICV"
putexcel B26 ="IOF"
putexcel B27 ="EDMC"
putexcel B28 ="HBS"
putexcel B29 ="IES"
putexcel B30 ="HBS"
putexcel B31 ="ENBCNV"
putexcel B32 ="ENIGH"

putexcel D2 = "World Bank"
putexcel D3	 ="Stat. Office"
putexcel D4	 ="Stat. Office"
putexcel D5	 ="Stat. Office"
putexcel D6	 ="World Bank"
putexcel D7	 ="World Bank"
putexcel D8	 ="World Bank"
sleep 500
putexcel D9	 ="Stat. Office"
putexcel D10 ="Stat. Office"
putexcel D11 ="Stat. Office"
putexcel D12 ="World Bank"
putexcel D13 ="World Bank"
putexcel D14 ="Stat. Office"
putexcel D15 ="Stat. Office"
putexcel D16 ="World Bank"
putexcel D17 ="World Bank"
putexcel D18 ="Stat. Office"
putexcel D19 ="World Bank"
putexcel D20 ="World Bank"
putexcel D21 ="World Bank"
sleep 500
putexcel D22 ="World Bank"
putexcel D23 ="World Bank"
putexcel D24 ="Stat. Office"
putexcel D25 ="World Bank"
putexcel D26 ="World Bank"
putexcel D27 ="World Bank"
putexcel D28 ="World Bank"
putexcel D29 ="U. of Cape Town"
sleep 500
putexcel D30 ="World Bank"
putexcel D31 ="Stat. Office"
putexcel D32 ="Stat. Office"

putexcel J2 = "12"
putexcel J3	 ="24"
putexcel J4	 ="33"
putexcel J5	 ="45"
putexcel J6	 ="13"
putexcel J7	 ="17"
putexcel J8	 ="17"
putexcel J9	 ="22"
putexcel J10 ="24"
putexcel J11 ="12"
sleep 500
putexcel J12 ="13"
putexcel J13 ="17"
putexcel J14 ="41"
putexcel J15 ="88"
putexcel J16 ="75"
putexcel J17 ="13"
putexcel J18 ="19"
putexcel J19 ="7"
putexcel J20 ="47"
putexcel J21 ="6"
putexcel J22 ="15"
putexcel J23 ="6"
putexcel J24 ="41"
putexcel J25 ="11"
putexcel J26 ="21"
putexcel J27 ="41"
putexcel J28 ="9"
putexcel J29 ="6"
sleep 500
putexcel J30 ="13"
putexcel J31 ="9"
putexcel J32 ="39"

putexcel K2 = "22"
putexcel K3	 ="3"
putexcel K4	 ="8"
putexcel K5	 ="1"
putexcel K6	 ="23"
putexcel K7	 ="1"
putexcel K8	 ="18"
putexcel K9	 ="1"
putexcel K10 ="5"
putexcel K11 ="19"
putexcel K12 ="1"
putexcel K13 ="1"
putexcel K14 ="1"
sleep 500
putexcel K15 ="3"
putexcel K16 ="7"
putexcel K17 ="2"
putexcel K18 ="1"
putexcel K19 ="3"
putexcel K20 ="17"
putexcel K21 ="6"
putexcel K22 ="6"
putexcel K23 ="1"
putexcel K24 ="8"
putexcel K25 ="8"
putexcel K26 ="3"
putexcel K27 ="1"
putexcel K28 ="2"
sleep 500
putexcel K29 ="1"
putexcel K30 ="2"
putexcel K31 ="1"
putexcel K32 ="1"

putexcel L2 = "COICOP"
putexcel L3	 ="COICOP"
putexcel L4	 ="Country-specific"
putexcel L5	 ="COICOP"
putexcel L6	 ="COICOP"
putexcel L7	 ="COICOP"
putexcel L8	 ="Country-specific"
putexcel L9	 ="COICOP"
putexcel L10 ="COICOP"
putexcel L11 ="COICOP"
putexcel L12 ="COICOP"
putexcel L13 ="COICOP"
sleep 500
putexcel L14 ="COICOP"
putexcel L15 ="COICOP"
putexcel L16 ="COICOP"
putexcel L17 ="COICOP"
putexcel L18 ="COICOP"
putexcel L19 ="COICOP"
putexcel L20 ="COICOP"
putexcel L21 ="COICOP"
putexcel L22 ="COICOP"
putexcel L23 ="COICOP"
putexcel L24 ="Country-specific"
putexcel L25 ="COICOP"
putexcel L26 ="COICOP"
putexcel L27 ="COICOP"
putexcel L28 ="COICOP"
putexcel L29 ="COICOP"
putexcel L30 ="COICOP"
putexcel L31 ="COICOP"
putexcel L32 ="COICOP"
sleep 500

putexcel M2 = " "
putexcel M3	 =" "
putexcel M4	 =" "
putexcel M5	 =" "
putexcel M6	 =" "
putexcel M7	 =" "
putexcel M8	 =" "
putexcel M9	 ="No self-production; Only urban"
putexcel M10 =" "
putexcel M11 =" "
sleep 500
putexcel M12 =" "
putexcel M13 =" "
putexcel M14 =" "
putexcel M15 =" "
putexcel M16 =" "
putexcel M17 =" "
putexcel M18 =" "
putexcel M19 ="Imputed TOR"
putexcel M20 =" "
putexcel M21 =" "
putexcel M22 ="Imputed TOR"
putexcel M23 =" "
putexcel M24 =" "
putexcel M25 ="Pre-filled diary"
sleep 500
putexcel M26 =" "
putexcel M27 ="Only urban"
putexcel M28 =" "
putexcel M29 =""
putexcel M30 ="Imputed TOR"
putexcel M31 =" "
putexcel M32 =" "



		
		
