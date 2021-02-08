	
/*	
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
	14: =1 if allow for PIT
*/	
	
	cap program drop optimal_tax_pit
	program define optimal_tax_pit
	
	***************************************************
	*	A. Data Prep
	***************************************************
{	
	** Prepare PIT data
	use "$main/data/PIT_parameters_AJ.dta", replace
	drop if country_code=="US" | country_code=="CN"
	keep country_code  mtr size_pit
	*put PIT threshold in correct format
	replace size_pit=100-size_pit
	sort country_code
	tempfile pit_data
	save `pit_data', replace

	** Prepare the data in wide format 		
	use "$main/proc/output_for_simulation_pct_COICOP2_`1'", replace
	*use "$main/proc/output_for_simulation_pct_COICOP2_central", replace
	egen group = group(country_code percentile) 
	
	preserve 
	tempfile temp_data 
	duplicates drop group country_code percentile, force
	keep group country_code percentile
	save `temp_data' , replace 
	restore
	
	keep group exp_total exp_informal COICOP2 year
	reshape wide exp_total exp_informal, i(group) j(COICOP2)
	
	merge 1:1 group using `temp_data'
	drop group _merge 
	
	** Merge to get PIT 
	merge m:1 country_code using `pit_data' //get 22 countries out of 31
	drop if _merge==2
	gen aj_data=(_merge==3)
	drop _merge
	label var mtr "MTR paid by richest households"
	label var size_pit "Pctile of households at the top paying PIT"

	** Merge to get GDP
	preserve
	tempfile gdp_data	
	import excel using "$main/data/Country_information.xlsx" , clear firstrow	
	rename Year year
	
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	save `gdp_data'		
	restore
	
	merge m:1 country_code year using `gdp_data'	
	keep if _merge==3
	drop _merge
	gen ln_GDP = log(GDP_pc_constantUS2010) 
	
	*ipolate missing values of PIT parameters
	foreach var in mtr size_pit {
	cap drop `var'_hat
	reg `var' ln_GDP
	predict `var'_hat, xb
	}
	/*
	tw scatter mtr ln_GDP, mlabel(country_code) mlabsize(2.5) || scatter mtr_hat ln_GDP if missing(mtr), saving(graph1, replace) mlabel(country_code) mlabsize(2.5)
	tw scatter size_pit ln_GDP, mlabel(country_code) mlabsize(2.5) || scatter size_pit_hat ln_GDP if missing(size_pit), saving(graph2, replace) mlabel(country_code) mlabsize(2.5)
	gr combine graph1.gph graph2.gph, row(2)
	gr export "$main/graphs/calibration/ipolated_PIT_parameters.pdf", replace	as(pdf)
	*/
