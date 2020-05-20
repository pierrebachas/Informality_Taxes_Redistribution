
***********************************************************************
* 	MASTER FILE INFORMALITY, CONSUMPTION TAXES and REDISTRIBUTION 	  * 
***********************************************************************

***********************
* SCENARIO CONSIDERED *
***********************	
	
	*** INFORMALITY DEFINITION
	global scenario = "central"			// Choose scenario to be run: central, proba, robust	
	display "$scenario"
	
	if "$scenario" == "central" {
			global Inf_weight_5 = 0		// Share of large stores informal 
			global Inf_weight_4 = 0		// Share of specialized stores informal
			global Inf_weight_3 = 1		// Share of corner stores informal
			}
	else if "$scenario" == "proba" {
			global Inf_weight_5 = 0.1	// Share of large stores informal 
			global Inf_weight_4 = 0.5	// Share of specialized stores informal
			global Inf_weight_3 = 0.9	// Share of corner stores informal
			}	
	else if "$scenario" == "robust" {
			global Inf_weight_5 = 0		// Share of large stores informal 
			global Inf_weight_4 = 1		// Share of specialized stores informal
			global Inf_weight_3 = 1		// Share of corner stores informal
			}		
			
	*************************************************
	* Overview of all script names					*
	*************************************************
	
	** Descriptive Figures: Based on microdata, country by country 
		  Informality_Engel_curves.do						// Informality Engel Curves by Country. Figure A1	
		  Food_Engel_curves.do 								// Food Engel Curves by Country + Agg consumption and slopes of Food Engel curves by Country 
		  IEC_UrbanRural.do									// Informality Engel Curves by Country, urban and rural separated			

	** Meta Data Generation Files: Generate Statistics at the country level 	 
		 * Main
		  Master_regressions_postestimation.do				// Agg consumption and slopes of IEC by Country 
		  Master_regressions_postestimation_COICOP12.do  	// Agg consumption and slopes of EC by COICOP2 * Country * total/formal/informal
		  Output_for_simulations.do                         // Agg consumption by COICOP2 * Country * Decile  
		 
		 *Robustness
		  Master_regressions_postestimation_InfFood		  		// Agg consumption and slopes Country * Formal/Informal * Food/non-Food (also 2*2 Engel Curve figures)
		  Master_missings_COICOP12.do							// Agg consumption spent Missing * Country * Decile
		  Master_formality_levels.do							// Agg consumption spent by PoP * Country * Decile
		  Master_regressions_postestimation_deciledummies.do 	// Residuals from the regressions for each decile dummy by country (allows for non-parametric decile graphs) 
	
	** PAPER SECTIONS 2, 3.1, 3.2.1
	** Figures and Tables for Paper, based on postetimation results 
		  
		  * Figure based on census data 
		  cross_country_census_analysis.do				// Figure 1, panel(a) using census data 
		  FirmSize_Census.do 							// Figure 2,3 panel (b), (c)
		  
		  * Figures based on postestimation data 
          Graphs_regressions_output_IEC.do 				// Figures for Informality Engel curves: Figure 2, 3, A2, A3, Table 2, A1, A2, A3, A6, A8				  
		  Graphs_regressions_output_IEC_urbrural.do 	// Figures for Informality Engel curves by Rural vs Urban : Figure A7
		  Graphs_regressions_output_Engel_InfFood		// Figures for Engel Curves of Inf vs For - Food vs non-Food , Figure 4 (panels c and d) , A10, A11, A12
  
		  Graphs_missing_by_coicop.do					// Documents size and COICOP2 composition of the unspecified category , Figure A3, B1  
		  Graphs_robustness_formality_levels.do			// Documents size of each PoP. Figure A4, A5. + statistics for the country loop when no distinction level 3 and 4. 
          Graphs_regressions_output_IEC_deciles.do 		// Figures Informal Consumption by Deciles				
		  Graphs_regressions_output_Engel_Food.do 		// Figures for Food Engel curves 		  
		  
	 *Table Generation Files
		  cross_country_descriptive_tables.do 			// Creates Table 1, B3
		  Tables_regressions_output.do					// Creates Table 2
		  Tables_PoP_by_country.do						// Creates Table B4

	** PAPER SECTION 3.2.2		  
	** Figures and explorations for descriptive mechanism section 
		  Quality_price_tradeoff.do						// Produces the table on reason for choosing PoP and a figure on quality by decile: Figure A9 Table A4 
		  cross_country_price_quantity_regressions_harmonized.do 	// regressions on price
		  Graphs_regressions_output_price_quantity.do 				// Figure for Table A5

	** PAPER SECTION 3.3		  
	** Work on Global Consumption Database 
		  WB_GCDB_draft.do							// The code we sent to DECDG (Tefera), to have Engel Food estimates and average food consumption for Globl Consumption Database
		  Global_Consumption_Database.do 			// Append file sent by DECDG, merge with GDP and create Figures 4 (panels a and b)
		  countries_population.do 					// To find the % of World population in GCD sample (Appendix B.3)
		  Global_Consumption_Database_map.do		// To draw the maps of the core and extended samples . Figure B2
	
	** PAPER SECTION 4: 		
	** Mechanical Simulation   
		  simulations_mechanical.do 			// Mechanical simulations. Creates Figures 5 and 6 and table A6. 

	** PAPER SECTION 6: 		
	** Optimal Tax Programs  		  
	
		  optimal_tax_program.do				// Optimal tax food/non food 
		  optimal_tax_program_COICOP12.do		// Optimal tax rate differentiation across all 12 COICOPs		 
		  Calibrations_results.do 				// Creates Figure 7, A13, A14, A15
		  
		  Optimal_tax_simulated_data.do 		// (unused in paper) Optimal tax scenarios, simulated data to check role of slope versus budget shares  
	
	** Gini 
		  gini.do 								// Compute change in gini under the different scenario, food/non-food rate differentiation
		  GINI_COICOP12.do 						// Compute change in gini under the different scenario, rate differentiation across all 12 COICOPs		  
		  Gini_output_Fig8_A16.do				// Creates .csv to import to R and create Figure 8 and A16
		  gini.R 								// Creates Figure 8  
		  Gini_output_tableA7					// Creates Table A7

		
		
		
		
		
		
		
		
		
		
		
		
		
		
