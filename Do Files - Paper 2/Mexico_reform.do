** generate graphs for pass-through in informal retail stores based on Mexican reform **
clear
set more off


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
	
	
**** FIGURE 2 *******	
import excel using "$main/tables/2.Prices_from_graphs_new.xlsx", firstrow sheet("Formal1_informal")  clear
format  I %tdMon-YY
*Paper Figure 2a
local size med
local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
local xtitle "xtitle("Month", margin(medsmall) size(`size'))"
local yaxis "ylabel(-0.05(0.05)0.1, nogrid  labsize(`size'))   yline(-0.05(0.05)0.1, lstyle(minor_grid) lcolor(gs1))"
local ytitle "ytitle("Log Price (index = 0 in Aug '13)", size(`size') margin(medsmall))"
local xaxis "xlabel(18993 19084 19206 19328 19449 19571 19693 19814 19936 20058 20179 20301 20423, angle(45) labsize(`size'))"		
		
		
sort month
twoway  (connected log_relativo_norm I, mcolor(blue) msymbol(circle) lcolor(blue)) (connected H I, msymbol(circle_hollow) mcolor(blue) lcolor(blue)), xline(19571, lcolor(gs6) lpattern(dash)) xline(19724, lcolor(gs6) lpattern(solid))  legend(label(1 "Border") label(2 "Non-Border"))   `xtitle' `xaxis' `ytitle' `yaxis'  `graph_region_options'
graph save "$main/graphs/Mexican_reform/prices_levels.gph", replace
graph export "$main/graphs/Mexican_reform/prices_levels.eps", replace


clear
import excel using "$main/tables/2.Prices_from_graphs_new.xlsx", firstrow sheet("DDD_informal1") 

*Paper Figure 2b
local size med
local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
local xtitle "xtitle("Month", margin(medsmall) size(`size'))"
local yaxis "ylabel(-.02(.01).06, nogrid  labsize(`size'))   yline(-.02(.01).06, lstyle(minor_grid) lcolor(gs1))"
local ytitle "ytitle("Log Price", size(`size') margin(medsmall) )"
local xaxis "xlabel(18993 19084 19206 19328 19449 19571 19693 19814 19936 20058 20179 20301 20423, angle(45) labsize(`size'))"		
		
		
twoway (connected Lower Estimate Upper Period)
* NB: label vars are off : Upper is the point estimate
rename Upper point_estimate
rename Lower pointest_low
rename Estimate pointest_upper
gen full_pass=0.05 if Time>=19724
replace full_pass=0 if Time<19724
gen model_pass=0.005 if Time>=19724
replace model_pass=0 if Time<19724
twoway (connected point_estimate Time, msymbol(circle) mcolor(blue) lcolor(blue) lpattern(shortdash)) (line pointest_low Time, lpattern(shortdash) lcolor(blue)) (line pointest_upper Time, lpattern(shortdash) lcolor(blue)) ///
(line full_pass Time, lcolor(red) lpattern(longdash_dot) lwidth(medium)) (line model_pass Time, lcolor(red) lwidth(medium)),  ///
 `xtitle' `xaxis' `ytitle' `yaxis'  `graph_region_options' legend(order(1 2 4 5)) legend(rows(2)) legend(label(1 "D-in-D coefs") label(2 "95% CI") label(4 "Full pass-through") label(5 "Model pass-through"))  
graph save "$main/graphs/Mexican_reform/prices_didcoef.gph", replace
graph export "$main/graphs/Mexican_reform/prices_didcoef.eps", replace

