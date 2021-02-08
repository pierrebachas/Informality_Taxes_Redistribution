

******************
* CONTROL CENTER *
******************

local gdp				=1 //import data on GDP
local iso_code			=0 //import country_2let
local vat_thresholds	=0
local euromonitor		=0
local graphs			=0
local table_appendix	=1


*******
* GDP *
*******

if `gdp'	{
import excel "$main/tables/cross_country/allcountry_info_00_20.xlsx", sheet("Data") firstrow clear

 
 *Taking GDP mean over the period 2014-2019
drop TimeCode
ren Time year
ren CountryName country_fullname
ren CountryCode country_3let
drop if country_3let==""

*for now we keep


ren GDPpercapitaconstant2010US gdp_pc_
ren Consumerpriceindex2010100 cpi_
ren PopulationtotalSPPOPTOTL pop_
ren DECalternativeconversionfacto conversion_dec_
ren PPPconversionfactorGDPLCU conversion_gdp_
ren PPPconversionfactorprivatec conversion_conso_
ren PricelevelratioofPPPconvers conversion_price
ren Inflationconsumerpricesannu inflation_

reshape wide gdp_pc_ conversion_gdp_ pop_ conversion_dec_ conversion_conso_ conversion_price inflation_ cpi_ , i(country*) j(year) 

destring gdp_pc_2002- cpi_2020, force replace

egen pop_14_19=rowmean(pop_2014 pop_2015 pop_2016 pop_2017 pop_2018 pop_2019)	
egen gdp_pc_14_19=rowmean(gdp_pc_2014 gdp_pc_2015 gdp_pc_2016 gdp_pc_2017 gdp_pc_2018 gdp_pc_2019)	
egen conversion_rate_14_19=rowmean(conversion_dec_2014 conversion_dec_2015 conversion_dec_2016 conversion_dec_2017 conversion_dec_2018 conversion_dec_2019)	

replace country_fullname="Bahamas" if country_fullname=="Bahamas, The"
replace country_fullname="Congo, Democratic Republic" if country_fullname=="Congo, Dem. Rep."
replace country_fullname="Congo-Brazzaville" if country_fullname=="Congo, Rep."
replace country_fullname="Côte d'Ivoire" if country_fullname=="Cote d'Ivoire"
replace country_fullname="Egypt" if country_fullname=="Egypt, Arab Rep."
replace country_fullname="Gambia" if country_fullname=="Gambia, The"
replace country_fullname="Hong Kong, China" if country_fullname=="Hong Kong SAR, China"
replace country_fullname="Iran" if country_fullname=="Iran, Islamic Rep."
replace country_fullname="Kyrgyzstan" if country_fullname=="Kyrgyz Republic"
replace country_fullname="Laos" if country_fullname=="Lao PDR"
replace country_fullname="Macau, China" if country_fullname=="Macao SAR, China"
replace country_fullname="North Korea" if country_fullname=="Korea, Dem. People’s Rep."
replace country_fullname="Russia" if country_fullname=="Russian Federation"
replace country_fullname="Sao Tomé e Príncipe" if country_fullname=="Sao Tome and Principe"
replace country_fullname="Slovakia" if country_fullname=="Slovak Republic"
replace country_fullname="Sint Maarten" if country_fullname=="Sint Maarten (Dutch part)"
replace country_fullname="South Korea" if country_fullname=="Korea, Rep."
replace country_fullname="St Kitts and Nevis" if country_fullname=="St. Kitts and Nevis"
replace country_fullname="St Lucia" if country_fullname=="St. Lucia"
replace country_fullname="St Vincent and the Grenadines" if country_fullname=="St. Vincent and the Grenadines"
replace country_fullname="Syria" if country_fullname=="Syrian Arab Republic"
replace country_fullname="US Virgin Islands" if country_fullname=="Virgin Islands (U.S.)"
replace country_fullname="USA" if country_fullname=="United States"
replace country_fullname="Venezuela" if country_fullname=="Venezuela, RB"
replace country_fullname="Yemen" if country_fullname=="Yemen, Rep."

gen log_gdp_pc_14_19=log(gdp_pc_14_19)


tempfile gdp
save `gdp'
}
	
*******************
* Iso codes *
*******************

