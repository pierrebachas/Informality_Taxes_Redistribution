

					*************************************
					* 			Main DO FILE			*
					* 	      ECUADOR 2012				*
					*************************************



***************
* DIRECTORIES *
***************

if "`c(username)'"=="wb520324" { 													// Eva's WB computer 
	global main "C:/Users/wb520324/Dropbox/Regressivity_VAT/Stata"		
}	
 else if "`c(username)'"=="" { 										
	global main ""
	}
	
	qui include "$main/dofiles/server_header.doh" 								// Runs a file defining the globals for all subpath
	display "`c(current_date)' `c(current_time)'"


********************************************************************************
********************************************************************************

	
	global country_fullname "Ecuador2012"
	global country_code "EC"
	
/* SUMMARY:
   Step 0:  Data overview
   Step 1:  Prepare covariates at the household level
   Step 2: Preparing the expenditures database 
   Step 2.1: Harmonization of names, introduction of labels
   Step 2.2: Product crosswalk if product codes are not COICOP
   Step 3: Generating total expenditures and total income
   Step 3.1: Total expenditures
   Step 3.2 Total income
   Step 3.3: Merge with the household covariates datafile
   Step 4: Crosswalk between places of purchase and classification
   Step 5: Creation of database at the COICOP_4dig level
   */
	
*****************************
* Step 0:  Data overview    *
*****************************	
	
/*
*Weight variable is called fexp_cen2010 [the expansion factor]
1. Miebros del Hogar (Personas).dta: Contains info of all people that make up households, with demographic, educational, etc. variables
2. Indentificacion.dta - has weight variable as well as total household income, total spending, and some variable called relation
   which is described as relation income-expenditure (I imagine its some sort of variable for savings)?
3. Gastos Diarios Seccion II: daily monetary and non-monetary expenses in food, beverages, and tobacco. 
4. Gastos Diarios Seccion III: daily monetary and non-monetary expenses. 
5. Gastos Diarios Seccion IV: daily monetary and non-monetary expenses. 
6. Gastos Mensuales: monthly expenses
7. Gastos Trimenstrales: quarterly expenses
8. Gastos Semestrales: half year expenses
9. Gastos Anuales: annual expenses

*additional modules on benefits but maybe the total income variable is okay? 
*/


*****************************************************
* Step 1: Prepare covariates at the household level *
*****************************************************

* [Output = Note in Masterfile + dataset _household_cov_original to complete later]
	clear
	set more off
	use "$main/data/$country_fullname/04_enighur11_personas.dta", clear
	ren identif_hog hhid
	drop if p04 != 1 //keep only household heads and single-person households
	duplicates drop hhid, force
	tempfile demo_indiv
	save `demo_indiv'
	
	clear	
	set more off
	use "$main/data/$country_fullname/01_enighur11_identificacion.dta", clear
	
	*hhid
	ren identif_hog hhid
	merge m:1 hhid using `demo_indiv'
 	keep if _merge == 3


	*We select the necessary variables and use the same names for all countries :
	*hhid hh_weight geo_loc geo_loc_min (sometimes others geographic variables when available) urban head_sex head_age head_edu hh_size exp_agg_tot inc_agg_tot
	*Sometimes rent information is in the HH dataset: house_owner, house_rent, house_est_rent, house_pay ...	
 	

	rename fexp_cen2010 						hh_weight
	rename provincia							geo_loc //24
	rename ciudad								geo_loc_min // 624
	rename area 								urban 
	rename p02									head_sex
	rename p03									head_age
	rename p14a									head_edu
	rename numpers 								hh_size
	rename p07									head_ethnicity
	

	*We need to construct/modify some of them
	
	*exp_agg_tot
	gen expenses = gasto*12 //annualize (monthly?) expenses

	*inc_agg_tot
	gen income = ingreso*12 //annualize (monthly?) income
	
	*census_block
	egen census_block = concat(zona sector) // 1056 unique values; this is my best guess
	

	*We destring and label some variables for clarity/uniformity 
	destring head_sex, force replace
	destring head_age, force replace			
	destring head_edu, force replace					// Some of these variables are already numeric
	
	ta head_sex, missing
	label define head_sex_lab 1 "Male" 2 "Female"
	label values head_sex head_sex_lab
	
	ta urban
	ta urban, nol
	replace urban = 0 if urban == 2
	label define urban_lab 0 "Rural" 1 "Urban"
	label values urban urban_lab
	
	
	*We keep only one line by household and necessary covariates 
 	duplicates drop hhid , force 
 
	keep hhid hh_weight head_sex head_age head_edu hh_size urban geo_loc  geo_loc_min census_block 
	destring hhid, replace
	order hhid, first 
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_household_cov_original.dta" , replace
	


