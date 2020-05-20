
					*****************************************************
					* 		   Main Table of Regression Results			*
					* 	  	       Scenarios A, B, and C				*
					*****************************************************
***************
* DIRECTORIES *
***************
	
 if "`c(username)'"=="wb446741" { 											// Pierre's WB computer 
	global main "C:\Users\wb446741\Dropbox\Regressivity_VAT\Stata"
	}
	else if "`c(username)'"=="pierrebachas" { 									// Pierre's personal laptop
	global main "/Users/pierrebachas/Dropbox/Regressivity_VAT/Stata"
	}	
 else if "`c(username)'"=="elieg" { 											// Elie's laptop
	global main "C:\Users\elieg\Dropbox\Regressivity_VAT\Stata"
	}
 else if "`c(username)'"=="roxannerahnama" {
    global main "/Users/roxannerahnama/Dropbox/World_Bank/Regressivity_VAT/Stata" //Roxanne's laptop
}
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath	
	display "`c(current_date)' `c(current_time)'"

	
*********************************************	
// Objective
*********************************************	

/*

Create central table for Appendix (Tables C1-C3) where: 

-Rows are countries 

-Columns are specifications

	(1) is the "basic" no controls 
	
		corresponds to iteration 5 in Master_regressions_postestimation.do 
		
	(2) 1 + household characteristics (HC)
	
		corresponds to iteration 9 in Master_regressions_postestimation.do 	
		
	(3)-(4) + geography
	
		-(3) is HC + rural-urban
		
		corresponds to iteration 17 in Master_regressions_postestimation.do 
		
		-(4) is HC + geo_loc_min
		
		corresponds to iteration 18 in Master_regressions_postestimation.do 
		
		-(5) is HC + census_block
		
		corresponds to iteration 19 in Master_regressions_postestimation.do
		
	(6)-(7)-(8) are HC + COICOP 2, 3, and 4
	
		-(6) corresponds to iteration 10 in Master_regressions_postestimation.do 
		-(7) corresponds to iteration 11 in Master_regressions_postestimation.do 
		-(8) corresponds to iteration 12 in Master_regressions_postestimation.do 
	
	
	(9)-(10)-(11) are HC + geo_loc_min + COICOP 2 (8), 3 (9), and 4 (10)
	
		-(9)  corresponds to iteration 14 in Master_regressions_postestimation.do 
		-(10)  corresponds to iteration 15 in Master_regressions_postestimation.do 
		-(11) corresponds to iteration 16 in Master_regressions_postestimation.do 
	
	(12) is HC + census_block + COICOP 4
	
		- (12) corresponds to iteration 20 in Master_regressions_postestimation.do
	
-Entries are inverse slopes (no stars), standard error in parentheses (round two decimals)

*/	
	
	
*********************************************	
// Preliminaries
*********************************************	
	
	set more off
	set matsize 10000	
	
	global drop_housing = 1  // Set to 1 to run the code without housing	
	 
