************************
// ACS Load_Clean Data
************************
/*
    Created on 20.3.2021
    @author: Florian Fickler
    Goal:
        1. Clean ACS data - County & MSA level
		2. Extract data from each of the 4 datasets and then merge them together into one large ACS dataset
	Note:
	The following data is included in the final dataset but not used in any estimations! It is kept for further research and to complement the data for non-fixed effects analysis.
*/

**************************************
**Loop For both County and MSA data **
**************************************

foreach area_class in "MSA" "County" {
    // set cd
	cd "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey/`area_class'_Data"

    
	**********************
	** Demographic Data **
	**********************
	foreach wave in 1 5 {
		drop _all
		
		***************
		// Loading //
		**************
		//import delimited "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey\County_Data\AC_County_1yr\ACS_County_1_Demo_new.csv", rowrange(3)
		import delimited "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey/`area_class'_Data\ACS_`area_class'_`wave'yr\ACS_`area_class'_`wave'_Demo_new.csv", rowrange(3)

		// keep relevant Variables
		keep geo_id name dp05_0001e dp05_0002pe dp05_0009pe dp05_0010pe dp05_0011pe dp05_0012pe dp05_0013pe dp05_0014pe dp05_0018e dp05_0020pe dp05_0021pe dp05_0024pe dp05_0037pe dp05_0038pe dp05_0039pe dp05_0044pe dp05_0057pe dp05_0071pe

		// rename to meaningfull names
		rename (geo_id name dp05_0001e dp05_0002pe dp05_0009pe dp05_0010pe dp05_0011pe dp05_0012pe dp05_0013pe dp05_0014pe  dp05_0018e dp05_0020pe dp05_0021pe dp05_0024pe dp05_0037pe dp05_0038pe dp05_0039pe dp05_0044pe dp05_0057pe dp05_0071pe) (id	geographicareaname	PopulationTotal	PopulationMale	Population20to24	Population25to34	Population35to44	Population45to54 Population55to59	Population60to64	PopulationAgeMedian	Population16over	Population18over	Population65over	Race_White	Race_Black	Race_Native	Race_Asian	Race_Other	Race_Latino)
		
		***************
		// Cleaning //
		**************
		// destring variables with str-coded-missings, denoted by "N"
		foreach var of varlist Race_White	Race_Black	Race_Native	Race_Asian	Race_Other	Race_Latino {
			
			destring `var', force replace
		}
	
	// save dataset
	save ACS_`area_class'_`wave'_Demo.dta, replace
}


	*****************
	** Social Data **
	*****************
	foreach wave in 1 5 {
		drop _all
		
		***************
		// Loading //
		**************
		import delimited "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey/`area_class'_Data\ACS_`area_class'_`wave'yr\ACS_`area_class'_`wave'_Social_new.csv", rowrange(3)

		// keep relevant Variables
		keep geo_id name dp02_0002pe dp02_0004pe dp02_0008pe dp02_0012pe dp02_0014pe dp02_0015pe dp02_0016e dp02_0053e dp02_0060pe dp02_0061pe dp02_0062pe dp02_0065pe dp02_0152pe dp02_0153pe

		// rename to meaningfull names
		rename (geo_id name dp02_0002pe dp02_0004pe dp02_0008pe dp02_0012pe dp02_0014pe dp02_0015pe dp02_0016e dp02_0053e dp02_0060pe dp02_0061pe dp02_0062pe dp02_0065pe dp02_0152pe dp02_0153pe) (id geographicareaname  hhmariedcouplefamily hhcohabitingcouple hhmalealone hhfemalealone hhwithkids hhwith65 HH_Size_Mean Educ_Enrolment  educattainmentlessthan9thgrade educattainment9thto12thnodiploma Educ_Highschool Educ_Bachelor   hhcomputer hhbroadbandinternet)

		//rename some variables for consisntency
		rename hh* HH_*
			
		***************
		// Cleaning //
		**************	
		// gen single HH
		gen HH_Single = HH_malealone + HH_femalealone
		label var HH_Single "HH Male & Female living alone"
		drop HH_malealone HH_femalealone

		// Aggregate less than HS
		gen Educ_NoHighschool = educattainmentlessthan9thgrade + educattainment9thto12thnodiploma
		label var Educ_NoHighschool "Educ-Attainment-LessthanHS(dropouts)"
		drop educattainmentlessthan9thgrade educattainment9thto12thnodiploma

		// Aggregate Married and Cohabiting
		gen HH_Married_Cohabiting = HH_mariedcouplefamily + HH_cohabitingcouple
		label var HH_Married_Cohabiting "HH-Married-and-Cohabiting"
		drop HH_cohabitingcouple HH_mariedcouplefamily
		
		// save dataset
		save ACS_`area_class'_`wave'_Social.dta, replace
	}


	*******************
	** Economic Data **
	*******************
	foreach wave in 1 5 {
		drop _all
		
		***************
		// Loading //
		**************
		import delimited "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey/`area_class'_Data\ACS_`area_class'_`wave'yr\ACS_`area_class'_`wave'_Econ_new.csv", rowrange(3)
		// keep relevant Variables
		keep geo_id name dp03_0001e dp03_0002pe dp03_0006pe dp03_0009pe dp03_0019pe dp03_0020pe dp03_0021pe dp03_0022pe dp03_0023pe dp03_0024pe dp03_0025e dp03_0027pe dp03_0028pe dp03_0029pe dp03_0030pe dp03_0031pe dp03_0033pe dp03_0034pe dp03_0035pe dp03_0036pe dp03_0037pe dp03_0038pe dp03_0039pe dp03_0040pe dp03_0041pe dp03_0042pe dp03_0043pe dp03_0044pe dp03_0045pe dp03_0047pe dp03_0048pe dp03_0049pe dp03_0052pe dp03_0053pe dp03_0054pe dp03_0055pe dp03_0056pe dp03_0057pe dp03_0058pe dp03_0059pe dp03_0060pe dp03_0061pe dp03_0062e dp03_0063e dp03_0064pe dp03_0066pe dp03_0068pe  dp03_0070pe dp03_0072pe dp03_0074pe dp03_0096pe dp03_0098pe dp03_0128pe dp03_0129pe

		// rename to meaningfull names
		rename (geo_id name dp03_0001e dp03_0002pe dp03_0006pe dp03_0009pe dp03_0019pe dp03_0020pe dp03_0021pe dp03_0022pe dp03_0023pe dp03_0024pe dp03_0025e dp03_0027pe dp03_0028pe dp03_0029pe dp03_0030pe dp03_0031pe dp03_0033pe dp03_0034pe dp03_0035pe dp03_0036pe dp03_0037pe dp03_0038pe dp03_0039pe dp03_0040pe dp03_0041pe dp03_0042pe dp03_0043pe dp03_0044pe dp03_0045pe dp03_0047pe dp03_0048pe dp03_0049pe dp03_0052pe dp03_0053pe dp03_0054pe dp03_0055pe dp03_0056pe dp03_0057pe dp03_0058pe dp03_0059pe dp03_0060pe dp03_0061pe dp03_0062e dp03_0063e dp03_0064pe dp03_0066pe dp03_0068pe  dp03_0070pe dp03_0072pe dp03_0074pe dp03_0096pe dp03_0098pe dp03_0128pe dp03_0129pe) (id geographicareaname WAPopulation LFPR  armedforces UER     commute_alone commute_carpool commute_publictransportation commute_walked commute_other commute_workingfromhome commute_traveltime_mean occupation_management occupation_service occupation_salesoffice occupation_BuildingRessources occupation_ProductionTransport industry_agriculture industry_construction industry_manufacturing industry_wholesaletrade industry_retailtrade industry_transportation industry_information industry_financialservices industry_Management industry_SocialServices industry_ArtHotelEntertainment industry_other industry_publicservices Worker_Wage Worker_Gov Worker_Self_Emp HH_below10000 HH_10000to14999 HH_15000to24999 HH_25000to34999 HH_35000to49999 HH_50000to74999 HH_75000to99999 HH_100000to149999 HH_150000to199999 HH_200000above HH__Median_Income HH__Mean_Income HH_with_earning HH_with_socialsecurity HH_with_pension HH_suppl_security_inc HH_cashassistance Poverty_FoodstrampSNAP Health_Insured Health_Public Poverty_Line_all Poverty_Line_kids)

		***************
		// Cleaning //
		**************
		// destring variables with str-coded-missings missings, denoted by "N"
		foreach var of varlist industry* occupation* commute* Poverty_Line_kids{
			
			destring `var', force replace
		}
		
		// save dataset
		save ACS_`area_class'_`wave'_Econ.dta, replace
	}
	******************
	** Housing Data **
	******************
	foreach wave in 1 5 {
		drop _all
		
		***************
		// Loading //
		**************
		import delimited "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey/`area_class'_Data\ACS_`area_class'_`wave'yr\ACS_`area_class'_`wave'_Housing_new.csv", rowrange(3)
		
		// keep relevant Variables
		keep geo_id name dp04_0001e dp04_0003pe dp04_0007pe dp04_0008pe dp04_0009pe dp04_0010pe dp04_0011pe dp04_0012pe dp04_0013pe dp04_0014pe dp04_0015pe dp04_0017pe dp04_0018pe dp04_0019pe dp04_0020pe dp04_0021pe dp04_0022pe dp04_0023pe dp04_0024pe dp04_0025pe dp04_0026pe dp04_0037e dp04_0046pe dp04_0048e dp04_0049e dp04_0058pe dp04_0059pe dp04_0060pe dp04_0061pe dp04_0089e dp04_0134e

		// rename to meaningfull names
		rename (geo_id name dp04_0001e dp04_0003pe dp04_0007pe dp04_0008pe dp04_0009pe dp04_0010pe dp04_0011pe dp04_0012pe dp04_0013pe dp04_0014pe dp04_0015pe dp04_0017pe dp04_0018pe dp04_0019pe dp04_0020pe dp04_0021pe dp04_0022pe dp04_0023pe dp04_0024pe dp04_0025pe dp04_0026pe dp04_0037e dp04_0046pe dp04_0048e dp04_0049e dp04_0058pe dp04_0059pe dp04_0060pe dp04_0061pe dp04_0089e dp04_0134e )	(id	geographicareaname	Housing_Units_Total	Housing_VacancyRate Neighbor_None	units1unitattached	units2units	Neighbor_2to3	units5to9units	units10to19units	Neighbor_19plus	unitsmobilehomes	unitsothervanrvboat	built2014orlater	built2010to2013	built2000to2009	built1990to1999	built1980to1989	built1970to1979	built1960to1969	built1950to1959	built1940to1949	built1939orearlier	Rooms_Median	OwnerOccupied_Share	AverageHHSizeOwnerOccupied	AverageHHSizeRenterOccupied	vehicle_None	vehicle_One	vehicle_Two	vehicle_ThreeorMore	House_MedianValue_OwnerOccupied	Rent_Gross_Median)
		
		***************
		// Cleaning //
		**************
		foreach var of varlist unit* Neighbor* AverageHHSizeRenterOccupied House_MedianValue_OwnerOccupied AverageHHSizeOwnerOccupied Rent_Gross_Median{
			
			destring `var', force replace
		}  
		
		// Aggreagte some of the building years
		// New buildings
		gen Buldings_New = (built2014orlater + built2010to2013 + built2000to2009)
		label var Buldings_New "Housing-Built-2000orlater"
		drop built2000to2009 built2010to2013 built2014orlater
		// Aged-Buildings
		gen Buldings_Aged = (built1990to1999 + built1980to1989 + built1970to1979)
		label var Buldings_Aged "Housing-Built-1970to1999"
		drop built1970to1979 built1980to1989 built1990to1999
		// Old-Buildings
		gen Buldings_Old = (built1960to1969 + built1950to1959 + built1940to1949 + built1939orearlier)
		label var Buldings_Old "Housing-Built-1969orEarlier"
		drop built1939orearlier built1940to1949 built1950to1959 built1960to1969
		
		// One Neighbor
		gen Neighbor_1 = (units1unitattached + units2units)
		label var Neighbor_1 "Housing-Unit-1attached-and-2units"
		// Two-3 Neighbors
		label var Neighbor_2to3 "Housing-Unit-3to4"
		// 4-18 Neighbors
		gen Neighbor_4to18 = (units5to9units + units10to19units)
		label var Neighbor_4to18 "Housing-Unit-5to9-and-10to19units"
		// could also add the 20+ here and make this the "many Neighbors group"
		//drop redundant vars
		drop units10to19units units2units units5to9units units1unitattached
		
		// Aggregate Non Traditional Housing
		gen Neighbor_other = (unitsmobilehomes + unitsothervanrvboat)
		label var Neighbor_other "Housing-Unit-Mobilehomes-RV-Van-Boat"
		drop unitsmobilehomes unitsothervanrvboat	
		
		// Recode House_MedianValue_OwnerOccupied to in 1000$'s
		replace House_MedianValue_OwnerOccupied = House_MedianValue_OwnerOccupied / 1000
		label var House_MedianValue_OwnerOccupied "Housing-Value-OwnerOccupied-Median-in-1000Dollar"
		
		// generate an average HH-size for all Units
		gen HH_Size_Mean = (OwnerOccupied_Share * AverageHHSizeOwnerOccupied + (100-OwnerOccupied_Share) * AverageHHSizeRenterOccupied)/100
		label var HH_Size_Mean "Housing-Average-HH-Size"
		drop AverageHHSizeOwnerOccupied AverageHHSizeRenterOccupied

		// save dataset
		save ACS_`area_class'_`wave'_Housing.dta, replace
	}

// End of MSA/County Loop
}



*********************
// Merging by Wave //
*********************
// Seperately For each Area_Class due to specific cleaning etc

*********
// MSA //
*********
// set cd
cd "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey/MSA_Data"

// Loop through Waves
foreach wave in 1 5 {
	drop _all
	
	// Load in first file
	use ACS_MSA_`wave'_Demo.dta
	
	// Loop through remaining files and merge them with each other
	foreach file in Econ Housing Social{
		merge 1:1 id using ACS_MSA_`wave'_`file'.dta, nogen assert(3)
		// assert command confirms, that there are only matches otherways breaks loop
	}
	
	// drop oklahoma entry (not an msa)
	drop if id == "0400000US40"
	
	// drop id variable
	drop id
	
	// Split geographic name into parts
	// First Split Name and State-Area Combi
	split geographicareaname, parse(",")
	rename geographicareaname1 Area_Name
	
	// replace with upper case letters to match with FBI data
	replace Area_Name = strupper(Area_Name)
	
	// Second, Split State from Micro/Macro Indicator
	split geographicareaname2
	rename geographicareaname21 state
	// Produces 3 Variables, States, Micro/Macro Indicator, and a variable containing the word Area

	// Dummy for Metro/Micro Area
	gen MSA_Metro = 1 if geographicareaname22 =="Metro"
	replace MSA_Metro = 0 if geographicareaname22 == "Micro"
	
	// Drop unused splits 	
	drop geographicareaname22 geographicareaname23 geographicareaname2
	
	// Find Cross-Border MSA's that should stay in the Dataset
	gen state_sample =  0
	
	// Define local with postal-codes with crime-data	
	local postal "AR MA OK OH WA CT CO SD MT ND RI NC ID OR KS MI VT NH WV IA KY SC TN VA"	
	
	// Loop through states names and increase state_sample by one if a state with data is detected
	foreach plz in `postal' {
		replace state_sample = state_sample + 1 if strpos(state, "`plz'" ) != 0
	}
	
	// Loop through the states names and count the number of states included (+1 for the first state)
	gen number_states_msa = length(state) - length(subinstr(state, "-", "", .)) + 1
	
	// gen dummy for missing crime-dataset
	gen lacking_states = number_states_msa- state_sample  if state_sample != 0
	
	drop number_states_msa state_sample
	
	drop if lacking_states == .

	// Order Data and Creating empty Indicator Vars
	foreach var in POPULATION RACE WORK_POPULATION COMMUTING BUILDINGS INDUSTRY WORKER_CLASS HH_INCOME HEALTH HOUSING NEIGHBORS VEHICLES OCCUPATION  HH_CHARACTERISTICS EDUCATION {
		gen `var' = .
	}
	
	order geographicareaname Area_Name state MSA_Metro lacking_states POPULATION PopulationTotal PopulationMale Population16over Population18over Population20to24 Population25to34 Population35to44 Population45to54 Population55to59 Population60to64 Population65over PopulationAgeMedian RACE Race_White Race_Black	Race_Native	Race_Asian Race_Other Race_Latino WORK_POPULATION WAPopulation LFPR armedforces UER WORKER_CLASS Worker_Wage Worker_Gov Worker_Self_Emp EDUCATION Educ_Enrolment Educ_NoHighschool Educ_Highschool Educ_Bachelor HH_INCOME HH_below10000 HH_10000to14999 HH_15000to24999 HH_25000to34999 HH_35000to49999 HH_50000to74999 HH_75000to99999 HH_100000to149999 HH_150000to199999 HH_200000above HH__Median_Income HH__Mean_Income HH_with_earning HH_with_socialsecurity HH_with_pension HH_suppl_security_inc HH_cashassistance Poverty_FoodstrampSNAP Poverty_Line_all Poverty_Line_kids HEALTH Health_Insured Health_Public HH_CHARACTERISTICS HH_Size_Mean HH_Single HH_Married_Cohabiting HH_withkids HH_with65 HH_computer HH_broadbandinternet COMMUTING commute_alone commute_carpool commute_publictransportation commute_walked commute_other commute_workingfromhome commute_traveltime_mean VEHICLES vehicle_None vehicle_One vehicle_Two vehicle_ThreeorMore HOUSING Housing_Units_Total Housing_VacancyRate OwnerOccupied_Share Rooms_Median House_MedianValue_OwnerOccupied Rent_Gross_Median NEIGHBORS Neighbor_None Neighbor_1 Neighbor_2to3 Neighbor_4to18 Neighbor_19plus Neighbor_other BUILDINGS Buldings_New Buldings_Aged Buldings_Old OCCUPATION occupation_management occupation_service occupation_salesoffice occupation_BuildingRessources occupation_ProductionTransport INDUSTRY industry_agriculture industry_construction industry_manufacturing industry_wholesaletrade industry_retailtrade industry_transportation industry_information industry_financialservices industry_Management industry_SocialServices industry_ArtHotelEntertainment industry_other industry_publicservices 

	// save combined file
	save C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\ACS_MSA_`wave', replace
}



************
// County //
************
// set cd
cd "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey/County_Data"

// Loop through waves of ACS
foreach wave in 1 5 {
	drop _all
	
	// Load in first file	
	use ACS_County_`wave'_Demo.dta
	
	// Loop through remaining files and merge them with each other
	foreach file in Econ Housing Social{
		merge 1:1 id using ACS_County_`wave'_`file'.dta, nogen assert(3)
		// assert command confirms, that there are only matches otherways breaks loop
	}
		
	// drop id variable
	drop id
	
	// Split geographic name into parts
	// First Split Name and State-Area Combi
	split geographicareaname, parse(",")
	rename geographicareaname1 Area_Name
	rename geographicareaname2 state
	
	// Reduce the Area_Name to the Counties actual name without the "County/City" string
	replace Area_Name = subinstr(Area_Name, "County", "", .)
	// replace with upper case letters to match with FBI data
	replace Area_Name = strupper(Area_Name)
	
	// trim leading spaces
	replace state = strtrim(state)
	
	// run File to exchange Statenames with their postal codes
	run "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\CodeList_StatesAbbrev.do"
	
	// Reduce sample to states with crime data
	gen state_sample =  0
	
	// Define local with postal-codes with crime-data	
	local postal "AR MA OK OH WA CT CO SD MT ND RI NC ID OR KS MI VT NH WV IA KY SC TN VA"	
	
	// Loop through states names and increase state_sample by one if a state with data is detected
	foreach plz in `postal' {
		replace state_sample = state_sample + 1 if strpos(state, "`plz'" ) != 0
	}
	
	// drop if not in sample
	drop if state_sample == 0
	drop state_sample	
	
	// Order Data and Creating empty Indicator Vars
	foreach var in POPULATION RACE WORK_POPULATION COMMUTING BUILDINGS INDUSTRY WORKER_CLASS HH_INCOME HEALTH HOUSING NEIGHBORS VEHICLES OCCUPATION  HH_CHARACTERISTICS EDUCATION {
		gen `var' = .
	}
	
	order geographicareaname Area_Name state POPULATION PopulationTotal PopulationMale Population16over Population18over Population20to24 Population25to34 Population35to44 Population45to54 Population55to59 Population60to64 Population65over PopulationAgeMedian RACE Race_White Race_Black	Race_Native	Race_Asian Race_Other Race_Latino WORK_POPULATION WAPopulation LFPR armedforces UER WORKER_CLASS Worker_Wage Worker_Gov Worker_Self_Emp EDUCATION Educ_Enrolment Educ_NoHighschool Educ_Highschool Educ_Bachelor HH_INCOME HH_below10000 HH_10000to14999 HH_15000to24999 HH_25000to34999 HH_35000to49999 HH_50000to74999 HH_75000to99999 HH_100000to149999 HH_150000to199999 HH_200000above HH__Median_Income HH__Mean_Income HH_with_earning HH_with_socialsecurity HH_with_pension HH_suppl_security_inc HH_cashassistance Poverty_FoodstrampSNAP Poverty_Line_all Poverty_Line_kids HEALTH Health_Insured Health_Public HH_CHARACTERISTICS HH_Size_Mean HH_Single HH_Married_Cohabiting HH_withkids HH_with65 HH_computer HH_broadbandinternet COMMUTING commute_alone commute_carpool commute_publictransportation commute_walked commute_other commute_workingfromhome commute_traveltime_mean VEHICLES vehicle_None vehicle_One vehicle_Two vehicle_ThreeorMore HOUSING Housing_Units_Total Housing_VacancyRate OwnerOccupied_Share Rooms_Median House_MedianValue_OwnerOccupied Rent_Gross_Median NEIGHBORS Neighbor_None Neighbor_1 Neighbor_2to3 Neighbor_4to18 Neighbor_19plus Neighbor_other BUILDINGS Buldings_New Buldings_Aged Buldings_Old OCCUPATION occupation_management occupation_service occupation_salesoffice occupation_BuildingRessources occupation_ProductionTransport INDUSTRY industry_agriculture industry_construction industry_manufacturing industry_wholesaletrade industry_retailtrade industry_transportation industry_information industry_financialservices industry_Management industry_SocialServices industry_ArtHotelEntertainment industry_other industry_publicservices 
	
	
	// save combined file
	save C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\ACS_County_`wave', replace
}