************************************************************
* Step 2: Renaming and labelling the expenditures database *
************************************************************

************************************************************
* Step 2.1: Harmonization of names, introduction of labels *
************************************************************


	*DIARY
	clear 
	set more off
	use "$main/data/$country_fullname/28_enighur11_gdiarios_seccion2.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog    					hhid
	rename fexp_cen2010 					hh_weight
	rename gd210 							TOR_original 
	rename gd201							product_code
	rename gd201d							product_name
	rename gd205							quantity
	rename gd206							unit 
	rename gd209							amount_paid  // cuanto pago o tendra que pagar?
	rename gd208							payment_method

	
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = gd213
	gen agg_value_on_period_nm = gd214
	replace agg_value_on_period = agg_value_on_period_nm if agg_value_on_period == . 


	gen module_tracker = "Diary 1"
	tempfile diary
	save `diary'
	
	*DIARY 2
	
	clear 
	set more off

	use "$main/data/$country_fullname/29_enighur11_gdiarios_seccion3.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gd310 							TOR_original 
	rename gd301							product_code
	rename gd301d							product_name
	rename gd305 							quantity
	rename gd309							amount_paid // cuanto pago o tendra que pagar?
	rename gd306							unit 
	rename gd308							payment_method
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = gd313
	gen agg_value_on_period_nm = gd314
	replace agg_value_on_period = agg_value_on_period_nm if agg_value_on_period == . 							
	
	gen module_tracker = "Diary 2"
	tempfile diary2
	save `diary2'
	
	*DIARY 3
	clear 
	set more off

	use "$main/data/$country_fullname/30_enighur11_gdiarios_seccion4.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gd410 							TOR_original 
	rename gd401							product_code
	rename gd401d							product_name
	rename gd405							quantity
	rename gd406							unit
	rename gd409							amount_paid // Cuanto pago?
	rename gd408							payment_method 
	
	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = gd413
	
	
	gen module_tracker="Diary 3"
	tempfile diary3
	save `diary3'
	
	
	
	*DIARY MONTH
	clear
	set more off
	use "$main/data/$country_fullname/35_enighur11_gmensuales.dta", clear
	
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gm09 							TOR_original 
	rename gm01								product_code
	rename gm01d							product_name
	rename gm05								quantity
	rename gm06								unit 
	rename gm08								amount_paid // cuanto pago o tendra que pagar?
	rename gm07								payment_method

	*We need to construct/modify some of them
	*agg_value_on_period
	gen agg_value_on_period = gm12
	gen agg_value_on_period_nm = gm13
	replace agg_value_on_period = agg_value_on_period_nm if agg_value_on_period == . 
	
	gen module_tracker="Diary Monthly"
	tempfile diary_month
	save `diary_month'
	
	*DIARY QUATERLY
	clear
	set more off
	use "$main/data/$country_fullname/36 enighur11_gtrimestrales.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gt11 							TOR_original 
	rename gt01								product_code
	rename gt01d							product_name
	rename gt05								quantity
	rename gt06								unit 
	rename gt08								amount_paid // cuanto pago o tendra que pagar?
	rename gt07								payment_method 

	*We need to construct/modify some of them
	*agg_value_on_period 
	gen agg_value_on_period = gt15
	gen agg_value_on_period_nm = gt16
	replace agg_value_on_period = agg_value_on_period_nm if agg_value_on_period == . 
	
	gen module_tracker="Diary Quarter"
	tempfile diary_quarter
	save `diary_quarter'
	
	*DIARY SEMESTER
	clear
	set more off
	use "$main/data/$country_fullname/37_enighur11_gsemestrales.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gs11 							TOR_original 
	rename gs01								product_code
	rename gs01d							product_name
	rename gs05								quantity
	rename gs06								unit 
	rename gs08								amount_paid // cuanto pago o tendra que pagar?
	rename gs07								payment_method

	*We need to construct/modify some of them
	*agg_value_on_period 
	gen agg_value_on_period = gs15
	gen agg_value_on_period_nm = gs16
	replace agg_value_on_period = agg_value_on_period_nm if agg_value_on_period == . 	
	
	gen module_tracker="Diary Semester"
	tempfile diary_semester
	save `diary_semester'
	
	*DIARY ANNUAL
	clear
	set more off	
	use "$main/data/$country_fullname/38_enighur11_ganuales.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename ga11 							TOR_original //65 categories for this one 
	rename ga01								product_code
	rename ga01d							product_name
	*ren ga14								agg_value_on_period
	rename ga05								quantity
	rename ga06								unit 
	rename ga08								amount_paid // cuanto pago o tendra que pagar?
	rename ga07								payment_method
	
	*We need to construct/modify some of them
	*agg_value_on_period 
	gen agg_value_on_period = ga15
	gen agg_value_on_period_nm = ga16
	replace agg_value_on_period = agg_value_on_period_nm if agg_value_on_period == . 	
	
	gen module_tracker="Diary Annual"
	tempfile diary_annual
	save `diary_annual'
	
	*HOUSING 1
	clear 
	set more off
	use "$main/data/$country_fullname/31_enighur11_gmensuales_partea.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gma01							product_code
	rename gma02							product_name 
	rename gma04							amount_paid
	rename gma05 							quantity
	
	*We need to construct/modify some of them

	*agg_value_on_period 
	gen agg_value_on_period = amount_paid
	replace agg_value_on_period = gma06 if gma06 != .

	*TOR_original
	gen TOR_original = 81

	
	gen module_tracker="Housing 1"
	tempfile housing
	save `housing'
	
	*HOUSING 2
	clear 
	set more off
	use "$main/data/$country_fullname/32_enighur11_gmensuales_parteb.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gmb01							product_code
	rename gmb02							product_name 
	rename gmb04 							quantity
	rename gmb05							unit
	
	*We need to construct/modify some of them
	
	*agg_value_on_period 
	gen agg_value_on_period = gmb08

	*TOR_original
	gen TOR_original = 81

	
	gen module_tracker="Housing 2"
	tempfile housing2
	save `housing2'
	
	*HOUSING 3
	clear 
	set more off
	use "$main/data/$country_fullname/33_enighur11_gmensuales_partec.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gmc01							product_code
	rename gmc02							product_name 
	rename gmc04 							quantity
	rename gmc05							unit
	rename gmc06							amount_paid
	
	*We need to construct/modify some of them
	*agg_value_on_period 
	gen agg_value_on_period = amount_paid


	*TOR_original
	gen TOR_original = 81

	
	gen module_tracker="Housing 3"
	tempfile housing3
	save `housing3'
	
	*HOUSING 4
	clear 
	set more off
	use "$main/data/$country_fullname/34_enighur11_gmensuales_parted.dta", clear
	
	*We select the necessary variables in each file and use the same names for all countries :
	*hhid, TOR_original, amount_paid, agg_value_on_period, quantity, unit, price, reason_recode, country_of_prod, product_code,coicop_2dig, housing
	rename identif_hog						hhid
	rename fexp_cen2010 					hh_weight
	rename gmd01							product_code
	rename gmd02							product_name 
	rename gmd04							amount_paid
	
	*We need to construct/modify some of them
	
	*quantity
	gen quantity=1

	
	*agg_value_on_period 
	gen agg_value_on_period = amount_paid


	*TOR_original
	gen TOR_original = 81

	
	gen module_tracker="Housing 4"
	tempfile housing4
	save `housing4'
	
	*Append all the modules
	use `diary', clear 
	append using `diary2'
	append using `diary3'
	append using `diary_month'
	append using `diary_quarter'
	append using `diary_semester'
	append using `diary_annual'
	append using `housing'
	append using `housing2'
	append using `housing3'
	append using `housing4'
	
	
	*coicop_2dig
	tostring product_code, generate(str_product_code) 
	gen coicop_2dig = substr(str_product_code,1,2)  //extract first 2-digits of product code to identify housing expenses 
	destring product_code, replace
	gen housing = 1 if coicop_2dig == "41"				// Actual rent
	replace housing = 1 if coicop_2dig == "42"				// Imputed rent as expense
	
	
	*We remove mising (or negative) values, destring and label some variables for clarity/uniformity 
	destring hhid, replace
	
	
	replace agg_value_on_period = 12 * agg_value_on_period
	drop if agg_value_on_period ==.
	drop if agg_value_on_period<=0
	
	destring TOR_original, force replace
	ta TOR_original

	#delim ; // create the label
	label define TOR_original_label 
