
					*************************************
					* 				DO FILE				*
					*   CONSUMPTION SEGMENT BY DECILE 	*
					*************************************

********************************************************************************
********************************************************************************

	global db_fullname "Global_Consumption_Database"
	global country_code "mwi"
	
	putexcel set "$main/tables/$db_fullname/$country_code.xls", sheet("General_stats") modify
	global excel_row = 1
	display $excel_row
	
	

**********
* Step 1 * Create COICOP catgeories (2 digits and 4 digits)
**********

clear
set more off
use "$main/data/${db_fullname}/old_Test_Malawi/${country_code}2010_ppp.dta", clear

local country = "mwi"
gen country="`country'"


distinct basic_hd  // 81 different coicop codes
set more off
ta basic_hd, missing 
tostring basic_hd , gen (basic_hd_str)
gen COICOP_4dig=substr(basic_hd_str, 1,4)
destring COICOP_4dig, replace
gen str6 COICOP_2dig = substr(string(COICOP_4dig,"%01.0f"), 3,2) 
destring COICOP_2dig, replace


**********
* Step 2 * Generate deciles of cons_tot
**********
keep if basic_hd_str!="1104111" // remove "Actual and imputed rentals for housing"
by hid: egen exp_total_noh = sum(cons_tot) 
gen expense_pp_noh = exp_total_noh / hhsize
gen log_expense_pp_noh= log(expense_pp_noh) // log=ln 
xtile decile = log_expense_pp_noh [weight=wta_hh], nq(10)




**********
* Step 3 * Aggregate the database, each consumption category share by decile
**********
local hhld_controls hhsize // hagey adeq_fao nb_children 


sort hid COICOP_2dig
collapse (sum) cons_tot (mean) `hhld_controls'   log_expense_pp_noh  decile exp_total_noh psu , 	by(hid wta_hh COICOP_2dig country)	//cons_tot par categorie COICOP et exp_total_noh sans housing
gen share_item_in_exp_total_noh = cons_tot / exp_total_noh // share of each coicop 2 digit category by hhid
replace share_item_in_exp_total_noh = share_item_in_exp_total_noh*100

*keep if COICOP_2dig == 1
* mean share food at the decile level (weighted) 
egen num = total(share_item_in_exp_total_noh * wta_hh)  , by(decile COICOP_2dig) 
egen den = total(wta_hh)  , by(decile COICOP_2dig) 
gen mean_dec_share_food = num/den

*Double counting des weight et des expenses because several lign for each household!
collapse (mean) log_expense_pp_noh wta_hh decile `hhld_controls' , 	by(hid )	//cons_tot par categorie COICOP et exp_total_noh sans housing


* mean log average expense as the decile level (weighted) 
egen num_exp = total(log_expense_pp_noh * wta_hh), by(decile) 
egen den_exp = total(wta_hh), by(decile) 
gen mean_dec_log_exp = num_exp/den_exp


* sans weight 
egen num_exp_no = total(log_expense_pp_noh), by(decile) 
egen den_exp_no = total(wta_hh)
gen mean_dec_log_exp_no = num_exp_no/den_exp_no

*sans log 
egen num_exp = total(expense_pp_noh * wta_hh), by(decile) 
egen den_exp = total(wta_hh), by(decile) 
gen mean_dec_exp = num_exp/den_exp
gen log= log(expense_pp_noh)

collapse (mean) expense_pp_noh , by (decile)

*N By decile

unique hid , by(decile) gen(N_decile)
bys decile: egen n_decile=sum(N_decile)

**********
* OUTPUT 1 *  Stata Database: Stat by decile (mean_dec_share_food , mean_dec_log_exp , n)
**********

preserve 
collapse (mean) mean_dec_share_food mean_dec_log_exp N_decile, by(country decile)
save "$main/data/$db_fullname/${country_code}_decile_stat", replace 
restore


**********
* Step 4 *  ENGEL CURVES SLOPES
**********