if `iso_code' {
import excel "$main/tables/iso3166paysmonde.xls", sheet("Codes de pays - iso3166") firstrow clear

keep Pays car D

ren Pays country_fullname
ren car country_2let
ren D country_3let
	
	
tempfile iso_2let
save `iso_2let'
}


******************
* Retail report  *
******************

if `euromonitor' {
import excel "$main/tables/cross_country/Passport_Stats_22-12-2020_2010_GMT.xls", sheet("Statistics Data") firstrow clear
drop CurrentConstant
ren Geography country_fullname
ren Category establishment_type
ren DataType variable
ren Unit unit
ren F Y2014
ren G Y2015
ren H Y2016
ren I Y2017
ren J Y2018
ren K Y2019
drop if variable==""
replace variable="nb_establishment" if variable=="Sites/outlets"
replace variable="sales" if variable=="Retail Value RSP excl Sales Tax" 
replace variable="selling_space" if variable=="Selling space"

reshape wide Y* unit , i(country_fullname establishment_type) j(variable) string

destring Y*sales *nb_establishment *selling_space , force replace

**Formality dummy
replace establishment_type = subinstr(establishment_type, " - modelled", "", .)
gen formal=1 if establishment_type=="Modern Grocery Retailers" // for now we keep only Modern Grocery Retailers, which is the sum of all types of modern establishment, but for some countries only this total is provided
replace formal=0 if establishment_type=="Traditional Grocery Retailers"
drop if formal==. // for now 

egen sales_14_19=rowmean(Y*sales)	
egen nb_establishment_14_19=rowmean(*nb_establishment)	
egen selling_space_14_19=rowmean(*selling_space)	
replace selling_space_14_19= selling_space_14_19*1000

*collapse (sum) sales_14_19 nb_establishment_14_19 , by (country_fullname  formal unitsales)



*******************
* Merge with gdp  *
*******************

merge m:1 country_fullname using `gdp'
keep if _merge==3
drop _merge
merge m:1 country_3let using `iso_2let'


replace country_2let="CW" if country_fullname=="Curacao"
replace country_2let="XK" if country_fullname=="Kosovo"
replace country_2let="ME" if country_fullname=="Montenegro"
replace country_2let="RO" if country_fullname=="Romania"
replace country_2let="RS" if country_fullname=="Serbia"
replace country_2let="SX" if country_fullname=="Sint Maarten"
replace country_2let="SS" if country_fullname=="South Sudan"
								  
drop if _merge==2
drop _merge

merge m:1 country_2let using `vat_threshold'
keep if _merge
save "$main/proc/retail_report.dta" , replace

/*


    Result                           # of obs.
    -----------------------------------------
    not matched                            82
        from master                        24  (_merge==1)
        from using                         58  (_merge==2)

    matched                               412  (_merge==3)
    -----------------------------------------



	ta country_fullname if _merge==1

                             Geography |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                               Anguilla |          2        8.33        8.33
                           Asia Pacific |          2        8.33       16.67
                            Australasia |          2        8.33       25.00
                         Eastern Europe |          2        8.33       33.33
                          French Guiana |          2        8.33       41.67
                             Guadeloupe |          2        8.33       50.00
                          Latin America |          2        8.33       58.33
                             Martinique |          2        8.33       66.67
                 Middle East and Africa |          2        8.33       75.00
                                Réunion |          2        8.33       83.33
                                 Taiwan |          2        8.33       91.67
                         Western Europe |          2        8.33      100.00
----------------------------------------+-----------------------------------
                                  Total |         24      100.00





*/


*Conversion 
replace sales_14_19= sales_14_19*10^3 if strpos(unitsales, "billion")
*replace sales_14_19= sales_14_19*10^6 if strpos(unitsales, "million")
gen us_dollar=(strpos(unitsales, "USD"))
gen sales_14_19_usdollar= sales_14_19 if us_dollar==1
replace sales_14_19_usdollar= sales_14_19/conversion_rate_14_19 if us_dollar==0


*Compute shares 
bys country_fullname: egen total_sales=total(sales_14_19)
bys country_fullname: egen total_sales_usdollar=total(sales_14_19_usdollar)

bys country_fullname: egen total_establisment=total(nb_establishment_14_19)
gen total_establisment_pc=total_establisment/pop_14_19

