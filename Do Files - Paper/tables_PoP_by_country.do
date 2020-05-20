					*************************************
					*	 	CREATE SYNTHETIC			*
					* 	 RETAILERS TABLE BY SECTOR		*
					*************************************



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
else if "`c(username)'"=="wb520324" { 											// Eva's WB computer 
	global main "C:\Users\wb520324\Dropbox\Regressivity_VAT\Stata"
	}
	
else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}	
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath
	display "`c(current_date)' `c(current_time)'"

			
*******************************************************	
* 	0. Parameters: Informality definition and sample
******************************************************		
	*** SAMPLE 	
	import excel using "$main/data/Country_index_for_stata_loop.xlsx" , clear firstrow sheet("main_sample") 
*	keep if country_code == "MX"			// To run on one country select its acronym  
	
	qui valuesof country_code
	local country_code = r(values)
	display `"`country_code'"'
	qui valuesof country_fullname
	local country_fullname = r(values)
	display `"`country_fullname'"'
	
	local n_models : word count `country_code'
	assert `n_models'==`:word count `country_fullname''  // this ensures that the two lists are of the same length
	
		
*********************************************	
// 1. Loop Over all Countries with COICOP
*********************************************		

	forval k=1/`n_models' {
	***************
		* GLOBALS	 *
		***************	
		
		global country_code `: word `k' of `country_code''		
		global country_fullname `: word `k' of `country_fullname''	
		display "*************** Country: $country_fullname **************************" 
		
	// We extract all the countries table where we assigned the classification 
	import excel "$main/tables/$country_fullname/${country_fullname}_TOR_recode_nohousing.xls",  sheet("recode(Aug19)") firstrow clear
	destring pct_expenses, force replace

	gen country="$country_fullname"
	keep country pct_expenses TOR_original_label detailed_classification   
	

	rename pct_expenses pct 
	label var pct "$\%$"
	rename TOR_original_label Original_name
	rename detailed_classification classification 
	
	replace pct=pct
	
	
	*We create a variable to sort our TOR in the desired order
	gen right_TOR_order=1 if classification==5
	replace right_TOR_order=2 if classification==4
	replace right_TOR_order=3 if classification==10
	replace right_TOR_order=4 if classification==6
	replace right_TOR_order=5 if classification==8
	replace right_TOR_order=6 if classification==3
	replace right_TOR_order=7 if classification==2
	replace right_TOR_order=8 if classification==1
	replace right_TOR_order=9 if classification==7
	replace right_TOR_order=10 if classification==9
	replace right_TOR_order=11 if classification==99
	
	gsort right_TOR_order +classification -pct
	
	bysort right_TOR_order: gen Assigned="Formal" if classification==5 & _n == 1 
	* one country does not have the category 5
	bysort right_TOR_order: replace Assigned="Formal" if classification==4 & _n == 1 & country=="Mozambique2009"
	bysort right_TOR_order: replace Assigned="Informal" if classification==3 & _n == 1
	*few countries do not have the category 3
	bysort right_TOR_order: replace Assigned="Informal" if classification==2 & _n == 1 & (country=="Montenegro2009" | country=="Mozambique2009"  | country=="SouthAfrica2011" | country=="Tanzania2012" | country=="Tunisia2010")  
	bysort right_TOR_order: replace Assigned="Unspec." if classification==99 & _n == 1

	
	
		*collapse unspecified
	egen total_unspecified= sum(pct) if classification==99
	replace pct=total_unspecified if classification==99
	replace Original_name="Other" if classification==99
	duplicates drop country pct Original_name classification, force

	
	*id to merge later
	tostring classification, replace
*	gen id1=1 if classification=="5" | classification=="4" | classification=="10" | classification=="6" | classification=="8"
*	replace id1=2 if classification=="3" | classification=="2" | classification=="1" | classification=="7" | classification=="9"
*	replace id1=3 if classification=="99"
*	gen id2=[_n]
*	egen id = concat(id1 id2)

	

    drop if classification=="."
	replace classification="1 non-market" if classification=="1"
	replace classification="2 no store front" if classification=="2"
	replace classification="3 corner shops" if classification=="3"
	replace classification="4 specialized shops" if classification=="4"
	replace classification="5 large stores" if classification=="5"
	replace classification="6 institutions" if classification=="6"
	replace classification="7 service from individual" if classification=="7"
	replace classification="8 entertainment" if classification=="8"
	replace classification="9 informal entertainment" if classification=="9"
	replace classification="4 specialized shops" if classification=="10"
	replace classification="99 n.a./other" if classification=="99"
	
	
    drop right_TOR_order total_unspecified
	
	*Cut the number of characters allowed so that the column is not too large
	gen Original_name_short=substr(Original_name, 1, 42)
	drop Original_name
	rename Original_name_short Original_name
	gen loriginal_name=lower(Original_name)
	drop Original_name
	ren loriginal_name Original_name
    order country Assigned pct Original_name classification , first 

