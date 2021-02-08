					*************************************
					* 		CROSS COUNTRY GRAPHS + 		*
					*************************************
					
									
*********************************************	
* Preliminaries
*********************************************	
	
	cap log close
	clear all
	set more off
	
	qui include "$main/dofiles/server_header.doh" 		// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"	

	// uses written ado file "latexify" 
	
	global scenario "central"    // central , proba , robust: see definition in Master.do

************************************************************************	
* 0. Load Dataset 
************************************************************************	
	
	
	
	* Load Data of regression Output 
	use "$main/proc/regressions_output_price_$scenario.dta", replace 
	
	* Identify the different regressions
	bys country_fullname : gen id_reg= _n
	
	
************************************************************************	
* 1. Basic Data Prep 
************************************************************************	

	
	** Generate p-values and confidence intervals
	** Note for a one sided hypothesis can divide by 2 the current p-value 
	** p-value probability that null hypothesis beta = 0 is true 
	local df_r = 1000000	
	gen p_value_2s = (2 * ttail(`df_r', abs(b/se))) / 2
	
	** Note: we want to test the one-sided hypothesis: H0 beta = 0 vs Ha beta < 0 
	gen p_value_1s = p_value_2s / 2 if b >0
	replace p_value_1s = 1 - p_value_2s/2 if b < 0 
	drop p_value_2s
	
	gen ci_low = b - 1.96*se
	gen ci_high = b + 1.96*se

	**************************************************************************	
	* Reshape the data for the iterations: this will give b`x' and se`x' 
	**************************************************************************
	
	{
	reshape wide b se p_value_1s ci_low ci_high , i(country_fullname nb_purchases nb_geo_clusters nb_product_code nb_fixed_effects) j(id_reg)
		
	
	* Assign Variable labels, which explain what each b is
	
	label var b1 "No Unspecified, no self-consumption"
	label var b2 "Winsorized, no self-consumption"	
	label var b3 "No Unspecified"
	label var b4 "Winsorized"
		
	
	
	}	
		
**************************************************	
* 2. Summary statistics and slope coefficients	
************************************************** 
	*Table A5 in the paper(Appendix), coef by country 
	
	sort country_fullname
	gen id_country=_n
	
	sum id_country 
	matrix results = J(`r(max)'*2+4,6,.)	
	
	forvalues i = 1(1)`r(max)'  {
		forvalues j = 1(1)4 {
		
		local k = 2*`i'-1
		local l = 2*`i'	
		
	    sum b`j' if id_country==`i' 	
	    matrix results[`k',`j'] = `r(mean)'
	
	    sum se`j' if id_country==`i' 	
	    matrix results[`l',`j'] = `r(mean)'
	    }
		*Informations
		forvalues j = 5(1)8 {

		local k = 2*`i'-1
		sum nb_purchases if id_country==`i' 
		matrix results[`k',5] = `r(mean)' 
		*sum nb_geo_clusters if id_country==`i' 
		*matrix results[`k',6] = `r(mean)' 
		*sum nb_product_code if id_country==`i' 
		*matrix results[`k',7] = `r(mean)'
		sum nb_fixed_effects if id_country==`i' 
		matrix results[`k',6] = `r(mean)'
		}
	}
	

	

		
	mat list results
	
// Generate an automatic table of results 
		global writeto "$main/tables/cross_country/table3_$scenario.tex"
		cap erase $writeto
		local u using $writeto
		local o extracols(1)
		local t1 "Benin"
		local t2 "Bolivia"
		local t3 "Brazil"
		local t4 "Burundi"
		local t5 "Chad"
		local t6 "Colombia"
		local t7 "Comoros"
		local t8 "CongoDRC"
		local t9 "Congo Rep"
		local t10 "Costa Rica"
		local t11 "Dominican Rep"
		local t12 "Ecuador"
		local t13 "Eswatini"
		local t14 "Mexico"
		local t15 "Montenegro"
		local t16 "Morocco"
		local t17 "Peru"
		local t18 "Sao Tome"
		local t19 "Serbia"
		local t20 "Tanzania"
		local cc=1
		local tt=1
		sum id_country 
		forvalues i = 1(1)`r(max)'  {
		local k = 2*`i'-1
		local l = 2*`i'	
		latexify results[`k',1...] `u', title("{`t`tt''}") format(%4.2f %4.2f %4.2f %4.2f  %7.0f %4.0f) append
		latexify results[`l',1...] `u', brackets("()") `o' format(%4.2f) append
		local ++tt
	}
	
		*All Countries (Mean)

	forvalues j = 1(1)4 {
		sum b`j' 
		matrix results[1,`j'] = `r(mean)'  
		sum ci_low`j'
		matrix results[2,`j'] = `r(mean)' 
		sum ci_high`j'
		matrix results[3,`j'] = `r(mean)' 	
		count if p_value_1s`j' <= 0.05 				// Count how many rejected one-sided t-tests
		matrix results[4,`j'] = `r(N)'

	}
		global writeto "$main/tables/cross_country/table3_mean_$scenario.tex"
		cap erase $writeto
		local u using $writeto
		local o extracols(1)
		local t1 "Avg. of 20 Countries"
		latexify results[41,1...] `u', format(%4.2f %4.2f %4.2f %4.2f  %7.0f %4.0f) append
		latexify results[42,1...] `u', brackets("[]") `o'  format(%4.1f) append
		latexify results[43,1...] `u',  format(%4.1f) append
		latexify results[5,1...] `u', format(%4.0f) append			
		