1 "Hipermercados" 2 "Supermercados de cadena" 3 "Tiendas de barrio"
4 "Mercados" 5 "Comisariatos de empresa" 6 "Verdulera/Frutera"
7 "Bodegas, distribuidores" 8 "Ferias libres" 9 "Panaderas"
10 "Vendedores ambulantes" 11 "Delicatessen" 
12 "Tercena/carnicera"
13 "Pescadera" 14 "Restaurantes, salones" 15 "Cadena de restaurantes" 16 "Kioscos fijos"
17 "Bahas, Ipiales" 18 "Bazares" 19 "Agencias de turismo" 20 "Articulos deportivos" 21 "Aseguradoras" 22 "Boticas y farmacias" 23 "Calzado de todo tipo" 24 "Canteras (minas)" 25 "Centros de proteccion social"
26 "Centros, Serv. de recreacion, estadios" 27 "Computadoras y accesorios" 28 "Concecionarios" 29 "Electrodomesticos y accesorios" 30 "Equipos medicos"
31 "Establecimientos educativos" 32 "Establecimientos financieros" 33 "Establecimientos privados de salud" 34 "Establecimientos publicos de salud" 35 "Estacionamientos" 36 "Fabricas y distribuidoras mayoristas" 37 "Ferreterias" 
38 "Floristeria" 39 "Fotocopiadoras" 40 "Gasolineras"
41 "Hoteles y otros serv. de alojamiento" 42 "Inmoviliarias" 43 "Instituciones publicas" 44 "Instrumentos musicales" 45 "Joyerias y relojerias" 46 "Jugueteria" 47 "Laboratorios clinicos " 48 "Lavanderias" 49 "Librerias y papelerias" 51 "Mascotas y accesorios"
52 "Mecanica industrial" 53 "Mecanicas automotrices" 54 "Muebles y enceres" 55 "Pticas" 56 "Organizaciones sociales" 57 "Perfumerias" 58 "Productos de atencion personal" 59 "Productos textiles" 
60 "Reparacion de calzado" 61 "Repuestos de automotores" 62 "Ropa de todo tipo" 63 "Salas de belleza " 64 "Sastres, costureras, modistas" 65 "Servicio artesanal (plomero, albaoil)" 66 "Servicio de reparacion electrodomestico" 67 "Servicio de fletes, carga"
68 "Servicio de telefonÌa publica o privada" 69 "Servicios profesionales (abogados, arqu)" 70 "Transporte de pasajeros" 71 "Venta por cat·logo o television" 72 "Ventas por internet" 73 "Personas particulares" 74 "Otros sitios de compra especializados"  
80 "Productos autoconsumo, autosuministro" 81 "Otros";
	#delim cr
	label list TOR_original_label
	label values TOR_original TOR_original_label // assign it
	ta TOR_original

	decode TOR_original, gen(TOR_original_name)
	ta TOR_original_name

	
	*We keep all household expenditures and relevant variables
	keep hhid product_code TOR_original TOR_original_name  quantity unit amount_paid agg_value_on_period  TOR_original_name coicop_2dig housing
	order hhid, first
	sort hhid
	save "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta", replace