bys country_fullname: egen total_selling_space=total(selling_space_14_19)



gen share_sales_tradi=(sales_14_19/total_sales)*100 if formal==0
gen share_establishment_tradi=(nb_establishment_14_19/total_establisment)*100 if formal==0
gen total_establishment_tradi_pc=(nb_establishment_14_19/pop_14_19) if formal==0

gen share_sales_modern=(sales_14_19/total_sales)*100 if formal==1
gen share_establishment_modern=(nb_establishment_14_19/total_establisment)*100 if formal==1
gen total_establishment_modern_pc=(nb_establishment_14_19/pop_14_19) if formal==1


*Average size
gen average_size_tradi=sales_14_19_usdollar/nb_establishment_14_19 if formal==0
bysort country_fullname  (average_size_tradi) : replace average_size_tradi = average_size_tradi[_n-1] if missing(average_size_tradi)


gen average_size_modern=sales_14_19_usdollar/nb_establishment_14_19  if formal==1
bysort country_fullname  (average_size_modern) : replace average_size_modern = average_size_modern[_n-1] if missing(average_size_modern)

gen average_size_total=total_sales_usdollar/total_establisment  


*Selling space
gen selling_space_modern = selling_space_14_19/nb_establishment_14_19 if formal==1
bysort country_fullname  (selling_space_modern) : replace selling_space_modern = selling_space_modern[_n-1] if missing(selling_space_modern)

gen selling_space_tradi = selling_space_14_19/nb_establishment_14_19 if formal==0
bysort country_fullname  (selling_space_tradi) : replace selling_space_tradi = selling_space_tradi[_n-1] if missing(selling_space_tradi)

gen selling_space_total= total_selling_space/total_establisment

*Ratio 
gen ratio_sales_modern_tradi=average_size_modern/average_size_tradi
gen ratio_space_modern_tradi=selling_space_modern/selling_space_tradi


}
***********
* Graphs  *
***********

*********************
* Sample Selection  *
*********************
*A faire essayer de forcer l'axis

if `graphs' {

// locals 
local pop_threshold = 1000000
local ressource_rich "OMN SAU AGO BHR TCD QAT KAZ LBY NOR MOZ KWT ARE" 
local expenditure_surveys "BEN BOL BRA BFA BDI CMR TCD CHL COL COM COD COG CRI DOM ECU SWZ MEX MNE MAR MOZ NER PNG PER PRY RWA STP SEN SRB ZAF TZA TUN URY"
	
// Keep based on thresholds
keep if pop_14_19>=`pop_threshold' & pop_14_19!=.

gen ressource_rich = 0
foreach var in `ressource_rich'{
replace ressource_rich = 1 if country_3let=="`var'"
}

gen expenditure_surveys = 0
foreach var in `expenditure_surveys'{
replace expenditure_surveys = 1 if country_3let=="`var'"
}


* 		Same options and looks on axis et axis titles
* 		xscale(range) coupe le un peu avant 12, (je crois 11.5 suffit)


local subsample "ressource_rich==0"	

