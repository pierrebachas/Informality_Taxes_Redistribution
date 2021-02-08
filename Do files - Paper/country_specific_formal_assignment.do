

** Do file **
* This do-file picks the sample and specification to calculate the tradi and modern formal shares, on a country by country basis
* The main (only) degree of freedom is whether to use the the winz or the non-winz distribution; the choice is based on the extent to which
* either distribution generates an average retail sales value in the WB data that is closer to the average retail sales value in Euromonitor

	
	
	***********************
	* Modern/Tradi Shares *
	***********************
	
	clear
	clear matrix
	set more off
	
	use "$proc/WB_Enterprise/modern_tradi_formality_shares_weights_based_on_surveys.dta" 
		
	sort country_code n_reg
	
	gen tradi_share=.
	gen modern_share=.
	
	* AFG *
	replace tradi_share=intersect_tradi_retail if country_code == "AFG" & n_reg== 9 & winz_p99 ==1 
	replace modern_share=intersect_modern_retail if country_code == "AFG" & n_reg== 9 & winz_p99 ==1 
	
	* AGO*
	** Come back to this
	
	* ARG *
	replace tradi_share=intersect_tradi_retail if country_code == "ARG" & n_reg== 9 & winz_p99 ==1 
	replace modern_share=intersect_modern_retail if country_code == "ARG" & n_reg== 9 & winz_p99 ==1 
	
	* BGD *
	replace tradi_share=intersect_tradi_all if country_code == "BGD" & n_reg== 9 & winz_p99 == 0 
	replace modern_share=intersect_modern_all if country_code == "BGD" & n_reg== 9 & winz_p99 == 0 
	
	* BRA * 
	replace tradi_share=intersect_tradi_all if country_code == "BRA" & n_reg== 9 & winz_p99 == 0 
	replace modern_share=intersect_modern_all if country_code == "BRA" & n_reg== 9 & winz_p99 == 0 
	
	* BWA
	replace tradi_share=intersect_tradi_retail if country_code == "BWA" & n_reg== 9 & winz_p99 == 1
	replace modern_share=intersect_modern_retail if country_code == "BWA" & n_reg== 9 & winz_p99 == 1 
	
	* BFA * 
	replace tradi_share=intersect_tradi_retail if country_code == "BFA" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_retail if country_code == "BFA" & n_reg== 9 & winz_p99 == 0 
	
	* CMR * 
	replace tradi_share=intersect_tradi_all if country_code == "CMR" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "CMR" & n_reg== 9 & winz_p99 == 0 
	
	* DRC * 
	replace tradi_share=intersect_tradi_all if country_code == "COD" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "COD" & n_reg== 9 & winz_p99 == 0 
	
	* CPV * 
	** Come back to this
	
	* KHM * 
	** Come back to this
	
	* EGY *
	** Come back to this
	*replace tradi_share=intersect_tradi_retail if country_code == "EGY" & n_reg== 9 & winz_p99 == 0
	*replace modern_share=intersect_modern_retail if country_code == "EGY" & n_reg== 9 & winz_p99 == 0 
	
	* GHA *
	replace tradi_share=intersect_tradi_all if country_code == "GHA" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "GHA" & n_reg== 9 & winz_p99 == 0 
	
	* GTM *
	replace tradi_share=intersect_tradi_retail if country_code == "GTM" & n_reg== 9 & winz_p99 == 1
	replace modern_share=intersect_modern_retail if country_code == "GTM" & n_reg== 9 & winz_p99 == 1 
	
	* CIV *
	replace tradi_share=intersect_tradi_retail if country_code == "CIV" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_retail if country_code == "CIV" & n_reg== 9 & winz_p99 == 0 
	
	* IND *
	replace tradi_share=intersect_tradi_all if country_code == "IND" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "IND" & n_reg== 9 & winz_p99 == 0 
	
	* KEN * 
	replace tradi_share=intersect_tradi_retail if country_code == "KEN" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_retail if country_code == "KEN" & n_reg== 9 & winz_p99 == 0 
	
	* LAO *
	replace tradi_share=intersect_tradi_all if country_code == "LAO" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "LAO" & n_reg== 9 & winz_p99 == 0 
	
	* MDG *
	replace tradi_share=intersect_tradi_all if country_code == "MDG" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "MDG" & n_reg== 9 & winz_p99 == 0 
	
	* MUS *
	replace tradi_share=intersect_tradi_all if country_code == "MUS" & n_reg== 9 & winz_p99 == 1
	replace modern_share=intersect_modern_all if country_code == "MUS" & n_reg== 9 & winz_p99 == 1 
	
	* MLI *
	replace tradi_share=intersect_tradi_all if country_code == "MLI" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "MLI" & n_reg== 9 & winz_p99 == 0 
	
	* MOZ *
	replace tradi_share=intersect_tradi_retail if country_code == "MOZ" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_retail if country_code == "MOZ" & n_reg== 9 & winz_p99 == 0 
	
	* MMR *
	** Come back to this
	
	* NPL *
	* Does not really work - imposing 'e weights' makes too big a difference
	replace tradi_share=intersect_tradi_all if country_code == "NPL" & n_reg== 8 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "NPL" & n_reg== 8 & winz_p99 == 0 
	
	* NER
	replace tradi_share=intersect_tradi_retail if country_code == "NER" & n_reg== 9 & winz_p99 == 1
	replace modern_share=intersect_modern_retail if country_code == "NER" & n_reg== 9 & winz_p99 == 1 
	
	* PAK *
	replace tradi_share=intersect_tradi_all if country_code == "PAK" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "PAK" & n_reg== 9 & winz_p99 == 0 
	
	* PER *
	replace tradi_share=intersect_tradi_retail if country_code == "PER" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_retail if country_code == "PER" & n_reg== 9 & winz_p99 == 0 
	
	* RW *
	replace tradi_share=intersect_tradi_all if country_code == "RWA" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "RWA" & n_reg== 9 & winz_p99 == 0 
	
	* SEN * 
	** Come back to this
	
	* TZA *
	replace tradi_share=intersect_tradi_all if country_code == "TZA" & n_reg== 9 & winz_p99 == 1
	replace modern_share=intersect_modern_all if country_code == "TZA" & n_reg== 9 & winz_p99 == 1 
	
	* UGA *
	replace tradi_share=intersect_tradi_all if country_code == "UGA" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "UGA" & n_reg== 9 & winz_p99 == 0 
	
	* ZMB *
	replace tradi_share=intersect_tradi_all if country_code == "ZMB" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "ZMB" & n_reg== 9 & winz_p99 == 0 
	
	* ZMB *
	replace tradi_share=intersect_tradi_all if country_code == "ZMB" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_all if country_code == "ZMB" & n_reg== 9 & winz_p99 == 0 
	
	* ZWE *
	replace tradi_share=intersect_tradi_retail if country_code == "ZWE" & n_reg== 9 & winz_p99 == 0
	replace modern_share=intersect_modern_retail if country_code == "ZWE" & n_reg== 9 & winz_p99 == 0 
	
	gen consumptionsurveys=1 if winz_p99==.
	
	* cross country graph of actual countries
	twoway (scatter tradi_share log_GDP, mcolor(green)) (lpolyci tradi_share log_GDP, ciplot(rline) lpattern(shortdash) lcolor(green)) (scatter modern_share log_GDP, mcolor(blue)) (lpolyci modern_share log_GDP, ciplot(rline) lpattern(shortdash) lcolor(blue)), ///
	graphregion(color(white)) legend(order(1 2 4 5)) xtitle("Log GDP per capita") legend(label (1 "Traditional Stores") label(2 "Fit + 95% CI") label(4 "Modern Stores") label(5 "Fit + 95%CI")) ytitle("Formal share of stores, in %") ///
	xlabel(5.5(1)9.5) ylabel(0(.1)1)
	* 'Fig_assignmentdevactual'
	
	* now predict formal shares for expenditure diary surveys
	collapse (mean) consumptionsurveys tradi_share modern_share gdp_pc_survey_year region log_GDP, by(country_code )
	
	
	drop if consumptionsurveys==. & tradi_share==.
	
	gen africa=1 if region==1
	replace africa=0 if region!=1
	
	gen southamerica=1 if region==2
	replace southamerica=0 if region!=2
	
	gen mena=1 if region == 3
	replace mena=0 if region != 3
	
	gen asia = 1 if region == 4
	replace asia = 0 if region != 4
	
	* NB: no WB-retail data in Europe - MENA, so omitted category will be south american
	reg modern_share log_GDP africa asia
	predict fit_modernshare, xb
	
	reg tradi_share log_GDP africa asia
	predict fit_tradishare, xb
	
	replace fit_tradishare=tradi_share if tradi_share!=.
	replace fit_modernshare=modern_share if modern_share!=.
	
	**** This has ignored the two European countries we had: 
	
	su  tradi_share //mean: 81% cited in paper p.3
	su  modern_share // mean: 10 % cited in paper p.3
	
	twoway (scatter fit_tradishare log_GDP if consumptionsurveys==1, mcolor(green)) (lpolyci fit_tradishare log_GDP if consumptionsurveys==1, ciplot(rline) lpattern(shortdash) lcolor(green)) ///
	(scatter fit_modernshare log_GDP if consumptionsurveys==1, mcolor(blue)) (lpolyci fit_modernshare log_GDP if consumptionsurveys==1, ciplot(rline) lpattern(shortdash) lcolor(blue)), ///
	graphregion(color(white)) legend(order(1 2 4 5)) xtitle("Log GDP per capita") legend(label (1 "Traditional Stores") label(2 "Fit + 95% CI") label(4 "Modern Stores") label(5 "Fit + 95%CI")) ytitle("Formal share of stores, in %") ///
	xlabel(5.5(1)9.5)
	* 'Fig_assignmentdevpredict'
	** NB for Eva: differentiate dots between those that are predicted and those that are not
	
	rename country_code country_3let

	merge 1:1 country_3let using  "$proc/croswalk_country_name_isocodes.dta"
	keep if _merge==3
	drop _merge
	rename country_3let country_code_3let
	rename country_2let country_code
	
	order country_fullname country_code country_code_3let , first
	save "$main/proc/WB_Enterprise/dataset_formalityshare_actualpredict.dta" , replace
	
