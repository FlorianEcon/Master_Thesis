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
// Drop counties without any Weather Data
gen rep = 1 if prcp != .
bys geographicareaname: egen sumrep = sum(rep)
drop rep

drop if sumrep == 0
drop sumrep

bys geographicareaname: egen zerocrimes = count(crimes_number) if crimes_number == 0 | prcp == . | trips_pP == . | PopulationAtHome == .
bys geographicareaname: egen maxzero = max(zerocrimes)
bys geographicareaname: egen obscrimes = count(crimes_number)
gen difobs = obscrimes - maxzero
drop if difobs == 0
drop zerocrimes obscrimes difobs maxzero


**********************************************
// i. Non-Crime Summaries - S1//
**********************************************
	// Adjust population at home to a variable from 0-100 instead of 0-1
	gen PopHome100 = 100 * PopulationAtHome

	// solve 4 cases of outliers in trips
	replace trips_pP = . if trips_pP > 21

	// Summary statistics for non-crime data
	estpost sum  UER_month  PopHome100 trips_pP prcp
	esttab using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/S1.tex", cells("count mean(fmt(2)) sd(fmt(2)) min(fmt(1)) max(fmt(0))")  nonumber replace 

**********************************************
// ii. Crime Summaries - S2 //
**********************************************
		// Calculate total crimes happened during the day and night
		// Total Crimes
		gen crimes_daytime = daytime_crime_AA + daytime_crime_Rape + daytime_crime_Robbery + daytime_crime_MVT + daytime_crime_Murder + daytime_crime_Larcency + daytime_crime_Burglary
		gen crime_nighttime = crimes_number - crimes_daytime
		replace crime_nighttime = 0 if crime_nighttime <0
	
		// Property Crimes
		gen daytime_crime_Property =  daytime_crime_Burglary + daytime_crime_Larcency + daytime_crime_MVT + daytime_crime_Robbery
		gen nighttime_crime_Property = Offense_FBI_Property - daytime_crime_Property
		replace nighttime_crime_Property = 0 if nighttime_crime_Property <0
		
		// Violent Crimes
		gen daytime_crime_Violent =  daytime_crime_AA + daytime_crime_Murder + daytime_crime_Rape
		gen nighttime_crime_Violent = Offense_FBI_Violent - daytime_crime_Violent
		replace nighttime_crime_Violent = 0 if nighttime_crime_Violent <0

		// And Total Crimes happend in residential areas by Group
		// Total - only needs non residential
		gen nonresi_crimes = crimes_number - location_residence
		
		// Property
		gen residential_Property = residential_Burglary + residential_Larcency + residential_MVT + residential_Robbery
		gen nonresi_property = Offense_FBI_Property - residential_Property
		replace nonresi_property = 0 if nonresi_property <0
		
		// Violent
		gen residential_Violent = residential_AA + residential_Murder + residential_Rape
		gen nonresi_Violent = Offense_FBI_Violent - residential_Violent
		replace nonresi_Violent = 0 if nonresi_Violent < 0

		
		// Offenses
		foreach var in "AA" "Murder" "Rape" "Burglary" "Larcency" "MVT" "Robbery"{
		    // Nighttime
			gen nightime_`var' = Offense_`var' - daytime_crime_`var'
			
			// Location
			gen nonresi_`var' = Offense_`var' - residential_`var'			
		}

	// Summaries of Unemployment, Precipitation, and Criminal Opportunity
	 estpost sum  crimes_number Offense_FBI_Property Offense_Larcency Offense_Burglary Offense_MVT Offense_Robbery Offense_FBI_Violent Offense_AA Offense_Rape Offense_Murder location_residence crimes_daytime
	 
	esttab using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/S2.tex", cells("count mean(fmt(2)) sd(fmt(2)) min(fmt(1)) max(fmt(0))")  nonumber replace 


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
// i. Run First Stage Regressions - Table - FS //
**********************************************
	// Note: This Proceder is taken from Lin & Wooldridge (2019) - Residuals from this first stage are included in the latter regressions to test for the exogeneity of our variable.

	// Without month controls
	xtreg PopulationAtHome prcp, fe cluster(Area_ID)
	eststo FS_Pop
	predict double Pop_fe, e
	
	xtreg trips_pP prcp, fe cluster(Area_ID)
	eststo FS_Trip
	predict double trips_fe, e
	
	// With month controls
	xtreg PopulationAtHome prcp i.month, fe cluster(Area_ID)
	eststo FS_Pop_M
	predict double Pop_fe_M, e	
	
	xtreg trips_pP prcp i.month, fe cluster(Area_ID)
	eststo FS_Trip_M
	predict double trips_fe_M, e
	
	// First Stage Table
	esttab FS* using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/FS.tex", keep(prcp) title("First Stage Regressions") coeflabels(prcp "Precipitation") replace scalars("N_g Cluster")
		

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
		// POISSON
		// IV & Month
		qui: xtpoisson Offense_FBI_Property PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC1b_P_PIVM_Prop
				
		qui: xtpoisson Offense_FBI_Property trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC1b_T_PIVM_Prop
		
				
	*******************
	// c) Violent Crimes
	*******************	
		// POISSON		
		// IV & Month
		qui: xtpoisson Offense_FBI_Violent PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC1c_P_PIVM_Vio
				
		qui: xtpoisson Offense_FBI_Violent trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC1c_T_PIVM_Vio
				
  
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
		esttab OC1b_P_PIVM_Prop OC2a_P_Rob OC2a_P_Lar OC2a_P_Bur OC2a_P_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2aHome.tex", keep(PopulationAtHome) title("Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "\% Pop at Home") mtitles("Property Crimes" "Robbery" "Larcency" "Burglary" "MVT")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC1b_T_PIVM_Prop OC2a_T_Rob OC2a_T_Lar OC2a_T_Bur OC2a_T_MVT using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2aTrip.tex", keep(trips_pP) title("Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Property Crimes" "Robbery" "Larcency" "Burglary" "MVT") replace scalars("N_g Cluster")
		
		
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
		esttab OC1c_P_PIVM_Vio OC2b_P_AA OC2b_P_Mur OC2b_P_Rape using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2bHome.tex", keep(PopulationAtHome) title("Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "\% Pop at Home") mtitles("Violent Crimes" "AA" "Murder" "Rape")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab OC1c_T_PIVM_Vio OC2b_T_AA OC2b_T_Mur OC2b_T_Rape using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC2bTrip.tex", keep(trips_pP) title("Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Violent Crimes" "AA" "Murder" "Rape") replace scalars("N_g Cluster")
	
		
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
	// Daytime
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
		
	// Nighttime	
		// Total Crimes
		qui: xtpoisson crime_nighttime PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3a_P_TotN
		
		qui: xtpoisson crime_nighttime trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3a_T_TotN	
		  
		// Property Crimes
		qui: xtpoisson nighttime_crime_Property PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3a_P_PropN
					
		qui: xtpoisson nighttime_crime_Property trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3a_T_PropN	
		
		//  Violent Crimes
		qui: xtpoisson nighttime_crime_Violent PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3a_P_VioN
					
		qui: xtpoisson nighttime_crime_Violent trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3a_T_VIoN
		
		
		// Table OC3a
		// Population at Home
		esttab  OC3a_P_Prop OC3a_P_PropN  OC3a_P_Vio OC3a_P_VioN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3aHomeN.tex", keep(PopulationAtHome) title("Daytime Opportunity Home for AggregateCrimes") coeflabels(PopulationAtHome "\% Pop at Home") mtitles("Prop Day" "Prop Night" "Violent Day" "Violent Night")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab   OC3a_T_Prop OC3a_T_PropN  OC3a_T_VIo OC3a_T_VIoN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3aTripN.tex", keep(trips_pP) title("Daytime Opportunity Trips for Aggregate Crimes") coeflabels(trips_pP "Trips p.P.") mtitles("Prop Day" "Prop Night" "Violent Day" "Violent Night") replace scalars("N_g Cluster")
	

	*******************
	// b) Property Crimes
	*******************
	// Daytime	
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
	
	// Nighttime	
		// Robbery
		qui: xtpoisson nightime_Robbery PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_RobN
					
		qui: xtpoisson nightime_Robbery trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_RobN
		
		// Larcency
		qui: xtpoisson nightime_Larcency PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_LarN
					
		qui: xtpoisson nightime_Larcency trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_LarN
		
		// Burglary
		qui: xtpoisson nightime_Burglary PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_BurN
					
		qui: xtpoisson nightime_Burglary trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_BurN
		
		// MVT
		qui: xtpoisson nightime_MVT PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3b_P_MVTN
					
		qui: xtpoisson nightime_MVT trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3b_T_MVTN
		
	
		// Table OC3b
		// Population at Home
		esttab   OC3b_P_Rob OC3b_P_RobN  OC3b_P_Lar OC3b_P_LarN  OC3b_P_Bur OC3b_P_BurN  OC3b_P_MVT OC3b_P_MVTN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3bHomeN.tex", keep(PopulationAtHome) title("Daytime Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "\% Pop at Home") mtitles("Rob Day" "Rob Night"  "Lar Day"  "Lar Night"  "Burg Day" "Burg Night" "MVt Day" "MVT Night" )   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC3b_T_Rob OC3b_T_RobN  OC3b_T_Lar OC3b_T_LarN  OC3b_T_Bur OC3b_T_BurN  OC3b_T_MVT OC3b_T_MVTN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3bTrip.tex", keep(trips_pP) title("Daytime Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Rob Day" "Rob Night"  "Lar Day"  "Lar Night"  "Burg Day" "Burg Night" "MVt Day" "MVT Night" ) replace scalars("N_g Cluster")
	
      		   
	*******************
	// c) Violent Crimes
	*******************
	// Daytime
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
		
	// Nighttime
		// AA
		qui: xtpoisson nightime_AA PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3c_P_AAN
					
		qui: xtpoisson nightime_AA trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3c_T_AAN
		
		// Murder
		qui: xtpoisson nightime_Murder PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3c_P_MurN
					
		qui: xtpoisson nightime_Murder trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3c_T_MurN
		
		// Rape
		qui: xtpoisson nightime_Rape PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC3c_P_RapeN
					
		qui: xtpoisson nightime_Rape trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC3c_T_RapeN
		
		// Table OC3c
		// Population at Home
		esttab OC3c_P_AA OC3c_P_AAN OC3c_P_Mur OC3c_P_MurN OC3c_P_Rape OC3c_P_RapeN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3cHomeN.tex", keep(PopulationAtHome) title("Daytime Opportunity Home for Violent Offenses") coeflabels(PopulationAtHome "\% Pop at Home") mtitles("AA Day" "AA Night" "Murder Day" "Murder Night" "Rape Day" "Rape Night")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab OC3c_T_AA OC3c_T_AAN OC3c_T_Mur OC3c_T_MurN  OC3c_T_Rape OC3c_T_RapeN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC3cTripN.tex", keep(trips_pP) title("Daytime Opportunity Trips on Violent Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("AA Day" "AA Night" "Murder Day" "Murder Night" "Rape Day" "Rape Night") replace scalars("N_g Cluster")
	 

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
	// Residential
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
		
	// Non-residential
		// Total Crimes
		qui: xtpoisson nonresi_crimes PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4a_P_TotN
		
		qui: xtpoisson nonresi_crimes trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4a_T_TotN
		  
		// Property Crimes
		qui: xtpoisson nonresi_property PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4a_P_PropN
					
		qui: xtpoisson nonresi_property trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4a_T_PropN
		
		//  Violent Crimes
		qui: xtpoisson nonresi_Violent PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4a_P_VioN
					
		qui: xtpoisson nonresi_Violent trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4a_T_VioN
	
	  	// Table OC4a
		// Population at Home
		esttab  OC4a_P_Tot OC4a_P_TotN OC4a_P_Prop OC4a_P_PropN OC4a_P_Vio OC4a_P_VioN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4aHomeN.tex", keep(PopulationAtHome) title("Residential Opportunity Home for AggregateCrimes") coeflabels(PopulationAtHome "\% Pop at Home") mtitles("Residential" "Non" "Property Residential" "Non" "Violent Residential" "Non")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC4a_T_Tot OC4a_T_TotN OC4a_T_Prop OC4a_T_PropN OC4a_T_Vio OC4a_T_VioN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4aTripN.tex", keep(trips_pP) title("Residential Opportunity Trips for Aggregate Crimes") coeflabels(trips_pP "Trips p.P.") mtitles("Residential" "Non" "Property Residential" "Non" "Violent Residential" "Non") replace scalars("N_g Cluster")
	
	
	*******************
	// b) Property Crimes
	*******************
	// Residential
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
		
		
		// Non Residential
		// Robbery
		qui: xtpoisson nonresi_Robbery PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_RobN
					
		qui: xtpoisson nonresi_Robbery trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_RobN
		
		// Larcency
		qui: xtpoisson nonresi_Larcency PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_LarN
					
		qui: xtpoisson nonresi_Larcency trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_LarN
		
		// Burglary
		qui: xtpoisson nonresi_Burglary PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_BurN
					
		qui: xtpoisson nonresi_Burglary trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_BurN
		
		// MVT
		qui: xtpoisson nonresi_MVT PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4b_P_MVTN
					
		qui: xtpoisson nonresi_MVT trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4b_T_MVTN
	
  		// Table OC4b
		// Population at Home
		esttab  OC4b_P_Rob OC4b_P_RobN OC4b_P_Lar OC4b_P_LarN OC4b_P_Bur OC4b_P_BurN OC4b_P_MVT OC4b_P_MVTN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4bHome.tex", keep(PopulationAtHome) title("Residential Opportunity Home for Property Offenses") coeflabels(PopulationAtHome "\% Pop at Home") mtitles("Rob Res" "Non" "Lar Res" "Non" "Burg Res" "Non" "MVT res" "non")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC4b_T_Rob OC4b_T_RobN OC4b_T_Lar OC4b_T_LarN OC4b_T_Bur OC4b_T_BurN OC4b_T_MVT OC4b_T_MVTN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4bTrip.tex", keep(trips_pP) title("Residential Opportunity Trips on Property Offenses") coeflabels(trips_pP "Trips p.P.") mtitles("Rob Res" "Non" "Lar Res" "Non" "Burg Res" "Non" "MVT res" "non")  replace scalars("N_g Cluster")
	
	*******************
	// c) Violent Crimes
	*******************
	// residential
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
		
	// Non residential
		// AA
		qui: xtpoisson nonresi_AA PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4c_P_AAN
					
		qui: xtpoisson nonresi_AA trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4c_T_AAN
		
		// Murder
		qui: xtpoisson nonresi_Murder PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4c_P_MurN
					
		qui: xtpoisson nonresi_Murder trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4c_T_MurN
		
		// Rape
		qui: xtpoisson nonresi_Rape PopulationAtHome Pop_fe_M i.month, fe vce(robust)
		eststo OC4c_P_RapeN
					
		qui: xtpoisson nonresi_Rape trips_pP trips_fe_M i.month, fe vce(robust)
		eststo OC4c_T_RapeN
		
		// Table OC4c
		// Population at Home
		esttab  OC4c_P_AA OC4c_P_AAN OC4c_P_Mur OC4c_P_MurN OC4c_P_Rape OC4c_P_RapeN using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4cHome.tex", keep(PopulationAtHome) title("Residential Opportunity Home for Violent Offenses") coeflabels(PopulationAtHome "\% Pop at Home") mtitles( "Violent Residential" "AA" "Murder" "Rape")   replace scalars("N_g Cluster")
		
		// Trips p.P.
		esttab  OC4c_T_AA OC4c_T_AAN  OC4c_T_Mur OC4c_T_MurN OC4c_T_Rape OC4c_T_RapeN  using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset/Tables/OC4cTrip.tex", keep(trips_pP) title("Residential Opportunity Trips on Violent Offenses") coeflabels(trips_pP "Trips p.P.") mtitles( "Violent Residential" "AA" "Murder" "Rape") replace scalars("N_g Cluster")