foreach var in mtr size_pit {
	replace `var'=`var'_hat if missing(`var')
	}
	*replace impossible values
	replace size_pit=100 if size_pit>=100
	replace size_pit=round(size_pit)
	replace mtr=round(mtr)
	
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
	
	** 5. Generate buget shares at the pctle level
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
	
	*** Generate the total across pctles at the country level 
	foreach x in "total" "informal" "formal" { 
		forvalues i = 0(1)2 { 
			bysort country: egen exp_`x'`i'_allpct = total(exp_`x'`i') 
			}
		}	
		
	** Generate the Phi's that is the pctile's share of total spending/Income:
	gen phi = exp_total0 / exp_total0_allpct
			
	order CountryName PPP_current GDP_pc_currentUS GDP_pc_constantUS2010 ln_GDP  year country_code percentile  exp_total0 exp_total1 exp_total2 exp_informal0 exp_informal1 exp_informal2 exp_formal0 exp_formal1 exp_formal2 phi
	sort country_code percentile	
	
	}
	
	*	Define Deciles, which are used for welfare weights and to determine saving rates
	cap drop decile
	gen decile=.
	replace decile=1 if percentile>=1 & percentile<=10
	replace decile=2 if percentile>=11 & percentile<=20
	replace decile=3 if percentile>=21 & percentile<=30
	replace decile=4 if percentile>=31 & percentile<=40
	replace decile=5 if percentile>=41 & percentile<=50
	replace decile=6 if percentile>=51 & percentile<=60
	replace decile=7 if percentile>=61 & percentile<=70
	replace decile=8 if percentile>=71 & percentile<=80
	replace decile=9 if percentile>=81 & percentile<=90
	replace decile=10 if percentile>=91 & percentile<=100	
	
	
	***************************************************	
	*	B. DEFINE BUDGET SHARES AND EXTENSIONS
	***************************************************
	{
	* Removing inequalities in total expenditure
	/*
	Note: This keeps total consumption of pctle 1 unchanged but sets the ratio of total consumption in other pctles to pctle 1 equal in all countries.
	Consequence: optimal uniform rates with no informal sector are the same everywhere - inequalities in total expenditure can't be driving differences across countries
	*/
	if `11'==1 {
	cap drop x* 
	cap drop ratio 
	
	gen x = exp_total0 if percentile==1 
	bys country: egen x2=max(x)
	
	gen x3=exp_total0 /x2 

	bys percentile: egen ratio=mean(x3)
		gen exp_total=x2*ratio
	}
	if `11'==0 {
	gen exp_total=exp_total0
	}
	
	cap drop x*
	cap drop ratio 
	
	*Saving rates
	gen savings_rate = `12'*decile
	gen inc_total0 = exp_total0  / (1-savings_rate)			// This is now the true targetting potential of the tax, note that the tax base used remains exp_total 
	if `12' > 0 {
		replace exp_total0=inc_total0
		drop phi 
		bysort country: egen exp_total0_alldeciles = total(exp_total0) 
		** Generate the Phi's that is the decile's share of total spending/Income:
		gen phi = exp_total0 / exp_total0_alldeciles
	} 
	
	* Budget shares of each pctle 	
	
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
	* No informal sector
	
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
			
***************************************************
	*	E. With PIT
***************************************************
if `14'==1 {
foreach var in t_A t_F t_A_food t_A_nf t_F_food t_F_nf exp_total0 exp_total0_allpct phi share_F share_I share_A_food share_A_nf share_F_food share_F_nf s_F s_I s_A_food s_A_nf s_F_food s_F_nf {
rename `var' `var'_pre_pit
}

*** New income variables	
	//use average income in pctle x as income threshold if size_pit=x
	cap drop x*
	gen x=exp_total0_pre_pit if percentile==size_pit
	cap drop y_bar
	bys country_code: egen y_bar=max(x)
	gen exp_total0=exp_total0_pre_pit
	replace exp_total0=exp_total0_pre_pit-mtr*(exp_total0_pre_pit-y_bar)/100 if percentile>=size_pit
	gen dy_pit=(exp_total0-exp_total0_pre_pit)/exp_total0_pre_pit //income change because of PIT
    // New phi
	bysort country: egen exp_total0_allpct = total(exp_total0) 
	gen phi = exp_total0 / exp_total0_allpct
*** New budget shares
	//Pctile level shares
	gen eta_I=(1-eta_F*s_F_pre_pit)/s_I_pre_pit
	foreach var in F I A_food A_nf F_food F_nf {
	gen share_`var'= share_`var'_pre_pit*(1+dy_pit*(eta_`var'-1))
	}
	
	// Aggregate level shares
	cap drop dyagg_pit
			*growth in aggregate income
	gen dyagg_pit=(exp_total0_allpct-exp_total0_allpct_pre_pit)/exp_total0_allpct_pre_pit
	replace dyagg_pit=0 if missing(mtr)
	foreach var in F I A_food A_nf F_food F_nf {
	gen s_`var'= s_`var'_pre_pit*(1+dyagg_pit*(eta_`var'-1))
	}
*** New SWF
	// CALIBRATE THE A PARAMETER (g'(y)=-a/y^2 - see overleaf note)
	cap drop cg //'old' g values
	gen cg = . 
	local max_g = `3'
	forval i=1/10 {
	replace cg = (1/9)*[10*`max_g'-1]+`i'*(1-`max_g')/9 if decile==`i'
	}
	*gen one a per decile*country
	cap drop a_par
	gen a_par=.
	sort country decile
	forval i=2/10 {
	cap drop x*
	cap drop y_dm1
	cap drop y_d
	bys country: egen x=mean(exp_total0_pre_pit) if decile==`i'-1
	bys country: egen x2=mean(exp_total0_pre_pit) if decile==`i'
	bys country: egen y_dm1=max(x)
	bys country: egen y_d=max(x2)
	replace a_par=(y_dm1)^2/(y_d-y_dm1) if decile==`i'
	}
	cap drop g
	gen g=.
	cap drop x*
	cap drop y_d
	cap drop y_dn
	bys country decile: egen x=mean(exp_total0_pre_pit)
	bys country decile: egen x2=mean(exp_total0) 
	replace g=cg-a_par*(x2-x)/(x^2)
	replace g=cg if decile==1
	
	cap drop g_mean
	bys country: egen g_mean=mean(g) 
	*Value of public funds
	cap drop mu
	gen mu=g_mean*`6'

*** Optimal rates with PIT

{
	
	*1. Uniform rates
	* No informal sector
	
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
	*cap drop t_`name'
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
	*cap drop t_F`name'
	gen t_F`name' =num/den
	}	
	}
	
	cap drop x*
	cap drop num
	cap drop den
}	
	
	end			// End of Program 
	
	