* Generate moments (median, percentiles) 
qui sum log_expense_pp_noh [aw = wta_hh]  , d // removed "if tag_1== 1" ?
local median  = `r(p50)' 
local p5 = `r(p5)'
local p95 = `r(p95)'
local p10 = `r(p10)'
local p90 = `r(p90)'		
local bottom = floor(`r(p5)')
local top = ceil(`r(p95)')
local bottom10 = floor(`r(p10)')
local top90 = ceil(`r(p90)')

local hhld_controls hhsize // hagey adeq_fao nb_children 

** Linear: 
reg share_item_in_exp_total_noh log_expense_pp_noh `hhld_controls' if COICOP_2dig == 1 [aw = wta_hh] , robust
reg share_item_in_exp_total_noh log_expense_pp_noh `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p5' & log_expense_pp_noh <= `p95' [aw = wta_hh] , robust
reg share_item_in_exp_total_noh log_expense_pp_noh `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p10' & log_expense_pp_noh <= `p90' [aw = wta_hh] , robust		

** Quadratic
gen log_expense_pp_noh_sq = log_expense_pp_noh^2		

reg share_item_in_exp_total_noh log_expense_pp_noh log_expense_pp_noh_sq `hhld_controls' if COICOP_2dig == 1  [aw = wta_hh] , robust			
reg share_item_in_exp_total_noh log_expense_pp_noh log_expense_pp_noh_sq `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p5' & log_expense_pp_noh <= `p95'  [aw = wta_hh] , robust	
reg share_item_in_exp_total_noh log_expense_pp_noh log_expense_pp_noh_sq `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p10' & log_expense_pp_noh <= `p90'  [aw = wta_hh] , robust		


*residual, first food on hh caracteristics and then the residual 
xi: reg share_item_in_exp_total_noh `hhld_controls' if COICOP_2dig == 1 [weight=wta_hh]
predict food_res1, res


**********
* Step 5 *  ENGEL CURVES GRAPHS
**********
* Generate moments (median, percentiles) 
qui sum log_expense_pp_noh [aw = wta_hh]  , d // removed "if tag_1== 1" ?
local median  = `r(p50)' 
local p5 = `r(p5)'
local p95 = `r(p95)'
local p10 = `r(p10)'
local p90 = `r(p90)'		
local bottom = floor(`r(p5)')
local top = ceil(`r(p95)')
local bottom10 = floor(`r(p10)')
local top90 = ceil(`r(p90)')

local hhld_controls hhsize //   hagey adeq_fao nb_children 

* Food ENGEL curve:

#delim ;
twoway (lpolyci share_item_in_exp_total_noh log_expense_pp_noh if COICOP_2dig == 1 & log_expense_pp_noh>= `bottom' & log_expense_pp_noh<= `top' [aw = wta_hh])
(lfit share_item_in_exp_total_noh log_expense_pp_noh if COICOP_2dig == 1 & log_expense_pp_noh>= `p5' & log_expense_pp_noh<= `p95' [aw = wta_hh]), 
xscale(range(`bottom' `top'))
xlabel(`bottom'(1)`top')  ylabel(0(10)100)
xline(`median', lcolor(red)) xline( `p5', lcolor(orange) lpattern(dash))  xline( `p95', lcolor(orange) lpattern(dash))
graphregion(fcolor(white)) plotregion(fcolor(white))	name(Engel_food, replace) title(Food Engel Curve)
legend(off) xtitle("") 			;

graph save "$main/graphs/$db_fullname/${country_code}_Engel_food_5_95.gph", replace ;	
#delim cr				

#delim ;
twoway (lpolyci food_res1 log_expense_pp_noh if COICOP_2dig == 1 & log_expense_pp_noh>= `bottom' & log_expense_pp_noh<= `top' [aw = wta_hh])
(lfit food_res1 log_expense_pp_noh if COICOP_2dig == 1 & log_expense_pp_noh>= `p5' & log_expense_pp_noh<= `p95' [aw = wta_hh]), 
xscale(range(`bottom' `top'))
xlabel(`bottom'(1)`top') ylabel(0(10)100)
xline(`median', lcolor(red)) xline( `p5', lcolor(orange) lpattern(dash))  xline( `p95', lcolor(orange) lpattern(dash))
graphregion(fcolor(white)) plotregion(fcolor(white))	name(Engel_food, replace) title(Food Engel Curve)
legend(off) xtitle("") 			;

graph save "$main/graphs/$db_fullname/${country_code}_Engel_food_5_95_res1.gph", replace ;	
#delim cr				

graph combine "$main/graphs/$db_fullname/${country_code}_Engel_food_5_95.gph" "$main/graphs/$db_fullname/${country_code}_Engel_food_5_95_res1.gph" 

**********
* OUTPUT 2 *  PDF: The two Engel curves graphs combined
**********

graph export "$main/graphs/$db_fullname/${country_code}_Engel_food.pdf", replace   

**********
* Step 6 *  Create a database with the regressions coefficients 
**********
qui sum log_expense_pp_noh [aw = wta_hh]  , d 
local median  = `r(p50)' 
local p5 = `r(p5)'
local p95 = `r(p95)'
local p10 = `r(p10)'
local p90 = `r(p90)'		
local bottom = floor(`r(p5)')
local top = ceil(`r(p95)')

local hhld_controls hhsize // hhagey adeq_fao nb_children
local country_name=50 //from the list I sent you on Excel, but it might exists a better way of doing it 

// Matrix of results
matrix results = J(6,10,.)

reg share_item_in_exp_total_noh log_expense_pp_noh `hhld_controls' if COICOP_2dig == 1 [aw = wta_hh] , robust
local obs = `e(N)'
local adjusted_r2 = `e(r2_a)'

matrix results[1,1] = `country_name'
matrix results[1,2] = 1
matrix results[1,3] = _b[log_expense_pp_noh]
matrix results[1,4] = _se[log_expense_pp_noh]
matrix results[1,7] = `e(N)'
matrix results[1,8] = `e(r2_a)'
matrix results[1,9] = _b[_cons]
matrix results[1,10] = _se[_cons]

reg share_item_in_exp_total_noh log_expense_pp_noh `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p5' & log_expense_pp_noh <= `p95' [aw = wta_hh] , robust
matrix results[2,1] =`country_name'
matrix results[2,2] = 2
matrix results[2,3] = _b[log_expense_pp_noh]
matrix results[2,4] = _se[log_expense_pp_noh]
matrix results[2,7] = `e(N)'
matrix results[2,8] = `e(r2_a)'
matrix results[2,9] = _b[_cons]
matrix results[2,10] = _se[_cons]


reg share_item_in_exp_total_noh log_expense_pp_noh `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p10' & log_expense_pp_noh <= `p90' [aw = wta_hh] , robust		
matrix results[3,1] =`country_name'
matrix results[3,2] = 3
matrix results[3,3] = _b[log_expense_pp_noh]
matrix results[3,4] = _se[log_expense_pp_noh]
matrix results[3,7] = `e(N)'
matrix results[3,8] = `e(r2_a)'
matrix results[3,9] = _b[_cons]
matrix results[3,10] = _se[_cons]


reg share_item_in_exp_total_noh log_expense_pp_noh log_expense_pp_noh_sq `hhld_controls' if COICOP_2dig == 1  [aw = wta_hh] , robust			
matrix results[4,1] =`country_name'
matrix results[4,2] = 1
matrix results[4,3] = _b[log_expense_pp_noh]
matrix results[4,4] = _se[log_expense_pp_noh]
matrix results[4,5] = _b[log_expense_pp_noh_sq]
matrix results[4,6] = _se[log_expense_pp_noh_sq]
matrix results[4,7] = `e(N)'
matrix results[4,8] = `e(r2_a)'
matrix results[4,9] = _b[_cons]
matrix results[4,10] = _se[_cons]


reg share_item_in_exp_total_noh log_expense_pp_noh log_expense_pp_noh_sq `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p5' & log_expense_pp_noh <= `p95'  [aw = wta_hh] , robust	
matrix results[5,1] =`country_name'
matrix results[5,2] = 2
matrix results[5,3] = _b[log_expense_pp_noh]
matrix results[5,4] = _se[log_expense_pp_noh]
matrix results[5,5] = _b[log_expense_pp_noh_sq]
matrix results[5,6] = _se[log_expense_pp_noh_sq]
matrix results[5,7] = `e(N)'
matrix results[5,8] = `e(r2_a)'
matrix results[5,9] = _b[_cons]
matrix results[5,10] = _se[_cons]


reg share_item_in_exp_total_noh log_expense_pp_noh log_expense_pp_noh_sq `hhld_controls' if COICOP_2dig == 1 & log_expense_pp_noh>= `p10' & log_expense_pp_noh <= `p90'  [aw = wta_hh] , robust		
matrix results[6,1] =`country_name'
matrix results[6,2] = 3
matrix results[6,3] = _b[log_expense_pp_noh]
matrix results[6,4] = _se[log_expense_pp_noh]
matrix results[6,5] = _b[log_expense_pp_noh_sq]
matrix results[6,6] = _se[log_expense_pp_noh_sq]
matrix results[6,7] = `e(N)'
matrix results[6,8] = `e(r2_a)'
matrix results[6,9] = _b[_cons]
matrix results[6,10] = _se[_cons]
	
	
	matlist results
	
	preserve
	clear
	svmat results
	rename results1 country
	rename results2 regression_nb
	rename results3 b
	rename results4 se
	rename results5 b_sq
	rename results6 se_sq
	rename results7 N
	ren results8 adjusted_r2
	ren results9 b_cons
	ren results10 se_cons
	label define country_labels 50 "Malawi" 
	label values country country_labels
	
**********
* OUTPUT 3 *  Stata Database: regressions coefficients with standard errors, N , and adjusted R squared 
**********
save "$main/data/$db_fullname/${country_code}_reg_coeff", replace 



