************************
// Estimation
************************
/*
    Created on 12.8.2021
    @author: Florian Fickler
    Goal:
        1. Run regressions for both mechanisms included in the Opportunity Channel
			a. Unemployment-Opportunity Mechanism (UO)
			b. Opportunity-Crime Mechanism (OC)
		2. Create tables from these regressions for the paper
		3. Create graphs
		4. Creae summary statistics
		
	Note: Currently only uses ACS Wave 5 and Pop-Weighted NIBRS observations
	
	// Decide between month and week FE
	
	

*/


drop _all
//set cd
cd "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset"

// Load Dataset
use "Opportunity_County_Popweight_5.dta"

****************************************************************************************************
// 1. Summary Statistics
****************************************************************************************************
// Some days miss a observation for prcp so we will only use days that have rain data available
// Also for some counties we only have 0 crimes registeres, this does not allow any variation to be exploited in FE and therefore they are consequentially dropped from Poisson
drop if missing(prcp)
// Identify non crime counties
// egen temp_tot_crimes = total(crimes_number), by(Area_ID )
// drop if temp_tot_crimes == 0
// drop temp_tot_crimes


**********************************************
// i. Non-Crime Summaries - S1//
**********************************************
	gen PopHome100 = 100 * PopulationAtHome

	// add do Data section
	replace trips_pP = . if trips_pP > 21

	estpost sum  UER_month trips_pP PopHome100 prcp
	esttab using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/S1.tex", cells("mean(fmt(2)) sd(fmt(2)) min(fmt(1)) max(fmt(0))")  nonumber replace 

**********************************************
// ii. Crime Summaries - S2 //
**********************************************
		// Calculate total crimes happened during the day (should be in merger or NIBRS LOAD!)
		gen crimes_daytime = daytime_crime_AA + daytime_crime_Rape + daytime_crime_Robbery + daytime_crime_MVT + daytime_crime_Murder + daytime_crime_Larcency + daytime_crime_Burglary

		gen daytime_crime_Property =  daytime_crime_Burglary * daytime_crime_Larcency + daytime_crime_MVT + daytime_crime_Robbery

		gen daytime_crime_Violent =  daytime_crime_AA + daytime_crime_Murder + daytime_crime_Rape


		// And Total Crimes happend in residential areas by Group
		gen residential_Property = residential_Burglary + residential_Larcency + residential_MVT + residential_Robbery

		gen residential_Violent = residential_AA + residential_Murder + residential_Rape


	// Summaries of Unemployment, Precipitation, and Criminal Opportunity
	 estpost sum  crimes_number Offense_FBI_Property Offense_Larcency Offense_Burglary Offense_MVT Offense_Robbery    Offense_FBI_Violent Offense_AA Offense_Rape Offense_Murder  location_residence crimes_daytime     
	esttab using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/S2.tex", cells("mean(fmt(2)) sd(fmt(2)) min(fmt(1)) max(fmt(0))")  nonumber replace 
	




****************************************************************************************************
// 2. Unemployment - Opportunity Mechanism
****************************************************************************************************

**********************************************
// Preliminaries							 //
**********************************************
// Set up as Panel
// First create an id for each county
egen Area_ID = group(geographicareaname)

// Also need to create a state id for state FE later
egen state_id = group(state)

// xtset
// strongly balanced panel
xtset Area_ID day_year

// create squared UE
gen UER_month2 = UER_month * UER_month