*Graphs
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis1 "yline(0(20)100, lstyle(minor_grid) lcolor(gs1))"	
	local yaxis2 "ylabel(0.1(0.05)0.3, nogrid  labsize(`size'))   yline(0.1(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
	local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)11, labsize(`size')) xscale(range(5(1)11.5))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local dots "msize(vsmall) mcolor(blue) mlabel(country_2let) mlabsize(2.5)"	
	local dots2 "msize(medsmall) mcolor(gray) mlabsize(2.5) msymbol(plus)"	


*Share of modern sales in total sales
	# d ; 	
	
	twoway  (scatter share_sales_modern log_gdp_pc_14_19 if `subsample' &    expenditure_surveys==1 , `dots') 
	(scatter share_sales_modern log_gdp_pc_14_19 if `subsample' &    expenditure_surveys==0 , `dots2')
			(lpoly share_sales_modern log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)), 
			`graph_region_options'
			`xaxis'
			`xtitle'
			`yaxis1'
			 ytitle("Share of Sales (%)", size(`size') margin(medsmall)) ylabel(0(20)100, nogrid  labsize(`size')) yscale(range(0(20)100)) 
			 legend(order(1 "Countries in Core Sample") position(11) ring(0));
			 
			gr save "$main/graphs/retail_report/retail_report_share_modern_sales_legend.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_share_modern_sales_legend.pdf", replace ;		
	# d cr	

*Share of modern sales in total sales - no legend
	# d ; 	
	
	twoway  (scatter share_sales_modern log_gdp_pc_14_19 if `subsample' &   expenditure_surveys==1 , `dots') 
	(scatter share_sales_modern log_gdp_pc_14_19 if `subsample' &   expenditure_surveys==0 , `dots2')
			(lpoly share_sales_modern log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)), 
			`graph_region_options'
			`xaxis'
			`xtitle'
			`yaxis1'
			 ytitle("Share of Sales (%)", size(`size') margin(medsmall)) ylabel(0(20)100, nogrid  labsize(`size')) yscale(range(0(20)100)) 
			 legend(off)
 ; 
			gr save "$main/graphs/retail_report/retail_report_share_modern_sales.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_share_modern_sales.pdf", replace ;		
	# d cr
*Share of modern retailers in total retailers
	local subsample "ressource_rich==0"	
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis1 "yline(0(25)75, lstyle(minor_grid) lcolor(gs1))"	
	local yaxis2 "ylabel(0.1(0.05)0.3, nogrid  labsize(`size'))   yline(0.1(0.05)0.3, lstyle(minor_grid) lcolor(gs1))"
	local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)11, labsize(`size')) xscale(range(5(1)11.5))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local dots "msize(vsmall) mcolor(blue) mlabel(country_2let) mlabsize(2.5)"	
	local dots2 "msize(medsmall) mcolor(gray) mlabsize(2.5) msymbol(plus)"	

	# d ; 	
	
	twoway  (scatter share_establishment_modern log_gdp_pc_14_19 if `subsample' & expenditure_surveys==1 , `dots') 
	(scatter share_establishment_modern log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 , `dots2')
	(lpoly share_establishment_modern log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)), 
			`graph_region_options'
			`xaxis'
			`xtitle'
			`yaxis1'
			 ytitle("Share of # Retailers (%)", size(`size') margin(medsmall)) ylabel(0(25)75, nogrid  labsize(`size')) yscale(range(0(25)75))  
			 			 legend(order(1 "Countries in Core Sample") position(11) ring(0)); 
			gr save "$main/graphs/retail_report/retail_report_share_modern_retailers_legend.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_share_modern_retailers_legend.pdf", replace ;		
	# d cr	

	# d ; 	
	
	twoway  (scatter share_establishment_modern log_gdp_pc_14_19 if `subsample' & expenditure_surveys==1 , `dots') 
	(scatter share_establishment_modern log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 , `dots2')
	(lpoly share_establishment_modern log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)), 
			`graph_region_options'
			`xaxis'
			`xtitle'
			`yaxis1'
			 ytitle("Share of # Retailers (%)", size(`size') margin(medsmall)) ylabel(0(25)75, nogrid  labsize(`size')) yscale(range(0(25)75))  legend(off)  ; 
			gr save "$main/graphs/retail_report/retail_report_share_modern_retailers.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_share_modern_retailers.pdf", replace ;		
	# d cr	


*# modern retailers per inhabitant
local subsample "ressource_rich==0"	

	# d ; 	
	
	twoway  (scatter total_establishment_modern_pc log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 , mlabel(country_2let) mcolor(blue)  msize(vsmall))  
	(scatter total_establishment_modern_pc log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 ,  msize(medsmall) mcolor(gray) msymbol(plus))
	(lpoly total_establishment_modern_pc log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)),  
			graphregion(color(white)) plotregion(color(white)) 
			xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall)) 
			 ytitle("Modern Retailers, # Retailers per inhabitant", margin(medsmall))  xlabel(6(1)12, labsize(small) nogrid) legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_total_establishment_modern_pc.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_total_establishment_modern_pc.pdf", replace ;		
	# d cr	