***************************************************************
* Step 2.2: Product crosswalk if product codes are not COICOP * 
***************************************************************

// Not needed

************************************************************
*   Step 3: Generating total expenditures and total income *
************************************************************
**********************************
*   Step 3.1: Total expenditures *
**********************************
	*We construct the necessary variables and use the same names for all countries : exp_total, exp_housing, exp_noh
	*exp_total
	by hhid: egen exp_total = sum(agg_value_on_period) 
	
	*exp_housing
	by hhid: egen exp_rent = sum(agg_value_on_period) if coicop_2dig == "41" // actual rent as expenses
	by hhid: egen exp_ir = sum(agg_value_on_period) if coicop_2dig == "42" // imputed rent as expenses
	gen exp_ir_withzeros = exp_ir
	replace exp_ir_withzeros = 0 if exp_ir_withzeros == .
	gen exp_rent_withzeros = exp_rent
	replace exp_rent_withzeros = 0 if exp_rent_withzeros == .
	gen exp_housing = exp_ir_withzeros + exp_rent_withzeros
	
	*exp_noh
	gen exp_noh = exp_total - exp_housing	// Expenses without imputed rent and without actual rent
	
	*We keep only the relevant variables
	keep hhid exp_total exp_housing exp_noh
	
***************************
*   Step 3.2 Total income *
***************************

	* This step will require to investigate the following datafiles : 
	
