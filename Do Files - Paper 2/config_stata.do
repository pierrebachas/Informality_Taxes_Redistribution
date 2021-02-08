/*To run ST_2010_ICF.do
ssc install fs
*To run Tables_PoP_by_country.do
ssc install valuesof
ssc install moremata
*To run CM_2014_ECAM.do
net from https://www.sealedenvelope.com/
 xfill
ssc install labutil
*To run cross_country_descriptive_tables.do
ssc install unique
*To run Master_regressions_postestimation.do
ssc install reghdfe
ssc install ftools
*/

	clear all
	set more off
	
	program main
		* *** Add required packages from SSC to this list ***
		local ssc_packages "fs valuesof moremata  labutil unique reghdfe ftools"
		* *** Add required packages from SSC to this list ***
	
		if !missing("`ssc_packages'") {
			foreach pkg in "`ssc_packages'" {
			* install using ssc, but avoid re-installing if already present
				capture which `pkg'
				if _rc == 111 {                 
				   dis "Installing `pkg'"
				   quietly ssc install `pkg', replace
				   }
			}
		}
	
		* Install packages using net, but avoid re-installing if already present
		capture which grc1leg
		   if _rc == 111 {
			quietly net from "https://www.sealedenvelope.com/"
			quietly cap ado uninstall xfill
			quietly net install xfill
		   }
		
	
	end
	
	main

	/*