*# tradi retailers per inhabitant
local subsample "ressource_rich==0"	

	# d ; 	
	
	twoway  (scatter total_establishment_tradi_pc log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 , mlabel(country_2let) mcolor(blue)  msize(vsmall))  
	(scatter total_establishment_tradi_pc log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 ,  msize(medsmall) mcolor(gray) msymbol(plus))
	(lpoly total_establishment_tradi_pc log_gdp_pc_14_19 if `subsample' ,  lcolor(gray)), 
			graphregion(color(white)) plotregion(color(white)) 
			xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall)) ytitle("Traditional Retailers, # Retailers per inhabitant", margin(medsmall))  xlabel(6(1)12, labsize(small) nogrid) legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_total_establishment_tradi_pc.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_total_establishment_tradi_pc.pdf", replace ;		
	# d cr	

	
*# total retailers per inhabitant ( & formal==1 otherwise two datapoint at the same position)
local subsample "ressource_rich==0"	

	# d ; 	
	
	twoway  (scatter total_establisment_pc log_gdp_pc_14_19 if `subsample' & expenditure_surveys==1 & formal==1 , mlabel(country_2let) mcolor(blue)  msize(vsmall))  
	(scatter total_establisment_pc log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 ,  msize(medsmall) mcolor(gray) msymbol(plus))
	(lpoly total_establisment_pc log_gdp_pc_14_19 if `subsample' ,  lcolor(gray)), 
			graphregion(color(white)) plotregion(color(white)) 
			xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall)) ytitle("# Retailers per inhabitant", margin(medsmall))  xlabel(6(1)12, labsize(small) nogrid) legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_total_establishment_total_pc.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_total_establishment_total_pc.pdf", replace ;		
	# d cr	




*space size of modern retailers
	local subsample "ressource_rich==0"	
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis1 "ylabel(0(500)2000, nogrid  labsize(`size'))   yline(0(500)2000, lstyle(minor_grid) lcolor(gs1))"
	local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)11, labsize(`size')) xscale(range(5(1)11.5))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local dots "msize(vsmall) mcolor(blue) mlabel(country_2let) mlabsize(2.5)"	
	local dots2 "msize(medsmall) mcolor(gray) mlabsize(2.5) msymbol(plus)"	


	# d ; 	
	
	twoway  (scatter selling_space_modern log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 & formal==1 , `dots')  
	(scatter selling_space_modern log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 & formal==1,  `dots2')
	(lpoly selling_space_modern log_gdp_pc_14_19 if `subsample' ,  lcolor(gray)),  
			 ytitle("Average Retailer Size (Sq Meters)", size(`size') margin(medsmall)) 
			`graph_region_options'
			`xaxis'
			`xtitle'
			`yaxis1'
			 legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_selling_space_modern.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_selling_space_modern.pdf", replace ;		
	# d cr	


*space size of tradi retailers
	local subsample "ressource_rich==0"	
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis1 "ylabel(0(100)400, nogrid  labsize(`size'))   yline(0(100)400, lstyle(minor_grid) lcolor(gs1))"
	local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)11, labsize(`size')) xscale(range(5(1)11.5))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local dots "msize(vsmall) mcolor(blue) mlabel(country_2let) mlabsize(2.5)"	
	local dots2 "msize(medsmall) mcolor(gray) mlabsize(2.5) msymbol(plus)"	


	# d ; 	
	
	twoway  (scatter selling_space_tradi log_gdp_pc_14_19 if `subsample' & expenditure_surveys==1 , `dots')
	(scatter selling_space_tradi log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 ,  `dots2')
	(lpoly selling_space_tradi log_gdp_pc_14_19 if `subsample' ,  lcolor(gray)),  
			ytitle("Average Retailer Size (Sq Meters)", size(`size') margin(medsmall))
			graph_region_options'
			`xaxis'
			`xtitle'
			`yaxis1'
			 legend(off)  ; 
			gr save "$main/graphs/retail_report/retail_report_selling_space_tradi.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_selling_space_tradi.pdf", replace ;		
	# d cr	


	
*space size of total retailers( & formal==1 otherwise two datapoint at the same position)
local subsample "ressource_rich==0"	

	# d ; 	
	
	twoway  (scatter selling_space_total log_gdp_pc_14_19 if `subsample' & expenditure_surveys==1 & formal==1 , mlabel(country_2let) mcolor(blue) msize(vsmall))
	(scatter selling_space_total log_gdp_pc_14_19 if `subsample' & expenditure_surveys==0 & formal==1  ,  msize(medsmall) mcolor(gray) msymbol(plus))
	(lpoly selling_space_total log_gdp_pc_14_19 if `subsample'   ,  lcolor(gray)),  
			graphregion(color(white)) plotregion(color(white)) 
			xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall)) ytitle("Average Retailer Size, in Sq Meters", margin(medsmall))  xlabel(6(1)12, labsize(small) nogrid)
			legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_selling_space_total.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_selling_space_total.pdf", replace ;		
	# d cr	

* Ratio space size of total retailers ( & formal==1 otherwise two datapoint at the same position)
local subsample "ressource_rich==0"	

	# d ; 	
	
	twoway  (scatter ratio_space_modern_tradi log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 & formal==1 & country_2let!="BO" , mlabel(country_2let) mcolor(blue)  msize(vsmall))  
	(scatter ratio_space_modern_tradi log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 & formal==1  ,  msize(medsmall) mcolor(gray) msymbol(plus))
	(lpoly ratio_space_modern_tradi log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)),  
			graphregion(color(white)) plotregion(color(white)) 
			xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall))
			 ytitle("Size Ratio [Modern/Traditional], based on Sq Meters", margin(medsmall))  xlabel(6(1)12, labsize(small) nogrid) legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_space_size_ratio.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_space_size_ratio.pdf", replace ;		
	# d cr	
	
*value size of modern retailers
	local subsample "ressource_rich==0"	
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis1 "ylabel(0(5)15, nogrid  labsize(`size'))   yline(0(5)15, lstyle(minor_grid) lcolor(gs1))"
	local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)11, labsize(`size')) xscale(range(5(1)11.5))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local dots "msize(vsmall) mcolor(blue) mlabel(country_2let) mlabsize(2.5)"	
	local dots2 "msize(medsmall) mcolor(gray) mlabsize(2.5) msymbol(plus)"	


	# d ; 	
	
	twoway  (scatter average_size_modern log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 & formal==1 , `dots')  
	(scatter average_size_modern log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0  & formal==1, `dots2')
	(lpoly average_size_modern log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)),  
			ytitle("Average Retailer Size (Sales Mil. USD)", size(`size') margin(medsmall))  
			`xaxis'
			`xtitle'
			`yaxis1'
			 legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_value_size_modern.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_value_size_modern.pdf", replace ;		
	# d cr	



*value size of tradi retailers
	local subsample "ressource_rich==0"	
	local size medlarge
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"	
	local yaxis1 "ylabel(0(0.25)1, nogrid  labsize(`size'))   yline(0(0.25)1, lstyle(minor_grid) lcolor(gs1))"
	local ytitle "ytitle("Tax rate", margin(medsmall) size(`size'))"	
	local xaxis "xlabel(5(1)11, labsize(`size')) xscale(range(5(1)11.5))"
	local xtitle "xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall) size(`size'))"
	local dots "msize(vsmall) mcolor(blue) mlabel(country_2let) mlabsize(2.5)"	
	local dots2 "msize(medsmall) mcolor(gray) mlabsize(2.5) msymbol(plus)"	

	# d ; 	
	
	twoway  (scatter average_size_tradi log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 , `dots')  
	(scatter average_size_tradi log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 ,  `dots2')
	(lpoly average_size_tradi log_gdp_pc_14_19 if `subsample' ,  lcolor(gray)),  
			ytitle("Average Retailer Size (Sales Mil. USD)", size(`size') margin(medsmall))  
			`xaxis'
			`xtitle'
			`yaxis1'
			legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_value_size_tradi.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_value_size_tradi.pdf", replace ;		
	# d cr	


	
*value size of total retailers ( & formal==1 otherwise two datapoint at the same position)
local subsample "ressource_rich==0"	

	# d ; 	
	
	twoway  (scatter average_size_total log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 , mlabel(country_2let) mcolor(blue)  msize(vsmall))  
	(scatter average_size_total log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==0 ,  msize(medsmall) mcolor(gray) msymbol(plus))
	(lpoly average_size_total log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)),  
			graphregion(color(white)) plotregion(color(white)) 
			xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall))
			 ytitle("Average Retailer Size, in Sales US$ M", margin(medsmall))  xlabel(6(1)12, labsize(small) nogrid) legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_value_size_total.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_value_size_total.pdf", replace ;		
	# d cr	

	* Ratio value size of total retailers ( & formal==1 otherwise two datapoint at the same position)
local subsample "ressource_rich==0"	

	# d ; 	
	
	twoway  (scatter ratio_sales_modern_tradi log_gdp_pc_14_19 if `subsample' &  expenditure_surveys==1 & formal==1 , mlabel(country_2let) mcolor(blue)  msize(vsmall))  
	(scatter ratio_sales_modern_tradi log_gdp_pc_14_19 if `subsample' & country_2let!="ET" &  expenditure_surveys==0 & formal==1  ,   msize(medsmall) mcolor(gray) msymbol(plus))
	(lpoly ratio_sales_modern_tradi log_gdp_pc_14_19 if `subsample'  ,  lcolor(gray)),  
			graphregion(color(white)) plotregion(color(white)) 
			xtitle("Log GDP per capita, Constant 2010 USD", margin(medsmall))
			 ytitle("Size Ratio [Modern/Traditional], based on Sales", margin(medsmall))  xlabel(6(1)12, labsize(small) nogrid) legend(off) ; 
			gr save "$main/graphs/retail_report/retail_report_value_size_ratio.pdf", replace ;
			graph export "$main/graphs/retail_report/retail_report_value_size_ratio.pdf", replace ;		
	# d cr	
}
***********
* Table	  *
***********

if `table_appendix' {
import excel "$main/tables/cross_country/Retail_VAT.xls", sheet("Paper Sample") firstrow clear
rename country country_fullname
replace country_fullname="Congo-Brazzaville" if country_fullname=="Congo"
replace country_fullname="Congo, Democratic Republic" if country_fullname=="DRC"
replace country_fullname="Sao Tomé e Príncipe" if country_fullname=="Sao Tome"
replace country_fullname="Papua New Guinea" if country_fullname=="Papua NG"

*No data for Paraguay, we will import them manually. 
*The VAT threshold in paraguay is equal to twelve times the minimum wage (https://www.set.gov.py/portal/PARAGUAY-SET/detail?folder-id=repository:collaboration:/sites/PARAGUAY-SET/categories/SET/biblioteca-virtual/preguntas-frecuentes/iva&content-id=/repository/collaboration/sites/PARAGUAY-SET/documents/biblioteca/biblioteca-virtual/iva-preguntas-frecuentes) which is 331,23$ in January 2020 (https://www.lanacion.com.py/mitad-de-semana/2020/01/29/paraguay-se-ubica-con-el-cuarto-mejor-salario-minimo-de-la-region/#:~:text=El%20salario%20m%C3%ADnimo%20en%20este,representan%20US%24%20331%2C23)
replace country_fullname="Paraguay" if country_fullname=="" // Import man
  
merge m:1 country_fullname using `gdp'
drop if _merge==2
drop _merge

*Conversion 

foreach var in tradi_size modern_size  {
replace `var'= `var'*10^3 if strpos(currency_store, "billion")
replace `var'= `var'*10^3 if strpos(currency_store, "Billion")
}

foreach var in VAT  {
replace `var'= `var'*10^3 if strpos(currency_VAT, "billion")
replace `var'= `var'*10^3 if strpos(currency_VAT, "Billion")
}

foreach var in currency_store currency_VAT  {
gen us_dollar_`var'=(strpos(`var', "USD"))
}

foreach var in tradi_size modern_size {
gen `var'_usdollar= `var' if us_dollar_currency_store==1
replace `var'_usdollar= `var'/conversion_dec_2019 if us_dollar_currency_store==0
}

foreach var in VAT {
gen `var'_usdollar= `var' if us_dollar_currency_VAT==1
replace `var'_usdollar= `var'/conversion_dec_2019 if us_dollar_currency_VAT==0
}

keep country_fullname tradi_size_usdollar modern_size_usdollar VAT_usdollar ratio_tradiK ratio_modernK
order country_fullname tradi_size_usdollar modern_size_usdollar VAT_usdollar ratio_tradiK ratio_modernK , first

export excel "$main/tables/cross_country/table_appendixC.xls", replace  firstrow(variables)  locale(C)

*Make sure to format the cells, put the country name in bold, 
}