************************************************************
*   Step 3.3: Merge with the household covariates datafile *
************************************************************

	collapse (mean) exp_total exp_housing exp_noh  , by(hhid)
	merge 1:1 hhid using "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	keep if _merge ==3
	drop _merge
	
	save "$main/proc/$country_fullname/${country_code}_household_cov.dta", replace


*******************************************************************
* Step 4: Crosswalk between places of purchase and classification *
*******************************************************************
*[Output = Note in country report explaining choices]
   
	clear 
	set more off
	use "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	*We have decided to not take housing into account
	drop if housing == 1
	
	set more off
	label list
	capture label drop TOR_original_label
	collapse (sum) agg_value_on_period, by (TOR_original TOR_original_name)
	rename agg_value_on_period expenses_value_aggregate
	egen total_exp = sum(expenses_value_aggregate)  
	gen pct_expenses = expenses_value_aggregate / total_exp 
	order TOR_original_name TOR_original expenses_value_aggregate pct_expenses total_exp 
 
	
	*We assign the crosswalk (COUNTRY SPECIFIC !)
	gen detailed_classification=1 if inlist(TOR_original,80)
	replace detailed_classification=2 if inlist(TOR_original,10,8,16,18,4)
	replace detailed_classification=3 if inlist(TOR_original,3,7)
	replace detailed_classification=4 if inlist(TOR_original,48,64,60,53,52,42,28,40,30,19,59,27,37,61,51,29,23,20,63,62,58,57,54,49,46,45,44,39,38,74,13,12,11,9,6)
	replace detailed_classification=5 if inlist(TOR_original,1,36,2)
	replace detailed_classification=6 if inlist(TOR_original,5,17,21,31,32,33,34,43,47,68,35,56,70,71,72,25,67,69)
	replace detailed_classification=7 if inlist(TOR_original,73,65,66)
	replace detailed_classification=8 if inlist(TOR_original,14,15,26,41)
	replace detailed_classification=10 if inlist(TOR_original,22)	
	replace detailed_classification=99 if inlist(TOR_original,55,81,24)


	export excel using "$main/tables/$country_fullname/${country_fullname}_TOR_stats_for_crosswalk.xls", replace firstrow(variables) sheet("TOR_codes")
	*Note: This table is exported to keep track of the crosswalk between the original places of purchases and our classification 
	
	*We remove mising values, destring and label some variables for clarity/uniformity 
	#delim ; 
	label define detailed_classification_label 
	1 "1: non-market" 2 "2: no store front" 3 "3: convenience and corner shops"
	4 "4: specialized shops" 5 "5: large stores" 6 "6: institutions" 
	7 "7: service from individual" 8 "8: entertainment" 9 "9: informal entertainment" 
	99 "99: unspecified" ;
	#delim cr
	label list detailed_classification_label
	label values detailed_classification detailed_classification_label // assign it
	ta detailed_classification
	
	*We merge with expenditures dataset
	merge 1:m TOR_original using "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"

	*We keep all household expenditures and relevant variables
    keep hhid product_code TOR_original TOR_original_name agg_value_on_period coicop_2dig TOR_original_name housing detailed_classification TOR_original TOR_original_name pct_expenses 
	order hhid, first
	sort hhid

	

