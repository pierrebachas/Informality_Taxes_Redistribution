



	*******************	
	* TABLE FOR PAPER *
	*******************

local table_A7 = 1
	if `table_A7' {
	matrix results = J(5,6,.)
	matrix results_ratio = J(5,6,.)
	
	use "$main/waste/cross_country/gini_central_baseline_newdata.dta", clear 


	sum  pct_dif_gini_2
	matrix results[1,1] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[2,1] = `r(mean)' 
	
	sum  pct_dif_gini_2 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[1,1] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[2,1] = `r(mean)' 
	drop ratio 
	
	use "$main/waste/cross_country/gini_central_e_c_1_baseline_newdata.dta", clear 


	sum  pct_dif_gini_2
	matrix results[1,2] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[2,2] = `r(mean)' 
	
	sum  pct_dif_gini_2 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[1,2] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[2,2] = `r(mean)'
	drop ratio 
	
	use "$main/waste/cross_country/gini_central_e_c_2_baseline_newdata.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,3] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[2,3] = `r(mean)' 
	
	sum  pct_dif_gini_2 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[1,3] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[2,3] = `r(mean)'
	drop ratio 
	
	
	use "$main/waste/cross_country/gini_specific_baseline_newdata.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,4] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[2,4] = `r(mean)'

	sum  pct_dif_gini_2 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[1,4] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[2,4] = `r(mean)'
	drop ratio 
	
	
	
	use "$main/waste/cross_country/gini_central_baseline_vat_newdata.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,5] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[2,5] = `r(mean)' 
	
	sum  pct_dif_gini_2 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[1,5] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[2,5] = `r(mean)'
	drop ratio 

	use "$main/waste/cross_country/gini_central_baseline_savings_newdata.dta", clear 


	sum  pct_dif_gini_2
	matrix results[1,6] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[2,6] = `r(mean)' 
	
	sum  pct_dif_gini_2 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[1,6] = `r(mean)' 
	drop ratio 

	sum  pct_dif_gini_3 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[2,6] = `r(mean)'
	drop ratio 
	
	/*use "$main/waste/cross_country/gini_proba_baseline_newdata.dta", clear 
	
	sum  pct_dif_gini_2
	matrix results[1,4] = `r(mean)' 
	sum pct_dif_gini_3
	matrix results[2,4] = `r(mean)' 
	
	sum  pct_dif_gini_2 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[1,4] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3 if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3 if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[2,4] = `r(mean)'
	drop ratio 
	*/
	
	use "$main/waste/cross_country/gini_central_baseline_coicop12.dta", clear 


 
	sum pct_dif_gini_F
	matrix results[3,1] = `r(mean)' 
	
	sum  pct_dif_gini_F if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_F if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[3,1] = `r(mean)' 
	drop ratio 
	
	use "$main/waste/cross_country/gini_central_e_c_1_coicop12.dta", clear 



	sum pct_dif_gini_F
	matrix results[3,2] = `r(mean)' 
	
	sum  pct_dif_gini_F if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_F if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[3,2] = `r(mean)' 
	drop ratio 

	
	use "$main/waste/cross_country/gini_central_e_c_2_coicop12.dta", clear 
	
	

	sum pct_dif_gini_F
	matrix results[3,3] = `r(mean)'
	
	sum  pct_dif_gini_F if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_F if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[3,3] = `r(mean)' 
	drop ratio 
	
	use "$main/waste/cross_country/gini_specific_coicop12.dta", clear 
	
 

	sum pct_dif_gini_F
	matrix results[3,4] = `r(mean)'
	
	sum  pct_dif_gini_F if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_F if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[3,4] = `r(mean)' 
	drop ratio 
	 
	
	use "$main/waste/cross_country/gini_central_baseline_vat_coicop12.dta", clear 
	


	sum pct_dif_gini_F
	matrix results[3,5] = `r(mean)' 
	
	sum  pct_dif_gini_F if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_F if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[3,5] = `r(mean)' 
	drop ratio 
	
	use "$main/waste/cross_country/gini_central_baseline_savings_coicop12.dta", clear 

 

	sum pct_dif_gini_F
	matrix results[3,6] = `r(mean)' 
	
	sum  pct_dif_gini_F if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_F if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[3,6] = `r(mean)' 
	drop ratio 
	
	
	/*use "$main/waste/cross_country/gini_proba_coicop12.dta", clear 
	
 

	sum pct_dif_gini_F
	matrix results[3,4] = `r(mean)' 
	
	sum  pct_dif_gini_F if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_F if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[3,4] = `r(mean)' 
	drop ratio 
	*/
	
	 
	
	use "$main/waste/cross_country/gini_central_baseline_pit.dta", clear 
	
	sum pct_dif_gini_2_cons_only
	matrix results[4,1] = `r(mean)'
	sum pct_dif_gini_3_cons_only
	matrix results[5,1] = `r(mean)'
	
	sum  pct_dif_gini_2_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[4,1] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[5,1] = `r(mean)'
	drop ratio 
	
	use "$main/waste/cross_country/gini_central_e_c_1_pit.dta", clear 

	sum pct_dif_gini_2_cons_only
	matrix results[4,2] = `r(mean)'
	sum pct_dif_gini_3_cons_only
	matrix results[5,2] = `r(mean)' 
	
	sum  pct_dif_gini_2_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[4,2] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[5,2] = `r(mean)'
	drop ratio 
	
	use "$main/waste/cross_country/gini_central_e_c_2_pit.dta", clear 
	
	sum pct_dif_gini_2_cons_only
	matrix results[4,3] = `r(mean)'
	sum pct_dif_gini_3_cons_only
	matrix results[5,3] = `r(mean)'
	
	sum  pct_dif_gini_2_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[4,3] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[5,3] = `r(mean)'
	drop ratio 
	
		use "$main/waste/cross_country/gini_specific_baseline_pit.dta", clear 
	
	sum pct_dif_gini_2_cons_only
	matrix results[4,4] = `r(mean)'
	sum pct_dif_gini_3_cons_only
	matrix results[5,4] = `r(mean)'
	
	sum  pct_dif_gini_2_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[4,4] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[5,4] = `r(mean)'
	drop ratio 
	
	
	
	use "$main/waste/cross_country/gini_central_baseline_vat_pit.dta", clear 
	
	sum pct_dif_gini_2_cons_only
	matrix results[4,5] = `r(mean)'
	sum pct_dif_gini_3_cons_only
	matrix results[5,5] = `r(mean)'
	
	sum  pct_dif_gini_2_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[4,5] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[5,5] = `r(mean)'
	drop ratio 
	
	use "$main/waste/cross_country/gini_central_baseline_savings_pit.dta", clear 

	sum pct_dif_gini_2_cons_only
	matrix results[4,6] = `r(mean)'
	sum pct_dif_gini_3_cons_only
	matrix results[5,6] = `r(mean)' 
	
	sum  pct_dif_gini_2_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[4,6] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[5,6] = `r(mean)'
	drop ratio 
	
	/*use "$main/waste/cross_country/gini_proba_baseline_pit.dta", clear 
	
	sum pct_dif_gini_2_cons_only
	matrix results[4,4] = `r(mean)'
	sum pct_dif_gini_3_cons_only
	matrix results[5,4] = `r(mean)'
	
	sum  pct_dif_gini_2_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_2_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[4,4] = `r(mean)' 
	drop ratio 
	
	sum  pct_dif_gini_3_cons_only if ln_GDP>7.65
	local middle =`r(mean)' 
	sum  pct_dif_gini_3_cons_only if ln_GDP<7.65
	local low =`r(mean)' 
	gen ratio =`middle'/`low'
	sum ratio
	matrix results_ratio[5,4] = `r(mean)'
	drop ratio 
	*/
	

	
	
	mat list results
		
	// Generate an automatic table of results 
	global writeto "$main/tables/cross_country/tableA7_new_country_saving_rate.tex"
	cap erase $writeto
	local u using $writeto
	latexify results[1,1...] `u', title("Uniform rate") format(%4.2f) append
	latexify results[2,1...] `u', title("Food rate differentiation") format(%4.2f) append	
	latexify results[3,1...] `u', title("Full rate differentiation (12 goods)") format(%4.2f) append	
	latexify results[4,1...] `u', title("Uniform rate with PIT") format(%4.2f) append	
	latexify results[5,1...] `u', title("Food rate differentiation with PIT") format(%4.2f) append	
	
	mat list results_ratio
		
	// Generate an automatic table of results 
	global writeto "$main/tables/cross_country/tableA7_panelb_new_country_saving_rate.tex"
	cap erase $writeto
	local u using $writeto
	latexify results_ratio[1,1...] `u', title("Uniform rate") format(%4.2f) append
	latexify results_ratio[2,1...] `u', title("Food rate differentiation") format(%4.2f) append	
	latexify results_ratio[3,1...] `u', title("Full rate differentiation (12 goods)") format(%4.2f) append	
	latexify results_ratio[4,1...] `u', title("Uniform rate with PIT") format(%4.2f) append	
	latexify results_ratio[5,1...] `u', title("Food rate differentiation with PIT") format(%4.2f) append	
	}	
	