**********************************************
// i. Effect on Population @ Home - Table UO1 //
**********************************************
// Population at Home and Trips have an opposite relationship with Opportunity! Maybe use Pop not at home?
// Month or Week? Latter is more granular but only adds for FE - POP and there might even be better the explain without (only turn results insiginficant)

	*******************
	// a) Linear Model
	*******************
	// No additional Controls
	qui: xtreg PopulationAtHome UER_month, cluster(Area_ID) fe	
	eststo UO1_Pop
	
	// Month FE
	qui: xtreg PopulationAtHome UER_month i.month, cluster(Area_ID) fe	
	eststo UO1_Pop_M
	
	// WEEK FE
	qui: xtreg PopulationAtHome UER_month i.week, cluster(Area_ID) fe	
	eststo UO1_Pop_W

	
	**********************
	// b) Quadratic Model
	**********************
	// No additional Controls
	qui: xtreg PopulationAtHome UER_month UER_month2, cluster(Area_ID) fe	
	eststo UO1_Pop_Q
	
	// Month FE
	qui: xtreg PopulationAtHome UER_month UER_month2 i.month, cluster(Area_ID) fe	
	eststo UO1_Pop_QM
	
	// WEEK FE
	qui: xtreg PopulationAtHome UER_month UER_month2 i.week, cluster(Area_ID) fe	
	eststo UO1_Pop_QW
	
	// Table UO1 - Rest of the formatting is done in Latex
	esttab UO1* using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/UO1.tex", keep(UER_month UER_month2) title("Population At Home") nomtitles coeflabels(UER_month "Unemployment" UER_month2 "Unemployment squared") replace scalars("N_g Cluster")

**********************************************
// i. Effect on Trips p.P. - Table UO2 		//
**********************************************
// Population at Home and Trips have an opposite relationship with Opportunity! Maybe use Pop not at home?
// Month or Week? Latter is more granular but only adds for FE - POP and there might even be better the explain without (only turn results insiginficant)

	*******************
	// a) Linear Model
	*******************
	// No additional Controls
	qui: xtreg trips_pP UER_month, cluster(Area_ID) fe
	eststo UO2_Trip
	
	// Month FE
	qui: xtreg trips_pP UER_month i.month, cluster(Area_ID) fe	
	eststo UO2_Trip_M
	
	// WEEK FE
	qui: xtreg trips_pP UER_month i.week, cluster(Area_ID) fe	
	eststo UO2_Trip_W

	
	
	**********************
	// b) Quadratic Model
	**********************
	// No additional Controls
	qui: xtreg trips_pP UER_month UER_month2, cluster(Area_ID) fe	
	eststo UO2_Trip_Q
	
	// Month FE
	qui: xtreg trips_pP UER_month UER_month2 i.month, cluster(Area_ID) fe	
	eststo UO2_Trip_QM
	
	// WEEK FE
	qui: xtreg trips_pP UER_month UER_month2 i.week, cluster(Area_ID) fe	
	eststo UO2_Trip_QW
	
	// Table UO2
	esttab UO2* using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/UO2.tex", keep(UER_month UER_month2) title("Trips per Person") nomtitles coeflabels(UER_month "Unemployment" UER_month2 "Unemployment squared") replace scalars("N_g Cluster")


****************************************************************************************************
// 3. Opportunity - Crime Mechanism
****************************************************************************************************
**********************************************
// i. Preliminaries							 //
**********************************************	
	**********************************************
	// a) Calculate Missing Variables (Add to NIBRS LOAD Eventually) //
	**********************************************
	// Moved upward
		
	**********************************************
	// b) Reduce Sample to smalles common level //
	**********************************************

		


	**********************************************
	// c) Run First Stage Regressions - Table - FS //
	**********************************************
		// Note: This Proceder is taken from Lin & Wooldridge (2019) - Residuals from this first stage are included in the latter regressions to test for the exogeneity of our variable.
		// Needs some implementations for panel bootstrap on the whole estimation (e.g. both regressions) or usage of the dfelta method (also SEM/GEM comand could be usefull)
		// Check obs per group!
		
		// Using vce(bootstrap) automatically clusters the SE
		
		// need to set seed!
		set seed 98435
		
		// Without month controls
		qui: xtreg PopulationAtHome prcp, fe vce(bootstrap)
		eststo FS_Pop
		predict double Pop_fe, e
		
		qui: xtreg trips_pP prcp, fe vce(bootstrap)
		eststo FS_Trip
		predict double trips_fe, e
		
		// With month controls
		qui: xtreg PopulationAtHome prcp i.month, fe vce(bootstrap)
		eststo FS_Pop_M
		predict double Pop_fe_M, e	
		
		qui: xtreg trips_pP prcp i.month, fe vce(bootstrap)
		eststo FS_Trip_M
		predict double trips_fe_M, e
		
		// First Stage Table
		esttab FS* using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/FS.tex", keep(prcp) title("First Stage Regressions") coeflabels(prcp "Precipitation") replace scalars("N_g Cluster")
		
		// Note, does this also count for the FS from the FE estimators?


