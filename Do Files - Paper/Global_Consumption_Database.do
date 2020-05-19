
					*************************************
					* 			DO FILE 				*
					*    Global Consumption Database	*
					*************************************	
***************************
* PRELIMINARIES *
***************************	

	set more off
	clear all 
	cap log close
						
***************************
* CONTROL CENTER *
***************************					
	
	local append_GCD 		= 0
	local gdp	     		= 0
	local gcd        		= 0
	local data_prep  		= 0
	local graph_food_share  = 1
	local graph_slope 		= 1
					 		
******************************
* 0.1. Append the GCD datafiles 
******************************
	if `append_GCD' { 

	*Append all the files sent by the GCD team - Stat by decile	
	
		clear all
		cd "$main/data/Global_Consumption_Database/results_excluding_hhage_children"
		fs "*decile_stat.dta"
		append using `r(files)'
		save "$main/data/Global_Consumption_Database/results_excluding_hhage_children/decile_stat_excluding_hhage_children.dta" , replace //105 country 
		
		
		clear all
		cd "$main/data/Global_Consumption_Database/results_including_hhage_children"
		fs "*decile_stat.dta"
		append using `r(files)'
		
		save "$main/data/Global_Consumption_Database/results_including_hhage_children/decile_stat_including_hhage_children.dta" , replace //80 country 
		
	*Append all the files sent by the GCD team - Reg Coefficient
	cd "$main/data/Global_Consumption_Database/results_excluding_hhage_children"
	clear all
	local file_name "AFG ALB ARM BDI BEL BEN BFA BGD BGR BIH BLR BOL BTN CMR COD COG COL CPV CYP DNK ESP EST ETH FIN FJI FRA GAB GBR GEO GHA GIN GMB GRC GTM HND HRV HTI HUN IDN IND IRL IRQ ITA JAM KAZ KEN KGZ KHM KSV LAO LBR LKA LSO LTU LUX LVA MAR MDA MDG MDV MEX MKD MLI MLT MNE MNG MOZ MRT MUS MWI NAM NER NGA NIC NPL PAK PAN PER PHL POL PRY ROU RWA SEN SLE SLV SOM SRB SSD STP SVK SVN SWE SWZ TGO THA TJK TLS TUR TZA UGA UKR VNM ZAF ZMB" 
	local n_models : word count `file_name'	
	
	forval i=1/`n_models' {
		
	***************
	* GLOBALS	 *
	***************	
	global file_name `: word `i' of `file_name''		
	
	**********************
	* LOAD DATA	 *
	**********************	
	use "$main/data/Global_Consumption_Database/results_excluding_hhage_children/`: word `i' of `file_name''_reg_coeff.dta", clear
	gen country_corrected ="$file_name"
	save "$main/data/Global_Consumption_Database/results_excluding_hhage_children/adj_$file_name.dta", replace
	}
	
	fs "adj_*.dta"
	append using `r(files)'
	drop country 
	ren country_corrected country
	order country, first 
	duplicates drop country b , force
	save "$main/data/Global_Consumption_Database/results_excluding_hhage_children/reg_coeff_excluding_hhage_children.dta" , replace //105 country 
	
	cd "$main/data/Global_Consumption_Database/results_including_hhage_children"
	clear all
	local file_name "AFG ALB ARM BDI BEN BFA BGD BIH BLR BOL BTN CMR COD COG COL CPV ETH FJI GAB GEO GHA GIN GMB GTM HND HTI IDN IND IRQ JAM KAZ KEN KGZ KHM KSV LAO LBR LSO MAR MDA MDG MDV MEX MKD MLI MNE MNG MOZ MRT MUS MWI NER NGA NPL PAK PAN PER PHL POL PRY ROU RWA SLE SLV SOM SRB SSD STP SWZ TGO THA TJK TLS TUR TZA UGA UKR VNM ZAF ZMB" 
	local n_models : word count `file_name'	
	
	forval i=1/`n_models' {
		
	***************
	* GLOBALS	 *
	***************	
	global file_name `: word `i' of `file_name''		
	
	**********************
	* LOAD DTA	 *
	**********************	
	use "$main/data/Global_Consumption_Database/results_including_hhage_children/`: word `i' of `file_name''_reg_coeff.dta", clear
	gen country_corrected ="$file_name"
	save "$main/data/Global_Consumption_Database/results_including_hhage_children/adj_$file_name.dta", replace
	}
	
	fs "adj*.dta"
	append using `r(files)'
	drop country 
	ren country_corrected country
	order country, first 
	duplicates drop country b , force
	save "$main/data/Global_Consumption_Database/results_including_hhage_children/reg_coeff_including_hhage_children.dta" , replace //80 country 
	
	} 		// End of 0.Append the GCD datafiles 	
	
*************************************
* 0.2. Prepare dataset GDP to merge *
*************************************
 if `gdp' {
	
	clear 
	import excel "$main\tables\Global_Consumption_Database\Data_Extract_From_World_Development_Indicators.xlsx", sheet("GDP_capita") firstrow clear
	drop if country_fullname==""
	drop if country_3let==""
	duplicates drop
	merge 1:1 country_3let using "$main/tables/Global_Consumption_Database/code_country_correspondance.dta"
	keep if _merge==3 | country_fullname=="Comores" | country_fullname=="Chile" | country_fullname=="Costa Rica" |  country_3let=="DOM" | country_3let=="ECU" | country_3let=="TUN" | country_3let=="URY" | country_3let=="Dominican Republic" | country_3let=="PNG"
	drop _merge 
	ren GDP GDP_per_capita_constant_US_2010
	* Define  Log GDP per capita  (Note: use to be Log income in base 2, converted PPP USD) 
	destring GDP_per_capita_constant_US_2010 , replace force
	replace GDP_per_capita_constant_US_2010=	1657.5	 if country_fullname=="Bolivia"
	replace GDP_per_capita_constant_US_2010=	10538.8	 if country_fullname=="Brazil"
	replace GDP_per_capita_constant_US_2010=	562.8	 if country_fullname=="BurkinaFaso"
	replace GDP_per_capita_constant_US_2010=	244.1	 if country_fullname=="Burundi"
	replace GDP_per_capita_constant_US_2010=	300.8	 if country_fullname=="Congo, Dem. Rep."
	replace GDP_per_capita_constant_US_2010=	2503.3	 if country_fullname=="Congo, Rep."
	replace GDP_per_capita_constant_US_2010=	1428.2	 if country_fullname=="Cameroon"
	replace GDP_per_capita_constant_US_2010=	15059.5	 if country_fullname=="Chile"
	replace GDP_per_capita_constant_US_2010=	5910.3	 if country_fullname=="Colombia"
	replace GDP_per_capita_constant_US_2010=	9065	 if country_fullname=="Costa Rica"
	replace GDP_per_capita_constant_US_2010=	5121.1	 if country_3let=="DOM"
	replace GDP_per_capita_constant_US_2010=	5140.3	 if country_fullname=="Ecuador"
	replace GDP_per_capita_constant_US_2010=	4168.5	 if country_fullname=="Eswatini"
	replace GDP_per_capita_constant_US_2010=	2091.2	 if country_fullname=="Morocco"
	replace GDP_per_capita_constant_US_2010=	9536.6	 if country_fullname=="Mexico"
	replace GDP_per_capita_constant_US_2010=	404.6	 if country_fullname=="Mozambique"
	replace GDP_per_capita_constant_US_2010=	330.6	 if country_fullname=="Niger"
	replace GDP_per_capita_constant_US_2010=	2004.8	 if country_fullname=="Papua New Guinea"
	replace GDP_per_capita_constant_US_2010=	6172.7	 if country_fullname=="Peru"
	replace GDP_per_capita_constant_US_2010=	672.6	 if country_fullname=="Rwanda"
	replace GDP_per_capita_constant_US_2010=	1094.7	 if country_fullname=="Sao Tome and Principe"
	replace GDP_per_capita_constant_US_2010=	7416.7	 if country_fullname=="South Africa"
	replace GDP_per_capita_constant_US_2010=	747.7	 if country_fullname=="Tanzania"
	replace GDP_per_capita_constant_US_2010=	4142	 if country_fullname=="Tunisia"
	replace GDP_per_capita_constant_US_2010=	9068.2	 if country_fullname=="Uruguay"
	
	gen gdp_pp_2010 = log(GDP_per_capita_constant_US_2010)
	save "$main/tables/Global_Consumption_Database/GDP_capita.dta" , replace
 }

