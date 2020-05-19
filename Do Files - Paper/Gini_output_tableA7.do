



	*******************	
	* TABLE FOR PAPER *
	*******************

local table_A7 = 1
	if `table_A7' {
	matrix results = J(5,7,.)
	
	use "$main/waste/cross_country/gini_central_baseline.dta", clear 


	sum  pct_dif_gini_2
	matrix results[1,1] = `r(mean)' 
	sum pct_dif_gini_1
	matrix results[2,1] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[3,1] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_central_baseline_vat.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,2] = `r(mean)' 
	sum pct_dif_gini_1
	matrix results[2,2] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[3,2] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_central_baseline_savings.dta", clear 


	sum  pct_dif_gini_2
	matrix results[1,3] = `r(mean)' 
	sum pct_dif_gini_1
	matrix results[2,3] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[3,3] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_proba.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,4] = `r(mean)' 
	sum pct_dif_gini_1
	matrix results[2,4] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[3,4] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_robust.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,5] = `r(mean)' 
	sum pct_dif_gini_1
	matrix results[2,5] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[3,5] = `r(mean)'

	use "$main/waste/cross_country/gini_central_e_c_1.dta", clear 


	sum  pct_dif_gini_2
	matrix results[1,6] = `r(mean)' 
	sum pct_dif_gini_1
	matrix results[2,6] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[3,6] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_central_e_c_2.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,7] = `r(mean)' 
	sum pct_dif_gini_1
	matrix results[2,7] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[3,7] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_central_baseline_coicop12.dta", clear 


	sum pct_dif_gini_A
	matrix results[4,1] = `r(mean)' 
	sum pct_dif_gini_F
	matrix results[5,1] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_central_baseline_vat_coicop12.dta", clear 
	

	sum pct_dif_gini_A
	matrix results[4,2] = `r(mean)' 
	sum pct_dif_gini_F
	matrix results[5,2] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_central_baseline_savings_coicop12.dta", clear 

 
	sum pct_dif_gini_A
	matrix results[4,3] = `r(mean)' 
	sum pct_dif_gini_F
	matrix results[5,3] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_proba_coicop12.dta", clear 
	
 
	sum pct_dif_gini_A
	matrix results[4,4] = `r(mean)' 
	sum pct_dif_gini_F
	matrix results[5,4] = `r(mean)' 
	
	use "$main/waste/cross_country/gini_robust_coicop12.dta", clear 
	
 
	sum pct_dif_gini_A
	matrix results[4,5] = `r(mean)' 
	sum pct_dif_gini_F
	matrix results[5,5] = `r(mean)'
	 
	 
	use "$main/waste/cross_country/gini_central_e_c_1_coicop12.dta", clear 


	sum  pct_dif_gini_A
	matrix results[4,6] = `r(mean)' 
	sum pct_dif_gini_F
	matrix results[5,6] = `r(mean)' 

	
	use "$main/waste/cross_country/gini_central_e_c_2_coicop12.dta", clear 
	
	
	sum pct_dif_gini_A
	matrix results[4,7] = `r(mean)' 
	sum pct_dif_gini_F
	matrix results[5,7] = `r(mean)'
	*/
	mat list results
		
	// Generate an automatic table of results 
	global writeto "$main/tables/cross_country/tableA7.tex"
	cap erase $writeto
	local u using $writeto
	latexify results[1,1...] `u', title("Uniform rate, only formal taxed") format(%4.2f) append
	latexify results[2,1...] `u', title("Food rate differentiation, formal \& informal taxed") format(%4.2f) append
	latexify results[3,1...] `u', title("Food rate differentiation, only formal taxed") format(%4.2f) append	
	latexify results[4,1...] `u', title("Food rate differentiation, formal \& informal taxed (12 goods)") format(%4.2f) append
	latexify results[5,1...] `u', title("Food rate differentiation, only formal taxed (12 goods)") format(%4.2f) append	
	}	
	