*********************************************************
* Step 5: Creation of database at the COICOP_4dig level *
*********************************************************
* Consumption labels, and creation of the database at the COICOP_4dig level
* [Output = Note in Masterfile + consumption data with standardized classification of codes ]
	
	
	*We construct the necessary variables: COICOP_2dig COICOP_3dig COICOP_4dig
	gen str6 COICOP_2dig = substr(string(product_code,"%07.0f"), 1,2) 
	gen str6 COICOP_3dig = substr(string(product_code,"%07.0f"), 1,3) 
	gen str6 COICOP_4dig = substr(string(product_code,"%07.0f"), 1,4) 

	*We destring and label some variables for clarity/uniformity 
	destring COICOP_2dig, force replace											
	destring COICOP_3dig, force replace											
	destring COICOP_4dig, force replace											

	merge m:1 COICOP_2dig using "$main/proc/COICOP_label_2dig.dta"
	drop if _merge == 2
	drop _merge
	drop COICOP_2dig
	ren COICOP_Name2 COICOP_2dig
	
	merge m:1 COICOP_3dig using "$main/proc/COICOP_label_3dig.dta"
	drop if _merge == 2
	drop _merge
	drop COICOP_3dig
	ren COICOP_Name3 COICOP_3dig
	
	merge m:1 COICOP_4dig using "$main/proc/COICOP_label_4dig.dta"	
	drop if _merge == 2	
	drop _merge
	drop COICOP_4dig
	ren COICOP_Name4 COICOP_4dig
	
	
	*We save the database with all expenditures for the price/unit analysis
	save "$main/proc/$country_fullname/${country_code}_exp_full_db.dta" , replace

	*We create the final database at the COICOP_4dig level of analysis
	collapse (sum) agg_value_on_period, by(hhid housing TOR_original COICOP_4dig COICOP_3dig COICOP_2dig  detailed_classification) 
	
	*We rename and create variables relevant for future analysis
	rename agg_value_on_period exp_TOR_item										// Expenses by item
	by hhid : egen exp_total= sum(exp_TOR_item)
	gen share_exp_total = exp_TOR_item/exp_total								// Share of total expenses by TOR
	by hhid : egen exp_noh= sum(exp_TOR_item) if housing !=1
	gen share_exp_noh = exp_TOR_item/exp_noh									// Share of total expenses by TOR without imputed rent
	replace share_exp_noh = . if housing == 1
	
	order hhid COICOP_4dig COICOP_3dig COICOP_2dig exp_TOR_item  TOR_original detailed_classification  housing , first
	save "$main/proc/$country_fullname/${country_code}_temp_exp_TOR_item_COICOP_4dig.dta" , replace
	
	*We delete unnecessary files
	erase "$main/waste/$country_fullname/${country_code}_household_cov_original.dta"
	erase "$main/waste/$country_fullname/${country_code}_all_lines_raw.dta"
	
	