*	rename Assigned Assigned_$country_fullname
*	rename pct pct_$country_fullname
*	rename Original_name Original_name_$country_fullname
*	rename classification classification_$country_fullname
*	rename id1 id1_$country_fullname
*	rename id2 id2_$country_fullname

	
	tempfile $country_fullname
	save `$country_fullname'
	}
	
*Full dictionnary
use `Benin2015' , clear
append using `Bolivia2004'
append using `Brazil2009'
append using `BurkinaFaso2009'
append using `Burundi2014'
append using `Cameroon2014'
append using `Chad2003'
append using `Chile2017'
append using `Colombia2007'
append using `Comoros2013'
append using `Congo_DRC2005'
append using `Costa_Rica2014'
append using `Dominican_Rep2007'
append using `Ecuador2012'
append using `Eswatini2010'
append using `Mexico2014'
append using `Montenegro2009'
append using `Morocco2001'
append using `Mozambique2009'
append using `Niger2007'
append using `Papua_NG2010'
append using `Peru2017'
append using `Congo_Rep2005'
append using `Rwanda2014'
append using `SaoTome2010'
append using `Senegal_Dakar2008'
append using `Serbia2015'
append using `SouthAfrica2011'
append using `Tanzania2012'
append using `Tunisia2010'
append using `Uruguay2005'

drop if pct<0.005 &  Assigned=="" // drop less than 0.5% if not 

* Add manually Unspecified category to Comoros whixh does not have one
insobs 1, before(155)

replace country = "Comoros2013" in 155
replace Assigned = "Unspec." in 155
replace pct = 0 in 155
replace Original_name = "other" in 155


export excel "$main/tables/retailers_table/all_TOR_cross_countries.xls", replace  firstrow(variables)  locale(C)

* WHEN YOU IMPORT THE EXCEL TO LATEX MAKE SURE TO CHANGE THE FORMAT OF THE % COLUMN!!!! AND PUT THE ASSIGNED AS COLUMN IN BOLD CHARACTERS


*DRAFT

*by 2
use `Benin2015' , clear
merge 1:1 id using `Bolivia200
*Find the max
use `Benin2015' , clear
append using `Bolivia2004'
append using `Brazil2009'

egen obs_per_sector= count(classification), by (country Assigned_as)
egen max_formal=max(obs_per_sector) if Assigned_as=="Formal"
egen max_informal=max(obs_per_sector) if Assigned_as=="Informal"

su obs_per_sector if Assigned_as=="Formal", meanonly 
global max_formal = r(max)

su obs_per_sector if Assigned_as=="Informal", meanonly 
global max_informal = r(max)

putexcel set "$main\tables\retailers_table\all_TOR_cross_countries.xls", sheet("BJ_BO_BR") modify
global excel_row = 1
display $excel_row
putexcel A$excel_row = "Assigned to"
putexcel B$excel_row = "%"
putexcel D$excel_row = "Classification"
putexcel E$excel_row = "%"
putexcel G$excel_row = "Classification"
putexcel H$excel_row = "%"
putexcel J$excel_row = "Classification"

local file_num "Benin Bolivia Brazil"
local excel_col "C F I"	
local n_country : word count `file_num'
forval i=1/`n_country' {


		***************
		* GLOBALS	 *
		***************	

global file_num `: word `i' of `file_num''	
global excel_col `: word `i' of `excel_col''

putexcel $excel_col$excel_row = "$file_num"


}

