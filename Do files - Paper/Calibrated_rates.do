
	****************************************************************************************************************
	/*	
	*** Data: 
		
		1: scenario used to construct the dataset (central/robust/proba)
		
		*** Government Preferences:
		
		2: government preferences 1=welfarist (baseline), 2=poverty-averse
		3: government preference, if welfarist relative weight on bottom decile compared to top (Decreases by linear steps across deciles)
		4: government preferences, if poverty averse: decile above which household is considered non-poor (baseline - set to 0)
		5: government preferences, if povery averse: welfare weight of poor relative to non-poor (default is 2) (baseline - set to 0)
		6: value of public funds, set mu=`6' times the average welfare weight (baseline is 1)
		
		*** Structural Parameters: 
		7: Fix uncompensated price elasticites endogeneously (0,1). If 1: need to determine 8 and 9. if 0: need to determine 10
		8: value of price compensated own price elasticity (baseline = 0.7)	
		9: value of elasticity of compensated elasticity of substitution formal vs informal (baseline = 1.5)						
		10: Value chosen for all uncompensated elasticities if fixed exogenously (baseline=1)
		
		*** Extensions:  	
		[For Removing Inequality] 
		11: =1 if remove inequalities in total expenditure (baseline), 0 otherwise	
		[for varying saving rates]
		12: savings_rate drops by that amount between decile  (baseline=0, when include savings =0.015)
		[for VAT on inputs]
		13: passthrough of taxes on informal prices (baseline =0, when include VAT on inputs for now 0.07)
		14: =1 if allow for PIT
	*/	

	****************************************************************************************************************
		
	cap log close
	set more off	
	
	local run_program = 0
	local uniform_rates_together = 0		// To obtain the 4 quadrants in one figure 
	local uniform_rates_separate = 1		// Figure in Paper 
	local food_subsidy = 0					// Separate rates, as plotted in figure 7 of paper
	local food_subsidy_robust = 0			// Food subisdy robustness
	
	****************************************************************************************************************
	
	*	A. Optimal Tax Rates, no PIT 
	
	****************************************************************************************************************
	
	** Run the program once such that it is loaded in memory	

	if `run_program' { 
		do "$main/dofiles/optimal_tax_program.do"		
		}
	
	**************************************************************
	* 	Matching the following moment: average uniform rate = 18%
	***************************************************************
	*** Our free parameter are the social welfare weights: 
	* when set to 11 get average value of uniform VAT rate of 18 in the central scenario (e_sub = 1.5)
	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
	sum t_F
	
	****************************************************************************************************************
	*	A1. Baseline: uniform rate, no PIT
	****************************************************************************************************************		
	if `uniform_rates_together'	{
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		*local yaxis "ylabel(0.05(0.05)0.5, nogrid  labsize(`size'))   yline(0.05(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		*local xaxis "xlabel(0(1)14,  labsize(`size')) xscale(range(7.5 14.5))"


	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 0 1 0 0 0 0
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		ytitle("Optimal Uniform Rate", margin(medsmall) size(`size')) 
		title("No efficiency")
		`graph_region_options'
		saving(graph_r1, replace) ; 
		#delim cr
	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		ytitle("Optimal Uniform Rate", margin(medsmall) size(`size')) 
		title("Elasticity=1.5")
		`graph_region_options'
		saving(graph_r2, replace) ; 
		#delim cr

	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1 1 0 0 0 0
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		ytitle("Optimal Uniform Rate", margin(medsmall) size(`size')) 
		title("Elasticity=1")
		`graph_region_options'
		saving(graph_r3, replace) ; 
		#delim cr

	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 2 1 0 0 0 0
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) ,  legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		ytitle("Optimal Uniform Rate", margin(medsmall) size(`size')) 
		title("Elasticity=2")
		`graph_region_options'
		saving(graph_r4, replace) ; 
		#delim cr
		
	gr combine graph_r1.gph graph_r2.gph   graph_r3.gph graph_r4.gph, col(2)    iscale(0.5)  ///
	graphregion(color(white)) title("Figure A13 with new data") 
	gr export "$main/graphs/calibration/Figa13_newdata_03_12.pdf", replace	as(pdf) 	
			

}

	
	if `uniform_rates_separate'	{
		
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis1 "ylabel(0.1(0.1)0.7, nogrid  labsize(`size'))   yline(0.1(0.1)0.7, lstyle(minor_grid) lcolor(gs1))"	
	local yaxis2 "ylabel(0.1(0.05)0.3, nogrid  labsize(`size'))   yline(0.1(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
	local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)10, labsize(`size'))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"	


	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 0 1 0 0 0 0
	preserve
	duplicates drop t_F ln_GDP, force
		#delim ; 
		twoway (scatter t_F ln_GDP, `dots') 
		(lfit t_F ln_GDP, lcolor(red)) , 
		legend(off) 
		`xtitle' 	`xaxis'  
		`ytitle'	`yaxis1'
		`graph_region_options'; 
		graph export "$main/graphs/unfiorm_rates_G1.pdf" , replace 	; 
		#delim cr
		restore
	
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0
	preserve
	duplicates drop t_F ln_GDP, force
		#delim ; 
		twoway (scatter t_F ln_GDP, `dots' ) 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  `xaxis'
		`ytitle'	`yaxis2'
		`graph_region_options' ; 
		graph export "$main/graphs/unfiorm_rates_G2.pdf" , replace 	; 
		#delim cr
		restore

	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1 1 0 0 0 0
	preserve
	duplicates drop t_F ln_GDP, force
		#delim ; 
		twoway (scatter t_F ln_GDP, `dots') 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  `xaxis'
		`ytitle'	`yaxis2'
		`graph_region_options' ; 
		graph export "$main/graphs/unfiorm_rates_G3.pdf" , replace 	; 
		#delim cr
		restore
		
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 2 1 0 0 0 0
	preserve
	duplicates drop t_F ln_GDP, force
		#delim ; 
		twoway (scatter t_F ln_GDP, `dots') 
		(lfit t_F ln_GDP, lcolor(red)) ,  legend(off) 
		`xtitle'  `xaxis'
		`ytitle'	`yaxis2'
		`graph_region_options' ;  
		graph export "$main/graphs/unfiorm_rates_G4.pdf" , replace 	; 
		#delim cr
		restore	

}	
	
	
	****************************************************************************************************************
	*	A2. rate differentiation, no PIT. 
	****************************************************************************************************************		
	
	*	Food_subsidy: central efficiency (1.5) 
	if `food_subsidy' { 
	qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0 0

	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
		local mean=round(`r(mean)', 0.01)	
		
		sum t_A t_F t_A_nf t_F_nf t_A_food t_F_food
		
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0.2(0.2)1.2, nogrid  labsize(`size'))  yline(1, lcolor(black) lw(medthick))  yline(0.2(0.2)1.2, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", size(`size') margin(medsmall) )"
		local xaxis "xlabel(5(1)10, labsize(`size'))"		
		local markerlabels "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
		
		preserve 
		duplicates drop y1 ln_GDP, force
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , `markerlabels') (lfit y1 ln_GDP, lcolor(green)) , 
		legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		/// title("All Varieties Taxed, with Efficiency Change") 
		name(graph_r3, replace) ;	
	
		
		graph export "$main/graphs/cross_country/fig7_A_$scenario.pdf", replace	;
		
		#delim cr
		restore
		
		preserve 
		duplicates drop y2 ln_GDP, force
		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, `markerlabels') (lfit y2 ln_GDP, lcolor(orange)) , 
		legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		/// title("Only Formal Varieties Taxed, with Efficiency Change")  
		name(graph_r4, replace) ;
		#delim cr	
		restore
		graph export "$main/graphs/cross_country/fig7_B_$scenario.pdf", replace	
		
	} 	
	
	
	
	* food_subsidy: vary efficiency 
	if `food_subsidy_robust' { 

		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0.2(0.2)1.2, nogrid  labsize(`size'))  yline(1, lcolor(black) lw(medthick))  yline(0.2(0.2)1.2, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", size(`size') margin(medsmall) )"
		local xaxis "xlabel(5(1)10, labsize(`size'))"		
		local markerlabels "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"	
	
		qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0 0

		cap drop y2
		gen y2= (t_F_food) / t_F_nf
		su y2, d
		local mean=round(`r(mean)', 0.01)	
		
		preserve
		duplicates drop y2 ln_GDP , force
		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, `markerlabels') (lfit y2 ln_GDP, lcolor(orange)) , 
		legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		name(graph_r1, replace) ;
		#delim cr
		restore
		
		graph export "$main/graphs/cross_country/food_subsidy_e15_$scenario.pdf", replace	
		
		qui optimal_tax_pit central 1 11 0 0 1 1 0.7 0 1 0 0 0 0 0

		cap drop y2
		gen y2= (t_F_food) / t_F_nf
		su y2, d
		local mean=round(`r(mean)', 0.01)	
		
		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, `markerlabels') (lfit y2 ln_GDP, lcolor(orange)) , 
		legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		name(graph_r2, replace) ;
		#delim cr	
		
		graph export "$main/graphs/cross_country/food_subsidy_e00_$scenario.pdf", replace			
		
		qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1 1 0 0 0 0 0

		cap drop y2
		gen y2= (t_F_food) / t_F_nf
		su y2, d
		local mean=round(`r(mean)', 0.01)	
		
		preserve
		duplicates drop y2 ln_GDP , force
		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, `markerlabels') (lfit y2 ln_GDP, lcolor(orange)) , 
		legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		name(graph_r3, replace) ;
		#delim cr	
		
		graph export "$main/graphs/cross_country/food_subsidy_e10_$scenario.pdf", replace			
		restore 
		
		
		qui optimal_tax_pit central 1 11 0 0 1 1 0.7 2 1 0 0 0 0 0
		
		
		cap drop y2
		gen y2= (t_F_food) / t_F_nf
		su y2, d
		local mean=round(`r(mean)', 0.01)	
		
		preserve
		duplicates drop y2 ln_GDP , force
		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, `markerlabels') (lfit y2 ln_GDP, lcolor(orange)) , 
		legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		name(graph_r4, replace) ;
		#delim cr	
	 
		
		graph export "$main/graphs/cross_country/food_subsidy_e20_$scenario.pdf", replace		
		restore
	} 		
	
	
	****************************************************************************************************************
	
	*	B. Optimal Tax Rates, interaction with PIT 
	
	****************************************************************************************************************
	
	

*B. With PIT	
*GRAPH IN PAPER
	*Fig a13

{
			local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local yaxis "ylabel(, nogrid  labsize(`size'))   yline(, lstyle(minor_grid) lcolor(gs1))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		*local xaxis "xlabel(0(1)14,  labsize(`size')) xscale(range(7.5 14.5))"


qui optimal_tax_pit central 1 11 0 0 1 0 0.7 1.5 1 0 0 0 1
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  
		`xaxis'
		ylabel(0.3(0.1)0.6, nogrid  labsize(`size'))   yline(0.3(0.1)0.6, lstyle(minor_grid) lcolor(gs1))
		ytitle("Tax Rate", margin(medsmall) size(`size')) 
		xtitle("Log GDP per capita, Constant 2010 USD")
		`graph_region_options'
		saving(graph_r1, replace) ; 
		#delim cr
gr export "$main/graphs/calibration/G1_pit.pdf", replace	as(pdf) 	
	
qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 1
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  
		`xaxis'
		ylabel(0.1(0.05)0.25, nogrid  labsize(`size'))   yline(0.1(0.05)0.25, lstyle(minor_grid) lcolor(gs1))
		ytitle("Tax Rate", margin(medsmall) size(`size')) 
		xtitle("Log GDP per capita, Constant 2010 USD")
		`graph_region_options'
		saving(graph_r2, replace) ; 
		#delim cr
gr export "$main/graphs/calibration/G2_pit.pdf", replace	as(pdf) 	
	
qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1 1 0 0 0 1
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'  
		`xaxis'
		ylabel(0.1(0.05)0.25, nogrid  labsize(`size'))   yline(0.1(0.05)0.25, lstyle(minor_grid) lcolor(gs1))
		ytitle("Tax Rate", margin(medsmall) size(`size')) 
	xtitle("Log GDP per capita, Constant 2010 USD")
		`graph_region_options'
		saving(graph_r3, replace) ; 
		#delim cr
gr export "$main/graphs/calibration/G3_pit.pdf", replace	as(pdf) 	
	
qui optimal_tax_pit central 1 11 0 0 1 1 0.7 2 1 0 0 0 1
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) ,  legend(off) 
		`xtitle'  
		`xaxis'
		ylabel(0.1(0.05)0.25, nogrid  labsize(`size'))   yline(0.1(0.05)0.25, lstyle(minor_grid) lcolor(gs1))
		ytitle("Tax Rate", margin(medsmall) size(`size')) 
xtitle("Log GDP per capita, Constant 2010 USD")
		`graph_region_options'
		saving(graph_r4, replace) ; 
		#delim cr
gr export "$main/graphs/calibration/G4_pit.pdf", replace	as(pdf) 	
			

}
gr combine graph_r1.gph graph_r2.gph   graph_r3.gph graph_r4.gph, col(2)    iscale(0.5)  ///
	graphregion(color(white)) title("Figure A13 with new data & PIT") 
gr export "$main/graphs/calibration/Figa13_newdata_10_12_pit.pdf", replace	as(pdf) 	

*GRAPH IN PAPER
	*Fig 7

{
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0(0.2)1.2, nogrid  labsize(`size'))  yline(1, lcolor(black) lw(medthick))  yline(0(0.2)1.2, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", size(`size') margin(medsmall) )"
		*local xaxis "xlabel(5(1)10, labsize(`size'))"	

qui optimal_tax_pit central 1 11 0 0 1 0 0.7 1.5 1 0 0 0 1
drop if missing(mtr)
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
	
		
		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(green)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		saving(graph_r1, replace) ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r1_pit.pdf", replace	as(pdf) 
				su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(orange)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'   
		saving(graph_r2, replace) ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r2_pit.pdf", replace	as(pdf) 

qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 0 1
drop if missing(mtr)
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 
			
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(green)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		saving(graph_r3, replace) ;
		#delim cr	
			gr export "$main/graphs/calibration/graph_r3_pit.pdf", replace	as(pdf) 

		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(orange)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		saving(graph_r4, replace) ;
		#delim cr	
				gr export "$main/graphs/calibration/graph_r4_pit.pdf", replace	as(pdf) 

}
gr combine graph_r1.gph graph_r2.gph   graph_r3.gph graph_r4.gph, col(2)  ycommon  iscale(0.5)  ///
	graphregion(color(white)) title("Figure 7 with new data & PIT") 
gr export "$main/graphs/calibration/Fig7_newdata_10_12_pit.pdf", replace	as(pdf) 


*C. Intermediate checks
qui optimal_tax_pit central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 1
	*Change in disposable income
bys decile: su dy_pit	 // 0 up to decile 6, up -10.5% in decile 10
bys percentile: su dy_pit	 if  decile==10 // from -6% to -18%

cap drop x
bys country: egen x=mean(dy_pit)
tw scatter x size_pit , saving(graph1, replace) ytitle("Average % change in y due to PIT") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x mtr , saving(graph2, replace) ytitle("Average % change in y due to PIT") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x ln_GDP , saving(graph3, replace) ytitle("Average % change in y due to PIT") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
gr combine graph1.gph graph2.gph graph3.gph   , row(2)   iscale(0.5)  ///
	graphregion(color(white))  title("Average change in y due to PIT")
gr export "$main/graphs/calibration/change_y_pit.pdf", replace	as(pdf) //threshold matters, MTR not so much - as expected

cap drop x
bys country: egen x=mean(dy_pit) if decile==10
tw scatter x size_pit , saving(graph1, replace) ytitle("Average % change in y due to PIT") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x mtr , saving(graph2, replace) ytitle("Average % change in y due to PIT") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x ln_GDP , saving(graph3, replace) ytitle("Average % change in y due to PIT") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
gr combine graph1.gph graph2.gph graph3.gph   , row(2)   iscale(0.5)  ///
	graphregion(color(white))  title("Average change in y due to PIT  - top 10%")
gr export "$main/graphs/calibration/change_y_pit_top10.pdf", replace	as(pdf) 


	*Change in phi [expect i) phi to fall at the top, increase at the bottom ii) the more so the higher size_pit]

su phi_pre_pit phi
bys decile: su phi_pre_pit phi // new phi only higher frmo decile 9 onwards

bys decile: su phi_pre_pit phi if country_c=="ZA" 
bys decile: su phi_pre_pit phi if country_c=="TZ" //phi falls a lot more at the top in ZA than in TZ

	*Change in budget shares
*Expect: budget shares at the top to fall when eta>1, increase otherwise. 
	*no change at the bottom:
foreach v in F I A_food A_nf F_food F_nf {
su share_`v'_pre_pit if decile==1
su share_`v' if decile==1
}

	*change at the top:
foreach v in F I A_food A_nf F_food F_nf {
su eta_`v'
su share_`v'_pre_pit if decile==10
su share_`v' if decile==10
}

	*change in aggregate
foreach v in F I A_food A_nf F_food F_nf {
su eta_`v'
su s_`v'_pre_pit if decile==10
su s_`v' if decile==10
}

*Graph: change in formal budget share
cap drop x*
bys decile: egen x=mean(share_F) 
bys decile: egen x1=mean(share_F_pre_pit) 
bys decile: gen x2=_n
tw scatter x1 decile || scatter x decile , saving(graph1, replace) ytitle("Share formal")  graphregion(color(white))  ///
legend(order(1 "No PIT" 2 "With PIT")) title("Average across all")
cap drop x*
bys decile: egen x=mean(share_F) if country_c=="ZA"
bys decile: egen x1=mean(share_F_pre_pit) if country_c=="ZA"
bys decile: gen x2=_n
tw scatter x1 decile|| scatter x decile , saving(graph2, replace) ytitle("Share formal")  graphregion(color(white))  ///
legend(order(1 "No PIT" 2 "With PIT")) title("ZA")
gr combine graph1.gph graph2.gph, row(2) colfirst   iscale(0.5)  ///
	graphregion(color(white)) title("Change in IEC with PIT") 
gr export "$main/graphs/calibration/IEC_change_pit.pdf", replace	as(pdf) // PIT decreases income at the top, which in turn decreases s_F (because eta_F>1) - in ZA this actually leads to 'flattening' out of IEC as the top
	
cap drop x*
gen x1=(share_F-share_F_pre_pit) if decile==10
bys country: egen x=mean(x1) if decile==10
tw scatter x size_pit , saving(graph1, replace) ytitle("Change in s_F (pct pt) in top 10") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x mtr , saving(graph2, replace) ytitle("Change in s_F (pct pt) in top 10") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x ln_GDP , saving(graph3, replace) ytitle("Change in s_F (pct pt) in top 10") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
gr combine graph1.gph graph2.gph graph3.gph   , row(2)   iscale(0.5)  ///
	graphregion(color(white))  title("Change in s_F in top 10 because of PIT")
gr export "$main/graphs/calibration/change_share_F_top10.pdf", replace	as(pdf) 

	
cap drop x*
gen x1=(s_F-s_F_pre_pit) 
bys country: egen x=mean(x1)
tw scatter x size_pit , saving(graph1, replace) ytitle("Change in aggregate s_F (pct pt)") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x mtr , saving(graph2, replace) ytitle("Change in aggregate s_F (pct pt)") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
tw scatter x ln_GDP , saving(graph3, replace) ytitle("Change in aggregate s_F (pct pt)") mlabel(country_code) graphregion(color(white)) mlabsize(2.5)
gr combine graph1.gph graph2.gph graph3.gph   , row(2)   iscale(0.5)  ///
	graphregion(color(white))  title("Change in aggregate s_F because of PIT")
gr export "$main/graphs/calibration/change_s_F.pdf", replace	as(pdf) 
	
	
	*Change in g
cap drop x
gen x=(g-cg)/cg
tw scatter x size_pit if decile==10 , saving(graph1, replace) ytitle("% change in g of top decile") mlabel(country_code) graphregion(color(white)) 
tw scatter x mtr if decile==10 , saving(graph2, replace) ytitle("% change in g of top decile") mlabel(country_code) graphregion(color(white)) 
tw scatter x ln_GDP if decile==10 , saving(graph3, replace) ytitle("% change in g of top decile") mlabel(country_code) graphregion(color(white)) 
gr combine graph1.gph graph2.gph   graph3.gph , row(2)  ycommon  iscale(0.5)  ///
	graphregion(color(white)) title("Change in g in top decile due to PIT") 
gr export "$main/graphs/calibration/gtop10_pit.pdf", replace	as(pdf) 
	
*where does the variation come from	? seems to be due to the fact that we divide by y^2 to get the new g, which is a bit odd
su a_par if country=="TN"
su a_par if country=="ZA"
	
	
*GRAPH IN PAPER	Appendix E.1
cap drop x
gen x=(t_F-t_F_pre_pit)
gen size_pit_reversed= 100-size_pit

	sum x // Number in paper for average change in tax rates  


local size med
local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
*local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
local yaxis "ylabel(-0.04(0.01)0, nogrid  labsize(`size'))   yline(-0.04(0.01)0, lstyle(minor_grid) lcolor(gs1))"
local ytitle "ytitle("Change in Tax Rate", size(`size') margin(medsmall))"
local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"


preserve
duplicates drop x size_pit_reversed, force
#delim ; 
tw scatter x size_pit_reversed, `dots' 
 xtitle("% of Households Above Income Tax Threshold", margin(medsmall) size(`size')) xlabel(0(10)50, labsize(`size')) 
 `ytitle'
 `yaxis'
`graph_region_options'
 `mlabel' 
 saving(graph1, replace) ;
 #delim cr	
gr export "$main/graphs/calibration/e1_threshold.pdf", replace	as(pdf) 
restore

preserve
duplicates drop x mtr, force			
#delim ; 
tw scatter x mtr , `dots'
 xtitle("Top Personal Income Tax Rate", margin(medsmall) size(`size')) xlabel(10(10)50, labsize(`size')) 
 `ytitle'
 `yaxis'
`graph_region_options'
 `mlabel' 
 saving(graph2, replace) ;
 #delim cr	
gr export "$main/graphs/calibration/e1_top.pdf", replace	as(pdf) 
restore

preserve
duplicates drop x ln_GDP, force
#delim ;  
tw scatter x ln_GDP, `dots'
 xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size')) xlabel(5(1)10, labsize(`size')) 
 `ytitle'
 `yaxis'
`graph_region_options'
 `mlabel' 
 saving(graph3, replace) ;
 #delim cr	
gr export "$main/graphs/calibration/e1_gdp.pdf", replace	as(pdf) 
restore

			
			

	
		
			
		*Change in rate diff
su t_F_food t_F_food_pre_pit  
su t_F_nf t_F_nf_pre_pit 

cap drop x*
gen x1=t_F_food/t_F_nf
gen x2=t_F_food_pre_pit/t_F_nf_pre_pit
su x2,  d
su x1, d  // very slight increase in relative rate on food overall

gen x=(x1-x2)/x2
su x, d //mostly increases, effects are tiny

tw scatter x size_pit if ~missing(mtr) , saving(graph1, replace) ytitle("Average % change in ratio due to PIT") mlabel(country_code) graphregion(color(white)) 
tw scatter x ln_GDP if ~missing(mtr) , saving(graph2, replace) ytitle("Average % change in ratio due to PIT") mlabel(country_code) graphregion(color(white)) 

gr combine graph1.gph graph2.gph    , row(2) colfirst ycommon  iscale(0.5)  ///
	graphregion(color(white)) title("Change in t_food/t_nf, with inf sector") 
gr export "$main/graphs/calibration/rate_diff_pit.pdf", replace	as(pdf) 

		*Change in rate diff, no informal sector
su t_A_food t_A_food_pre_pit  
su t_A_nf t_A_nf_pre_pit 

cap drop x*
gen x1=t_A_food/t_A_nf
gen x2=t_A_food_pre_pit/t_A_nf_pre_pit
su x2,  d
su x1, d  // very slight increase in relative rate on food overall

gen x=(x1-x2)/x2
su x, d //mostly increases, effects are tiny

tw scatter x size_pit if ~missing(mtr) , saving(graph1, replace) ytitle("Average % change in ratio due to PIT") mlabel(country_code) graphregion(color(white)) 
tw scatter x ln_GDP if ~missing(mtr) , saving(graph2, replace) ytitle("Average % change in ratio due to PIT") mlabel(country_code) graphregion(color(white)) 

gr combine graph1.gph graph2.gph    , row(2) colfirst ycommon  iscale(0.5)  ///
	graphregion(color(white)) title("Change in t_food/t_nf, no inf sector") 
gr export "$main/graphs/calibration/rate_diff_pit_noinf.pdf", replace	as(pdf) 