**********************************************
// ii. Overall Effect on Crime	- Table OC1	//
**********************************************
	// Note:
	// Might add the regressions with POLS to the Appendix
	// Still need to think about the reporting of the First Stage results
	// Could add the xtreg for the poisson as preliminary codes outside this table so that it can be run seperately! - These are the First Stages anyway, so doing this would allow a first stage table!


	// Table OC1: Depicts the overall effects on Crime from oppoertunity for both measures and the three aggregates
	// Two options, two horizontal and 3 vertical panels, or Two tables with 3 vertical panels each

	*******************
	// a) Total Crimes
	*******************
		// FIXED EFFECTS	
		// no controls
		qui: xtreg crimes_number PopulationAtHome, fe cluster(Area_ID)
		eststo OC1a_P_FE_Tot
		
		qui: xtreg crimes_number trips_pP, fe cluster(Area_ID)
		eststo OC1a_T_FE_Tot
		
		// Note: robust and cluster on Area_ID produces the same SE, however STATA does not allow cluster for some reason, so I deviate here and use robust instead
		// IV
		qui: xtivreg crimes_number (PopulationAtHome = prcp), fe vce(r)
		eststo OC1a_P_FEIV_Tot
		
		qui: xtivreg crimes_number (trips_pP = prcp), fe vce(r)
		eststo OC1a_T_FEIV_Tot
		
		// IV & Month
		qui: xtivreg crimes_number (PopulationAtHome = prcp) i.month, fe vce(r)
		eststo OC1a_P_FEIVM_Tot
		
		qui: xtivreg crimes_number (trips_pP = prcp) i.month, fe vce(r)
		eststo OC1a_T_FEIVM_Tot
		
		// POISSON
		// no controls
		qui: xtpoisson crimes_number PopulationAtHome, fe vce(robust)
		eststo OC1a_P_P_Tot
		
		qui: xtpoisson crimes_number trips_pP, fe vce(robust)
		eststo OC1a_T_P_Tot
		
		// IV
		qui: xtpoisson crimes_number PopulationAtHome Pop_fe, fe vce(robust)
		eststo OC1a_P_PIV_Tot
		
		qui: xtpoisson crimes_number trips_pP trips_fe, fe vce(robust)
		eststo OC1a_T_PIV_Tot
		
		// IV & Month
		qui: xtpoisson crimes_number PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC1a_P_PIVM_Tot
		
		qui: xtpoisson crimes_number trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC1a_T_PIVM_Tot	
		
		// Table OC1a - Total Crimes
		// SPlitting into two tables for each opportunity variable
		// Population at Home
		esttab OC1a_P_FE_Tot OC1a_P_FEIV_Tot OC1a_P_FEIVM_Tot OC1a_P_P_Tot OC1a_P_PIV_Tot OC1a_P_PIVM_Tot using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1aHome.tex", keep(PopulationAtHome Pop_fe Pop_fe_M) title("Opportunity Home on Total Crime") coeflabels(PopulationAtHome "Population Home") mtitles("FE" "FE-IV" "FE-IV-M" "P" "P-IV" "P-IV-M")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab OC1a_T_FE_Tot OC1a_T_FEIV_Tot OC1a_T_FEIVM_Tot OC1a_T_P_Tot OC1a_T_PIV_Tot OC1a_T_PIVM_Tot using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1aTrip.tex", keep(trips_pP trips_fe trips_fe_M) title("Opportunity Trips on Total Crime") coeflabels(trips_pP "Trips p.P.") mtitles("FE" "FE-IV" "FE-IV-M" "P" "P-IV" "P-IV-M") replace scalars("N_g Cluster")
		
		
	*******************
	// b) Property Crimes
	*******************
		// FIXED EFFECTS	
		// no controls
		qui: xtreg Offense_FBI_Property PopulationAtHome, fe cluster(Area_ID)
		eststo OC1b_P_FE_Prop
		
		qui: xtreg Offense_FBI_Property trips_pP, fe cluster(Area_ID)
		eststo OC1b_T_FE_Prop
		
		// Note: robust and cluster on Area_ID produces the same SE, however STATA does not allow cluster for some reason, so I deviate here and use robust instead
		// IV
		qui: xtivreg Offense_FBI_Property (PopulationAtHome = prcp), fe vce(r)
		eststo OC1b_P_FEIV_Prop
		
		qui: xtivreg Offense_FBI_Property (trips_pP = prcp), fe vce(r)
		eststo OC1b_T_FEIV_Prop
		
		// IV & Month
		qui: xtivreg Offense_FBI_Property (PopulationAtHome = prcp) i.month, fe vce(r)
		eststo OC1b_P_FEIVM_Prop
		
		qui: xtivreg Offense_FBI_Property (trips_pP = prcp) i.month, fe vce(r)
		eststo OC1b_T_FEIVM_Prop
		
		// POISSON
		// no controls
		qui: xtpoisson Offense_FBI_Property PopulationAtHome, fe vce(robust)
		eststo OC1b_P_P_Prop
		
		qui: xtpoisson Offense_FBI_Property trips_pP, fe vce(robust)
		eststo OC1b_T_P_Prop
		
		// IV
		qui: xtpoisson Offense_FBI_Property PopulationAtHome Pop_fe, fe vce(robust)
		eststo OC1b_P_PIV_Prop
		
		qui: xtpoisson Offense_FBI_Property trips_pP trips_fe, fe vce(robust)
		eststo OC1b_T_PIV_Prop
		
		// IV & Month
		qui: xtpoisson Offense_FBI_Property PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC1b_P_PIVM_Prop
				
		qui: xtpoisson Offense_FBI_Property trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC1b_T_PIVM_Prop
		
		// Table OC1b
		// Population at Home
		esttab OC1b_P_FE_Prop OC1b_P_FEIV_Prop OC1b_P_FEIVM_Prop OC1b_P_P_Prop OC1b_P_PIV_Prop OC1b_P_PIVM_Prop using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1bHome.tex", keep(PopulationAtHome Pop_fe Pop_fe_M) title("Opportunity Home on Property Crime") coeflabels(PopulationAtHome "Population Home") mtitles("FE" "FE-IV" "FE-IV-M" "P" "P-IV" "P-IV-M")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab OC1b_T_FE_Prop OC1b_T_FEIV_Prop OC1b_T_FEIVM_Prop OC1b_T_P_Prop OC1b_T_PIV_Prop OC1b_T_PIVM_Prop using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1bTrip.tex", keep(trips_pP trips_fe trips_fe_M) title("Opportunity Tripe on Property Crime") coeflabels(trips_pP "Trips p.P.") mtitles("FE" "FE-IV" "FE-IV-M" "P" "P-IV" "P-IV-M") replace scalars("N_g Cluster")
		
		
	*******************
	// c) Violent Crimes
	*******************
		// FIXED EFFECTS	
		// no controls
		qui: xtreg Offense_FBI_Violent PopulationAtHome, fe cluster(Area_ID)
		eststo OC1c_P_FE_Vio
		
		qui: xtreg Offense_FBI_Violent trips_pP, fe cluster(Area_ID)
		eststo OC1c_T_FE_Vio	
		
		// Note: robust and cluster on Area_ID produces the same SE, however STATA does not allow cluster for some reason, so I deviate here and use robust instead
		// IV
		qui: xtivreg Offense_FBI_Violent (PopulationAtHome = prcp), fe vce(r)
		eststo OC1c_P_FEIV_Vio
		
		qui: xtivreg Offense_FBI_Violent (trips_pP = prcp), fe vce(r)
		eststo OC1c_T_FEIV_Vio
		
		// IV & Month
		qui: xtivreg Offense_FBI_Violent (PopulationAtHome = prcp) i.month, fe vce(r)
		eststo OC1c_P_FEIVM_Vio
		
		qui: xtivreg Offense_FBI_Violent (trips_pP = prcp) i.month, fe vce(r)
		eststo OC1c_T_FEIVM_Vio
		
		// POISSON
		// no controls
		qui: xtpoisson Offense_FBI_Violent PopulationAtHome, fe vce(robust)
		eststo OC1c_P_P_Vio
		
		qui: xtpoisson Offense_FBI_Violent trips_pP, fe vce(robust)
		eststo OC1c_T_P_Vio
		
		// IV
		qui: xtpoisson Offense_FBI_Violent PopulationAtHome Pop_fe, fe vce(robust)
		eststo OC1c_P_PIV_Vio
		
		qui: xtpoisson Offense_FBI_Violent trips_pP trips_fe, fe vce(robust)
		eststo OC1c_T_PIV_Vio
		
		// IV & Month
		qui: xtpoisson Offense_FBI_Violent PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC1c_P_PIVM_Vio
				
		qui: xtpoisson Offense_FBI_Violent trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC1c_T_PIVM_Vio
		
		// Table OC1c
		// Population at Home
		esttab OC1c_P_FE_Vio OC1c_P_FEIV_Vio OC1c_P_FEIVM_Vio OC1c_P_P_Vio OC1c_P_PIV_Vio OC1c_P_PIVM_Vio using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1cHome.tex", keep(PopulationAtHome Pop_fe Pop_fe_M) title("Opportunity Home on Violent Crimes") coeflabels(PopulationAtHome "Population Home") mtitles("FE" "FE-IV" "FE-IV-M" "P" "P-IV" "P-IV-M")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab OC1c_T_FE_Vio OC1c_T_FEIV_Vio OC1c_T_FEIVM_Vio OC1c_T_P_Vio OC1c_T_PIV_Vio OC1c_T_PIVM_Vio using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1cTrip.tex", keep(trips_pP trips_fe trips_fe_M) title("Opportunity Trips on Violent Crimes") coeflabels(trips_pP "Trips p.P.") mtitles("FE" "FE-IV" "FE-IV-M" "P" "P-IV" "P-IV-M") replace scalars("N_g Cluster")
		
		// Change in Endogeneity for the At Home (endo for VIo; Exo for Prop) might be due to pre-planned nature of many property crimes and spontaneous nature of violent crimes
		
	*******************
	// d) Aggregates
	*******************
	// Table OC1d
	// Population at Home
	esttab  OC1a_P_FEIVM_Tot OC1a_P_PIVM_Tot OC1b_P_FEIVM_Prop OC1b_P_PIVM_Prop OC1c_P_FEIVM_Vio   OC1c_P_PIVM_Vio using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1dHome.tex", keep(PopulationAtHome  Pop_fe_M) title("Opportunity Home on Aggregates") coeflabels(PopulationAtHome "Population Home") mtitles("Tot FE" "Tot P" "Prop FE" "Prop P" "Vio FE" "Vio P")   replace scalars("N_g Cluster")
	
	// Trips p.P.
	esttab  OC1a_T_FEIVM_Tot  OC1a_T_PIVM_Tot OC1b_T_FEIVM_Prop  OC1b_T_PIVM_Prop OC1c_T_FEIVM_Vio  OC1c_T_PIVM_Vio using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC1dTrip.tex", keep(trips_pP  trips_fe_M) title("Opportunity Trips on Aggregates") coeflabels(trips_pP "Trips p.P.") mtitles("Tot FE" "Tot P" "Prop FE" "Prop P" "Vio FE" "Vio P") replace scalars("N_g Cluster")

  