***************************************************************
* 0.3. Prepare the subset of countries from GCD we can use    *
***************************************************************
 if `gcd' {
		
	*Recreate the graphs 1/31 with total food/total expenditure with data coming from GCD website
	import delimited "$main/data/Global_Consumption_Database/GCD_website.csv", clear 

	ren consumptionsegment cons_seg
	ren country country_fullname
	ren localcurrency exp
	
	drop ïarea
	drop if cons_seg!="All"
	keep if sector=="All Sectors" | sector=="Food and Beverages"
	drop cons_seg
	replace sector="food" if sector=="Food and Beverages"
	replace sector="all" if sector=="All Sectors"
	reshape wide exp , i(country_fullname) j(sector) string
	
	replace country_fullname = "Bolivia (Plurinational State of)" in 9
	replace country_fullname = "Congo (the Democratic Republic of the)" in 48
	replace country_fullname = "Congo (the)" in 49
	replace country_fullname = "Eswatini" in 150
	replace country_fullname = "Gambia (the)" in 57
	replace country_fullname = "Kyrgyzstan" in 104
	replace country_fullname = "Lao People's Democratic Republic (the)" in 105
	replace country_fullname = "Niger (the)" in 126
	replace country_fullname = "Tanzania, United Republic of" in 152
	replace country_fullname = "Timor-Leste" in 154
	replace country_fullname = "Viet Nam" in 159
	replace country_fullname = "Philippines (the)" in 131
	replace country_fullname = "Moldova (the Republic of)" in 118
	replace country_fullname = "Republic of North Macedonia" in 110



	merge 1:m country_fullname using "$main/data/Global_Consumption_Database/reg_coeff_excluding_hhage_children_for_graph.dta"
	/*

    Result                           # of obs.
    -----------------------------------------
    not matched                           238
        from master                        82  (_merge==1)
        from using                        156  (_merge==2)

    matched                               474  (_merge==3)
    -----------------------------------------

  (_merge==1) // On the website but not in the data shared by Tefera (Brazil)
  (_merge==2) // Shared by Tefera but not in the website (mainly rich countries)  26
 

	*/
	tab country_fullname if _merge==2
	/*
	
									Country |      Freq.     Percent        Cum.
	----------------------------------------+-----------------------------------
									Belgium |          6        4.00        4.00
									Croatia |          6        4.00        8.00
									Cyprus |          6        4.00       12.00
									Denmark |          6        4.00       16.00
									Estonia |          6        4.00       20.00
									Finland |          6        4.00       24.00
									France |          6        4.00       28.00
									Georgia |          6        4.00       32.00
									Greece |          6        4.00       36.00
									Haiti |          6        4.00       40.00
									Hungary |          6        4.00       44.00
									Ireland |          6        4.00       48.00
									Italy |          6        4.00       52.00
								Luxembourg |          6        4.00       56.00
									Malta |          6        4.00       60.00
									Panama |          6        4.00       64.00
								Paraguay |          6        4.00       68.00
									Poland |          6        4.00       72.00
								Slovakia |          6        4.00       76.00
								Slovenia |          6        4.00       80.00
									Somalia |          6        4.00       84.00
								South Sudan |          6        4.00       88.00
									Spain |          6        4.00       92.00
									Sweden |          6        4.00       96.00
	United Kingdom of Great Britain and N.. |          6        4.00      100.00
	----------------------------------------+-----------------------------------
									Total |        150      100.00
	
	*/
	keep if _merge==3
	keep country_fullname expall expfood country_2let country_3let
	duplicates drop
	gen ratio_food_total=(expfood/expall)*100
	save "$main/data/Global_Consumption_Database/GCD_website_for_graph1.dta" , replace
	}
 
**************************************************************
* 1. Data Prep *
**************************************************************
	
	if `data_prep' { 
		
	
	//GRAPH 2//
	
	* Data from GCD
	clear all
	use "$main/data/Global_Consumption_Database/results_excluding_hhage_children/reg_coeff_excluding_hhage_children.dta" , clear 		//105 country
	* Drop unnecessary variables 
	keep if regression_nb==2 & b_sq==. // regression that match the one we did with the countries of the paper sample 
	keep country regression_nb b se
	
	* Rename the variables so that we can merge this file with the one containing the paper sample coef
	ren country country_3let
	ren regression_nb iteration
	ren b b_gcd
	ren se se_gcd
	
	* We need to merge the data from GCD with country_code 2 letters
	merge 1:1 country_3let using "$main/tables/Global_Consumption_Database/code_country_correspondance.dta" , gen(m_country_code)
	replace country_2let="XK" if country_3let=="KSV"
	drop if m_country_code==2
	drop m_country_code
	
	
	*We need to reduce the sample of GCD countries (we only take the one that appears in the website, so that we can compare the two graphs)
	merge 1:1 country_2let using "$main/data/Global_Consumption_Database/GCD_website_for_graph.dta" , gen(mgcd) keepusing(country_2let)
	keep if mgcd==3
	drop mgcd
	
	save "$main/data/Global_Consumption_Database/GCD_website_for_graph2.dta" , replace

	
	} 	// End of 1. Data Prep Loop 
	
