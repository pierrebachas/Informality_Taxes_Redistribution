
***************************************************
**	PRELIMINARIES	**
***************************************************

	clear all 
	set more off
	cap log close
	log using "$main/logs/optimal_tax_september.log", replace

	display "$scenario"
	
*********************************************	
* DATA PREP
*********************************************		
		
	*Obtain GDP_pc for the country
	
	local gdp_data_prep = 1
	if `gdp_data_prep' {
	import excel using "$main/data/Country_information.xlsx" , clear firstrow		
	rename Year year
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	save "$main/data/country_information.dta", replace
	}  

***************************************************
* PROGRAM**
***************************************************

	*********************************************************************************************************************************************************
	/*
	This program takes the following arguments:
	
	*** Data: 
	
	1: scenario used to construct the dataset (central/robust/proba)
	
	*** Government Preferences:
	
	2: government preferences 1=welfarist (baseline), 2=poverty-averse
	3: government preference, if welfarist relative weight on bottom decile compared to top (Decreases by linear steps across deciles)
	4: government preferences, if poverty averse: decile above which household is considered non-poor (baseline - set to 0)
	5: government preferences, if povery averse: welfare weight of poor relative to non-poor (default is 2) (baseline - set to 0)
	6: value of public funds, set mu=`5' times the average welfare weight (baseline is 1)
	
	*** Structural Parameters: 
	7: Fix uncompensated price elasticites endogeneously (0,1). If 1: need to determine 8 and 9. if 0: need to determine 10
	8: value of price compensated own price elasticity (baseline = 0.7)	
	9: value of elasticity of compensated elasticity of substitution formal vs informal (baseline = 1.5)						
	10: Value chosen for all uncompensated elasticities if fixed exogenously (baseline=1)
	
	*** Extensions:  	
	[For Removing Inequality] 
	11: =1 if remove inequalities in total expenditure (baseline), 0 otherwise	
	[for varying saving rates]
	12: savings_rate drops by that amount between decile  (baseline=0, when include savings =0.015)
	[for VAT on inputs]
	13: passthrough of taxes on informal prices (baseline =0, when include VAT on inputs for now 0.07)
		
	*/
	*********************************************************************************************************************************************************
	
	cap program drop optimal_tax
	program define optimal_tax

	***************************************************
	*	A. Data Prep
	***************************************************
{	
	** Prepare the data in wide format 		
	use "$main/proc/output_for_simulation_COICOP2_`1'.dta", replace
	
	egen group = group(country_code decile) 
	
	preserve 
	tempfile temp_data 
	duplicates drop group country_code decile, force
	keep group country_code decile
	save `temp_data' , replace 
	restore
	
	keep group exp_total exp_informal COICOP2 year
	reshape wide exp_total exp_informal, i(group) j(COICOP2)
	
	merge 1:1 group using `temp_data'
	drop group _merge 
	
	** Merge to get GDP
	merge m:1 country_code year using "$main/data/country_information.dta"
	keep if _merge==3
	drop _merge
	gen ln_GDP = log(GDP_pc_constantUS2010) 
	
	*** Merge to get IEC slope and Informal Budget Share
	preserve
	use "$main/proc/regressions_output_`1'.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_I
	gen b_F = - b_I
	
	rename b1 s_I
	gen s_F = 100 - s_I
	
	foreach var in s_F s_I b_F b_I {
		replace `var' = `var' /100
		} 
		
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	*** Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
	** Load the Engel Slopes
	preserve
	use "$main/proc/regressions_COICOP12_`1'.dta" , replace
	keep if iteration == 2    							// this keeps the betas
	
	rename bA b_A_COICOP
	rename bF b_F_COICOP
	rename bI b_I_COICOP
	
	keep country_code b_A_COICOP b_F_COICOP b_I_COICOP COICOP2
	reshape wide b_A_COICOP b_F_COICOP b_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_ECslopes
	save `temp_data_ECslopes' , replace 
	restore

	** Load the consumption shares
	preserve
	use "$main/proc/regressions_COICOP12_`1'.dta" , replace
	keep if iteration == 1    							// this keeps the betas
	
	rename bA s_A_COICOP
	rename bF s_F_COICOP
	rename bI s_I_COICOP
	
	keep country_code s_A_COICOP s_F_COICOP s_I_COICOP COICOP2
	reshape wide s_A_COICOP s_F_COICOP s_I_COICOP, i(country_code) j(COICOP2)	
	
	tempfile temp_data_shares
	save `temp_data_shares' , replace 
	restore	
	
	** Merge everything 
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge
	merge m:1 country_code using `temp_data_shares' 
	drop _merge
	
	*** Generate Food non Food from Engel slopes 
	
	gen s_A_food = s_A_COICOP1
	gen s_F_food = s_F_COICOP1
	gen s_I_food = s_I_COICOP1
	
	order s_A_COICOP*
	egen s_A_nf  = rowtotal(s_A_COICOP2-s_A_COICOP12)
	order s_F_COICOP*
	egen s_F_nf  = rowtotal(s_F_COICOP2-s_F_COICOP12)
	order s_I_COICOP*
	egen s_I_nf  = rowtotal(s_I_COICOP2-s_I_COICOP12)
	
	gen b_A_food = b_A_COICOP1
	gen b_F_food = b_F_COICOP1
	
	order b_A_COICOP*
	egen b_A_nf = rowtotal(b_A_COICOP2-b_A_COICOP12)
	order b_F_COICOP*
	egen b_F_nf = rowtotal(b_F_COICOP2-b_F_COICOP12)	
	order b_I_COICOP*
	egen b_I_nf = rowtotal(b_I_COICOP2-b_I_COICOP12)	
	
	** Generate Food non Food from Budget Shares
	* Generates food and non food - 1 indexes food, 2 indexes non-food
	
	** 5. Generate buget shares at the decile level
	* Generates Formal Spending for each COICOP12 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}

	order exp_total*
	egen tmp_exp_total2 = rowtotal(exp_total2-exp_total12)	
	order exp_informal*
	egen tmp_exp_informal2 = rowtotal(exp_informal2-exp_informal12)	
	order exp_formal*
	egen tmp_exp_formal2 = rowtotal(exp_formal2-exp_formal12)

	** Only keep food, non-food and total 
	foreach x in "total" "informal" "formal" { 
		drop exp_`x'2
		gen exp_`x'2 = tmp_exp_`x'2
		}
	
	drop exp_informal3-exp_informal12  exp_total3-exp_total12 tmp_exp*	
	
	*** Generate the total across deciles at the country level 
	foreach x in "total" "informal" "formal" { 
		forvalues i = 0(1)2 { 
			bysort country: egen exp_`x'`i'_alldeciles = total(exp_`x'`i') 
			}
		}	
		
	** Generate the Phi's that is the decile's share of total spending/Income:
	gen phi = exp_total0 / exp_total0_alldeciles
			
	order CountryName PPP_current GDP_pc_currentUS GDP_pc_constantUS2010 ln_GDP  year country_code decile  exp_total0 exp_total1 exp_total2 exp_informal0 exp_informal1 exp_informal2 exp_formal0 exp_formal1 exp_formal2 phi
	sort country_code decile	
	
	}
	
	***************************************************	
	*	B. DEFINE BUDGET SHARES AND EXTENSIONS
	***************************************************
	{
	* Removing inequalities in total expenditure
	/*
	Note: This keeps total consumption of decile 1 unchanged but sets the ratio of total consumption in deciles 2-10 to decile 1 equal in all countries.
	Consequence: optimal uniform rates with no informal sector are the same everywhere - inequalities in total expenditure can't be driving differences across countries
	*/
	if `11'==1 {
	cap drop x* 
	cap drop ratio 
	
	gen x = exp_total0 if decile==1 
	bys country: egen x2=max(x)
	
	gen x3=exp_total0 /x2 

	bys decile: egen ratio=mean(x3)
		gen exp_total=x2*ratio
	}
	if `11'==0 {
	gen exp_total=exp_total0
	}
	
	cap drop x*
	cap drop ratio 
	
	/*
	*Saving rates
	gen savings_rate = `12'*decile
	gen inc_total0 = exp_total0  / (1-savings_rate)			// This is now the true targetting potential of the tax, note that the tax base used remains exp_total 
	if `12' > 0 {
		replace exp_total0=inc_total0
		drop phi exp_total0_alldeciles
		bysort country: egen exp_total0_alldeciles = total(exp_total0) 
		** Generate the Phi's that is the decile's share of total spending/Income:
		gen phi = exp_total0 / exp_total0_alldeciles
	}
	*/ 
	
	* Budget shares of each decile 	
	
	*1. Share informal and formal sector
	gen share_I = exp_informal0 / exp_total0
	gen share_F = exp_formal0 / exp_total0
	
	*2. Share food (total and informal)
	gen share_A_food = exp_total1 / exp_total0
	gen share_F_food = exp_formal1 / exp_total0		
	gen share_I_food = exp_informal1 / exp_total0
	
	*3. Share non-food (total and informal) 
	gen share_A_nf = exp_total2 / exp_total0	
	gen share_F_nf = exp_formal2 / exp_total0	
	gen share_I_nf = exp_informal2 / exp_total0	
	
	}
	***************************************************
	*	C. Calibration parameters
	***************************************************
	
	* C.1 Government preferences
	{	
	if `2'==1 {
	cap drop g
	gen g = . 
	local max_g = `3'
	forval i=1/10 {
	replace g = (1/9)*[10*`max_g'-1]+`i'*(1-`max_g')/9 if decile==`i'
	}
	}
	if `2'==2 {
	cap drop g
	gen g=`5'
	replace g=1 if decile>`4'
	}
	
	cap drop g_mean
	bys country: egen g_mean=mean(g) 
	
	*Value of public funds
	cap drop mu
	gen mu=g_mean*`6'
	
	** Value of input passthrough 
	
	gen v_inputs = `13' 
	
	* C.2 Elasticities 
	
	*** Parameters which are fixed across countries and fully exogeneous 
	cap drop e_ownprice_c 
	cap drop e_substitution_c
	
	gen e_ownprice_c = - `8'
	gen e_substitution_c = `9' 
	
	*** Parameters which are fixed across countries but depend on data 

	*** generate average across country of slopes over budget shares
	cap drop eta_*
	cap drop b_over_s_*
	cap drop b_over_s_avg_*
	
	foreach name in "F" "A_food" "A_nf" "F_food" "F_nf" { 
		egen  b_avg_`name' = mean(b_`name')
		egen  s_avg_`name' = mean(s_`name')
		gen   b_over_s_`name' = b_avg_`name' / s_avg_`name'
		gen   eta_`name' = 1 + b_over_s_`name'		
		}

	** Uncompensated Elasticities: country specific and a function of the above country invariant parameters 		
	** First define the country specific parameters
	* Note come back here and make an option to set all uncomepnsated elasticities to a value of our choice 
			
	cap drop e	e_F e_A_food e_A_nf e_F_food e_F_nf 

	if `7' == 1 {  
		gen e 				= 	 -`10'
		gen e_F  			= 	 e_ownprice_c - 2 * e_substitution_c * (1-s_F) - eta_F * s_F
		gen e_A_food		= 	 e_ownprice_c - eta_A_food * s_A_food 
		gen e_A_nf			=	 e_ownprice_c - eta_A_nf * s_A_nf 
		gen e_F_food		=	 e_ownprice_c - 2 * e_substitution_c * (1 - (s_F_food / s_A_food)) - eta_F_food * s_F_food  
		gen e_F_nf 			=	 e_ownprice_c - 2 * e_substitution_c * (1 - (s_F_nf / s_A_nf)) - eta_F_nf * s_F_nf  
		}
	if `7' == 0 {
		gen e 			= 	 -`10'
		gen e_F		  	= 	 -`10'
		gen e_A_food 	= 	 -`10'
		gen e_A_nf		=	 -`10'
		gen e_F_food 	=	 -`10' 
		gen e_F_nf	 	=	 -`10' 
		}

	}
	//do "$main/dofiles/calibration_elasticities.do" // this creates for each country the relevant elasticities for all products, food and non-food
		
	***************************************************
	*	D. Optimal Tax Rates 
	***************************************************
	
	{
	
	*1. Uniform rates
	* No informal sector (ISSUE HERE COME BACK!) 
	
	cap drop x*
	cap drop num
	cap drop den
	gen x4 = phi
	gen x1 =(g-g_mean)* x4
	bys country : egen x2 =sum(x1)
	bys country:  egen x3 =sum(x4)
	gen num = (mu-g_mean) * x3 - x2
	gen den = - e * mu * x3 					// Im not sure here, TBD ? 
	cap drop t_A
	gen t_A = num/den
	
	* With informal sector
	cap drop x*
	cap drop num
	cap drop den	
	gen x4= phi * (share_F + v_inputs * share_I) / (s_F + v_inputs * s_I )
	gen x1=	(g-g_mean)*x4	
	bys country : egen x2=sum(x1)
	bys country : egen x3=sum(x4)
	gen num = (mu-g_mean)*x3-x2
	gen den = - e_F * mu * x3
	cap drop t_F	
	gen t_F = num/den
	
	*2. Food vs non-food, No informal sector 
	
	foreach name in "A_food" "A_nf"  { 
	cap drop x*
	cap drop num
	cap drop den
	gen x4= phi * share_`name'  / s_`name'
	gen x1= (g-g_mean)*x4
	bys country : egen x2=sum(x1)
	bys country: egen x3=sum(x4)
	gen num=(mu-g_mean)*x3-x2
	gen den= -e_`name' * mu * x3
	cap drop t_`name'
	gen t_`name' =num/den
	}	
	
	*3. Food vs non-food with informal sector
	
	foreach name in "_food" "_nf" { 
	cap drop x*
	cap drop num
	cap drop den
	gen x4= phi * (share_F`name' + v_inputs * share_I`name') / (s_F`name'+ v_inputs * s_I`name' )
	gen x1= (g-g_mean)*x4
	bys country : egen x2=sum(x1)
	bys country: egen x3=sum(x4)
	gen num=(mu-g_mean)*x3-x2
	gen den= -e_F`name' * mu * x3
	cap drop t_F`name'
	gen t_F`name' =num/den
	}	
	}
	
	cap drop x*
	cap drop num
	cap drop den	
			
	end			// End of Program 
	
	** TESTS 
	/*	
	set more off
	qui optimal_tax central 1 10 0 0 1 1 0.7 1.5 1 0 0 0	
	sum t_*
	*/ 
	
	//qui optimal_tax central 1 10 0 0 1 1 0.5 1.5 1 0 0 0.1	
	// sum t_*

	/*
	
	** Saving non food aggregate elasticities for the COICOP level program
	qui optimal_tax central 1 10 0 0 1 1 0.5 1.5 1 0 0 0	
	
	** Targetting t_inf1 (redistributive parameter of 5 give good values)

	set more off
	optimal_tax central 1 10 0 0 1 1 1 1.5 1 0 0 0	
	
	/*
	sum t_A t_F t_A_food t_A_nf t_F_food t_F_nf
	
	sum t_A, d
	sum t_F, d
	
	sum t_A_food, d
	sum t_A_nf, d
	
 	sum t_F_food, d
	sum t_F_nf, d
	*/ 
	
	

	
	
	
	
	
	
	
	
	
	
	
