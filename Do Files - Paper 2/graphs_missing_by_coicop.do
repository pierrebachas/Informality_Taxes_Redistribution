					*************************************
					* 		Missing/Unspecified			*
					*			by COICOP				*
					* 	  		 Graphs					*
					*************************************


	
******************	
* GRAPHS*
******************

global format eps // change to pdf for better resolution 
	******************	
	* GRAPH ONE
	******************
	
	
	use "$main/proc/missing_COICOP12_central.dta", clear 
	
	preserve
	
	collapse total_exp mean_exp total_exp_COICOP mean_exp_COICOP total_exp_missing mean_exp_missing , by(COICOP2)
	gen share_missing_over_total = (total_exp_missing/total_exp)*100
	egen sum_unspecified= sum(share_missing_over_total) // 13,6%
	ta sum_unspecified

	
	gen share_missing_over_total_coicop = (total_exp_missing/total_exp_COICOP)*100


	label define coicop_lab 1 "Food" 2 "Alcohol"3 "Clothes" 4 "Utilities & Fuels" 5 "Furnishing & Equipment" 6 "Health" 7 "Transport" 8 "Communication" 9 "Culture" 10 "Education" 11 "Restaurants" 12 "Misc. Goods"
	label values COICOP2 coicop_lab
	
	local size medsmall
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local yaxis "ylabel(0(1)5, labsize(`size') nogrid) yscale(range(0 5)) yline(1, lcolor(black) lw(medthick)) yline(0(1)7, lstyle(minor_grid) lcolor(gs1))" 

				
	*Graph A 
	#delim ; 
	graph bar (mean) share_missing_over_total, over(COICOP2, label(angle(45)  labsize(medsmall))) 
	graphregion(color(white)) bgcolor(white) plotregion(color(white))	
	ylabel(0(1)5, nogrid labsize(`size'))
	bar(1, color(navy))
	yscale(range(0 5)) 
	yline(0(1)5, lstyle(minor_grid) lcolor(gs1)) 		
	ytitle(" ", size (small)) ;
	graph export "$main/graphs/cross_country/missing_bycoicop_bar.${format}", replace 	; 

	#delim cr
	
	*Graph B 
	#delim ; 
	graph bar (mean) share_missing_over_total_coicop, over(COICOP2, label(angle(45) labsize(medsmall)))
	graphregion(color(white)) bgcolor(white) plotregion(color(white))	
	ylabel(0(20)60, nogrid labsize(`size'))
	bar(1, color(navy))
	yscale(range(0 70)) 
	yline(0(20)60, lstyle(minor_grid) lcolor(gs1)) 		
	ytitle(" ", size (small)) ;
	graph export "$main/graphs/cross_country/missing_bycoicop_bar_coicop.${format}", replace 	; 

	#delim cr
	restore


	******************	
	* GRAPH TWO 
	******************
	
	use "$main/proc/missing_COICOP12_central.dta", clear
	
	gen share_missing_over_total = (total_exp_missing/total_exp)*100

	keep country_code COICOP2 share_missing_over_total 
	reshape wide share_missing_over_total , i(country_code) j(COICOP2)
	egen total = rowtotal(share_missing_over_total*), missing


	tempfile missing_COICOP12_country
	save `missing_COICOP12_country'
	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow
	ren CountryCode country_code
	ren Year year
	merge 1:1 country_code using `missing_COICOP12_country'
	keep if _merge == 3
	drop _merge

	gen log_GDP = log(GDP_pc_constantUS2010)

	egen health_educ = rowtotal(share_missing_over_total6 share_missing_over_total10), missing
	egen fixed_spending = rowtotal(share_missing_over_total4 share_missing_over_total7 share_missing_over_total8), missing
	egen gs_rec = rowtotal(share_missing_over_total9 share_missing_over_total11 share_missing_over_total12), missing
	egen other = rowtotal(share_missing_over_total1 share_missing_over_total2 share_missing_over_total3 share_missing_over_total5), missing

	* Compute stat for paper p.7 ( total share of unspecified across 31 countries)
	egen total_unspecified= rowtotal(fixed_spending health_educ gs_rec other) , m
	egen mean_total_unspecified= mean(total_unspecified) // 17%
	
	#delim ; 
	graph bar fixed_spending health_educ gs_rec other, over(country_code, sort(log_GDP) label(labsize(vsmall))) stack
	graphregion(color(white)) bgcolor(white) plotregion(color(white)) 	bar(1, color(navy))	
	legend(label(1 "Utilities, Telecom, Gas") label(2 "Health & Education") position(11) ring(0) col(1) 
	label(3 "Diverse G&S, Recreation") label(4 "Other")) ytitle("Share of Unspecified Place of Purchase (in %)"  " ") 
	yline (0(10)60, lstyle(minor_grid) lcolor(gs1))
	ylabel(0(10)60, nogrid);
	graph export "$main/graphs/cross_country/missing_bycoicop_stackedbar.${format}", replace 	; 
	
	#delim cr	
	

	
