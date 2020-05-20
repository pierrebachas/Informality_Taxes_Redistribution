# Informality_Taxes_Redistribution
Replication codes for the paper "Informality Consumption Taxes &amp; Redistribution"
by Pierre Bachas, Lucie Gadenne and Anders Jensen. 

-----------------------------------------------------------------------------------------------------
This repository contains three folders:

Do files - Paper: These files allow for a full replication of the paper once each country's expenditure survey data has been obtained (the master.do file details which do file correspond to which graph or table).
Do files - Country Codes : These files allow to replicate the analysis we conducted for each country from the raw data. The same methodology is used for each country, with a few exceptions listed and detailed below.
Crosswalk : These files are needed for the analysis of some countries, which product codes where not following the COICOP classification and/or when the type of retailers classification was too detailed.

-----------------------------------------------------------------------------------------------------
Notes on the Data

The data comes from nationally representative income and expenditure surveys from 31 countries. 
Some of these micro-data are open access and can be obtained from the statistical agency of each countries, and others are restricted access. We list below the country names, survey acronyms and years for anyone interested in replicating our analysis. 

Country name	Survey	Year	Source
Benin	        EMICOV	2015	World Bank
Bolivia	      ECH	    2004	Stat. Office
Brazil	      POF	    2009	Stat. Office
BurkinaFaso	  EICVM	  2009	Stat. Office
Burundi	      ECVM	  2014	World Bank
Cameroon	    ECAM	  2014	World Bank
Chad	        ECOSIT	2003	World Bank
Chile	        EPF	    2017	Stat. Office
Colombia	    ENIG	  2007	Stat. Office
Comoros	      EDMC	  2013	Stat. Office
Congo_DRC	    E123	  2005	World Bank
Congo_Rep	    ECOM	  2005	World Bank
Costa_Rica	  ENIGH	  2014	Stat. Office
Dominican_Rep	ENIGH	  2007	Stat. Office
Ecuador	      ENIGHUR	2012	World Bank
Eswatini	    HIES	  2010	World Bank
Mexico	      ENIGH	  2014	Stat. Office
Montenegro	  HBS	    2009	World Bank
Morocco	      ENCDM	  2001	World Bank
Mozambique	  IOF	    2009	World Bank
Niger	        ENCBM	  2007	World Bank
Papua_NG	    HIES	  2010	World Bank
Peru	        ENAHO	  2017	Stat. Office
Rwanda	      EICV	  2014	World Bank
SaoTome	      IOF	    2010	World Bank
Senegal_Dakar	EDMC	  2008	World Bank
Serbia	      HBS	    2015	World Bank
SouthAfrica	  IES	    2011	U. of Cape Town
Tanzania	    HBS	    2012	World Bank
Tunisia	      ENBCNV	2010	Stat. Office
Uruguay	      ENIGH	  2005	Stat. Office

-----------------------------------------------------------------------------------------------------
Some countries analysis differ slighlty from the general structure. These differences are listed below:

Crosswalks:
Brazil (product_code & TOR)
Bolivia (COICOP & TOR)
Eswatini (COICOP)
Mexico (COICOP)
Morocco (COICOP)
Papua New Guinea (COICOP)
Peru (product_code & TOR)
South Africa (COICOP)

Question on Reason of purchase:
Benin
Burundi
Comores
Congo DRC
Congo Rep
Morocco

Imputation of some TOR (Type of retailer):
Cameroon
Montenegro
Mozambique
Niger
Tanzanie

Product Code not following COICOP:
Brazil
Chad
Peru
