stop! // to prevent mistakingly running everything

					*************************************
					* 			Main DO FILE			*
					* 	  COUNTRY CENSUS DATA SETS 		*
					*		 CROSS-COUNTRY GRAPH		*
					*************************************

***************
* DIRECTORIES *
***************

if "`c(username)'"=="WB446741" { 											// Pierre's WB computer 
	global main "C:\Users\wb446741\Dropbox\Regressivity_VAT\Stata"
	}
else if "`c(username)'"=="pierrebachas" { 									// Pierre's personal laptop
	global main "/Users/pierrebachas/Dropbox/Regressivity_VAT/Stata"
	}	
	else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}	
	

**************
** Globals  **
**************

global folder_name "Censuses"

clear all
set more off


*************************************
* COMBINE CENSUSES TOGETHER *
*************************************
clear 

import excel using "$main/data/$folder_name/Mexico/vatpayer_employee_tab.xlsx", firstrow
destring employees, replace
destring VAT_payer, replace
gen log_employ = log(employees+1)
gen country = "Mexico"
gen iso2 = "MX"

append using "$main/proc/$folder_name/PE_census.dta"
append using "$main/proc/$folder_name/CM_census.dta"
append using "$main/proc/$folder_name/RW_census.dta"

replace log_employ = 4 if log_employ > 4

gen formality = 1 if reg_status==1 & iso2 == "RW" 
replace formality = 1 if reg_status == 1 & iso2 == "CM"
replace formality = 0 if reg_status ==0 & iso2 == "RW" 
replace formality = 0 if reg_status ==0 & iso2 == "CM"
replace formality = 1 if pay_VAT ==1 & iso2 == "PE"
replace formality = 0 if pay_VAT ==0 & iso2 == "PE"
replace formality = VAT_payer if iso2 == "MX"

local size medlarge

// Informal Engel Curve		
#delim ;
twoway (lpoly formality log_employ if iso2=="RW", degree(1) lwidth(thick)) 
(lpoly formality log_employ if iso2=="CM", degree(1) lwidth(thick))
(lpoly formality log_employ if iso2=="PE", degree(1) lwidth(thick))
(lpoly formality log_employ if iso2=="MX", degree(1) lwidth(thick)),
//(lfit reg_current log_employ if log_employ>= `bottom' & log_employ <= `top'),	
xlabel(0(1)4, labsize(`size')) ylabel(0(0.2)1, nogrid labsize(`size'))
// xline(`median', lcolor(red)) xline( `p5', lcolor(orange) lpattern(dash))  xline( `p95', lcolor(orange) lpattern(dash))
legend(label(1 "Rwanda") label(2 "Cameroon") label(3 "Peru") label(4 "Mexico") size(`size') col(1) ring(0) position(4)) 
graphregion(fcolor(white)) plotregion(fcolor(white))  title("")
xtitle("Log Employment" , size(`size')) ytitle("Share Formal", size(`size') margin(medsmall)) graphregion(color(white)) bgcolor(white)
;
#delim cr
graph export "$main/graphs/$folder_name/engel_formality_logemploy_combined.pdf", replace
		




