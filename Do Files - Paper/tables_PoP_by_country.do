					*************************************
					*	 	CREATE SYNTHETIC			*
					* 	 RETAILERS TABLE BY SECTOR		*
					*************************************

		
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

* When importing to Excel, make sure to change the format of the pct column to "%" and make the "Assigned as" column in bold
