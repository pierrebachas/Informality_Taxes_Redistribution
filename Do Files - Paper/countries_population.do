***************
* DIRECTORIES *
***************

if "`c(username)'"=="Varo" { 													// Alvaro's laptop
	global main "/Users/Varo/Dropbox/Regressivity_VAT/Stata" 		
}	
 else if "`c(username)'"=="WB446741" { 											// Pierre's WB computer 
	global main "C:\Users\wb446741\Dropbox\Regressivity_VAT\Stata"
	}
else if "`c(username)'"=="pierrebachas" { 									// Pierre's personal laptop
	global main "/Users/pierrebachas/Dropbox/Regressivity_VAT/Stata"
	}	
 else if "`c(username)'"=="elieg" { 											// Elie's laptop
	global main "C:\Users\elieg\Dropbox\Regressivity_VAT\Stata"
}
 else if "`c(username)'"=="wb520324" { 											// Eva's WB computer 
	global main "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata"
	}
	
	else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}	
	
	
	
import excel "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata\tables\Global_Consumption_Database\Countries_population.xlsx", sheet("Sheet10") firstrow clear
drop A
ren B country_fullname
ren C pop2018
drop GCD 
gen GCD=.

merge 1:1 country_fullname using "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata\tables\Global_Consumption_Database\code_country_correspondance.dta"
keep if _merge==3
drop _merge
ren country_3let country
merge 1:1 country using "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata\data\Global_Consumption_Database\results_excluding_hhage_children\decile_stat_excluding_hhage_children_mean_exp.dta"
replace country_fullname="Kosovo" if country=="KSV"
replace country_fullname="South Sudan" if country=="SSD"
replace pop2018="1920079"  if country=="KSV"
replace pop2018="10975927" if country=="SSD"
tostring GCD, replace
replace GCD="Yes" if _merge==2 | _merge==3
replace GCD="No" if _merge==1
destring pop2018, replace
gen pop2018_sort=-pop2018
sort pop2018_sort
export excel using "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata\tables\Global_Consumption_Database\country_pop.xls" , replace



*Table B1 - Need to finish automating


putexcel set "$main/tables/cross_country/TableB1.xls", modify
sleep 500
egen ssa_pop_sample=sum(pop2018) if country_2let=="BJ" | country_2let=="BF" | country_2let=="BI" | country_2let=="CM" | country_2let=="TD" | country_2let=="KM" | country_2let=="CD" | country_2let=="CG" | country_2let=="SZ" | country_2let=="MZ" | country_2let=="NE" | country_2let=="RW" | country_2let=="ST" | country_2let=="SN" | country_2let=="ZA" | country_2let=="TZ" 
egen mena_pop_sample=sum(pop2018) if country_2let=="MA" | country_2let=="TN"
egen eca_pop_sample=sum(pop2018) if country_2let=="RS" | country_2let=="ME"
egen lac_pop_sample=sum(pop2018) if country_2let=="BO" | country_2let=="BR" | country_2let=="CL" | country_2let=="CO" | country_2let=="CR" | country_2let=="DO" | country_2let=="EC" | country_2let=="MX" | country_2let=="PE" | country_2let=="UY" 
egen eap_pop_sample=sum(pop2018) if country_2let=="PG" 

gen share_ssa=ssa_pop_sample/1078
gen share_mena=mena_pop_sample/449
gen share_eca=eca_pop_sample/918
gen share_lac=lac_pop_sample/641
gen share_eap=eap_pop_sample/2328

putexcel A1 = "Region"
sleep 500
putexcel B1 = "# Countries"
sleep 500
putexcel C1 = "Pop. of surveyed Countries"
sleep 500
putexcel D1 = "Total Pop."
sleep 500
putexcel E1 = "Proportion of Pop."
sleep 500

putexcel A2 ="Sub-Sharan Africa"
putexcel A3 ="Middle East & North Africa"
putexcel A4 ="Eastern Europe & Central Asia"
putexcel A5 ="Latin America and the Carribean"
putexcel A6 ="East Asia & Pacific"

putexcel B2 =16 
putexcel B3 =2 
putexcel B4 =2 
putexcel B5 =10 
putexcel B6 =1 


local region = "ssa mena eca eap lac"
local line = `c'+1 
sleep 500
putexcel C`i' =`region'_pop_sample
sleep 500

putexcel D2 =1078 
putexcel D3 =449 
putexcel D4 =918 
putexcel D5 =641 
putexcel D6 =2328 

sleep 500
putexcel E`i' =share_`region'

sleep 500
putexcel D2 =10
sleep 500
putexcel E2 =1 
sleep 500


* % du monde 56,2%

import excel using "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata\tables\Global_Consumption_Database\country_pop.xls" , clear firstrow

egen GCD_pop=sum(pop2018) if GCD=="Yes"
egen total_pop=sum(pop2018)
gen share_pop_GCD=GCD_pop/total_pop

* China Egypt and Iran % of world population
gen share_pop_country=pop2018/total_pop // China 18.7% Egypt 1.30% Iran 1%
// Brasil Chili Comores  Costa Rica Dominican Republic Ecuador Papua New Guinea Tunisia Uruguay
gen our_sample_only=(country=="BRA" |country=="CHL" |country=="COM" |country=="CRI" |country=="DOM" |country=="ECU" |country=="PNG" |country=="TUN" |country=="URY")
egen our_sample_only_pop=sum(pop2018) if our_sample_only==1
gen share_pop_our_sample_only=our_sample_only_pop/total_pop	  // 3.7%
	