*********************************************	
// Keep iterations used for main table C1
*********************************************		

	*import excel using "$main/data/Country_information.xlsx" , clear firstrow	// bring in full names of countries for table
	*ren CountryCode country_code
	*ren Year year
	
	*merge 1:m country_code year using "$main/proc/regressions_output.dta"
	*keep if _merge == 3
	*drop _merge

	use "$main/proc/regressions_output.dta", clear
	
	keep if iteration == 5 | iteration == 9 | inrange(iteration, 17, 20) | inrange(iteration, 10, 12) | inrange(iteration, 14, 16)
	keep country_code iteration b se 
	sort country_code iteration

	gen b_inv = (-1)*b	// inverse slope
	gen col_num = 1 if iteration == 5
	replace col_num = 2 if iteration == 9 
	replace col_num = 3 if iteration == 17 
	replace col_num = 4 if iteration == 18
	replace col_num = 5 if iteration == 19
	replace col_num = 6 if iteration == 10
	replace col_num = 7 if iteration == 11
	replace col_num = 8 if iteration == 12
	replace col_num = 9 if iteration == 14
	replace col_num = 10 if iteration == 15
	replace col_num = 11 if iteration == 16
	replace col_num = 12 if iteration == 20
	
	// round b_inv, se to two digits
	
	gen double b_inv_round=round(b_inv, 0.01)
	gen double se_round=round(se, 0.01)
	
	gen se_test = string(se_round)

	*add parentheses around se
	gen l = length(se_test)
	replace se_test = se_test+"0" if l==2
	destring se_test, replace
	
	sort country_code col_num
	keep country_code col_num b_inv_round se_test
	
	ren b_inv_round b_inv
	ren se_test se 
	
	sort col_num
	by col_num: egen avg = mean(b_inv)
	
	ta col_num avg // keep track of the column-level average coefficients to add as a final row in the table of results manually
	
	// create matrix of coef, se
	*edit by hand 
	
*	local country_code "BR BF BI CM CL CO CR CD EC MX MA MZ NE PG PE CG RW ZA TZ UY" 
	local country_code "BO BR BF BI CM CL CO CR CD DO EC SZ MX MA MZ NE PG PE CG RW ST ZA TZ TU UY" 
	local n_models : word count `country_code'	

	forval i=1/`n_models' {
	global country_code `: word `i' of `country_code''		

	mkmat b_inv if country_code== "$country_code", mat(b_$country_code) 
	matrix b_t_$country_code = b_$country_code'
	mkmat (se) if country_code== "$country_code", mat(se_$country_code) 
	matrix se_t_$country_code = se_$country_code'
	matrix $country_code = [b_t_$country_code \ se_t_$country_code ]
	}
	
	*come back and improve this code
	*matrix table_all = [BR\BF\BI\CM\CL\CO\CR\CD\EC\MX\MA\MZ\NE\PG\PE\CG\RW\ZA\TZ\UY]
	matrix table_all = [BO\BR\BF\BI\CM\CL\CO\CR\CD\DO\EC\SZ\MX\MA\MZ\NE\PG\PE\CG\RW\ST\ZA\TZ\TU\UY]
	matrix colnames table_all = No_control Hhld_Char Rur_Urb District Census_Block Level2 Level3 Level4 Level2 Level3 Level4 Level4
	matrix rownames table_all = Bolivia fillerhere Brazil fillerhere Burkina_Faso fillerhere Burundi fillerhere Cameroon ///
	fillerhere Chile fillerhere Colombia fillerhere Costa_Rica fillerhere Dem_Rep_Congo fillerhere Dominican_Rep fillerhere /// 
	Ecuador fillerhere Eswatini fillerhere Mexico fillerhere Morocco fillerhere Mozambique fillerhere ///
	Niger fillerhere Papua_New_Guinea fillerhere Peru fillerhere Rep_of_Congo fillerhere Rwanda fillerhere /// 
	SaoTome fillerhere South_Africa fillerhere Tanzania  fillerhere Tunisia fillerhere Uruguay fillerhere 
