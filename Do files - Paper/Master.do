
***********************************************************************
* 	MASTER FILE INFORMALITY, CONSUMPTION TAXES and REDISTRIBUTION 	  * 
***********************************************************************


/*Numbers quoted in the paper 
p.2 The progressivity of rate differentiation is overestimated by a factor of 2.5 when informal consumption is not taken into account (summarized version of what's detailed in 5.1)
p.3  We find that the optimal uniform rate consumption tax reduces the Gini coefficient by 1% in low-income countries and up to 3% in middle-income  countries;  with  rate  differentiation,  the  inequality  reduction  ranges  from  1.1% to 3.9%, , computed in: Gini_output.do
p.3 This inequality reduction is comparable in magnitude to that achieved by actualpersonal income taxes (PIT) in developing countries (2.5%) , computed in: Gini_output.do
p.3  In an extension, we find that incorporating a realistically enforceable PIT lowers the inequality reduction achieved through consumption taxes by 10-15% ? (detailed in section 7.3)
p.3 We  estimate  that  10% of traditional stores are formal, while 81% of modern stores are formal, computed in: country_specific_formal_assignment.do 
p.4 Rate differentiation is a widespread policy, implemented in 90% of developing countries, estimates found in this guide: https://www.ey.com/en_gl/tax-guides/worldwide-vat--gst-and-sales-tax-guide-2020  (The definition of differentiation is “reduced rate on final consumer goods, not for export purposes or sectoral differentiation”)
p.5 contains information on over 400,000 households computed with: cross_country_descriptive_tables.do
p.10: The  estimation  sample  consists  of  409,864 product-location-month price observations in informal retail stores, smaple size comes from a log file from work on Mexico census INEGO data
p.13 The informal budget share is on average 72% in rural areas versus 60% in urban areas: Graphs_regressions_output_IEC_urbrural.do
p.13 The survey block is the most granular location information and contains on average 74 households in our surveys. The median survey block is representative on average of 52,900 households computed with: cross_country_descriptive_tables.do
p.26 We find that consumption taxes reduce inequality by 2-2.7%, while the CEQ’s average estimate is 0.3%, computed in: Gini_output.do
p.28 Using data from the OECD Income Distribution Database, we calculate that direct taxes in developed countries achieve a 11.2% Gini-reduction in inequality computed with: Gini_output.do
*/



*********************
* EXTERNAL DATASETS *
*********************


** World Development Indicators 
* Data on GDP per capita (US$ and LCU), PPP Conversion factor... 
* The exact dataset we downloaded on 12/17/2019 is available here: https://databank.worldbank.org/embed/GDP/id/7ca22941
* see Excel: Country_information.xlsx						