**********************************************
// iii. Crime Heterogeneity	- Table OC2	//
**********************************************
	// Note:
	// This will depict the heterogeneity between different offenses
	// Therefore for each offense two Poisson-IV-FE regressions are run (one for each opportunity variable)
	// The Table will be split into two Panels, one for each type of crime (Property & Violent)
	// The table will most likely become two tables (one for each opportunity variable)
	// Each Panel will also include the estimate on crimes_number as a comparison
	//  IV's can taken from above and do not need to be calculated again

	*******************
	// a) Property Crimes
	*******************
		// Robbery
		qui: xtpoisson Offense_Robbery PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC2a_P_Rob
					
		qui: xtpoisson Offense_Robbery trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC2a_T_Rob
		
		// Larcency
		qui: xtpoisson Offense_Larcency PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC2a_P_Lar
					
		qui: xtpoisson Offense_Larcency trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC2a_T_Lar
		
		// Burglary
		qui: xtpoisson Offense_Burglary PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC2a_P_Bur
					
		qui: xtpoisson Offense_Burglary trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC2a_T_Bur
		
		// MVT
		qui: xtpoisson Offense_MVT PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC2a_P_MVT
					
		qui: xtpoisson Offense_MVT trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC2a_T_MVT
		
		// Table OC2a
		// Population at Home
		esttab OC1b_P_PIVM_Prop OC2a_P_Rob OC2a_P_Lar OC2a_P_Bur OC2a_P_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2aHome.tex", keep(PopulationAtHome Pop_fe_M) title("Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "Population Home") mtitles("Property Crimes" "Robbery" "Larcency" "Burglary" "MVT")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC1b_T_PIVM_Prop OC2a_T_Rob OC2a_T_Lar OC2a_T_Bur OC2a_T_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2aTrip.tex", keep(trips_pP trips_fe_M) title("Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Property Crimes" "Robbery" "Larcency" "Burglary" "MVT") replace scalars("N_g Cluster")
		
		// ALL Property Crimes
		esttab OC1b_P_PIVM_Prop OC1b_T_PIVM_Prop OC2a_P_Rob OC2a_T_Rob OC2a_P_Lar OC2a_T_Lar OC2a_P_Bur OC2a_T_Bur OC2a_P_MVT OC2a_T_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2aProp.tex", keep(PopulationAtHome Pop_fe_M trips_pP trips_fe_M) title("Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "Population Home" trips_pP "Trips p.P.")   replace scalars("N_g Cluster")
		
		
	*******************
	// b) Violent Crimes
	*******************
		// AA
		qui: xtpoisson Offense_AA PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC2b_P_AA
					
		qui: xtpoisson Offense_AA trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC2b_T_AA
		
		// Murder
		qui: xtpoisson Offense_Murder PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC2b_P_Mur
					
		qui: xtpoisson Offense_Murder trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC2b_T_Mur
		
		// Rape
		qui: xtpoisson Offense_Rape PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC2b_P_Rape
					
		qui: xtpoisson Offense_Rape trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC2b_T_Rape
		
		
		// Table OC2b
		// Population at Home
		esttab OC1c_P_PIVM_Vio OC2b_P_AA OC2b_P_Mur OC2b_P_Rape using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2bHome.tex", keep(PopulationAtHome Pop_fe_M) title("Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "Population Home") mtitles("Violent Crimes" "AA" "Murder" "Rape")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab OC1c_T_PIVM_Vio OC2b_T_AA OC2b_T_Mur OC2b_T_Rape using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2bTrip.tex", keep(trips_pP trips_fe_M) title("Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Violent Crimes" "AA" "Murder" "Rape") replace scalars("N_g Cluster")
	
		
