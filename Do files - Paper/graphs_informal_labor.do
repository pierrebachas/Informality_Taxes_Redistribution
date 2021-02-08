	 				*********************
					* 	INFORMAl LABOR	*
					*********************
					
		***************
		* DIRECTORIES *
		***************
			
		if "`c(username)'"=="wb446741" { 												// Pierre's WB computer 
		global main "C:\Users\wb446741\Dropbox\Regressivity_VAT\Stata"
		}
		else if "`c(username)'"=="pierrebachas" { 									// Pierre's personal laptop
		global main "/Users/pierrebachas/Dropbox/Regressivity_VAT/Stata"
		}	
		else if "`c(username)'"=="Economics" { 												// Lucie
		global main C:\Users\Economics\Dropbox\Regressivity_VAT_own\Regressivity_VAT\Stata
		}
		else if "`c(username)'"=="wb520324" { 											// Eva's WB computer 
		global main "C:\Users\wb520324\Dropbox\Regressivity_VAT/Stata"
		}
		
		else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
		global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
		}

		******************
		* CONTROL CENTER *
		******************
		
		local table = 0
		local graph = 0
		local graph_paper = 1
		
		
		*****************
		*	GRAPH PAPER	*
		*****************
		
		if `graph_paper' {
		import excel using "$main/data/Country_information.xlsx" , clear firstrow	
		tempfile gdp
		save  `gdp'
			
		import excel "$main/tables/informal_labor.xls", sheet("Sheet1") firstrow clear
		
		merge 1:1 CountryCode using  `gdp'
		
		ren CountryCode country_code
		gen log_GDP = log(GDP_pc_constantUS2010)
		
		gen ratio_income=RatioMedianRetailFormalPe
		replace ratio_income=RatioMedianRetailFormalMe if ratio_income==.
		
		*Graph A11
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0.5(0.5)2.5, nogrid  labsize(`size')) yline(1, lcolor(black) lw(medthick))  yline(0.5(0.5)2.5, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Median Income Ratio Formal & Retail / Total", size(`size') margin(medsmall) )"
		local xaxis "xlabel(5(1)10, labsize(`size'))"		
		local markerlabels "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
				
		#delim ; 	
		twoway (scatter ratio_income log_GDP , `markerlabels') (lfit ratio_income log_GDP) , 
		legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis'
		`ytitle'
		`graph_region_options'  
		name(graph_r3, replace) ;
		graph export "$main/graphs/cross_country/informal_labor.eps", replace	;
				
		#delim cr
				}

		*************
		*	TABLE	*
		*************

		if `table' {
		
		putexcel set "$main/tables/informal_labor.xls",  modify
		putexcel A1 = "Country"
		sleep 500
		putexcel B1 = "Mean exp_noh"
		sleep 500
		putexcel C1 = "Median exp_noh"
		sleep 500
		putexcel D1 = "Mean exp_noh - Retail"
		sleep 500
		putexcel E1 = "Median exp_noh - Retail"
		sleep 500
		putexcel F1 = "Mean exp_noh - Retail & Formal"
		sleep 500
		putexcel G1 = "Median exp_noh - Retail & Formal"
		sleep 500
		putexcel H1 = "Mean exp_noh - Retail & Informal"
		sleep 500
		putexcel I1 = "Median exp_noh - Retail & Informal"
		sleep 500
		putexcel J1 = "Ratio Mean Retail/ Mean All"
		sleep 500
		putexcel K1 = "Ratio Median Retail/ Median All"
		sleep 500
		putexcel L1 = "Ratio Mean Retail & Formal/ Mean All"
		sleep 500
		putexcel M1 = "Ratio Median Retail & Formal/ Median All"
		sleep 500
		putexcel N1 = "Ratio Mean  Retail & Informal/ Mean All"
		sleep 500
		putexcel O1 = "Ratio Median Retail & Informal/ Median All"
		sleep 500
		putexcel P1 = "Ratio Mean Retail & Formal (Pension/health)/ Mean All"
		sleep 500
		putexcel Q1 = "Ratio Median Retail & Formal (Pension/health)/ Median All"
		sleep 500
		putexcel R1 = "Ratio Mean  Retail & Informal (Pension/health)/ Mean All"
		sleep 500
		putexcel S1 = "Ratio Median Retail & Informal (Pension/health)/ Median All"
		sleep 500
		putexcel T1 =  "Formal (Pension/health) n= "
		sleep 500
		putexcel U1 = "Informal (Pension/health) n= "
		sleep 500

		putexcel A25 = "Winsorization at the 95%"
		sleep 500

		local country_code "BJ BF CM CL KM CD DO EC ME MZ NE PY PE RW ST SN RS TZ TN UY"	
		local country_fullname "Benin2015 BurkinaFaso2009 Cameroon2014 Chile2017 Comoros2013 Congo_DRC2005 Dominican_Rep2007 Ecuador2012 Montenegro2009 Mozambique2009 Niger2007 Paraguay2011 Peru2017 Rwanda2014 SaoTome2010 Senegal_Dakar2008 Serbia2015  Tanzania2012 Tunisia2010 Uruguay2005 " 	
		local n_models : word count `country_code'
		forval i=2/2 { //21
		global country_code `: word `i' of `country_code''	
		global country_fullname `: word `i' of `country_fullname''
		
		if "$country_code"=="PY" {
		use "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_product_code_4dig.dta" , replace
		}
		
		else if "$country_code"!="PY" {
		use "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
		} 
		
		
		bysort hhid  (exp_noh) : replace exp_noh = exp_noh[_n-1] if missing(exp_noh)

		duplicates drop hhid, force
		
		merge 1:1 hhid using  "$main/waste/$country_fullname/${country_code}_labor_head.dta"
		
		*Create alternative measure of formality
		gen pension_health=(pension==1 | health==1)
		replace pension_health=. if pension==. & health==.
		
		
		*Winsorization
		sum exp_noh , d
		local p95 = `r(p95)'
		
		replace exp_noh=`p95' if exp_noh>`p95' & exp_noh!=.
		
		
		sum exp_noh , d
		local mean_exp_noh = r(mean)
		local med_exp_noh = r(p50)

		sum exp_noh if retail==1 , d
		local mean_exp_noh_retail = r(mean)
		local med_exp_noh_retail = r(p50)

		sum exp_noh if retail==1 & formal_wage==1 , d
		local mean_exp_noh_formal = r(mean)
		local med_exp_noh_formal = r(p50)

		sum exp_noh if retail==1 & formal_wage==0, d
		local mean_exp_noh_informal = r(mean)
		local med_exp_noh_informal = r(p50)

		sum exp_noh if retail==1 & pension_health==1 , d
		local mean_exp_noh_pension = r(mean)
		local med_exp_noh_pension = r(p50)
		count if exp_noh!=. & retail==1 & pension_health==1 
		local pension_formal = `r(N)'

		sum exp_noh if retail==1 & pension_health==0, d
		local mean_exp_noh_inf_pension = r(mean)
		local med_exp_noh_inf_pension = r(p50)
		count if exp_noh!=. & retail==1 & pension_health==0
		local pension_informal = `r(N)'

		
		local line=`i' +1
		putexcel A`line' = "$country_fullname"
		sleep 500
		putexcel B`line' = `mean_exp_noh'
		sleep 500
		putexcel C`line' = `med_exp_noh'
		sleep 500
		putexcel D`line' = `mean_exp_noh_retail'
		sleep 500
		putexcel E`line' = `med_exp_noh_retail'
		sleep 500
		putexcel F`line' = `mean_exp_noh_formal'
		sleep 500
		putexcel G`line' = `med_exp_noh_formal'
		sleep 500
		putexcel H`line' = `mean_exp_noh_informal'
		sleep 500
		putexcel I`line' = `med_exp_noh_informal'
		sleep 500
		putexcel J`line' = `mean_exp_noh_retail'/`mean_exp_noh'
		sleep 500
		putexcel K`line' = `med_exp_noh_retail'/`med_exp_noh'
		sleep 500
		putexcel L`line' = `mean_exp_noh_formal'/`mean_exp_noh'
		sleep 500
		putexcel M`line' = `med_exp_noh_formal'/`med_exp_noh'
		sleep 500
		putexcel N`line' = `mean_exp_noh_informal'/`mean_exp_noh'
		sleep 500
		putexcel O`line' = `med_exp_noh_informal'/`med_exp_noh'
		sleep 500
		putexcel P`line' = `mean_exp_noh_pension'/`mean_exp_noh'
		sleep 500
		putexcel Q`line' = `med_exp_noh_pension'/`med_exp_noh'
		sleep 500
		putexcel R`line' = `mean_exp_noh_inf_pension'/`mean_exp_noh'
		sleep 500
		putexcel S`line' = `med_exp_noh_inf_pension'/`med_exp_noh'
		sleep 500
		putexcel T`line' = `pension_formal'
		sleep 500
		putexcel U`line' = `pension_informal'
		sleep 500
		}
		}
		*************
		*	GRAPH	*
		*************
		
		if `graph' {
		local country_code "BJ BF CM CL KM CD DO EC ME MZ NE PY PE RW ST SN RS ZA TZ TN UY"	
		local country_fullname "Benin2015 BurkinaFaso2009 Cameroon2014 Chile2017 Comoros2013 Congo_DRC2005 Dominican_Rep2007 Ecuador2012 Montenegro2009 Mozambique2009 Niger2007 Paraguay2011 Peru2017 Rwanda2014 SaoTome2010 Senegal_Dakar2008 Serbia2015 SouthAfrica2011 Tanzania2012 Tunisia2010 Uruguay2005 " 	
		local n_models : word count `country_code'
		forval i=21/21 { //21
		global country_code `: word `i' of `country_code''	
		global country_fullname `: word `i' of `country_fullname''

		if "$country_code"=="PY" {
		use "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_product_code_4dig.dta" , replace
		}
		
		else if "$country_code"!="PY" {
		use "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
		} 
		
		bysort hhid  (exp_noh) : replace exp_noh = exp_noh[_n-1] if missing(exp_noh)

		duplicates drop hhid, force
		
		merge 1:1 hhid using  "$main/waste/$country_fullname/${country_code}_labor_head.dta"
		
		
		local size medlarge
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
		local yaxis1 "ylabel(, nogrid  labsize(tiny)) "	
		local yaxis2 "ylabel(0.1(0.05)0.3, nogrid  labsize(`size'))   yline(0.1(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
		local xaxis "xlabel(, labsize(vsmall))"
		local xtitle "xtitle("Total exp. no housing", margin(medsmall) size(`size'))"
		local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"	
		local title "title($country_fullname)"
		//local width "width(100000)"

		
		sum exp_noh , d
		local p5 = `r(p5)'
		local p95 = `r(p95)'
		local bottom = floor(`r(p5)')
		local top = ceil(`r(p95)')
		
		*Obs
		count if exp_noh <= `top' 
		local all = `r(N)'
		di `all'
		count if exp_noh <= `top' & retail==1
		local retail = `r(N)'
		di `retail'
		count if exp_noh <= `top' & retail==1 & formal_wage==1
		local formal = `r(N)'
		di `formal'
		count if exp_noh <= `top' & retail==1 & formal_wage==0
		local informal = `r(N)'
		di `informal'
		
		
		
		*Show distribution of total_exp
		#delim ;
		tw (hist exp_noh if exp_noh <= `top' , color(grey%30)) , 
		name(G1, replace) 
		`graph_region_options'
		`xtitle'
		`xaxis'
		`yaxis1'
		legend(order (1 "All households") size(small)) ;
		#delim cr
		
		*Overlay distribution of total_exp for sample in retail (and maybe services)
		#delim ;
		tw (hist exp_noh if exp_noh <= `top', color(grey%30) `width') (hist exp_noh if exp_noh <= `top' & retail==1, color(blue%30) `width') ,
		name(G2, replace)
		`graph_region_options'
		`xtitle'
		`xaxis'
		`yaxis1'
		legend(order (1 "All households" 2 "Retail") size(small)) ;
		#delim cr
		
		*Overlay distribution of  total_exp for sample in retail (and maybe services) who are formal
		#delim ;
		tw (hist exp_noh if exp_noh <= `top', color(grey%30) `width') (hist exp_noh if exp_noh <= `top' & retail==1 & formal_wage==1, color(green%30) `width') , 
		name(G3, replace)
		`graph_region_options'
		`xtitle'
		`xaxis'
		`yaxis1'
		legend(order (1 "All households" 2 "Retail & Formal") size(small)) ;
		#delim cr
		
		*Overlay distribution of  total_exp for sample in retail (and maybe services) who are informal
		#delim ;
		tw (hist exp_noh if exp_noh <= `top', color(grey%30) `width') (hist exp_noh if exp_noh <= `top' & retail==1 & formal_wage==0, color(red%30) `width') , 
		name(G4, replace)
		`graph_region_options'
		`xtitle'
		`xaxis'
		`yaxis1'
		legend(order (1 "All households" 2 "Retail & Informal") size(small)) ;
		#delim cr
		
		*Overlay all
		#delim ;
		tw (hist exp_noh if exp_noh <= `top', color(grey%30) `width') (hist exp_noh if exp_noh <= `top' & retail==1, color(blue%30) `width') (hist exp_noh if exp_noh <= `top' & retail==1 & formal_wage==1, color(green%30) `width') (hist exp_noh if exp_noh <= `top' & retail==1 & formal_wage==0, color(red%30) `width') , 
		name(G5, replace)
		`graph_region_options'
		`xtitle'
		`xaxis'
		`yaxis1'
		legend(order (1 "All households" 2 "Retail" 3 "Retail & Formal" 4 "Retail & Informal") size(small)) ;
		#delim cr
		
		//gr combine G1 G2 G3 G4 , `title' graphregion(color(white)) ycommon
				
		grc1leg G5 G2 G3 G4 , `title' ycommon legendfrom(G5) graphregion(fcolor(white)	lcolor(white) ifcolor(white) ilcolor(white)) note("Sample Size:" "All: `all' Retail: `retail' Formal & Retail: `formal' Informal & Retail: `informal'" , size(vsmall))
		graph export "$main/graphs/laborextension/$country_fullname.pdf", replace

		}
		}
		