**************************************************************
* 2. FIGURES  *
**************************************************************	

	if `graph_food_share' {
	*****************************************
	* Figure 4 - Panel (a) Share of Food	*
	*****************************************

	*The paper sample N=31
	use "$main/proc/Food_Consumption_Data.dta" , clear
	ren country_code country_2let
	keep if iteration == 2 
	
	*GCD reduced sample N=79 (21 countries overlap with our sample)
	merge 1:1 country_2let using "$main/data/Global_Consumption_Database/GCD_website_for_graph.dta" , gen (m_gcd_sample)
		/*
	
    Result                           # of obs.
    -----------------------------------------
    not matched                            68
        from master                        10  (m_gcd_sample==1)
        from using                         58  (m_gcd_sample==2)

    matched                                21  (m_gcd_sample==3)
    -----------------------------------------
	tab country_2let if  m_gcd_sample==1 // In our sample but not in GCD
	*/
	* GDP data 
	merge m:1 country_2let using "$main/tables/Global_Consumption_Database/GDP_capita.dta" 
	keep if _m == 3
	drop _m 
	
	* Identify the two samples
	gen IEC_sample = 0
	replace IEC_sample  = 1 if m_gcd_sample == 1 | m_gcd_sample == 3
	
	****  LOCALS *****
				
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(20)100, nogrid labsize(`size')) yscale(range(0 12)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(5(1)10, labsize(`size'))"					
	local ytitle "ytitle("Food Consumption (Share of Total)", margin(medsmall) size(`size'))"	
	
	*** FIGURES by iteration of the linear regressions 
	
	local fit lpoly 
	
	sum b gdp_pp_2010  if IEC_sample == 1
	sum ratio_food_total gdp_pp_2010 if IEC_sample == 0
	
	#delim ; 
	twoway (scatter b gdp_pp_2010 if IEC_sample == 1, mcolor(red) mlabel(country_2let))
		   (scatter ratio_food_total gdp_pp_2010 if  IEC_sample == 0 , mcolor(green)) , 
			title("Average Food Share") 
	legend(label(1 Levels IEC Sample) label(2 Levels GCD Only)) 
	`xtitle' 
	`graph_region_options' ; 	
	
	twoway (scatter b gdp_pp_2010 if  IEC_sample == 1, mcolor(blue) msize(vsmall) mlabel(country_2let))
	(scatter ratio_food_total gdp_pp_2010 if IEC_sample == 0 , mcolor(gray) msize(medsmall) msymbol(plus)) 
	(`fit' b gdp_pp_2010 if  IEC_sample == 1, color(blue))
	(`fit' ratio_food_total gdp_pp_2010 if IEC_sample == 0 , color(gray))  , 
	legend(order(1 "Core Sample" 2 "Extended Sample") pos(1) ring(0) col(1) ) 
	`xtitle' 
	`xaxis'
	`yaxis'
	`ytitle' 
	`graph_region_options' 
	name(G , replace)		; 	
	
	#delim cr	
	graph export "$main/graphs/Global_Consumption_Database/total_foodshare_all_countries_`fit'.pdf", replace  

	}
	