** Findex Data 
* Input:Findex17_SavingsData.dta 
* Share of people with positive savings at the country*decile level
* Obtained by email on 18th of January 2021 from the Findex team. Aggregated data are publicly avaible here (https://globalfindex.worldbank.org/index.php/#data_sec_focus).
* We had to email the FINDEX team to obtain this data at the decile level.
** see dofile: Savings_from_Findex.do

** Enterprise and Informal Surveys
* Firm level data on registration status, total sales and sector
* Publicly available on the Enterprise Survey website: https://login.enterprisesurveys.org/content/sites/financeandprivatesector/en/library.html
* We also had to email the Enterprise Survey team to access the few Enterprise and Informal surveys that were conducted before 2005 (Bangladesh, Brazil, India, Pakistan, Senegal, Tanzania, Uganda) 
** see dofiles: WBES_data_creation.do, WBES_analysis.do

** Passport Database on Modern and Traditional Stores
* Sales and number of establishments of traditional and modern stores in each country of our sample
* Obtained through the Euromonitor website on 18/11/2020 (https://go.euromonitor.com/passport.html), access requires a subscription
** see Excel: Passport_Stats_22-12-2020_2010_GMT.xls 
** see dofile: country_specific_formal_assignment.do

** Data on VAT Threshold
* The value of the VAT exemption threshold in each country of our main sample (lack Paraguay!)
* Imported from this Excel file: Retail_VAT.xls. The sources of this data are detailed in the Excel. For most of the countries the data were downloaded in January 2021 from the International Bureau of Fiscal Documentation country-reports (https://research.ibfd.org/#/). 
** see dofile: retail_report.do

** Commitment to Equity (CEQ) Standard Indicators 
* Data on market income, direct/indirect taxes and transfers at the country*decile level for about 30 developing countries
* We use this data to compute the change in Gini coefficients from applying direct/indirect tax systems
* Dowloaded on this website in June 2019: https://commitmentoequity.org/datacenter/ (A more recent version of the data from May 2020 is available) , the data are in the Excel file, sheet "16. Incidence by decile"
** see dofile: Gini_output.do

** OECD Gini coefficients
* Data on Gini and disposible income for all OECD countries
* We use this data to compute the change in Gini coefficients from applying direct/indirect tax systems
* Downloaded on the OECD website in April 2020 : https://www.oecd.org/social/income-distribution-database.htm 
** see dofile: Gini_output.do


** Data on Personal Income Taxes 
* Data on the size of threshold for poor vs rich (not generate anywhere yet), cited in section 6.3
* Data collected from Jensen 2019  
* see: "$main/data/PIT_parameters_AJ.dta"


*(need to cite? Ask Anders database IMF)
**Ad VAT rates (FMI dataset Anders)
*Ask report IBFD, (envoyer un report a Pierre) Sign in () Exampl, open burundi , find the name, and enter thsoe into VAT threshold 
*



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
	
***********************
* SCENARIO CONSIDERED *
***********************	
	/* Scenarios: 
	central: modern taxed (large stores and specialized stores), traditional untaxed (self-production, non brick and mortar, corner sdtores)
	proba: applies probabilities of being taxed by store type using the MX census
	specific: country specific probabilities for modern and traditional using retail reports ("$main/proc/dataset_formalityshare_actualpredict.dta") 
	robust: moves specialized stores to traditional (unused in the paper)
	*/ 
	
	*** INFORMALITY DEFINITION
	global scenario = "central"			// Choose scenario to be run: central, specific, vat_input, proba, robust
	display "$scenario"
	
	if "$scenario" == "central" {
			global Inf_weight_5 = 0		// Share of large stores informal 
			global Inf_weight_4 = 0		// Share of specialized stores informal
			global Inf_weight_3 = 1		// Share of corner stores informal
			global Inf_weight_2 = 1		// Share of non brick and mortar front informal
			}
	else if "$scenario" == "vat_input" {
			global Inf_weight_5 = 0		// Share of large stores informal 
			global Inf_weight_4 = 0		// Share of specialized stores informal
			global Inf_weight_3 = 0.9		// Share of corner stores informal
			global Inf_weight_2 = 0.9		// Share of non brick and mortar front informal	
			}
	else if "$scenario" == "proba" {
			global Inf_weight_5 = 0.1	// Share of large stores informal 
			global Inf_weight_4 = 0.5	// Share of specialized stores informal
			global Inf_weight_3 = 0.9	// Share of corner stores informal
			global Inf_weight_2 = 1		// Share of non brick and mortar front informal
			}	
	else if "$scenario" == "robust" {
			global Inf_weight_5 = 0		// Share of large stores informal 
			global Inf_weight_4 = 1		// Share of specialized stores informal
			global Inf_weight_3 = 1		// Share of corner stores informal
			global Inf_weight_2 = 1		// Share of non brick and mortar front informal	
			}		
			
	global format eps // Change to pdf for higher graph resolution
	
	*************************************************
	* Overview of all script names and goals		*
	*************************************************
	
	** To install all necessary packages 
		  config_data.do
	
	** Descriptive Figures: Based on microdata, country by country 
		  Informality_Engel_curves.do					// Informality Engel Curves by Country. Figure 3 et Figure E1	
		  Food_Engel_curves.do 							// Food Engel Curves by Country + Agg consumption and slopes of Food Engel curves by Country 
		  IEC_UrbanRural.do								// Informality Engel Curves by Country, urban and rural separated			

	** Table Generation Files
		  cross_country_descriptive_tables.do 			// Creates Tables 1, E1
		  Tables_PoP_by_country.do						// Creates Table E7
		  countries_population.do 						// To find the % of World population in sample (Appendix B1) 

	** Meta Data Generation Files: Generate Statistics at the country level 	 
		 * Main
		  Master_regressions_postestimation.do				// Agg consumption and slopes of IEC by Country 
		  Master_regressions_postestimation_COICOP12.do  	// Agg consumption and slopes of EC by COICOP2 * Country * total/formal/informal
		  Master_regressions_postestimation_InfFood.do		// Agg consumption and slopes Country * Formal/Informal * Food/non-Food  (almost same as above but faster and only 2*2)
		  Output_for_simulations_percentiles.do  			// Agg consumption by COICOP2 * Country * Percentile 
		  Output_for_simulations_decile.do                  // Agg consumption by COICOP2 * Country * Decile  
 
		 *Robustness
		  Master_missings_COICOP12.do							// Agg consumption spent Missing * Country * Decile
		  Master_formality_levels.do							// Agg consumption spent by PoP * Country * Decile
		  Master_regressions_postestimation_deciledummies.do 	// Residuals from the regressions for each decile dummy by country (allows for non-parametric decile graphs) 
	
	** PAPER SECTIONS 1, 2, 3, 4 (and Appendix C)
	** Figures and Tables for Paper, based on postestimation results 
		  
		  ** Figures and Tables on motivation/formality assignement
		  retail_report.do									// Figure 1, Table E6
		  country_specific_formal_assignment.do //  Figure C2				

		  * Figure based on census data
		  FirmSize_Census.do 							// Figure C1 panel (a), (c)
		  Mexico_reform.do 								// Figure 2, Generate graphs for pass-through in informal retail stores based on Mexican reform
		  
		  * Figures and tables based on postestimation data 
          Graphs_regressions_output_IEC.do 				// Figures for Informality Engel curves: Figure 4, A3, A4, E5 Table 2, E2, E3, E4			  
		  Graphs_regressions_output_IEC_urbrural.do 	// Figures for Informality Engel curves by Rural vs Urban : Figure E4
		  Graphs_regressions_output_Engel_InfFood		// Figures for Engel Curves of Inf vs For - Food vs non-Food , Figure 5 , A7, A8 
  
		  Graphs_missing_by_coicop.do					// Documents size and COICOP2 composition of the unspecified category , Figure A1, E2  
		  Graphs_robustness_formality_levels.do			// Documents size of each PoP. Figure A2, E3. + statistics for the country loop when no distinction level 3 and 4. 
          Graphs_regressions_output_IEC_deciles.do 		// Figures Informal Consumption by Deciles				
		  Graphs_regressions_output_Engel_Food.do 		// Figures for Food Engel curves 		  
		  

		** Figures and explorations for descriptive mechanism section 
		  Quality_price_tradeoff.do									// Produces the table on reason for choosing PoP and a figure on quality by decile: Figure E6, Table A1, E5
		  cross_country_price_quantity_regressions_harmonized.do 	// regressions on price
		  Graphs_regressions_output_price_quantity.do 				// Figure for Table A2


		** PAPER SECTION 5: 		
		** Mechanical Simulation   
		  simulations_mechanical.do 				// Mechanical simulations. Creates Figures 6 and table A3.
		  Figures_percentiles 						// Produces Figure 7, A6
		  
		  
		** PAPER SECTION 6: 					
		** Optimal Tax Programs: two programs one with only food vs non food differatiation and one with the differentiation of all 12 COICOP categories. 
		** Inputs for programs: 				"proc/output_for_simulation_pct_COICOP2_$scenario" 
		**										"proc/regressions_output_$scenario.dta"
		**										"proc/regressions_COICOP12_$scenario.dta"
		**										"data/PIT_parameters_AJ.dta""
	
		  optimal_tax_pit_program.do			// Generates optimal tax food/non food, allows for PIT 
		  optimal_tax_program_COICOP12.do		// Optimal tax rate differentiation across all 12 COICOPs -  does not interact with PIT for now
		  
		  Calibrated_rates.do					// Figure 8, 9 runs checks on the above and produces graphs in Appendix E  		  
		  Callibrated_rates_COICOP12			// Figure A9a, A10a Calibrated tax rates, COICOP 12
		  
	
		** PAPER SECTION 7:
		** Calibration Results: Optimal Tax Rates and Gini Coefficients   
		
		
		** Gini 
		  gini.do 								// Compute change in gini under the different scenario, food/non-food rate differentiation
		  gini_pit.do 							// Figure 10, Compute change in gini under the different scenarios with PIT, food/non-food rate differentiation
		  GINI_COICOP12.do 						// Compute change in gini under the different scenario, rate differentiation across all 12 COICOPs		  
		  Gini_output_tableA7					// Creates Table A4
		  Graphs_gini_arrows					// Create  A9b, A10b
		
		** Figure on informal labor 
		  graphs_informal_labor.do 			// Figure A11, Compute average expenditures of people working in the retail, retail & formal, retail & informal  sector

			  
	******* Additional files 	  
		  
		  
		** Excel files to loop over all countries	
		  Country_index_for_stata_loop.xlsx				 // Loop over all countries (N=32) 
		  Country_index_for_stata_loop_reason.xlsx		 // Loop over the countries included in the price quantity tradeoff analysis (N=6)
		  Country_index_for_unit_values_stata_loop.xlsx  // Loop over the countries included in the unit values analysis sample (N=20)

		** Auxiliary and Unused in paper
		  cross_country_census_analysis.do				// Old Fig 1 panel(a) using census data 
		  Calibrations_results_full_rate_diff
		  Informality_Engel_curves_loglog.do			// Runs the Engel curves on a log log specification (to be developed to have standard tests?)
		  Engel_curves_Exploration.do 				// Use the deciles spending on the different sectors and build the formal/informal IEC by good 		 
		  Optimal_tax_simulated_data.do 		// (unused in paper) Optimal tax scenarios, simulated data to check role of slope versus budget shares	
		  gini.R 								// Creates R figure for comparison of scenarios  
		  gini_middle_low_inc.R 				// Creates R figure for comparison of scenarios  			
		  Gini_output.do						// Creates .csv to import to R and create Figure 8 and A16

		
	** Work on Global Consumption Database 
		 WB_GCDB_draft.do							// The code we sent to DECDG (Tefera), to have Engel Food estimates and average food consumption for Globl 	Consumption Database
		 Global_Consumption_Database.do 			// Append file sent by DECDG, merge with GDP and create Figures 4 (panels a and b)
		 Global_Consumption_Database_map.do		// To draw the maps of the core and extended samples . Figure B2
	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
