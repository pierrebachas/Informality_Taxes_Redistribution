
	
*****************************************************
/* 
		Percentiles data check 	
	
*/ 
*****************************************************	
		
	set more off
	
	*******************************************************************************
	* 0. Check that data is "continuous" lower pct always have lower consumption
	******************************************************************************	
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , clear
	
	keep if COICOP2 == 0 
	count 
	
	gen dif = exp_total - exp_total[_n-1] if country_code == country_code[_n-1]
	
	count if dif < 0 & dif!= . 
	
	***** Check that total expenditure increases always graphically  
	levelsof country_code , local(code)
	foreach name of local code {
				#delim ; 
			twoway (scatter exp_total percentile if COICOP2 == 0 & country_code == "`name'") 
			, name(`name',replace)	;
			#delim cr
			}		
	
	*******************************************************************************
	* 1. Check the shapes of the curves 
	******************************************************************************	
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , replace	

	gen inf_share = exp_informal / exp_total
	
	bysort country_code percentile: egen total_exp_pct = max(exp_total)

	gen share_of_total = exp_total / total_exp_pct	
	gen share_of_total_inf = exp_informal / total_exp_pct	
	gen share_of_total_for = (exp_total - exp_informal) / total_exp_pct	
	
	*** total expenditure and total expenditure on food	
			
	levelsof country_code , local(code)
	foreach name of local code {
			#delim ; 
			twoway (scatter exp_total percentile if COICOP2 == 1 & country_code == "`name'")
			(scatter exp_total percentile if COICOP2 == 0 & country_code == "`name'")
			, name(`name',replace)	;
			#delim cr
			}			
	
	
	*** Formality Engle curve
	levelsof country_code , local(code)
	foreach name of local code {
				#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == 0 & country_code == "`name'") 
			, name(`name',replace)	;
			#delim cr
			}	
	
	*** Formality Engle curve Food only 
	levelsof country_code , local(code)
	foreach name of local code {
				#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == 1 & country_code == "`name'") 
			, name(`name',replace)	;
			#delim cr
			}
			
	// The ratio food non-food will depend on the relative slopes of formal food to formal non-food I believe
	// As discussed by Duflo this is a nice graph to show: 
	
	levelsof country_code , local(code)
	foreach name of local code {
			#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == 1 & country_code == "`name'") 
			 (scatter share_of_total_for percentile if COICOP2 == 0 & country_code == "`name'") 
			, name(`name',replace)	;
			#delim cr
			}	
				
	// br country_code share_of_total_for percentile if COICOP2 == 1 & share_of_total_for == 0
	// br country_code share_of_total_for percentile if COICOP2 == 2 & share_of_total_for == 0			
			

	levelsof country_code , local(code)
	foreach name of local code {
			twoway scatter exp_total percentile if COICOP2 == 0 & country_code == "`name'", name(`name',replace)
			}			
			
	*******************************************************************************
	* 2. DinD for paper to explain preferential rates: ABOVE VS BELOW MEDIAN
	******************************************************************************	

	** Note this code drops all COICOP codes non food and basically replaces the all category with a non-food category
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , replace	
	
	** Only keep total and food (COICOP 0 et 1)
	drop if COICOP >= 2 
	
	bysort country_code percentile: 	egen total_exp_pct 	   = max(exp_total)
	bysort country_code percentile: 	egen food_exp_pct  	   = min(exp_total)
	bysort country_code percentile: 	egen food_inf_exp_pct  = min(exp_informal)
	
	replace exp_total 		= exp_total - food_exp_pct 				if COICOP2 == 0
	replace exp_informal 	= exp_informal - food_inf_exp_pct  		if COICOP2 == 0
	
	label define categories 0 "Non Food" 1 "Food"
	label values COICOP2 categories
	
	
	gen inf_share = exp_informal / exp_total
	
	gen share_of_total = exp_total / total_exp_pct	
	gen share_of_total_inf = exp_informal / total_exp_pct	
	gen share_of_total_for = (exp_total - exp_informal) / total_exp_pct	

	
	* DinD same graph but create something which is all non food and formal non food, through a collapse
	
	local country_by_country =1
	if `country_by_country' { 
	
	levelsof country_code , local(code)
	foreach name of local code {
			#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == 1 & country_code == "`name'") 
			(scatter share_of_total  percentile if COICOP2 == 1 & country_code == "`name'") 
			 (scatter share_of_total_for percentile if COICOP2 == 0 & country_code == "`name'") 
			 (scatter share_of_total percentile if COICOP2 == 0 & country_code == "`name'") 
			, legend(order(1 "Formal Food" 2 "All Food" 3 "Formal NF" 4 "All NF") row(1))
			name(`name',replace)	;
			#delim cr
			}				
	
	} 
	
	** How to summarize this??? 	
	** While food overall is useful to target with low rates because its Engel curve is downward slopping, "formal food" is a flat share 
	** of households budgets! thus, by itself observing a formal purchase of food conveys little information about household's income (tagging mechanism)
	** because the formal vs food channels are counterbalancing each other. 
	** Now note, though that formal non-food is a slighly better tag than just non-food (steeper Engel curve) 
	** --> this pushes the rates on both food and non-food up, but proportionally more on food, thus reducing the food subsidy in the world with an informal sector
	** Note: this is particulalry the case in poorer countries, thus reversing the previous gains. 
	** In particular in some poor countries formal food Engel curve is upward slopping!
	** Order of upgrade with income: once all food is formal, then even formal food is downward slopping
	** When almost all consumption is food then formal food can even be upward slopping 
	
	** Note: can we find a sufficient stat to make this point about relative tagging graphically (is it just our ratios of budget shares as we did previously ?)
	
	***********************************************************************************************		
	/*  DD Tagging ratios at the country level: Constructed in the following way
		TOP 50 vs BOTTOm 50
	
																								*/
	***********************************************************************************************	
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , replace	
	
	** Only keep total and food (COICOP 0 et 1)
	drop if COICOP >= 2 
	
	bysort country_code percentile: 	egen total_exp_pct 	   = max(exp_total)
	bysort country_code percentile: 	egen food_exp_pct  	   = min(exp_total)
	bysort country_code percentile: 	egen food_inf_exp_pct  = min(exp_informal)
	
	replace exp_total 		= exp_total - food_exp_pct 				if COICOP2 == 0
	replace exp_informal 	= exp_informal - food_inf_exp_pct  		if COICOP2 == 0
	
	label define categories 0 "Non Food" 1 "Food"
	label values COICOP2 categories
	
	
	gen inf_share = exp_informal / exp_total
	
	gen share_of_total = exp_total / total_exp_pct	
	gen share_of_total_inf = exp_informal / total_exp_pct	
	gen share_of_total_for = (exp_total - exp_informal) / total_exp_pct	
	
	gen median = . 
	
	forvalues j=1(1)2{
		local i = `j'*50
		replace median = `j' if percentile <= `i' & median == .
		} 
	
	collapse share_of_total_for share_of_total , by(median COICOP2 country_code)
	
	egen id = concat(country_code COICOP2)	, p(_)
	drop country_code COICOP2
	reshape wide share_of_total_for share_of_total  , i(id) j(median)
	
	split id, p(_) destring
	rename id1 country_code
	rename id2 COICOP2
		
	gen ratio_for = 	share_of_total_for2 / share_of_total_for1
	gen ratio_all = 	share_of_total2 / share_of_total1

	** second reshape 
	drop share_of_total_for1 share_of_total1 share_of_total_for2 share_of_total2 id
	reshape wide ratio_for ratio_all , i(country_code) j(COICOP2)
	
	gen ratio_for = ratio_for0 / ratio_for1
	gen ratio_all = ratio_all0 / ratio_all1
	
	order country_code ratio_all0 ratio_all1 ratio_all ratio_for0 ratio_for1 ratio_for
	
	*** Bring in country's GDP
	merge m:1 country_code using "$main/data/country_information.dta"
	keep if _merge==3
	drop _merge
	gen ln_GDP = log(GDP_pc_constantUS2010)	
	
	gen tag_all0 = ratio_all0 
	gen tag_all1 = 1/ratio_all1
	
	gen tag_for0 = ratio_for0
	gen tag_for1 = 1/ratio_for1	
	
	local code "ratio_all0 ratio_all1 ratio_for0 ratio_for1"
	foreach name of local code { 
		gen ln2_`name'	 = ln(`name')/ln(2)
		} 
	
	local yaxis "ylabel(-1(1)2, labsize(medsmall)) yscale(range(-1 2.1))" 	
	local graph_region "plotregion(color(white)) graphregion(color(white))"	
	
	local i = 0 
	local code "ln2_ratio_all0 ln2_ratio_all1 ln2_ratio_for0 ln2_ratio_for1"
	foreach name of local code {
		local i = `i'+ 1
		#delim ; 
		twoway (scatter `name' ln_GDP, mlabel(country_code)) (lfit `name' ln_GDP),
		yline(0 , lc(black))
		name(G`i', replace)
		 `yaxis'	
		 `graph_region' 
		 legend(off) ;
		#delim cr
		} 
		
	graph combine G1 G2 G3 G4, `graph_region' 
	
	
	**** Ok so this graph isnt too bad for the key DinD
	twoway (lfit ln2_ratio_all0 ln_GDP) (lfit ln2_ratio_all1 ln_GDP), name(G1, replace)
	twoway (lfit ln2_ratio_for0 ln_GDP) (lfit ln2_ratio_for1 ln_GDP), name(G2, replace)
	graph combine G1 G2
	
	*** Do a country specific tagging change ... not an easy point to come through 
	gen dif =  (ln2_ratio_for0 - ln2_ratio_for1) - (ln2_ratio_all0 - ln2_ratio_all1)
	
	twoway (scatter dif ln_GDP, mlabel(country_code))  (lfit dif ln_GDP) 
	
	
	*******************************************************************************
	* 3. DinD for paper to explain preferential rates: TOP vs BOTTOM 20%
	******************************************************************************	
	**** Ok so this graph is good, little issue is outliers:
	*** Check the issues remaining with funny countries: NE, MZ, CL  
	*** Ok so I think we have the graphs: Think is it going to be 3 pannels each with two lines (and the country dots?) --- or too messy ... 
	*** Or should the dif in dif be its own panel, that brings these fitted lines together ... and then back to 6 pannels:
	*** Panel (a) formal food, (b) formal-non-food, (c) all informal, (d) informal food, (e) informal non-food, (f) Dif in Dif ? 
	*** Think carefully as this will be a key figure!!!!	
	*** so Informal and Formal can have a color, Food and non-food (and total) can have different patterns (?)
	*** then combine all four lines on one figure for the DinD? 
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , replace	
	

	
	** Only keep total, food and create the sum of non-food 
	keep if COICOP == 0 | COICOP == 1 | COICOP == 2	
	
	*** 1st reshape the data to have exp-total and exp_informal by COICOP 
	egen id = concat(country_code percentile)	, p(_)
	drop country_code percentile 
	reshape wide  exp_total exp_informal , i(id) j(COICOP)
	
	split id, p(_) destring
	rename id1 country_code
	rename id2 percentile	
	

	sort country_code percentile
	
	replace exp_total2  = exp_total0 - exp_total1 
	replace exp_informal2 	= exp_informal0 - exp_informal1 
	
	*** Define the quintiles, and only keep the top and bottom ones: 
	gen quintile = . 
	
	forvalues j=1(1)5{
		local i = `j'*20
		replace quintile = `j' if percentile <= `i' & quintile == .
		} 
		
	
	*Decile to compute savings 
	gen decile=.
	replace decile=1 if percentile>=1 & percentile<=10
	replace decile=2 if percentile>=11 & percentile<=20
	replace decile=3 if percentile>=21 & percentile<=30
	replace decile=4 if percentile>=31 & percentile<=40
	replace decile=5 if percentile>=41 & percentile<=50
	replace decile=6 if percentile>=51 & percentile<=60
	replace decile=7 if percentile>=61 & percentile<=70
	replace decile=8 if percentile>=71 & percentile<=80
	replace decile=9 if percentile>=81 & percentile<=90
	replace decile=10 if percentile>=91 & percentile<=100	
	
	
	**Savings 
	local savings_rate = 0.015
	gen inc_total0 = 	.
	forvalues i = 1(1)10 { 		
		replace inc_total0 = exp_total0 / (1-`savings_rate'*`i')	if decile == `i'
		}
		
	keep if quintile == 1 | quintile == 5	

	** Obtain totals of expenditures for the bottom and top quintile 
	collapse (sum) exp_total0 inc_total0 (sum) exp_total1 (sum) exp_total2  (sum) exp_informal0 (sum) exp_informal1 (sum) exp_informal2 , by(quintile country_code) 
	
	forvalues i = 0(1)2 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		} 
		
	*VAT
	global vat_inputs = 0.1
	forvalues i = 0(1)2 { 
		gen exp_formal`i'_vat = exp_formal`i' + exp_informal`i' * $vat_inputs
		} 
		
		
	
	forvalues i = 0(1)2 { 
		gen share_of_total`i' = exp_total`i' / exp_total0
		gen share_of_total_inf`i' = exp_informal`i'  / exp_total0	
		gen share_of_total_for`i' = exp_formal`i'  / exp_total0	
		} 
	
	**Savings
	forvalues i = 0(1)2 { 
		gen share_of_total`i'_savings = exp_total`i' / inc_total0
		gen share_of_total_inf`i'_savings = exp_informal`i'  / inc_total0	
		gen share_of_total_for`i'_savings = exp_formal`i'  / inc_total0	
		} 
		
	**VAT
	forvalues i = 0(1)2 { 	
		gen share_of_total_for`i'_vat = exp_formal`i'  / exp_total0	
		} 
		
	** 2nd Reshape as to have a variable per quintile 	
	drop exp_* inc_total0
	reshape wide share_of_total*  , i(country_code) j(quintile)
	
	*** Generate ratio of qunitiles
		forvalues i = 0(1)2 { 
		gen ratio_all`i' = share_of_total`i'5 / share_of_total`i'1
		gen ratio_for`i' = share_of_total_for`i'5 / share_of_total_for`i'1
		} 
	
	*** Generate ratio of qunitiles - Savings
		forvalues i = 0(1)2 { 
		gen ratio_all`i'_savings = share_of_total`i'_savings5 / share_of_total`i'_savings1
		gen ratio_for`i'_savings = share_of_total_for`i'_savings5 / share_of_total_for`i'_savings1
		} 
		
	*** Generate ratio of qunitiles - VAT
		forvalues i = 0(1)2 { 
		gen ratio_for`i'_vat = share_of_total_for`i'_vat5 / share_of_total_for`i'_vat1
		} 
		
	*** Bring in country's GDP
	merge m:1 country_code using "$main/data/country_information.dta"
	keep if _merge==3
	drop _merge
	gen ln_GDP = log(GDP_pc_constantUS2010)	
	
	** Gen log base (2) ratios, which is the correct axis. 
	local code "ratio_all0 ratio_all1 ratio_all2 ratio_for0 ratio_for1 ratio_for2 ratio_all0_savings ratio_all1_savings ratio_all2_savings ratio_for0_savings ratio_for1_savings ratio_for2_savings ratio_for0_vat ratio_for1_vat ratio_for2_vat "
	foreach name of local code { 
		gen ln2_`name'	 = ln(`name')
		} 		
	
	*** FIGURE FOR PAPER
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis "ylabel(-1.5(0.5)2, nogrid labsize(`size')) yscale(range(-1.5 2.1)) yline(-1.5(0.5)2, lstyle(minor_grid) lcolor(gs1)) yline(0, lcolor(black) lw(medthick))" 
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local ytitle "ytitle("Budget Shares: Top20/Bottom20 (log)", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
	
	*** All figures at once:
	local all_figures = 0
	if `all_figures' { 
	
	local i = 0 
	local code "ln2_ratio_all1 ln2_ratio_all2 ln2_ratio_for1 ln2_ratio_for2 ln2_ratio_for0"
	foreach name of local code {
		local i = `i'+ 1
		#delim ; 
		twoway (scatter `name' ln_GDP, `dots') (lfit `name' ln_GDP), 
		name(G`i', replace)
		 `yaxis'	
		`xaxis' 
		`xtitle'
		`graph_region_options' 
		 legend(off) ;
		#delim cr
		graph export "$main/graphs/budget_shares_G`i'.eps" , replace 		
		
		} 
	} 	
	
	
	*** Panel A
		#delim ; 
		twoway (scatter ln2_ratio_for0 ln_GDP, `dots') (lfit ln2_ratio_for0 ln_GDP, lc(orange) lp(longdash)), 
		name(G3, replace)
		 `yaxis' `ytitle'	
		`xaxis' xtitle("")
		`graph_region_options' 
		 legend(off) ;
		#delim cr
		graph export "$main/graphs/budget_shares_G3.eps" , replace 
			
	*** Panel B
		#delim ; 
		twoway (scatter ln2_ratio_for1 ln_GDP, `dots') (lfit ln2_ratio_for1 ln_GDP, lc(orange) lp(shortdash)), 
		name(G4, replace)
		`yaxis' ytitle("")	 	
		`xaxis' xtitle("")
		`graph_region_options' 
		 legend(off) ;
		#delim cr
		graph export "$main/graphs/budget_shares_G4.eps" , replace 
		
	*** Panel C
		#delim ; 
		twoway (scatter ln2_ratio_for2 ln_GDP, `dots') (lfit ln2_ratio_for2 ln_GDP, lc(orange) ), 
		name(G5, replace)
		 `yaxis' ytitle("")	
		`xaxis' xtitle("")
		`graph_region_options' 
		 legend(off) ;
		#delim cr
		graph export "$main/graphs/budget_shares_G5.eps" , replace 	
		
	
	***** Panel D (et Appendix A12 Panel a et b)
	#delim ; 	

	
	twoway (lfit ln2_ratio_for1 ln_GDP, color(orange) lp(shortdash)) (lfit ln2_ratio_for2 ln_GDP, color(orange) ) 
	(lfit ln2_ratio_all1 ln_GDP, color(green) lp(shortdash)) (lfit ln2_ratio_all2 ln_GDP, color(green) ) 	, 	
	ytitle("")
	xtitle("Log GDP per capita, Constant 2010 USD")
		 `yaxis' `ytitle'
		`xaxis' `xtitle'
	`graph_region_options' 
	name(G6, replace)
	legend(off);
	//legend(order(1 "Formal Food" 2 "Formal Non-Food" 3 "Food" 4 "Non-Food" ) position(12) ring(0)) ; // Show only if scenario is central or specific
	
	#delim cr	

	graph export "$graphs/budget_shares_DD_1figure_${scenario}.eps" , replace 	
	
			***** Appendix A12 Panel c
	#delim ; 	

	
	twoway (lfit ln2_ratio_for1_vat ln_GDP, color(orange) lp(shortdash)) (lfit ln2_ratio_for2_vat ln_GDP, color(orange) ) 
	(lfit ln2_ratio_all1 ln_GDP, color(green) lp(shortdash)) (lfit ln2_ratio_all2 ln_GDP, color(green) ) 	, 	
	ytitle("")
	xtitle("Log GDP per capita, Constant 2010 USD")
		 `yaxis' `ytitle'
		`xaxis' `xtitle'
	`graph_region_options' 
	name(G7, replace)
	legend(off);	
	#delim cr	

	graph export "$graphs/budget_shares_DD_1figure_${scenario}_vat.eps" , replace 		
	
		***** Appendix A12 Panel d
	#delim ; 	

	
	twoway (lfit ln2_ratio_for1_savings ln_GDP, color(orange) lp(shortdash)) (lfit ln2_ratio_for2_savings ln_GDP, color(orange) ) 
	(lfit ln2_ratio_all1_savings ln_GDP, color(green) lp(shortdash)) (lfit ln2_ratio_all2_savings ln_GDP, color(green) ) 	, 	
	ytitle("Budget Shares: Top20/Bottom20 (log)")
	xtitle("Log GDP per capita, Constant 2010 USD")
		 `yaxis' `ytitle'
		`xaxis' `xtitle'
	`graph_region_options' 
	name(G8, replace) 
	legend(off);

	#delim cr	

	graph export "$graphs/budget_shares_DD_1figure_${scenario}_savings.eps" , replace 		
	
	
	*** Panel E
		#delim ; 
		twoway (scatter ln2_ratio_all1 ln_GDP, `dots') (lfit ln2_ratio_all1 ln_GDP, lc(green) lp(shortdash)), 
		name(G1, replace)
		`yaxis'	ytitle("")	
		`xaxis' `xtitle'
		`graph_region_options' 
		 legend(off) ;
		#delim cr
		graph export "$main/graphs/budget_shares_G1.eps" , replace 

	*** Panel F
		#delim ; 
		twoway (scatter ln2_ratio_all2 ln_GDP, `dots') (lfit ln2_ratio_all2 ln_GDP, lc(green)), 
		name(G2, replace)
		 `yaxis' ytitle("")	
		`xaxis' `xtitle'
		`graph_region_options' 
		 legend(off) ;
		#delim cr
		graph export "$main/graphs/budget_shares_G2.eps" , replace 		
		
		
		

		
	***********************************************************************************************		
	/* DinD figure poor vs rich 
	
																								*/
	***********************************************************************************************	
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , replace	
	
	drop if COICOP >= 2 
	bysort country_code percentile: egen total_exp_pct = max(exp_total)
	bysort country_code percentile: egen food_exp_pct  = min(exp_total)
	bysort country_code percentile: egen food_inf_exp_pct  = min(exp_informal)
	
	replace exp_total = exp_total - food_exp_pct if COICOP2 == 0
	replace exp_informal = exp_informal - food_inf_exp_pct  if COICOP2 == 0
	
	gen inf_share = exp_informal / exp_total
	
	gen share_of_total = exp_total / total_exp_pct	
	gen share_of_total_inf = exp_informal / total_exp_pct	
	gen share_of_total_for = (exp_total - exp_informal) / total_exp_pct		
	
	
	** DinD figure, poor vs middle income countries: 
		merge m:1 country_code year using "$main/data/country_information.dta"
		keep if _merge==3
		drop _merge
		gen ln_GDP = log(GDP_pc_constantUS2010)
		
		** Get the median GDP 
		
		_pctile ln_GDP , p(50)  
		return list
		local p_50 = round(100*`r(r1)')/100
		
		gen low_income = 0
		replace low_income = 1 if  ln_GDP < `p_50'

		
		collapse share_of_total_for share_of_total , by(low_income percentile COICOP2)
	
	* DinD same graph but create something which is all non food and formal non food, through a collapse
	
	replace share_of_total_for = share_of_total_for * 100
	replace share_of_total = share_of_total * 100	
	
	local graph_region "plotregion(color(white)) graphregion(color(white))"
	local yaxis "ylabel(0(20)100, nogrid labsize(medsmall)) yscale(range(0 100)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 	
	
			#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == 1 & low_income == 1) 
			(scatter share_of_total  percentile if COICOP2 == 1 & low_income == 1) 
			(scatter share_of_total_for percentile if COICOP2 == 0 & low_income == 1) 
			(scatter share_of_total percentile if COICOP2 == 0 & low_income == 1) 
			, legend(order(1 "Formal Food" 2 "All Food" 3 "Formal NF" 4 "All NF") row(1) size(small))
			title("Low Income")
			`graph_region' `yaxis'
			name(G1,replace)	;
			#delim cr

			#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == 1 & low_income == 0) 
			(scatter share_of_total  percentile if COICOP2 == 1 & low_income == 0) 
			(scatter share_of_total_for percentile if COICOP2 == 0 & low_income == 0) 
			(scatter share_of_total percentile if COICOP2 == 0 & low_income == 0) 
			, legend(order(1 "Formal Food" 2 "All Food" 3 "Formal NF" 4 "All NF") row(1) size(small))
			title("Middle Income")
			`graph_region' `yaxis'
			name(G2,replace)	;
			#delim cr		
			
	graph combine G1 G2 , 	plotregion(color(white)) graphregion(color(white))
	graph export "$graphs/DD_tagging.eps" , replace 
			
	*******************************************************************************
	* 3. Check odd countries 
	******************************************************************************		
	
	*** the oddity in Chile is not due to food but to something else, what could it be ??? is there one odd category we have left in? 
	
	*** CHILE: 
	*** Top is partially due to education, dont do anything
	*** Bottom is mainly due to category 4 of housing, there go back and check if housing is indeed well taken out from survey!!!
	*** Levels of bills are high ! could there be an issue linked to frequency of these payments (everyone seems to have them) 
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , clear
		
	gen inf_share = exp_informal / exp_total
	
	bysort country_code percentile: egen total_exp_pct = max(exp_total)

	gen share_of_total = exp_total / total_exp_pct	
	gen share_of_total_inf = exp_informal / total_exp_pct	
	gen share_of_total_for = (exp_total - exp_informal) / total_exp_pct

	keep if country_code == "CG"
	
	*** Formality Engle curve
	forvalues i=0(1)12 {
				#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == `i' ) 
			(scatter share_of_total percentile if COICOP2 == `i' ) 
			, name(G`i',replace)	;
			#delim cr
			}	
	
	
	*******************************************************************************
	* 4. Check category 4 : housing 
	******************************************************************************		
	
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , clear
		
	gen inf_share = exp_informal / exp_total
	
	bysort country_code percentile: egen total_exp_pct = max(exp_total)

	gen share_of_total = exp_total / total_exp_pct	
	gen share_of_total_inf = exp_informal / total_exp_pct	
	gen share_of_total_for = (exp_total - exp_informal) / total_exp_pct	
	
	set more off
	
	levelsof country_code , local(code)
	foreach name of local code {
			#delim ; 
			twoway (scatter share_of_total_for percentile if COICOP2 == 4 & country_code == "`name'") 
			(scatter share_of_total percentile if COICOP2 == 4 & country_code == "`name'") 
			, name(G`name', replace)	;
			#delim cr
			}				

			
	**************************************************************************************************
	* Check how different is the new source (at the pct level) from the new source at decile level 
	***************************************************************************************************
		
	
	**** Can be used as a check: group percentiles, ok indeed that works and is the same. 
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , clear
	gen decile = ceil(percentile/10)
	
	bysort decile country_code COICOP2: egen total_exp_pct = total(exp_total)
	
	egen tag = tag(decile country_code COICOP2)
	keep if tag == 1
	keep if COICOP2 == 0
	
	keep country_code  total_exp_pct decile
	tempfile data_from_pct
	save `data_from_pct' 
	
	**** How different was our previous data? 
	*** Measure percentage changes by country to know magnitude of changes and check in particular at top and bottom 
	*** Keep both bases for now to check that we dont make too many mistakes. 
	
	local filename "new_output_for_simulation_dcl"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , replace	

	keep if COICOP2 == 0
	
	merge 1:1 country_code  decile using `data_from_pct' 
	
	gen dif_pct = (exp_total  - total_exp_pct) / exp_total
	gen abs_dif_pct = abs(dif_pct)
	
	* how big are these diferences? 
	sum dif_pct , d 			// 10% higer on average at the decile-country level 
	hist dif_pct
	
	gsort -abs_dif_pct
	list country_code decile dif_pct if  _n <= 20 
	
	* Ok so observations:
	// there is a problem with Senegal, which I will need to ask Eva to investigate
	// There is often a "reversal" that is for the poorest households, the measure we were using (already created one) is quite a bit larger than the one recalculated
	// similarly the measure we were using at the top is often smaller than the one we recalculated
	// --> we thus get more inequality when using our reclaculated total consumption measure. I will rediscuss with Eva these issues. 
	
	// Concretely for Lucie: option 1: work with old data, issue some lower percentiles are larger than higher percentiles
	//						 option 2: work with new way, could change a bit our results (im curious in which way) 
	
	
	*************************************************************************
	* Check that both new sources at decile and pctile level are concordant:
	**************************************************************************
	
	**** Can be used as a check: group percentiles, ok indeed that works and is the same. 
	local filename "new_output_for_simulation_pct"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , clear
	gen decile = ceil(percentile/10)
	
	bysort decile country_code COICOP2: egen total_exp_pct = total(exp_total)
	
	egen tag = tag(decile country_code COICOP2)
	keep if tag == 1
	keep if COICOP2 == 0
	
	keep country_code  total_exp_pct decile
	tempfile data_from_pct
	save `data_from_pct' 	
	
	
	local filename "new_output_for_simulation"
	use "$main/proc/`filename'_COICOP2_$scenario.dta" , replace	

	keep if COICOP2 == 0
	
	merge 1:1 country_code  decile using `data_from_pct' 
	
	gen dif_pct = (exp_total  - total_exp_pct) / exp_total
	gen abs_dif_pct = abs(dif_pct)
	
	* how big are these diferences? 
	sum dif_pct , d 			// 10% higer on average at the decile-country level 
	hist dif_pct
	
	gsort -abs_dif_pct
	list country_code decile dif_pct if  _n <= 20 	
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