if `graph_slope' {
	***********************************************
	* Figure 4 - Panel (b) Food Consumption Slope *
	***********************************************

	*The paper sample N=31
	use "$main/proc/Food_Consumption_Data.dta" , clear
	ren country_code country_2let
	keep if iteration == 3 
	
	*GCD reduced sample N=79 (21 countries overlap with our sample)
	merge 1:1 country_2let using "$main/data/Global_Consumption_Database/GCD_website_for_graph2.dta" , gen (m_gcd_sample)
		/*
	
    Result                           # of obs.
    -----------------------------------------
    not matched                            68
        from master                        10  (m_gcd_sample==1)
        from using                         58  (m_gcd_sample==2)

    matched                                21  (m_gcd_sample==3)
    -----------------------------------------
 tab country_2let if  m_gcd_sample==1 // In our sample but not in GCD
*/

	* GDP data 
	merge m:1 country_2let using "$main/tables/Global_Consumption_Database/GDP_capita.dta" 
	keep if _m == 3
	drop _m 

	
	* Identify the two samples
	gen IEC_sample = 0
	replace IEC_sample  = 1 if m_gcd_sample == 1 | m_gcd_sample == 3
	
	****  LOCALS *****

	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis "ylabel(-25(5)5, nogrid labsize(`size')) yscale(range(-25 5)) yline(-25(5)5, lstyle(minor_grid) lcolor(gs1))" 	
	local ytitle "ytitle("Food Consumption Slope", margin(medsmall) size(`size'))"
	local xaxis "xlabel(5(1)10, labsize(`size'))"	
	local xscale "xscale(range(`bottom' `top'))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD ", margin(medsmall) size(`size'))" 
	local fit lpoly 
	
	*** FIGURES of the linear regressions 

	
	sum b gdp_pp_2010  if  IEC_sample == 1
	sum b_gcd gdp_pp_2010 if IEC_sample == 0
	
 	#delim ; 
	twoway (scatter b gdp_pp_2010 if  IEC_sample == 1, mcolor(red) msize(vsmall) mlabel(country_2let))
		   (scatter b_gcd gdp_pp_2010 if IEC_sample == 0 , mcolor(green)) , 
	legend(label(1 𝜷 IEC Sample) label(2 𝜷 GCD Only)) 
	yscale(range(0 15))
	
	`xtitle' 
	`graph_region_options' ; 	
	
	twoway (scatter b gdp_pp_2010 if IEC_sample == 1, mcolor(blue) msize(vsmall) mlabel(country_2let))
	(scatter b_gcd gdp_pp_2010 if IEC_sample == 0 , mcolor(gray) msize(medsmall)  msymbol(plus)) 
	(`fit' b gdp_pp_2010 if IEC_sample == 1, color(blue))
	(`fit' b_gcd gdp_pp_2010 if IEC_sample == 0 , color(gray))  ,  
	legend(order(1 "β Core Sample" 2 "β Extended Sample") pos(1) ring(0) col(1) ) 
	`xtitle' 
	`xaxis'
	`ytitle'
	`yaxis'
	`graph_region_options' 
	name(slope , replace)		; 	
	
	#delim cr	
	
	graph export "$main/graphs/Global_Consumption_Database/slope.pdf", replace
	
	} 
	
	
	