**********************************************
// iv. Daytime Heterogeneity	- Table OC3	//
**********************************************
	// Note:
	// This will depict the heterogeneity between day and nighttime
	// Therefore for each offense two Poisson-IV-FE regressions are run (one for each opportunity variable)
	// The Table will be split into two Panels, one for each type of crime (Property & Violent)
	// The table will most likely become two tables (one for each opportunity variable)
	// Each Panel will also include the estimate on crimes_number as a comparison
	//  IV's can taken from above and do not need to be calculated again
	
	*******************
	// a) Aggregate Crimes
	*******************
		// Total Crimes
		qui: xtpoisson crimes_daytime PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3a_P_Tot
		
		qui: xtpoisson crimes_daytime trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3a_T_Tot	
		  
		// Property Crimes
		qui: xtpoisson daytime_crime_Property PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3a_P_Prop
					
		qui: xtpoisson daytime_crime_Property trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3a_T_Prop	
		
		//  Violent Crimes
		qui: xtpoisson daytime_crime_Violent PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3a_P_Vio
					
		qui: xtpoisson daytime_crime_Violent trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3a_T_VIo
		
		// Table OC2a
		// Population at Home
		esttab  OC1a_P_PIVM_Tot OC3a_P_Tot  OC1b_P_PIVM_Prop OC3a_P_Prop  OC1c_P_PIVM_Vio OC3a_P_Vio using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3aHome.tex", keep(PopulationAtHome Pop_fe_M) title("Daytime Opportunity Home for AggregateCrimes") coeflabels(PopulationAtHome "Population Home") mtitles("Total" "Total Daytime" "Property" "Property Daytime" "Violent" "Violent Daytime")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC1a_T_PIVM_Tot OC3a_T_Tot  OC1b_T_PIVM_Prop OC3a_T_Prop  OC1c_T_PIVM_Vio OC3a_T_VIo using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3aTrip.tex", keep(trips_pP trips_fe_M) title("Daytime Opportunity Trips for Aggregate Crimes") coeflabels(trips_pP "Trips p.P.") mtitles("Total" "Total Daytime" "Property" "Property Daytime" "Violent" "Violent Daytime" ) replace scalars("N_g Cluster")
	

	*******************
	// b) Property Crimes
	*******************
		// Robbery
		qui: xtpoisson daytime_crime_Robbery PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_Rob
					
		qui: xtpoisson daytime_crime_Robbery trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_Rob
		
		// Larcency
		qui: xtpoisson daytime_crime_Larcency PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_Lar
					
		qui: xtpoisson daytime_crime_Larcency trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_Lar
		
		// Burglary
		qui: xtpoisson daytime_crime_Burglary PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_Bur
					
		qui: xtpoisson daytime_crime_Burglary trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_Bur
		
		// MVT
		qui: xtpoisson daytime_crime_MVT PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_MVT
					
		qui: xtpoisson daytime_crime_MVT trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_MVT
	
		// Table OC3b
		// Population at Home
		esttab   OC3a_P_Prop OC3b_P_Rob  OC3b_P_Lar  OC3b_P_Bur  OC3b_P_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3bHome.tex", keep(PopulationAtHome Pop_fe_M) title("Daytime Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "Population Home") mtitles("Property" "Robbery"  "Larceny"  "Burglary"  "MVT" )   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC3a_T_Prop OC3b_T_Rob  OC3b_T_Lar  OC3b_T_Bur  OC3b_T_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3bTrip.tex", keep(trips_pP trips_fe_M) title("Daytime Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Property" "Robbery"  "Larceny"  "Burglary"  "MVT") replace scalars("N_g Cluster")
	
      		   
	*******************
	// c) Violent Crimes
	*******************
		// AA
		qui: xtpoisson daytime_crime_AA PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3c_P_AA
					
		qui: xtpoisson daytime_crime_AA trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3c_T_AA
		
		// Murder
		qui: xtpoisson daytime_crime_Murder PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3c_P_Mur
					
		qui: xtpoisson daytime_crime_Murder trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3c_T_Mur
		
		// Rape
		qui: xtpoisson daytime_crime_Rape PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3c_P_Rape
					
		qui: xtpoisson daytime_crime_Rape trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3c_T_Rape
		
		// Table OC3c
		// Population at Home
		esttab OC3a_P_Vio OC3c_P_AA OC3c_P_Mur OC3c_P_Rape using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3cHome.tex", keep(PopulationAtHome Pop_fe_M) title("Daytime Opportunity Home for Violent Offenses") coeflabels(PopulationAtHome "Population Home") mtitles("Violent" "Violent Daytime" "AA" "Murder" "Rape")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab OC3a_T_VIo OC3c_T_Rape OC3c_T_Mur OC3c_T_AA using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3cTrip.tex", keep(trips_pP trips_fe_M) title("Daytime Opportunity Trips on Violent Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Violent" "Violent Daytime" "AA" "Murder" "Rape") replace scalars("N_g Cluster")
	 

