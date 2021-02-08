
***************************************************
**PRELIMINARIES**
***************************************************

	** Note replace the parameters from optimal_tax below with the locals from the program 

	clear all 
	set more off
	cap log close

	display "$scenario"
	
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
	8: value of price compensated own price elasticity (baseline = 0.5)	
	9: value of elasticity of compensated elasticity of substitution formal vs informal (baseline = 1.5)						
	10: Value chosen for all uncompensated elasticities if fixed exogenously (baseline=1)
	
	*** Extensions:  	
	[For Removing Inequality] 
	11: =1 if remove inequalities in total expenditure (baseline), 0 otherwise	
	[for varying saving rates]
	12: savings_rate drops by that amount between decile  (baseline=0, when include savings =0.01)
	[for VAT on inputs]
	13: passthrough of taxes on informal prices (baseline =0, when include VAT on inputs for now 0.07)
	
	14: rescaling of elasticities so that weighted sum = elasticity for all non-food products. if 0: no rescaling. if 1: does rescaling.
		
	*/
	*********************************************************************************************************************************************************
	
	cap program drop optimal_tax_COICOP12
	program define optimal_tax_COICOP12		
	
	***************************************************
	*	0. Elasticities RESCALING
	***************************************************	
	** Saving non food aggregate elasticities obtained by baseline program
	local rescaling_COICOP12 = 1
	if `rescaling_COICOP12' {	
	do "$main/dofiles/Optimal_tax_pit_program.do"
	qui optimal_tax_pit `1' 1 11 0 0 1 1 0.7 `9' 1 0 0 0 0 
	bys country: egen cons_A_nf=total(exp_total2)
	bys country: egen cons_F_nf=total(exp_formal2)
	keep country_code e_A_nf e_F_nf cons_A_nf cons_F_nf
	bys country: keep if _n==1
	sort country
	save "$main/proc/elasticities_nf.dta", replace	
	} 	
		
	***************************************************
	*	A. Data Prep
	***************************************************
{	
	** 1. Prepare the budget share data in wide format 		
	use "$main/proc/output_for_simulation_pct_COICOP2_`1'", replace
	
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
	
	** 2. Merge to get GDP
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
	
	*** 3. Merge to get IEC slope and Informal Budget Share 
	preserve
	use "$main/proc/regressions_output_`1'.dta", clear
	keep if iteration == 6 | iteration == 1
	keep country_code  b iteration
	reshape wide b , i(country_code) j(iteration)
	
	rename b6 b_informal
	gen b_formal = - b_informal
	
	rename b1 s_informal 
	gen s_formal = 100 - s_informal 
	
	tempfile temp_data_IECslopes
	save `temp_data_IECslopes' , replace 
	restore
	
	merge m:1 country_code using `temp_data_IECslopes' 
	drop _merge	
	
	*** 4. Merge to get Engel Curves and shares of each COICOP12 product at the country level (from the micro data)
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

	*** Merge Budget Share data at decile level with the country level slopes and shares
	
	merge m:1 country_code using `temp_data_ECslopes'
	drop _merge	
	merge m:1 country_code using `temp_data_shares'
	drop _merge		
		
	** 5. Generate buget shares at the decile level
	* Generates Formal Spending for each COICOP12 
	forvalues i = 0(1)12 { 
		gen exp_formal`i' = exp_total`i' - exp_informal`i'
		}
	
	** Generate total across all deciles for each COICOP12
	foreach x in "total" "informal" "formal" { 
		forvalues i = 0(1)12 { 
			bysort country: egen exp_`x'`i'_alldeciles = total(exp_`x'`i') 
			}
		}	
		
	** Generate the Phi's that is the decile's share of total spendin:
	gen phi = exp_total0 / exp_total0_alldeciles
	
	* Budget shares of each decile 		
	
	* Share informal sector
	gen share_inf= exp_informal0 / exp_total0
	
	* Share goods (total and informal): 
	* Terminology note: "a_" refers to country level,  "alpha_" refers to decile specific "s_" refers to country level, "share_" refers to decile specific shares. 
	forvalues i = 0(1)12 {
		gen share_A_COICOP`i' = exp_total`i' / exp_total0
		gen share_I_COICOP`i' = exp_informal`i' / exp_total0 
		gen share_F_COICOP`i' = exp_formal`i' / exp_total0 
		} 
		
	} 
	
	*	Define Deciles, which are used for welfare weights
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
	
	*Saving rates
	gen savings_rate = `12'*decile
	gen income = exp_total   / (1-savings_rate)
	gen inc_total0 = exp_total0  / (1-savings_rate)			// This is now the true targetting potential of the tax, note that the tax base used remains exp_total 
	if `12'>0 {
	replace exp_total0=inc_total0
	}
	}
	
	***************************************************
	*	C. Calibration parameters
	***************************************************
	
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

	forvalues i =1(1)12 { 
		egen b_avg_A_`i' = mean(b_A_COICOP`i')
		egen b_avg_F_`i' = mean(b_F_COICOP`i')
		egen s_avg_A_`i' = mean(s_A_COICOP`i')
		egen s_avg_F_`i' = mean(s_F_COICOP`i')	
		gen b_over_s_A_`i' 	= b_avg_A_`i' / s_avg_A_`i'					
		gen b_over_s_F_`i' 	= b_avg_F_`i' / s_avg_F_`i'	
		}
		
	cap drop eta_*
	
	forvalues i =1(1)12 {
		gen eta_A_COICOP`i'			= 1 + b_over_s_A_`i'
		gen eta_F_COICOP`i'		 	= 1 + b_over_s_F_`i'
		}
			
	** Uncompensated Elasticities: country specific and a function of the above country invariant parameters 		
	** First define the country specific parameters
	* Note come back here and make an option to set all uncomepnsated elasticities to a value of our choice 
	
	* Alphas are the share of informal consumption of the good 
		
	cap drop e		
	cap drop e_inf1			
	cap drop e_f_inf0 
	cap drop e_nf_inf0
	cap drop e_f_inf1
	cap drop e_nf_inf1
	
	if `7' == 1 {  	
		forvalues i = 1(1)12 {
			gen e_A_COICOP`i' = e_ownprice_c - eta_A_COICOP`i'* s_A_COICOP`i' 
			gen e_F_COICOP`i' = e_ownprice_c - 2 * e_substitution_c *( s_I_COICOP`i'/s_A_COICOP`i') - eta_F_COICOP`i' * s_F_COICOP`i'
			replace e_F_COICOP`i' = e_ownprice_c - eta_F_COICOP`i' * s_F_COICOP`i'  if e_F_COICOP`i' == .   // note for the few cases where s_A_COICOP`i' is 0
			} 
		}
	if `7' == 0 {
		forvalues i = 1(1)12 {
			gen e_A_COICOP`i' = -`10'
			gen e_F_COICOP`i' = -`10'
			}
		}

	*C.3 Rescaling elasticities
	if `14'==1 {
	sort country_code
	merge m:1 country using "$main/proc/elasticities_nf.dta"
	tab _merge
	drop _merge
	
	*get aggregate consumption
	forvalues i = 1(1)12 {
	bys country: egen cons_A_COICOP`i'=total(exp_total`i')
	cap drop x*
	gen x`i'=exp_total`i'-exp_informal`i'
	bys country: egen cons_F_COICOP`i'=total(x`i')
	}
	
	*get shares of each non-food COICOP in total non-food
	forvalues i = 1(1)12 {
	gen share_cons_A_COICOP`i'=cons_A_COICOP`i'/cons_A_nf
	gen share_cons_F_COICOP`i'=cons_F_COICOP`i'/cons_F_nf
	}
	
	*scaling factor
	gen x=e_A_COICOP2*share_cons_A_COICOP2+e_A_COICOP3*share_cons_A_COICOP3+e_A_COICOP4*share_cons_A_COICOP4+e_A_COICOP5*share_cons_A_COICOP5+e_A_COICOP6*share_cons_A_COICOP6+e_A_COICOP7*share_cons_A_COICOP7+e_A_COICOP8*share_cons_A_COICOP8+e_A_COICOP9*share_cons_A_COICOP9+e_A_COICOP10*share_cons_A_COICOP10+e_A_COICOP11*share_cons_A_COICOP11+e_A_COICOP12*share_cons_A_COICOP12
	gen scaling_A=x/e_A_nf
	cap drop x
	gen x=e_F_COICOP2*share_cons_F_COICOP2+e_F_COICOP3*share_cons_F_COICOP3+e_F_COICOP4*share_cons_F_COICOP4+e_F_COICOP5*share_cons_F_COICOP5+e_F_COICOP6*share_cons_F_COICOP6+e_F_COICOP7*share_cons_F_COICOP7+e_F_COICOP8*share_cons_F_COICOP8+e_F_COICOP9*share_cons_F_COICOP9+e_F_COICOP10*share_cons_F_COICOP10+e_F_COICOP11*share_cons_F_COICOP11+e_F_COICOP12*share_cons_F_COICOP12
	gen scaling_F=x/e_F_nf
	
	disp "OK"
	*replace elasticities
	forvalues i = 2(1)12 {
	rename e_A_COICOP`i' e_A_COICOP`i'_not_scaled
	rename e_F_COICOP`i' e_F_COICOP`i'_not_scaled
	gen e_A_COICOP`i'=e_A_COICOP`i'_not_scaled/scaling_A
	gen e_F_COICOP`i'=e_F_COICOP`i'_not_scaled/scaling_F
	}
	}
	***************************************************
	*	D. Optimal Tax Rates 
	***************************************************
	
	** Note: "share" is the decile specific budget share, "s" is the country aggreagte share 
	
	{
	
	*1. COICOP2 specific Rates 	
	
	* 1.A No informal sector
	forvalues i = 1(1)12 { 
		cap drop x*
		cap drop num
		cap drop den
		cap drop t_A_COICOP`i'
		gen x4 = phi * share_A_COICOP`i' / s_A_COICOP`i'
		gen x1= (g-g_mean)*x4
		bys country : egen x2=sum(x1)
		bys country : egen x3=sum(x4)
		gen num	=	(mu-g_mean)*x3-x2
		gen den = - e_A_COICOP`i' * mu * x3
		gen t_A_COICOP`i' =num/den
		replace t_A_COICOP`i' = 0 if t_A_COICOP`i' == . 
		} 

	* 1.B With informal sector
	forvalues i = 1(1)12 { 	
		cap drop x*
		cap drop num
		cap drop den
		cap drop t_F_COICOP`i'
		gen x4 = phi * (share_F_COICOP`i' + v_inputs * share_I_COICOP12) / (s_F_COICOP`i'+ v_inputs * s_I_COICOP12)
		gen x1=(g-g_mean)*x4
		bys country : egen x2=sum(x1)
		bys country : egen x3=sum(x4)
		gen num	=	(mu-g_mean)*x3-x2
		gen den = - e_F_COICOP`i' * mu * x3
		gen t_F_COICOP`i' =num/den
		replace t_F_COICOP`i' = 0 if t_F_COICOP`i' == . 
		}
	
	cap drop x*
	cap drop num
	cap drop den
	
	}
	}
		
	end			// End of Program 
	

	
	
	
	
	
	
	
	
	
	
	
	
