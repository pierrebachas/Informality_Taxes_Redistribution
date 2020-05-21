
					*************************************
					* 			  DO FILE 				*
					*   			Map					*
					*************************************	


	
***************************
* CONTROL CENTER *
***************************					
	
	local shape_file = 0
	local data_prep = 1
	
**********************************************
* 0. Create the datafiles with map coordinates
**********************************************
if `shape_file' {


	clear
	set more off
	shp2dta using "$main/data/Global_Consumption_Database/TM_WORLD_BORDERS-0.3.shp", database(worlddb) coordinates(worldcoord) genid(id)
	
	}
	
****************
* 1. Data prep
****************

if `shape_file' {
	use "$main/proc/Food_Engel_Curve.dta" , clear
	ren country_code country_2let
	keep if iteration == 8 
	merge 1:1 country_2let using "$main/data/Global_Consumption_Database/GCD_website_for_graph.dta" , gen (m_gcd_sample)
	
	* Code for map appendix: 1 IEC sample but no GCD 2 GCD only 3 Both 
	gen sample=1 if m_gcd_sample==3 
	replace sample=2 if m_gcd_sample==2
	replace sample=3 if  m_gcd_sample==1
	
	*Code for map 
	
	gen core_sample= (m_gcd_sample==1 | m_gcd_sample==3)
	
	tempfile GCD_IEC_samples_map
	save `GCD_IEC_samples_map'
	
	
	use "$main/data/Global_Consumption_Database/worlddb.dta" , clear
	ren ISO2 country_2let
	merge 1:1 country_2let using `GCD_IEC_samples_map'
	
	/* Perfect match because IEC + GCD sample = 89,  teh rest are the country of the world in any samples
	
    Result                           # of obs.
    -----------------------------------------
    not matched                           157
        from master                       157  (_merge==1)
        from using                          0  (_merge==2)

    matched                                89  (_merge==3)
    -----------------------------------------

	*/
	* Add the world countries that do not appear in GCD nor in core sample 
	replace core_sample=0 if _merge==1
	}
	
	
****************
* 2. Maps
****************
* Map for appendix, Figure B.2. - Option 1
	spmap sample using worldcoord , id(id) clmethod(custom) clbreaks(0.9 1.9 2.9 3.9) fcolor(gray eltblue blue) ocolor(grey) osize(0.1)  legend(symy(*2) symx(*2)size(*1.5) position(9)) legend(label(1 "Not covered") label(2 "In core and extended samples" )label(3 "Extended sample only" )  label(4 "Core sample only" ))
	graph export "$main\graphs\Global_Consumption_Database\map_gcd_core_sample_blue.pdf" , replace


* Map for appendix, Figure B.2. - Option 2
	spmap sample using worldcoord , id(id) clmethod(custom) clbreaks(0.9 1.9 2.9 3.9) fcolor(dkgreen midgreen olive_teal) ocolor(grey) osize(0.1)  legend(symy(*2) symx(*2)size(*1.5) position(9)) legend(label(1 "Not covered") label(2 "In core and extended samples" )label(3 "Extended sample only" )  label(4 "Core sample only" ))
	graph export "$main\graphs\Global_Consumption_Database\map_gcd_core_sample2.pdf" , replace

* Map for slides Princeton 
	
	spmap core_sample using worldcoord , id(id) clmethod(custom) clbreaks(0 0.9 1.9) fcolor(white green) ocolor(grey) osize(0.1)  legend(symy(*2) symx(*2)size(*1.5) position(9)) legend(order(3 "Core sample"))
	graph export "$main\graphs\Global_Consumption_Database\map_core_sample.pdf" , replace
