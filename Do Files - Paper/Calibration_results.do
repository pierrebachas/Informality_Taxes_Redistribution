	****************************************************************************************************************
	
	/*
		1: scenario used to construct the dataset (central/robust/proba)
		
		*** Government Preferences:
		
		2: government preferences 1=welfarist (baseline), 2=poverty-averse
		3: government preference, if welfarist relative weight on bottom decile compared to top (Decreases by linear steps across deciles)
		4: government preferences, if poverty averse: decile above which household is considered non-poor (baseline - set to 0)
		5: government preferences, if povery averse: welfare weight of poor relative to non-poor (default is 2) (baseline - set to 0)
		6: value of public funds, set mu=`5' times the average welfare weight (baseline is 1)
		
		*** Structural Parameters: 
		7: Fix uncompensated price elasticites endogeneously (0,1). If 1: need to determine 8 and 9. if 0: need to determine 10
		8: value of price compensated own price elasticity (baseline = 0.5)	
		9: value of elasticity of compensated elasticity of substitution formal vs informal (baseline = 1.5)						
		10: Value chosen for all uncompensated elasticities if fixed exogenously (baseline needs to be set to baseline of 8 for consistency)
		
		*** Extensions:  	
		[For Removing Inequality] 
		11: =1 if remove inequalities in total expenditure (baseline), 0 otherwise	
		[for varying saving rates]
		12: savings_rate drops by that amount between decile  (baseline=0, when include savings =0.01)
		[for VAT on inputs]
		13: passthrough of taxes on informal prices (baseline =0, when include VAT on inputs for now 0.07)*
		
	*/
	****************************************************************************************************************
		
	
	****************************************************************************************************************
	
	*A. RUN THE PROGRAM FOR DIFFERENT SCENARIOS
	
	****************************************************************************************************************
	
	** Run the program once such that it is loaded in memory	
	cap log close
	clear all
	set more off
	do "$main/dofiles/optimal_tax_program.do"		
	
	********************************************************
	*BASELINE - NO EFFICIENCY 
	********************************************************
	
	set trace on
	qui optimal_tax central 1 10 0 0 1 0 0.7 1.5 1 0 0 0	
	
	su t_A t_F , d		
	
	*Uniform rate graph
	
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local yaxis "ylabel(0.2(0.05)0.6, nogrid  labsize(`size'))  yline(0.2(0.05)0.6, lstyle(minor_grid) lcolor(gs1))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		local ytitle "ytitle("Optimal Uniform Rate", margin(medsmall) size(`size'))"
		
		*local xaxis "xlabel(0(1)14,  labsize(`size')) xscale(range(7.5 14.5))"
		#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5)) 
		(lfit t_F ln_GDP, lcolor(red)) ,saving(G1, replace) legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		`ytitle' 
		title("No Efficiency Considerations", margin(medsmall) size(`size'))
		`graph_region_options'
		name(G1, replace) ; 
		
		#delim cr
	
	*Rate diff graph	
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
	
		
		local size medsmall
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0(0.2)1.4, nogrid  labsize(`size'))  yline(1, lcolor(black) lw(medthick))  yline(0(0.2)1.4, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", size(`size') margin(medsmall) )"
		local xaxis "xlabel(5(1)10, labsize(`size'))"	

	
		
		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(orange)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("All Varieties Taxed, No Efficiency Change") 
		saving(graph_r1, replace) ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r1.pdf", replace	as(pdf) 
		
		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(green)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("Only Formal Varieties Taxed, No Efficiency Change")  
		saving(graph_r2, replace) ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r2.pdf", replace	as(pdf) 

	
	********************************************************
	*BASELINE - WITH EFFICIENCY, epsilon_tilde=1.5
	********************************************************
	qui optimal_tax central 1 10 0 0 1 1 0.5 1.5 1 0 0 0	
	su t_A t_F, d
	
	*Uniform rate graph 
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local yaxis "ylabel(0.05(0.05)0.3, nogrid  labsize(`size'))   yline(0.05(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		*local xaxis "xlabel(0(1)14,  labsize(`size')) xscale(range(7.5 14.5))"
			#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) ,saving(G2, replace) legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		ytitle("Optimal Uniform Rate", margin(medsmall) size(`size')) 
		//title("Cross price elasticity = 1.5")
		`graph_region_options'
		name(G2, replace) ; 
		#delim cr
		gr export "$main/graphs/calibration/G2.pdf", replace	as(pdf) 

		
	*Rate diff graph
	qui optimal_tax central 1 10 0 0 1 1 0.5 1.5 1 0 0 0	
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
	
		
		local size medsmall
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0(0.2)1.4, nogrid  labsize(`size'))  yline(1, lcolor(black) lw(medthick))  yline(0(0.2)1.4, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", margin(medsmall) size(`size') )"
	

		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(orange)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("All Varieties Taxed, With Efficiency Change") 
		saving(graph_r3, replace) ;
		#delim cr	

		gr export "$main/graphs/calibration/graph_r3.pdf", replace	as(pdf) 

		su y2 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	

		twoway (scatter y2 ln_GDP, msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(green)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("Only Formal Varieties Taxed, With Efficiency Change")  
		saving(graph_r4, replace)  ;
		#delim cr	
		
		gr export "$main/graphs/calibration/graph_r4.pdf", replace	as(pdf) 

		su y2 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ;
		twoway (scatter y2 ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("Only Formal Varieties Taxed, Cross price elasticity = 1.5")  
		saving(graph_r40, replace)  ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r40.pdf", replace	as(pdf) 


	
	********************************************************
	*ROBUST - WITH EFFICIENCY, epsilon_tilde=2
	********************************************************
	
	qui optimal_tax central 1 10 0 0 1 1 0.5 2 1 0 0 0
	su t_A t_F, d
	*Uniform rate graph 
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local yaxis "ylabel(0.05(0.05)0.3, nogrid  labsize(`size'))   yline(0.05(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		*local xaxis "xlabel(0(1)14,  labsize(`size')) xscale(range(7.5 14.5))"
			#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) ,saving(G3, replace) legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		ytitle("Optimal Uniform Rate", margin(medsmall) size(`size')) //title("Cross price elasticity = 2")
		`graph_region_options'
		name(G3, replace) ; 
		#delim cr
		gr export "$main/graphs/calibration/G3.pdf", replace	as(pdf) 
	
	*Rate diff graph
	qui optimal_tax central 1 10 0 0 1 1 0.5 2 1 0 0 0
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
	
		
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0(0.2)1.6, nogrid  labsize(`size'))  yline(1, lcolor(black))  yline(0(0.2)1.6, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate",  margin(medsmall) size(`size') )"
		
		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		title("All Varieties Taxed, Cross price elasticity = 2") 
		saving(graph_r5, replace)  ;
		su y2 , d;
		local mean=round(`r(mean)', 0.01);	
		twoway (scatter y2 ln_GDP,msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		// title("Only Formal Varieties Taxed, Cross price elasticity = 2")  
		saving(graph_r6, replace)  ;
		#delim cr
		gr export "$main/graphs/calibration/graph_r6.pdf", replace	as(pdf) 

	
	
	********************************************************
	*ROBUST - WITH EFFICIENCY, epsilon_tilde=1
	********************************************************
	qui optimal_tax central 1 10 0 0 1 1 0.5 1 1 0 0 0
	su t_A t_F, d
	*Uniform rate graph 
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local yaxis "ylabel(0.05(0.05)0.3, nogrid  labsize(`size'))   yline(0.05(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
		*local xaxis "xlabel(0(1)14,  labsize(`size')) xscale(range(7.5 14.5))"
			#delim ; 
		twoway (scatter t_F ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)) 
		(lfit t_F ln_GDP, lcolor(red)) ,saving(G4, replace) legend(off) 
		`xtitle'  
		`xaxis'
		`yaxis'
		ytitle("Optimal Uniform Rate" , margin(medsmall) size(`size')) //title("Cross price elasticity = 1")
		`graph_region_options'
		name(G4, replace) ; 
		#delim cr
		gr export "$main/graphs/calibration/G4.pdf", replace	as(pdf) 

	
	
	*Rate diff graph
	qui optimal_tax central 1 10 0 0 1 1 0.5 1 1 0 0 0
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
	
		
		local size med
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0(0.2)1.6, nogrid  labsize(`size'))  yline(1, lcolor(black))  yline(0(0.2)1.6, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", margin(medsmall) size(`size') )"
		
		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		title("All Varieties Taxed, Cross price elasticity = 1") 
		saving(graph_r7, replace)  ;
		su y2 , d;
		local mean=round(`r(mean)', 0.01);	
		twoway (scatter y2 ln_GDP, msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(red)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		// title("Only Formal Varieties Taxed, Cross price elasticity = 1")  
		saving(graph_r8, replace)  ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r8.pdf", replace	as(pdf) 

	
	
	********************************************************
	*BASELINE - NO EFFICIENCY, without INEQ
	********************************************************
	qui optimal_tax central 1 10 0 0 1 0 0.5 1.5 1 1 0 0	
	su t_A t_F, d
	
	
*Rate diff graph	
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
	
		
		local size medsmall
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0(0.2)1.4, nogrid  labsize(`size'))  yline(1, lcolor(black) lw(medthick))  yline(0(0.2)1.4, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", size(`size') margin(medsmall) )"
		local xaxis "xlabel(5(1)10, labsize(`size'))"	

	
		
		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(orange)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("All Varieties Taxed, No Efficiency Change") 
		saving(graph_r1, replace) ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r1_noineq.pdf", replace	as(pdf) 
		
		su y2 , d
		local mean=round(`r(mean)', 0.01)
		#delim ;	
		twoway (scatter y2 ln_GDP, msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(green)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("Only Formal Varieties Taxed, No Efficiency Change")  
		saving(graph_r2, replace) ;
		#delim cr	
		gr export "$main/graphs/calibration/graph_r2_noineq.pdf", replace	as(pdf) 
		
		********************************************************
	*BASELINE - WITH EFFICIENCY, epsilon_tilde=1.5, without ineq
	********************************************************
	qui optimal_tax central 1 10 0 0 1 1 0.5 1.5 1 1 0 0	
	su t_A t_F, d
	
			
	*Rate diff graph
	qui optimal_tax central 1 10 0 0 1 1 0.5 1.5 1 0 0 0	
	cap drop y1
	cap drop y2
		gen y1 = (t_A_food) / t_A_nf
		gen y2= (t_F_food) / t_F_nf
		su y1, d
		su y2, d
	
		
		local size medsmall
		local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
		local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))"
		local yaxis "ylabel(0(0.2)1.4, nogrid  labsize(`size'))  yline(1, lcolor(black) lw(medthick))  yline(0(0.2)1.4, lstyle(minor_grid) lcolor(gs1))"
		local ytitle "ytitle("Ratio Food Rate / Non Food Rate", margin(medsmall) size(`size') )"
	

		su y1 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	
		
		twoway (scatter y1 ln_GDP , msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y1 ln_GDP, lcolor(orange)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("All Varieties Taxed, With Efficiency Change") 
		saving(graph_r3, replace) ;
		#delim cr	

		gr export "$main/graphs/calibration/graph_r3_noineq.pdf", replace	as(pdf) 

		su y2 , d
		local mean=round(`r(mean)', 0.01)	
		#delim ; 	

		twoway (scatter y2 ln_GDP, msize(vsmall) color(black) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5))
		(lfit y2 ln_GDP, lcolor(green)) , legend(off) 
		`xtitle'
		`xaxis' 
		`yaxis' 
		`ytitle'
		`graph_region_options'  
		//title("Only Formal Varieties Taxed, With Efficiency Change")  
		saving(graph_r4, replace)  ;
		#delim cr	
		
		gr export "$main/graphs/calibration/graph_r4_noineq.pdf", replace	as(pdf) 

		
	
	****************************************************************************************************************
	
	*B. OUTPUTS
	
	****************************************************************************************************************
	
	
	
	*1. Uniform rates - equity 
	
	gr combine G1.gph, row(1) graphregion(color(white)) 
	gr export "$main/graphs/calibration/uniform_rates_equity.pdf", replace	as(pdf) 
	
	*2. Uniform rate - efficiency
	
	gr combine G2.gph G3.gph G4.gph, row(2) ycommon xcommon iscale(0.5) colfirst ///
	graphregion(color(white)) 
	gr export "$main/graphs/calibration/uniform_rates_efficiency.pdf", replace	as(pdf) 
	
	*3. Rate diff
	
	
	gr combine graph_r1.gph graph_r2.gph graph_r3.gph graph_r4.gph , row(2)  ycommon xcommon iscale(0.5) colfirst ///
	graphregion(color(white)) 
	gr export "$main/graphs/calibration/rate_diff.pdf", replace	as(pdf) 
		
	
	 
	gr combine  graph_r40.gph graph_r6.gph graph_r8.gph , row(2)  ycommon xcommon iscale(0.45) colfirst ///
	graphregion(color(white)) 
	gr export "$main/graphs/calibration/rate_diff_robust.pdf", replace	as(pdf) 
		