**********************************************
// v. Residential Heterogeneity	- Table OC4	//
**********************************************
	// Note:
	// This will depict the heterogeneity between residential and non-residental areas
	// Therefore for each offense two Poisson-IV-FE regressions are run (one for each opportunity variable)
	// The Table will be split into two Panels, one for each type of crime (Property & Violent)
	// The table will most likely become two tables (one for each opportunity variable)
	// Each Panel will also include the estimate on crimes_number as a comparison
	//  IV's can taken from above and do not need to be calculated again
	
	*******************
	// a) Aggregate Crimes
	*******************
		// Total Crimes
		qui: xtpoisson location_residence PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4a_P_Tot
		
		qui: xtpoisson location_residence trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4a_T_Tot	
		  
		// Property Crimes
		qui: xtpoisson residential_Property PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4a_P_Prop
					
		qui: xtpoisson residential_Property trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4a_T_Prop
		
		//  Violent Crimes
		qui: xtpoisson residential_Violent PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4a_P_Vio
					
		qui: xtpoisson residential_Violent trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4a_T_Vio
	
	  	// Table OC4a
		// Population at Home
		esttab  OC1a_P_PIVM_Tot OC4a_P_Tot  OC1b_P_PIVM_Prop OC4a_P_Prop  OC1c_P_PIVM_Vio OC4a_P_Vio using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4aHome.tex", keep(PopulationAtHome Pop_fe_M) title("Residential Opportunity Home for AggregateCrimes") coeflabels(PopulationAtHome "Population Home") mtitles("Total Residential" "Total" "Property Residential" "Property" "Violent Residential" "Violent")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC1a_T_PIVM_Tot OC4a_T_Tot  OC1b_T_PIVM_Prop OC4a_T_Prop  OC1c_T_PIVM_Vio OC4a_T_Vio using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4aTrip.tex", keep(trips_pP trips_fe_M) title("Residential Opportunity Trips for Aggregate Crimes") coeflabels(trips_pP "Trips p.P.") mtitles("Total Residential" "Total" "Property Residential" "Property" "Violent Residential" "Violent") replace scalars("N_g Cluster")
	
	
	*******************
	// b) Property Crimes
	*******************
		// Robbery
		qui: xtpoisson residential_Robbery PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_Rob
					
		qui: xtpoisson residential_Robbery trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_Rob
		
		// Larcency
		qui: xtpoisson residential_Larcency PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_Lar
					
		qui: xtpoisson residential_Larcency trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_Lar
		
		// Burglary
		qui: xtpoisson residential_Burglary PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_Bur
					
		qui: xtpoisson residential_Burglary trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_Bur
		
		// MVT
		qui: xtpoisson residential_MVT PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_MVT
					
		qui: xtpoisson residential_MVT trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_MVT
	
  		// Table OC4b
		// Population at Home
		esttab  OC4a_P_Prop OC4b_P_Rob OC4b_P_Lar OC4b_P_Bur OC4b_P_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4bHome.tex", keep(PopulationAtHome Pop_fe_M) title("Daytime Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "Population Home") mtitles("Property Daytime" "Robbery" "Larcency" "Burglary" "MVT")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC4a_T_Prop OC4b_T_Rob OC4b_T_Lar OC4b_T_Bur OC4b_T_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4bTrip.tex", keep(trips_pP trips_fe_M) title("Daytime Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles( "Property Daytime" "Robbery" "Larcency" "Burglary" "MVT") replace scalars("N_g Cluster")
	
	*******************
	// c) Violent Crimes
	*******************
		// AA
		qui: xtpoisson residential_AA PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4c_P_AA
					
		qui: xtpoisson residential_AA trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4c_T_AA
		
		// Murder
		qui: xtpoisson residential_Murder PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4c_P_Mur
					
		qui: xtpoisson residential_Murder trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4c_T_Mur
		
		// Rape
		qui: xtpoisson residential_Rape PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4c_P_Rape
					
		qui: xtpoisson residential_Rape trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4c_T_Rape
		
		// Table OC4c
		// Population at Home
		esttab  OC4a_P_Vio OC4c_P_AA OC4c_P_Mur OC4c_P_Rape using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4cHome.tex", keep(PopulationAtHome Pop_fe_M) title("Residential Opportunity Home for Violent Offenses") coeflabels(PopulationAtHome "Population Home") mtitles( "Violent Residential" "AA" "Murder" "Rape")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC4a_T_Vio OC4c_T_Rape OC4c_T_Mur OC4c_T_AA using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4cTrip.tex", keep(trips_pP trips_fe_M) title("Residential Opportunity Trips on Violent Offenses") coeflabels(trips_pP "Trips p.P.") mtitles( "Violent Residential" "AA" "Murder" "Rape") replace scalars("N_g Cluster")