*Formal
use `Benin2015' , clear
putexcel set "$main\tables\retailers_table\all_TOR_cross_countries.xls", sheet("BJ_BO_BR") modify
global excel_row = $excel_row + 1
global excel_row_max = $excel_row + $max_formal
display $excel_row
display $excel_row_max
putexcel (A$excel_row :A$excel_row_max) =Assigned_as
putexcel (B$excel_row :B$excel_row_max) =pct
putexcel (C$excel_row :C$excel_row_max) =Original_name
putexcel (D$excel_row :D$excel_row_max) =classification

*Bolivia

use `Bolivia2004' , clear
putexcel set "$main\tables\retailers_table\all_TOR_cross_countries.xls", sheet("BJ_BO_BR") modify
global excel_row_max = $excel_row + $max_formal
display $excel_row
display $excel_row_max
putexcel (E$excel_row :E$excel_row_max) =pct
putexcel (F$excel_row :F$excel_row_max) =Original_name
putexcel (G$excel_row :G$excel_row_max) =classification
*loop over Bolivia and Brazil

*Informal

*Unspecified (should be easier because only one line)

*FIND HOW TO HAVE THE INFORMATION DIFFERENt!

*DRAFT


*pct
local file_num "Benin Bolivia Brazil"
local excel_col "B E H"	
local n_country : word count `file_num'
forval i=1/`n_country' {


		***************
		* GLOBALS	 *
		***************	

global file_num `: word `i' of `file_num''	
global excel_col `: word `i' of `excel_col''

putexcel $excel_col :$excel_row = "$file_num"


}



keep if country=="Benin2015"

*global excel_row = $excel_row + 1
*global excel_row_max= $excel_row +17 /// way to automatize!
putexcel A2:A17 =Assigned_as
putexcel B$excel_row : B$excel_row_max = pct
putexcel C$excel_row : C$excel_row_max = Original_name
putexcel D$excel_row : D$excel_row_max = classification

use "$main\tables\retailers_table\benin_tmp.dta" ,clear 
putexcel set "$main\tables\retailers_table\all_TOR_cross_countries_tmp.xls", sheet("BJ_BO_BR") modify

putexcel A2:A17 =Assigned_as


global excel_row = $excel_row + 1
matrix results =

putexcel A$excel_row = matrix(results)

global excel_row = $excel_row + 7  // we have added six lines




global excel_row = 1
display $excel_row
putexcel A$excel_row = "Assigned to"
putexcel B$excel_row = "%"
putexcel D$excel_row = "Classification"
putexcel E$excel_row = "%"
putexcel G$excel_row = "Classification"
putexcel H$excel_row = "%"
putexcel J$excel_row = "Classification"

local file_num "Benin Bolivia Brazil"
local excel_col "C F I"	
local n_country : word count `file_num'
forval i=1/`n_country' {


		***************
		* GLOBALS	 *
		***************	

global file_num `: word `i' of `file_num''	
global excel_col `: word `i' of `excel_col''

putexcel $excel_col$excel_row = "$file_num"


}
global excel_row = $excel_row + 1
global excel_row = $excel_row + 7  // we have added six lines

putexcel A$excel_row = matrix(results)

export excel "$main\tables\retailers_table\all_TOR_cross_countries.xls", replace  firstrow(variables) 

* We have created the full glossary of all the TOR that exists per country
* We now want to import this table to latex, and remove the very small expenses 
drop if pct<0.005
	
	
	
	
*DRAFT 
	bysort right_TOR_order: replace order_assigned_as="Formal" if classification==4 & _n == 1 & country=="Mozambique2009"
	bysort right_TOR_order: replace order_assigned_as="Informal" if classification==3 & _n == 1
	*few countries do not have the category 3
	bysort right_TOR_order: replace order_assigned_as="Informal" if classification==2 & _n == 1 & (country=="Burundi2014" | country=="Chad2003" | country=="Comoros2013" | country=="Montenegro2009" | country=="Mozambique2009" | country=="Serbia2015" | country=="SouthAfrica2011" | country=="Tanzania2012" | country=="Tunisia2010")  
	bysort right_TOR_order: replace order_assigned_as="Unspecified" if classification==99 & _n == 1

***********************************************
********************DRAFT ROXANNE************** 
**********************************************
 // to prevent mistakingly running everything

					*************************************
					*	 	CREATE SYNTHETIC			*
					* 	 RETAILERS TABLE BY SECTOR		*
					*************************************



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
	else if "`c(username)'"=="wb520324" { 											// Eva's WB computer 
	global main "C:\Users\wb520324\Dropbox\Regressivity_VAT/Stata"
	}
	
	else if "`c(username)'"=="evadavoine" { 									// Eva's personal laptop
	global main "/Users/evadavoine/Dropbox/Regressivity_VAT/Stata"
	}	
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath
	display "`c(current_date)' `c(current_time)'"

	
