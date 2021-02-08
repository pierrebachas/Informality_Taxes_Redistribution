
***************************************************
**PRELIMINARIES**
***************************************************
		
	clear all 
	set more off
	cap log close
	global scenario = "central"			// Choose scenario to be run: central, proba, robust, specific	
	display "$scenario"


	set more off
	do "$main/dofiles/Optimal_tax_program_COICOP12.do" 	
	optimal_tax_COICOP12 central 1 11 0 0 1 1 0.7 1.5 1 0 0 0 1	
	matrix redist = J(4,3,.) 	

	bys country: keep if _n==1
	sort country	
		
	* Save only needed info
	keep country t_A* t_F* s_F* s_A*

	reshape long t_F_COICOP t_A_COICOP s_F_COICOP s_A_COICOP , i(country_code) j(COICOP)
	
	*** Stats of interest: 
	tabstat t_F_COICOP [aweight=s_F_COICOP], save	by(country_code) statistics(mean sd) 
	mat results = J(32,2,.)
	forvalues i = 1(1)32 { 
		matrix A = r(Stat`i')
		mat list A
		matrix results[`i',1]	= A[1,1]
		matrix results[`i',2]	= A[2,1]
		} 
	
	mat list results
	
	egen tag = tag(country_code)
	keep if tag == 1
	
	svmat results
	rename results1  mean 
	rename results2  sd
	gen coef_var = sd / mean 
	
	* prep GDP data 
	preserve 

	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	
	rename Year year
	
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	save `gdp_data'	
	
	restore 
	
	merge m:1 country_code using `gdp_data'
	gen ln_GDP = log(GDP_pc_constantUS2010)
	
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local ytitle "ytitle("Standard Deviation of Tax Rates" , margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(0.1)0.6, nogrid labsize(`size')) yscale(range(0 0.6)) yline(0(0.1)0.6, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local dots "msize(vsmall) color(gs1) mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)"
		
	#delim ; 
		
	twoway (scatter coef_var ln_GDP, `dots')  (lfit coef_var ln_GDP) ,
	`yaxis' `ytitle' 
	`xaxis' `xtitle'
	`graph_region_options'
	legend(off)
	name(G_uniform, replace)  ; 
	graph export "$main/graphs/CoefVar_COICOP12.eps" , replace 	 ; 
	
	
	#delim cr
	
	
	
	
	
	
	
	
	
	
			
