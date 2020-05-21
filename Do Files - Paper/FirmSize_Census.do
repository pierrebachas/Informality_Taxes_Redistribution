
*****************************************
/* Graph of firm size by retailer type */
*****************************************

* Data Note: Data is from INEGI_import_tables_25_10_2018 on the Number of personnel by store stype, 
* merged dataset CPI-CE (January 2014)

	import excel "data.xlsx", clear firstrow sheet("Sheet2") 

	drop if data_source == "census" 
	replace store = "Street stall" if store == "Markets, Street" 
		
	
	local x = 0.2*VAT_payer_mean[3] + 0.8*VAT_payer_mean[4] 
	display `x'
	replace VAT_payer_mean = `x' if store == "Specialized Stores"
	
	drop if store == "Mini-Markets"
	drop if store == "Department Stores"
	
	* Add an observation for Self-Production
	set obs `=_N+1'
	count 
	replace store = "(1) Non-Market" in `r(N)'
	replace VAT_payer_mean = 0 in `r(N)'
	replace Number_employees_median = 0 in `r(N)' 
	
	gen log_median = log(Number_employees_median)

	** Rename the store categories to match our classification
	replace store = "(2) Non-Brick & Mortar" if store ==  "Markets, Tianguis"
	replace store = "(3) Convenience Stores" if store ==  "Convenience Stores"
	replace store = "(4) Specialized Stores" if store ==  "Specialized Stores"
	replace store = "(5) Large Stores" if store ==  "Supermarkets"	
	
	sort VAT_payer_mean
	
	
	* Locals for figures: 
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	
	* G1: log p50 number of employees in CPI-Census merged data
	
	#delim ; 
	graph hbar log_median, over(store, sort(VAT_payer_mean))
	ytitle("Log of Median Number of Employees", size(`size') margin(`size'))
	title("")	 
	text(0.3 91 "N.A.", color(navy))
	ylabel(0(1)5, labsize(`size') nogrid) yline(0(1)5, lstyle(minor_grid) lcolor(gs1))
	`graph_region_options' ; 
	
	graph export "p50Employee_size_CPICensus.pdf", replace	;	
	
	#delim cr 
	
	* G2: VAT payer by store type in CPI-Census merged data
	
	#delim ; 
	graph hbar VAT_payer_mean, over(store, sort(VAT_payer_mean))	
	ytitle("Share of Firms Reporting VAT Payments", size(`size') margin(`size'))
	title("")
	text(0.07 91 "N.A.", color(navy))
	ylabel(0(0.2)1, labsize(`size') nogrid) yline(0(0.2)1, lstyle(minor_grid) lcolor(gs1))
	`graph_region_options' ; 
	
	graph export "VATpayer_CPICensus.pdf", replace	;	
	
	#delim cr 