*******************************************


global countries_fullnames `" "Montenegro2009" "'
sca n_countries = 1

*Fill in X one by one with each country below
*Benin2015
*Bolivia2004
*Brazil2009
*BurkinaFaso2009
*Burundi2014
*Cameroon2014
*Chad2003
*Chile2017
*Colombia2007
*Comoros2013
*Congo_DRC2005
*Costa_Rica2014
*Dominican_Rep2007
*Ecuador2012
*Eswatini2010
*Mexico2014
*Montenegro2009
*Morocco2001
*Mozambique2009
*Niger2007
*Papua_NG2010
*Peru2017
*Congo_Rep2005
*Rwanda2014
*SaoTome2010
*Senegal_Dakar2008
*Serbia2015
*SouthAfrica2011
*Tanzania2012
*Tunisia2010
*Uruguay2005


*keep at least two categories and another about 0.5\%


**
*1) Generate simplified TOR_recode tables per country 
* Two options: with TOR_original or TOR_recode directly
foreach h of numlist 1/ `=n_countries' {   // with or without housing
	set more off
	local country_fullname : word `h' of $countries_fullnames
	// working on TOR_original
	use "$main/tables/`country_fullname'/Retailer_classification_nohousing.dta", clear
	destring pct_expenses, force replace
	replace Formal_Informal_0_1 = 2 if Formal_Informal_0_1 == 0
	replace Formal_Informal_0_1 = 3 if Formal_Informal_0_1 == 9
	gsort Formal_Informal_0_1 -new_classification 
	by Formal_Informal_0_1: gen pct_order = _n
	drop if pct_expenses < 0.005
	*keep if pct_order < 6
	*drop if pct_order > 2 & pct_expenses < 0.005 // corresponds to 0.5%
	gen merge_code = Formal_Informal_0_1 * 10 + pct_order // 11, 12, 13, 14, 15, 21, 22, 23,... to 45
	order merge_code Formal_Informal Formal_Informal_0_1_label pct_expenses TOR_original_label new_classification TOR_Recode_label
	keep merge_code Formal_Informal_0_1_label pct_expenses TOR_original_label detailed_classification  
	rename pct_expenses pct_`country_fullname'
	rename TOR_original_label TOR_original_`country_fullname'
	save "$main/tables/retailers_table/`country_fullname'_retailers_table_nohousing.dta", replace
	di " `country_fullname' "
}

* Second step: merge country tables, choosing TOR_original or TOR_recode
foreach h of numlist 1/ `=n_countries' {   // with or without housing
	local country_fullname : word `h' of $countries_fullnames
	if `h' == 1 {
		use "$main/tables/retailers_table/`country_fullname'_retailers_table_nohousing.dta", clear
	}
	else {
	merge 1:1 merge_code using "$main/tables/retailers_table/`country_fullname'_retailers_table_nohousing.dta", nogen
	}
	di " `country_fullname' "

	export excel using "$main/tables/retailers_table/retailers_table_`country_fullname'.xls", replace firstrow(variables)
}

*drop merge_code
*export excel using "$main/tables/retailers_table/retailers_table.xls", replace firstrow(variables)

* Third step:
* open retailers_table_country_fullname and copy 
* paste contents to retailers_table_latex.xls [organize two countries next to each other, alphabetical]






/*OLD
// working on TOR_recode instead of TOR_original
	use "$main/tables/`country_fullname'/Retailer_classification.dta", clear
	destring pct_expenses, force replace
	sort Formal_Informal TOR_Recode_label
	collapse (sum) pct_expenses, by(Formal_Informal TOR_Recode_label) // the main difference is here
	gsort Formal_Informal -pct_expenses
	by Formal_Informal: gen pct_order = _n
	keep if pct_order < 6
	gen merge_code = Formal_Informal * 10 + pct_order // 11, 12, 13, 14, 15, 21, 22, 23,... to 45
	order merge_code Formal_Informal pct_expenses TOR_Recode_label // TOR_original_label not here
	keep merge_code Formal_Informal pct_expenses TOR_Recode_label
	rename pct_expenses pct_`country_fullname'
	rename TOR_Recode_label TOR_`country_fullname'
	save "$main/tables/retailers_table/`country_fullname'_retailers_table_recode.dta", replace
*/




	
	
	