/*	matrix rownames table_all = Brazil fillerhere Burkina_Faso fillerhere Burundi fillerhere Cameroon ///
	fillerhere Chile fillerhere Colombia fillerhere Costa_Rica fillerhere Dem_Rep_Congo fillerhere Ecuador fillerhere ///
	Mexico fillerhere Morocco fillerhere Mozambique fillerhere Niger fillerhere Papua_New_Guinea fillerhere Peru fillerhere /// 
	Rep_of_Congo fillerhere Rwanda fillerhere South_Africa fillerhere Tanzania  fillerhere Uruguay fillerhere */

	matrix list table_all
	
	
	*can add a line to code to make there be () around se?
	outtable using "$main/proc/table", mat(table_all) nobox f(%12.2fc) center replace // not the best format for the table 

	*post instructions
	
	/*
	When copying outtable latex code, use find/replace to remove all the "fillerheres" and just leave the replace as blank
	
	Need to manually create a final row that is the cross country averages.
	These averages are calculated in graphs_regression_output.do 
	
	*/

	
	/*
	
	*ROBUSTNESS TABLE C2: SCENARIO B (all of the 3's in new classification are classified as informal)

	*/
	
	use "$main/proc/regressions_output_robust_B.dta", clear
	
	keep if iteration == 5 | iteration == 9 | inrange(iteration, 17, 20) | inrange(iteration, 10, 12) | inrange(iteration, 14, 16)
	keep country_code iteration b se 
	sort country_code iteration

	gen b_inv = (-1)*b	// inverse slope
	gen col_num = 1 if iteration == 5
	replace col_num = 2 if iteration == 9 
	replace col_num = 3 if iteration == 17 
	replace col_num = 4 if iteration == 18
	replace col_num = 5 if iteration == 19
	replace col_num = 6 if iteration == 10
	replace col_num = 7 if iteration == 11
	replace col_num = 8 if iteration == 12
	replace col_num = 9 if iteration == 14
	replace col_num = 10 if iteration == 15
	replace col_num = 11 if iteration == 16
	replace col_num = 12 if iteration == 20
	
	// round b_inv, se to two digits
	
	gen double b_inv_round=round(b_inv, 0.01)
	gen double se_round=round(se, 0.01)
	
	gen se_test = string(se_round)

	*add parentheses around se
	gen l = length(se_test)
	replace se_test = se_test+"0" if l==2
	destring se_test, replace
	
	sort country_code col_num
	keep country_code col_num b_inv_round se_test
	
	ren b_inv_round b_inv
	ren se_test se 
	
	sort col_num
	by col_num: egen avg = mean(b_inv)
	
	ta col_num avg // keep track of the column-level average coefficients to add as a final row in the table of results manually
	
	// create matrix of coef, se
	
	local country_code "BR BF BI CM CL CO CR CD EC MX MA MZ NE PG PE CG RW ZA TZ UY" 
	local n_models : word count `country_code'	

	forval i=1/`n_models' {
	global country_code `: word `i' of `country_code''		

	mkmat b_inv if country_code== "$country_code", mat(b_$country_code) 
	matrix b_t_$country_code = b_$country_code'
	mkmat (se) if country_code== "$country_code", mat(se_$country_code) 
	matrix se_t_$country_code = se_$country_code'
	matrix $country_code = [b_t_$country_code \ se_t_$country_code ]
	}
	
	*come back and improve this code
	matrix table_all = [BR\BF\BI\CM\CL\CO\CR\CD\EC\MX\MA\MZ\NE\PG\PE\CG\RW\ZA\TZ\UY]
	matrix colnames table_all = No_control Hhld_Char Rur_Urb District CB Level2 Level3 Level4 Level2 Level3 Level4 Level4
	matrix rownames table_all = Brazil fillerhere Burkina_Faso fillerhere Burundi fillerhere Cameroon ///
	fillerhere Chile fillerhere Colombia fillerhere Costa_Rica fillerhere Dem_Rep_Congo fillerhere Ecuador fillerhere ///
	Mexico fillerhere Morocco fillerhere Mozambique fillerhere Niger fillerhere Papua_New_Guinea fillerhere Peru fillerhere /// 
	Rep_of_Congo fillerhere Rwanda fillerhere South_Africa fillerhere Tanzania  fillerhere Uruguay fillerhere 
	
	matrix list table_all
	
	
	*can add a line to code to make there be () around se?
	outtable using "$main/proc/table_robust_B", mat(table_all) nobox f(%12.2fc) center replace // not the best format for the table 

	*post instructions
	
	/*
	When copying outtable latex code, use find/replace to remove all the "fillerheres" and just leave the replace as blank
	
	Need to manually create a final row that is the cross country averages.
	These averages are calculated in graphs_regression_output.do 

	*/


	/*
	
	*ROBUSTNESS TABLE C3: SCENARIO C (all of the 3's in new classification are classified as formal)

	*/
	
	use "$main/proc/regressions_output_robust_C.dta", clear
	
	keep if iteration == 5 | iteration == 9 | inrange(iteration, 17, 20) | inrange(iteration, 10, 12) | inrange(iteration, 14, 16)
	keep country_code iteration b se 
	sort country_code iteration

	gen b_inv = (-1)*b	// inverse slope
	gen col_num = 1 if iteration == 5
	replace col_num = 2 if iteration == 9 
	replace col_num = 3 if iteration == 17 
	replace col_num = 4 if iteration == 18
	replace col_num = 5 if iteration == 19
	replace col_num = 6 if iteration == 10
	replace col_num = 7 if iteration == 11
	replace col_num = 8 if iteration == 12
	replace col_num = 9 if iteration == 14
	replace col_num = 10 if iteration == 15
	replace col_num = 11 if iteration == 16
	replace col_num = 12 if iteration == 20 
	
	// round b_inv, se to two digits
	
	gen double b_inv_round=round(b_inv, 0.01)
	gen double se_round=round(se, 0.01)
	
	gen se_test = string(se_round)

	*add parentheses around se
	gen l = length(se_test)
	replace se_test = se_test+"0" if l==2
	destring se_test, replace
	
	sort country_code col_num
	keep country_code col_num b_inv_round se_test
	
	ren b_inv_round b_inv
	ren se_test se 
	
	
	sort col_num
	by col_num: egen avg = mean(b_inv)
	
	ta col_num avg // keep track of the column-level average coefficients to add as a final row in the table of results manually

	
	// create matrix of coef, se
	
	local country_code "BR BF BI CM CL CO CR CD EC MX MA MZ NE PG PE CG RW ZA TZ UY" 
	local n_models : word count `country_code'	

	forval i=1/`n_models' {
	global country_code `: word `i' of `country_code''		

	mkmat b_inv if country_code== "$country_code", mat(b_$country_code) 
	matrix b_t_$country_code = b_$country_code'
	mkmat (se) if country_code== "$country_code", mat(se_$country_code) 
	matrix se_t_$country_code = se_$country_code'
	matrix $country_code = [b_t_$country_code \ se_t_$country_code ]
	}
	
	*come back and improve this code
	matrix table_all = [BR\BF\BI\CM\CL\CO\CR\CD\EC\MX\MA\MZ\NE\PG\PE\CG\RW\ZA\TZ\UY]
	matrix colnames table_all = No_control Hhld_Char Rur_Urb District CB Level2 Level3 Level4 Level2 Level3 Level4 Level4
	matrix rownames table_all = Brazil fillerhere Burkina_Faso fillerhere Burundi fillerhere Cameroon ///
	fillerhere Chile fillerhere Colombia fillerhere Costa_Rica fillerhere Dem_Rep_Congo fillerhere Ecuador fillerhere ///
	Mexico fillerhere Morocco fillerhere Mozambique fillerhere Niger fillerhere Papua_New_Guinea fillerhere Peru fillerhere /// 
	Rep_of_Congo fillerhere Rwanda fillerhere South_Africa fillerhere Tanzania  fillerhere Uruguay fillerhere 
	
	matrix list table_all
	
	
	*can add a line to code to make there be () around se?
	outtable using "$main/proc/table_robust_C", mat(table_all) nobox f(%12.2fc) center replace // not the best format for the table 

	*post instructions
	
	/*
	When copying outtable latex code, use find/replace to remove all the "fillerheres" and just leave the replace as blank
	
	Need to manually create a final row that is the cross country averages.
	These averages are calculated in graphs_regression_output.do 

	*/
