************************
// Merger
************************
/*
    Created on 20.3.2021
    @author: Florian Fickler
    Goal:
        1. Add some data points regarding days of the year
		2. Merge ACS and BTS to one County-Level dataset
		3. Add FBI Crime data and use distribution algorithm for multi-county Agencies
		4. Add Weather (NOOA) and Unemployment (LAUS) to the counties
		5. Save a final dataset for estimations
		6. This procedure is done for both waves of the ACS (Wave 1 obsolete)
		7. This is also done for the MSA level (currently not completely implemented)

*/

/// Merge All three Datasets to one big one
drop _all
//set cd
cd "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset"


****************************************************************************************************
// 1. County level
****************************************************************************************************
**********************************************
// i. Merging BTS & County-level Macro-Data //
**********************************************
foreach wave in 1 5 {
    // load in ACS File
	use ACS_County_`wave'
	
	// Important to keep in mind:
	// Due top the merge, all counties are part of both datasets (1;5) which with NIBRS creates the same number of matches
	// This might not be needed later, such that one might rather opt to drop all without ACS data (maybe therefore increasing the number of obs merged to the MSA)
	merge 1:m Area_Name state using BTS_Data.dta, nogen assert(2 3)
	
	// Merging with Wave 1 creates a lot of missings, due to the low sample size for the 1 year predictions
	// Merging with Wave 5 creates a perfect match
	
	********************************
	***  Holidays and Time-Dummy ***
	********************************
	// Create variables for the days and times
	**************************
	// Public Holiday Dummy //
	**************************
	// Dummy = 1 if the day is a public holiday in that state
	// Some states have exceptions that are exlluded
	// Others have additional days which are added after the federal holidays
	gen public_holiday = 0

	// Federal Holodays
	replace public_holiday = 1 if day == 1 & month == 1 // New-years Eve
	replace public_holiday = 1 if day == 21 & month == 1 // MLK-DAY
	replace public_holiday = 1 if day == 18 & month == 2 & !inlist(state, "KY", "NC", "IA", "KS", "RI")  // Presidents-Day
	replace public_holiday = 1 if day == 27 & month == 5 // Memorial Day
	replace public_holiday = 1 if day == 4 & month == 4 // Independence Day
	replace public_holiday = 1 if day == 2 & month == 9 // Labor Day
	replace public_holiday = 1 if day == 14 & month == 10 & !inlist(state, "KY", "NC", "IA", "KS", "VT", "TN") & !inlist(state, "SC", "MI", "OK", "AR", "ND", "OR", "WA")  // Columbus Day
	replace public_holiday = 1 if day == 11 & month == 11 // Veterans Day
	replace public_holiday = 1 if day == 28 & month == 11 // Thanksgiving
	replace public_holiday = 1 if day == 25 & month == 12 // Christmas Day

	// State Holidays
	replace public_holiday = 1 if day == 12 & month == 2 & state == "CO"  // Lincolns BD
	replace public_holiday = 1 if day == 5 & month == 3 & state == "VT"  // Town meeting Day
	replace public_holiday = 1 if day == 15 & month == 4 & state == "MA"  // Patriots Day
	replace public_holiday = 1 if day == 19 & month == 4 & inlist(state, "NC", "KY", "TN", "CO")  // Good Friday
	replace public_holiday = 1 if day == 10 & month == 5 & state == "SC"  // Confederate Memorial Day
	replace public_holiday = 1 if day == 20 & month == 6 & state == "WV"  // West Virginia Day
	replace public_holiday = 1 if day == 12 & month == 8 & state == "RI"  // Victory Day
	replace public_holiday = 1 if day == 16 & month == 8 & state == "VT"  // Bennington Battle Day
	replace public_holiday = 1 if day == 5 & month == 11 & inlist(state, "VA", "MT", "RI")  // Election Day
	replace public_holiday = 1 if day == 29 & month == 11 & inlist(state, "OK", "IA", "MI", "NH", "NC", "KY", "SC", "WA", "VA")  // Day after Thanksgiving
	replace public_holiday = 1 if day == 24 & month == 12 & inlist(state, "AR", "TN", "NC", "KY", "WA")  // Christmas Eve
	replace public_holiday = 1 if day == 26 & month == 12 & inlist(state, "OK", "SC", "NC")  // Day after Christmas
	replace public_holiday = 1 if day == 31 & month == 12 & inlist(state,"KY", "WA")  // New Years Eve 

	**********************
	// Weekends & Weeks //
	**********************
	// Create a date variable
	gen str_date = string(day) + "/" + string(month) + "/2019"
	generate eventdate = date(str_date, "DMY")

	// Extract Weekdays
	gen day_of_week = dow(eventdate)	

	// create a variable indicating the day-number of the entry (1-365) for 2019
	gen day_year = doy(eventdate)

	// Assign label
	label define weekdays 0 "Sunday" 1 "Monday" 2 "Thuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
	label values day_of_week weekdays

	// gen week of the year variable for disease merge
	gen week = week(eventdate)

	drop eventdate str_date

	// Generate a Weekend Dummy
	gen weekend = 0
	replace weekend = 1 if inlist(day_of_week, 0, 6)

	// Dummy for Weekend or Public holidays
	gen free_day = 0
	replace free_day = 1 if weekend == 1 | public_holiday == 1	
	
	// trim Area Name of trailing/leading spaces
	replace Area_Name = strtrim(Area_Name)
	
	// replace "." in Area Name such as St. Clair (these "." are not included in the FBI Data)	
	replace Area_Name = subinstr(Area_Name, ".", "", .)
	
	***
	// Order Variables
	***
	// order time-variables to the front
	order geographicareaname Area_Name state month day day_of_week day_year week free_day weekend
	
	*********************
	// save Macro-Trip-Data - temporary file
	tempfile ACS_BTS_County_`wave'
	save `ACS_BTS_County_`wave'', replace
	*********************
}
 
 
*****************************************
// 1.a) Merge NIBRS based on counties  //
*****************************************
	********************************
	// i. Dataset only containing direct matches
	********************************
foreach wave in 1 5 {
    drop _all
    // load in ACS File
	use `ACS_BTS_County_`wave''
	
	// Merge
	merge 1:1 Area_Name state day month using NIBRS_State_Data.dta // , nogen assert(2 3)
	
	// Extract the Subset of Agencies without a merge (merge later)
	preserve
	// number of affected obs 30.091
	// 197 agencies/Area_Names
	drop if _merge != 2
	drop _merge
	*********************
	// save Unmatched Agencies
	tempfile NIBRS_County_`wave'_UnMatched
	save `NIBRS_County_`wave'_UnMatched', replace
	*********************
	restore
		
	// drop unmatched Agencies
	drop if _merge == 2
	drop _merge
	
	/// !!!!
	/// Recalculate the following numbers with 1016 as the total numbers of counties - here biased due to distinct names from NIBRS
	
	// replace mssing values with zeros (or max)(if at least on entry for a county exists)
	// First: Look for counties without any data
	bys Area_Name state: egen County_NIBRS = total(crimes_number), missing
	// These areas have no Agency matched to them
	// THis affects 42 Counties in Total, 29 (69%) of which have a population of 9000 or less; only 8 (19%) have a population of above 15.200
	// List for details (Total of 15.330 obs)
	// Only 0.028% of all counties are affected
	// tab Area_Name state if County_NIBRS == .
	drop if County_NIBRS == .
	drop County_NIBRS	
	
	// Now Look finer (month opr week level; week might be to fine)
	bys Area_Name state month: egen County_NIBRS_month = total(crimes_number), missing
	// Affects 30.785 Observations in 253 (17%) counties
	// Again, most are very small counties - 84.33% are below 10.000 and 9% above 15.000 
	
	// bys Area_Name state week: egen County_NIBRS_week = total(crimes_number), missing
	
	// local with all variables that are replaced with zero
	local NIBRS_Vars crimes_number location_residence Offense_FBI_Violent Offense_FBI_Property property_value Offense_AA daytime_crime_AA residential_AA Offense_Murder daytime_crime_Murder residential_Murder Offense_Rape daytime_crime_Rape residential_Rape Offense_Robbery daytime_crime_Robbery residential_Robbery Offense_Burglary daytime_crime_Burglary residential_Burglary Offense_Larcency daytime_crime_Larcency residential_Larcency Offense_MVT daytime_crime_MVT residential_MVT
	
	foreach var in `NIBRS_Vars' {
		replace `var' = 0 if missing(`var') & !missing(County_NIBRS_month)
	}
	drop County_NIBRS_month
	
	// replace agency_pop and policeforce with the maximum values
	// since multiple agencies might report on different days, the max value of those should be equal to sum of these values across all agencies
	// these values do not change within the year, that why this approach works
	foreach var in agency_population policeforce {
		bys Area_Name state day month: egen `var'_sum = sum(`var')
		bys Area_Name state: egen `var'_max = max(`var'_sum)
		replace `var' = `var'_max
		drop `var'_max `var'_sum
	}

	/// ONLY Analytical
	// Define a weight for population
	// First replace 0 population as missing, data issue
	//replace agency_population = . if agency_population == 0
	
	// now generate the share
	// gen agency_pop_share = min(agency_population / PopulationTotal, 1) if !missing(agency_population)
	// most observations are very close to 1 (75% are over 82%; median = 96.6%)
	// most varation is for small counties and obs with low numbers of crime
	// possible to rescale all varibales with the inverse of this share, but would need to check, that no other (1-county) LEA is active in this county
		
	// replacing varaibles in relation with the msa
	// first string variables by sorting missings on top, then using last (hopefully with entry) obs to fill in missings
	foreach var in msa msa_state {
		sort geographicareaname `var'
		by geographicareaname : gen `var'_string = `var'[_N]
		replace `var' = `var'_string if missing(`var') & !missing(`var'_string)
		drop `var'_string
	}
	// Secondly numeric variables by using their max value (can only be 1 or 0 and shoudl be constant vor each area - msa do not change)
	foreach var in  multi_msa multi_state_msa {
		bys geographicareaname : egen `var'_max = max(`var')
		replace `var' = `var'_max if missing(`var') & !missing(`var'_max)
		drop `var'_max
	}
		
	// Deal with Non-MSA counties
	replace msa_state = state if msa == "Non-MSA"
	
	// replace missing multi county to zero - here only identified counties are in the dataset
	replace multi_county = 0 if missing(multi_county)
	
	*********************
	// save Macro-Trip-Data
	save ACS_BTS_NIBRS_County_`wave', replace
	*********************
}


**********************************************************************
// 1.b) Match with Population Weights for multi-county observations //
**********************************************************************
foreach wave in 1 5 {
    drop _all
	********************************
	// i. Create ACS Population Data
	********************************
	use ACS_County_`wave'
	
	// remove unused vars
	keep geographicareaname Area_Name state PopulationTotal
	
	// trim Area Name of trailing/leading spaces
	replace Area_Name = strtrim(Area_Name)
	
	// replace "." in Area Name such as St. Clair (these "." are not included in the FBI Data)	
	replace Area_Name = subinstr(Area_Name, ".", "", .)
	
	********************
	// save County-Population Data
	tempfile ACS_County_POP_`wave'
	save `ACS_County_POP_`wave'', replace
	********************
	
	****************************************
	// ii. NIBRS - Unmatched Data
	****************************************
	drop _all
	use NIBRS_State_Data.dta
			
	// Split Area name, creating one observation for each county
	split Area_Name, parse(";") gen(county)
	
	// reshape the dataset, so that we have one observation for each county
	reshape long county, i(id_NIBRS day month) j(county_number)
	
	// creates 4 obs per original one, since nibrs_obs have up to 4 counties, delete those without a county
	drop if missing(county)
		
	// gen variable indicating if observation has now muiltiple
	bys id_NIBRS: egen counties = max(county_number)
	gen id_long = 0
	replace id_long = 1 if counties >= 2
	drop counties
	
	// rename county and Area_Name for the merge - swap them
	rename (county Area_Name) (Area_Name county)
		
	// trim Area Name of trailing/leading spaces
	replace Area_Name = strtrim(Area_Name)
		
	// merge original ACS-BTS Data
	merge m:1 Area_Name state using `ACS_County_POP_`wave''
	
	// drop unused counties from ACS
	drop if _merge == 2
	drop if _merge == 1 & `wave' == 1
	drop _merge
	
	// calculate the covered pop of one county agencies and transfer it to all obs
	bys Area_Name state: egen coverd_pop_temp = max(agency_population) if id_long == 0 
	bys Area_Name state: egen coverd_pop = max(coverd_pop_temp)
	
	// calculate Net-Population in all counties
	gen net_pop = PopulationTotal - coverd_pop if id_long == 1
	// For some this is less than 0 (Data from Census != Data from FBI and overlapp in coverage) - We replace those with zero assuming the county is already fully covered
	replace net_pop = 0 if net_pop < 0
	drop coverd_pop coverd_pop_temp

	// generate the the total uncovered population within a LEA
	bys id_NIBRS day month: egen pop_sum = sum(net_pop) if id_long == 1
	// Drop those that have no covered population left (2LEA - 6 obs) 
	drop if pop_sum == 0 
	
	// gen a share variable, this can later be used (after merge, to distribute observations)
	gen pop_share = net_pop / pop_sum if id_long == 1
	drop pop_sum
	
	// Analytical - needs to be 1 for all obs
	// bys id_NIBRS day month: egen sum_share = sum(pop_share) if id_long == 1
	// sum sum_share
	// drop sum_share
	
	
	// reweight observations based on the popualtion share
	local crime_vars crimes_number location_residence Offense_FBI_Violent Offense_FBI_Property property_value Offense_AA daytime_crime_AA residential_AA Offense_Murder daytime_crime_Murder residential_Murder Offense_Rape daytime_crime_Rape residential_Rape Offense_Robbery daytime_crime_Robbery residential_Robbery Offense_Burglary daytime_crime_Burglary residential_Burglary Offense_Larcency daytime_crime_Larcency residential_Larcency Offense_MVT daytime_crime_MVT residential_MVT agency_population policeforce	
	foreach var in `crime_vars' {
			replace `var' = `var' * pop_share if id_long == 1		
	}
	
	********************************
	// iii. Collapse County Dataset
	********************************	
	// Since the msa variable is no no longer unique for each area_name, I will make it so
	// Assuming, that if a county is within an MSA for at least one observation, it should be for all
	// This negelcts the distinction set out by the FBI
	// we do have some counties, which are in multiple MSAs for some observations but not for others
	// while this is again, a result of the FBI using the msa variable for the activity of the agency, for the collapse this is not as important
		
	// Replace Non-MSA wth missing
	replace msa = "."  if msa == "Non-MSA"
	replace msa = ""  if msa == "."
	
	// Fill in missings
	//sort missings to the top, then using last observation within a group to fill in missings
	sort state Area_Name msa
	by state Area_Name : gen msa_string = msa[_N]
	replace msa = msa_string
	drop msa_string
	replace msa = "Non-MSA" if msa == ""

	// Rescale agency_population and policeforce
	foreach var in agency_population policeforce {
		bys Area_Name state day month: egen `var'_sum = sum(`var')
		bys Area_Name state: egen `var'_max = max(`var'_sum)
		replace `var' = `var'_max
		drop `var'_max `var'_sum
	}
	
	// Now collapse such that for each day/month/county we have one observation
	// Due to the change in policeforce/agency_population, we now use it to as grouping variables, they are the same within each observation
	collapse (sum) crimes_number location_residence Offense_FBI_Violent Offense_FBI_Property property_value Offense_AA daytime_crime_AA residential_AA Offense_Murder daytime_crime_Murder residential_Murder Offense_Rape daytime_crime_Rape residential_Rape Offense_Robbery daytime_crime_Robbery residential_Robbery Offense_Burglary daytime_crime_Burglary residential_Burglary Offense_Larcency daytime_crime_Larcency residential_Larcency Offense_MVT daytime_crime_MVT residential_MVT, by(agency_population policeforce day month state Area_Name msa)
	
	
	
	
	// We now round all numbers to whole numbers, this is done to apply a count estimator later on
	local crimes_number location_residence Offense_FBI_Violent Offense_FBI_Property property_value Offense_AA daytime_crime_AA residential_AA Offense_Murder daytime_crime_Murder residential_Murder Offense_Rape daytime_crime_Rape residential_Rape Offense_Robbery daytime_crime_Robbery residential_Robbery Offense_Burglary daytime_crime_Burglary residential_Burglary Offense_Larcency daytime_crime_Larcency residential_Larcency Offense_MVT daytime_crime_MVT residential_MVT agency_population policeforce
	foreach var in `crime_vars' {
			replace `var' = round(`var',1)		
	}
	
	
	
	****************************
	// save Dataset
	tempfile NIBRS_County_`wave'_PopWeighted
	save `NIBRS_County_`wave'_PopWeighted', replace
	****************************
	
	// merge with ACS-BTS data
	merge 1:1 Area_Name state day month using `ACS_BTS_County_`wave'', nogen	
	
	// As above, clean dataset and impute zeros for empty days
	bys Area_Name state: egen County_NIBRS = total(crimes_number), missing
	// These areas have no Agency matched to them
	// THis affects 32 Counties in Total, 24 (75%) of which have a population of 8500 or less; only 4 (9%) have a population of above 15.200
	// List for details (Total of 12.045 obs)
	// Only 0.031% of all counties are affected
	// tab Area_Name state if County_NIBRS == .
	drop if County_NIBRS == .
	drop County_NIBRS	
	
	// Now Look finer (month opr week level; week might be to fine)
	bys Area_Name state month: egen County_NIBRS_month = total(crimes_number), missing
	// Affects 30.688 Observations in 223 (21.9%) counties
	// Again, most are very small counties - 86.38% are below 10.000 and 6.5% above 15.000 
	
	// bys Area_Name state week: egen County_NIBRS_week = total(crimes_number), missing
	
	// local with all varieables that are replaced with zero
	local NIBRS_Vars crimes_number location_residence Offense_FBI_Violent Offense_FBI_Property property_value Offense_AA daytime_crime_AA residential_AA Offense_Murder daytime_crime_Murder residential_Murder Offense_Rape daytime_crime_Rape residential_Rape Offense_Robbery daytime_crime_Robbery residential_Robbery Offense_Burglary daytime_crime_Burglary residential_Burglary Offense_Larcency daytime_crime_Larcency residential_Larcency Offense_MVT daytime_crime_MVT residential_MVT
	
	foreach var in `NIBRS_Vars' {
		replace `var' = 0 if missing(`var') & !missing(County_NIBRS_month)
	}
	drop County_NIBRS_month
	
	// replace agency_pop and policeforce with the maximum values
	// since multiple agencies might report on different days, the max value of those should be equal to sum of these values across all agencies
	// these values do not change within the year, that why this approach works
	foreach var in agency_population policeforce {
		bys Area_Name state day month: egen `var'_sum = sum(`var')
		bys Area_Name state: egen `var'_max = max(`var'_sum)
		replace `var' = `var'_max
		drop `var'_max `var'_sum
	}
	
	
	/// ONLY Analatytical
	// First replace 0 population as missing, data issue
	//replace agency_population = . if agency_population == 0
	
	// now generate the share
	//gen agency_pop_share = min(agency_population / PopulationTotal, 1) if !missing(agency_population)
	// most observations are very close to 1 (q10 = 60%, q25 = 86%; q50 = 97)
	// most varation is for small counties and obs with low numbers of crime
	// This indicates, that even though we miss some observations, the overwhelming majority is accounted for
	// High corelation between share and NIBRS coverage!
	
	// regenerating the split-vars
	foreach var in CRIMES AGENCY_INFOS {
	gen `var' = .
	}
	
	// order dataset as others (different order, due to different merge)
	order geographicareaname Area_Name state msa month day day_of_week day_year week free_day weekend public_holiday POPULATION PopulationTotal PopulationMale Population16over Population18over Population20to24 Population25to34 Population35to44 Population45to54 Population55to59 Population60to64 Population65over PopulationAgeMedian RACE Race_White Race_Black Race_Native Race_Asian Race_Other Race_Latino WORK_POPULATION WAPopulation LFPR armedforces UER WORKER_CLASS Worker_Wage Worker_Gov Worker_Self_Emp EDUCATION Educ_Enrolment Educ_NoHighschool Educ_Highschool Educ_Bachelor HH_INCOME HH_below10000 HH_10000to14999 HH_15000to24999 HH_25000to34999 HH_35000to49999 HH_50000to74999 HH_75000to99999 HH_100000to149999 HH_150000to199999 HH_200000above HH__Median_Income HH__Mean_Income HH_with_earning HH_with_socialsecurity HH_with_pension HH_suppl_security_inc HH_cashassistance Poverty_FoodstrampSNAP Poverty_Line_all Poverty_Line_kids HEALTH Health_Insured Health_Public HH_CHARACTERISTICS HH_Size_Mean HH_Single HH_Married_Cohabiting HH_withkids HH_with65 HH_computer HH_broadbandinternet COMMUTING commute_alone commute_carpool commute_publictransportation commute_walked commute_other commute_workingfromhome commute_traveltime_mean VEHICLES vehicle_None vehicle_One vehicle_Two vehicle_ThreeorMore HOUSING Housing_Units_Total Housing_VacancyRate OwnerOccupied_Share Rooms_Median House_MedianValue_OwnerOccupied Rent_Gross_Median NEIGHBORS Neighbor_None Neighbor_1 Neighbor_2to3 Neighbor_4to18 Neighbor_19plus Neighbor_other BUILDINGS Buldings_New Buldings_Aged Buldings_Old OCCUPATION occupation_management occupation_service occupation_salesoffice occupation_BuildingRessources occupation_ProductionTransport INDUSTRY industry_agriculture industry_construction industry_manufacturing industry_wholesaletrade industry_retailtrade industry_transportation industry_information industry_financialservices industry_Management industry_SocialServices industry_ArtHotelEntertainment industry_other industry_publicservices TRIPS Population_BTS PopulationAtHome trips trips_pP trip_length_mean trips1 trips13 trips35 trips510 trips1025 trips2550 trips50100 trips100250 trips250500 trips500 CRIMES crimes_number location_residence Offense_FBI_Violent Offense_FBI_Property property_value Offense_AA daytime_crime_AA residential_AA Offense_Murder daytime_crime_Murder residential_Murder Offense_Rape daytime_crime_Rape residential_Rape Offense_Robbery daytime_crime_Robbery residential_Robbery Offense_Burglary daytime_crime_Burglary residential_Burglary Offense_Larcency daytime_crime_Larcency residential_Larcency Offense_MVT daytime_crime_MVT residential_MVT AGENCY_INFOS agency_population policeforce
		
	*********************
	// save Macro-Trip-Data
	save ACS_BTS_NIBRS_County_POPWeight_`wave', replace
	*********************
	
	
*********************************************
// 1.c) Add Unemploymenmt and Weather Data //
*********************************************
	
	********************************
	// i. LAUS - Unemployment
	********************************
	// merge on a monthly basis
	merge m:1 Area_Name state month using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\Laus_Month.dta"

	// As before, drop unused observations from using - these vary with the version of ACS used
	drop if _merge==2
	drop _merge


	********************************
	// ii. NOOA - Weather
	********************************
	
	// merge daily weather data
	merge 1:1 Area_Name state day_year using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\weather_county_day.dta"

	// drop observations only contained in the Weather data - these vary with the version of ACS used
	drop if _merge == 2
	drop _merge

	
*********************
// SAVE FINAL DATASET
// HERE: County-level observations
save Opportunity_County_Popweight_`wave', replace
*********************
	
}








/*
// MSA Part is currently not fully implemented!
// Needs readjustment for new crime data as done for the County Level - To-Do

****************************************************************************************************
// 2. MSA level
****************************************************************************************************
*******************************************
// i. BTS - MSA Level
*******************************************
drop _all
use BTS_Data.dta

// for merge rename Area_Name
rename Area_Name MSA_county
replace MSA_county = strtrim(MSA_county)	

// merge with Census Deliniation Files
merge m:1 MSA_county state using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\Census_MSA_County_List.dta" , assert (1 3)

drop if _merge == 1
drop _merge

// using a number rather than a share gives way to sum this up and then calculate the share later
replace PopulationAtHome = PopulationAtHome * Population_BTS

// collapse Dataset to day-month-msa level
// This command also collapses over states. Since BTS data is only for states that NIBRS is available this shouldn't be an issue
// Otherwhise this would produce more than 365 observations for cross-state MSAs
// Two ways to collapse via CBSA or CSA
preserve

************
// ii. CBSA
************
collapse (sum) TRIPS Population_BTS PopulationAtHome trips trips_pP trip_length_mean trips1 trips13 trips35 trips510 trips1025 trips2550 trips50100 trips100250 trips250500 trips500, by(day month CBSATitle)

replace PopulationAtHome = PopulationAtHome / Population_BTS
replace trips_pP = trips / Population_BTS

*******************************************
// save Dataset
tempfile BTS_MSA_CBSA_Data
save `BTS_MSA_CBSA_Data.dta', replace
*******************************************

restore

************
// iii. CSA
************
collapse (sum) TRIPS Population_BTS PopulationAtHome trips trips_pP trip_length_mean trips1 trips13 trips35 trips510 trips1025 trips2550 trips50100 trips100250 trips250500 trips500, by(day month  CSATitle)

replace PopulationAtHome = PopulationAtHome / Population_BTS
replace trips_pP = trips / Population_BTS

*******************************************
// save Dataset
tempfile BTS_MSA_CSA_Data
save `BTS_MSA_CSA_Data.dta', replace
*******************************************

   
*******************************************
// 2.a) NIBRS - MSA level
*******************************************
drop _all

************************************
// i. Prepare Data for Collapse
************************************
use NIBRS_State_Data.dta
// Create a non-share variable for daytimes
foreach var in AA Murder Rape Robbery Burglary Larcency MVT {
	replace daytime_crime_`var'  = daytime_crime_`var' *  Offense_`var' if Offense_`var' != 0
}

// Gen Non-MSA Dummy
gen Non_Msa = 0
replace Non_Msa = 1 if msa == "Non-MSA"

// Replace Non-MSA agencies with their county and impute a state based on the counties state
replace msa = Area_Name  if msa == "Non-MSA"
replace msa_state = state if missing(msa_state)

// Rescale agency_population and policeforce
foreach var in agency_population policeforce {
	bys msa msa_state: egen `var'_max = max(`var')
	replace `var' = `var'_max
	drop `var'_max
}

************************************
// ii. Collapse to Day-Month-MSA level
************************************
collapse (sum) Non_Msa crimes_number property_value location_residence location_outdoor location_other location_commerical Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property daytime_crime*, by(agency_population policeforce day month msa msa_state)
  
// rescaling after the collapse
replace Non_Msa = 1 if Non_Msa >=1

// Rescale agency_population and policeforce
foreach var in agency_population policeforce {
	bys msa msa_state day month: egen `var'_sum = sum(`var')
	bys msa msa_state: egen `var'_max = max(`var'_sum)
	replace `var' = `var'_max
	drop `var'_max `var'_sum
}
   
foreach var in AA Murder Rape Robbery Burglary Larcency MVT {
	replace daytime_crime_`var'  = daytime_crime_`var' /  Offense_`var' if Offense_`var' != 0
}

*******************************************
// save Data
tempfile NIBRS_State_MSA_Data
save `NIBRS_State_MSA_Data.dta', replace
*******************************************
   
*******************************************
// iii. Merge ACS and BTS Data for MSA level
*******************************************
foreach wave in 1 5 {
	drop _all
	
	// I will for now stick to the CBSA name, while the CSA name is a larger unit which might be more appropriate for some observations, it would also reduce the dataset to less than 30.000 observations
    // load in ACS File
	use ACS_MSA_`wave'
	
	// Reduce the geographicareaname to: MSA_name, State
	replace geographicareaname = subinstr(geographicareaname, "Micro", "", .)
	replace geographicareaname = subinstr(geographicareaname, "Metro", "", .)
	replace geographicareaname = subinstr(geographicareaname, "Area", "", .)
	replace geographicareaname = strtrim(geographicareaname)
	
	// one spelling/codec error to correct
	replace geographicareaname = "Cañon City, CO" if geographicareaname == "CaÃ±on City, CO"
	// only in wave == 5	
	
	// for merge rename geographicareaname
	rename geographicareaname CBSATitle
	merge 1:m CBSATitle using `BTS_MSA_CBSA_Data', assert(2 3)
	drop if _merge == 2 // only for ACS_1 important
	drop _merge
	rename CBSATitle geographicareaname
	
	********************************
	***  Holidays and Time-Dummy ***
	********************************
	// Create variables for the days and times
	**************************
	// Public Holiday Dummy //
	**************************
	// Dummy = 1 if the day is a public holiday in that state
	// Some states have exceptions that are exlluded
	// Others have additional days which are added after the federal holidays

	gen public_holiday = 0

	// Federal Holodays
	replace public_holiday = 1 if day == 1 & month == 1 // New-years Eve
	replace public_holiday = 1 if day == 21 & month == 1 // MLK-DAY
	replace public_holiday = 1 if day == 18 & month == 2 & !inlist(state, "KY", "NC", "IA", "KS", "RI")  // Presidents-Day
	replace public_holiday = 1 if day == 27 & month == 5 // Memorial Day
	replace public_holiday = 1 if day == 4 & month == 4 // Independence Day
	replace public_holiday = 1 if day == 2 & month == 9 // Labor Day
	replace public_holiday = 1 if day == 14 & month == 10 & !inlist(state, "KY", "NC", "IA", "KS", "VT", "TN") & !inlist(state, "SC", "MI", "OK", "AR", "ND", "OR", "WA")  // Columbus Day
	replace public_holiday = 1 if day == 11 & month == 11 // Veterans Day
	replace public_holiday = 1 if day == 28 & month == 11 // Thanksgiving
	replace public_holiday = 1 if day == 25 & month == 12 // Christmas Day

	// State Holidays
	replace public_holiday = 1 if day == 12 & month == 2 & state == "CO"  // Lincolns BD
	replace public_holiday = 1 if day == 5 & month == 3 & state == "VT"  // Town meeting Day
	replace public_holiday = 1 if day == 15 & month == 4 & state == "MA"  // Patriots Day
	replace public_holiday = 1 if day == 19 & month == 4 & inlist(state, "NC", "KY", "TN", "CO")  // Good Friday
	replace public_holiday = 1 if day == 10 & month == 5 & state == "SC"  // Confederate Memorial Day
	replace public_holiday = 1 if day == 20 & month == 6 & state == "WV"  // West Virginia Day
	replace public_holiday = 1 if day == 12 & month == 8 & state == "RI"  // Victory Day
	replace public_holiday = 1 if day == 16 & month == 8 & state == "VT"  // Bennington Battle Day
	replace public_holiday = 1 if day == 5 & month == 11 & inlist(state, "VA", "MT", "RI")  // Election Day
	replace public_holiday = 1 if day == 29 & month == 11 & inlist(state, "OK", "IA", "MI", "NH", "NC", "KY", "SC", "WA", "VA")  // Day after Thanksgiving
	replace public_holiday = 1 if day == 24 & month == 12 & inlist(state, "AR", "TN", "NC", "KY", "WA")  // Christmas Eve
	replace public_holiday = 1 if day == 26 & month == 12 & inlist(state, "OK", "SC", "NC")  // Day after Christmas
	replace public_holiday = 1 if day == 31 & month == 12 & inlist(state,"KY", "WA")  // New Years Eve 

	**********************
	// Weekends & Weeks //
	**********************
	// Create a date variable
	gen str_date = string(day) + "/" + string(month) + "/2019"
	generate eventdate = date(str_date, "DMY")

	// Extract Weekdays
	gen day_of_week = dow(eventdate)

	// Assign label
	label define weekdays 0 "Sunday" 1 "Monday" 2 "Thuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
	label values day_of_week weekdays

	// gen week of the year variable for disease merge
	gen week = week(eventdate)

	drop eventdate str_date

	// Generate a Weekend Dummy
	gen weekend = 0
	replace weekend = 1 if inlist(day_of_week, 0, 6)

	// Dummy for Weekend or Public holidays
	gen free_day = 0
	replace free_day = 1 if weekend == 1 | public_holiday == 1	
	
	// trim Area Name of trailing/leading spaces
	replace Area_Name = strtrim(Area_Name)
	
	// replace "." in Area Name such as St. Clair (these "." are not included in the FBI Data)	
	replace Area_Name = subinstr(Area_Name, ".", "", .)
	
	*********************************************************
	// iv. Merge with NIBRS (preparation)
	*********************************************************
	rename geographicareaname msa	
	split msa, parse(",")
	
	// replace msa only with the msa names
	replace msa = msa1
	drop msa1

	// generate a new variable giving the respective states to the msa names
	rename msa2 msa_state 
	
	*******************
	// Order Variables
	*******************
	// order time-variables to the front
	order msa msa_state Area_Name state month day day_of_week week free_day weekend
			
	*******************************************
	// save Macro-Trip-Data
	tempfile ACS_BTS_MSA_`wave'
	save `ACS_BTS_MSA_`wave'', replace
	*******************************************
	
	*******************************************
	// v. Merge ACS-BTS with NIBRS - MSA level
	*******************************************
	merge 1:1 msa msa_state day month using `NIBRS_State_MSA_Data'
	
	// drop ACS-BTS data that did not match
	drop if _merge == 1
	
	// Extract matched results
	preserve
	keep if _merge == 3

	// Calculate Agency Coverage - Agency-pop_share
	// First replace 0 population as missing, data issue
	replace agency_population = . if agency_population == 0
	
	// now generate the share
	gen agency_pop_share = min(agency_population / PopulationTotal, 1) if !missing(agency_population)
	
	*********************
	// Order variables
	*********************
	// regenerating the split-vars
	foreach var in CRIMES CRIMES_CHARACTERISTICS AGENCY_INFOS {
	gen `var' = .
	}
	
	order Area_Name state month day day_of_week week free_day weekend POPULATION PopulationTotal PopulationMale Population16over Population18over Population20to24 Population25to34 Population35to44 Population45to54 Population55to59 Population60to64 Population65over PopulationAgeMedian RACE Race_White Race_Black Race_Native Race_Asian Race_Other Race_Latino WORK_POPULATION WAPopulation LFPR armedforces UER WORKER_CLASS Worker_Wage Worker_Gov Worker_Self_Emp EDUCATION Educ_Enrolment Educ_NoHighschool Educ_Highschool Educ_Bachelor HH_INCOME HH_below10000 HH_10000to14999 HH_15000to24999 HH_25000to34999 HH_35000to49999 HH_50000to74999 HH_75000to99999 HH_100000to149999 HH_150000to199999 HH_200000above HH__Median_Income HH__Mean_Income HH_with_earning HH_with_socialsecurity HH_with_pension HH_suppl_security_inc HH_cashassistance Poverty_FoodstrampSNAP Poverty_Line_all Poverty_Line_kids HEALTH Health_Insured Health_Public HH_CHARACTERISTICS HH_Size_Mean HH_Single HH_Married_Cohabiting HH_withkids HH_with65 HH_computer HH_broadbandinternet COMMUTING commute_alone commute_carpool commute_publictransportation commute_walked commute_other commute_workingfromhome commute_traveltime_mean VEHICLES vehicle_None vehicle_One vehicle_Two vehicle_ThreeorMore HOUSING Housing_Units_Total Housing_VacancyRate OwnerOccupied_Share Rooms_Median House_MedianValue_OwnerOccupied Rent_Gross_Median NEIGHBORS Neighbor_None Neighbor_1 Neighbor_2to3 Neighbor_4to18 Neighbor_19plus Neighbor_other BUILDINGS Buldings_New Buldings_Aged Buldings_Old OCCUPATION occupation_management occupation_service occupation_salesoffice occupation_BuildingRessources occupation_ProductionTransport INDUSTRY industry_agriculture industry_construction industry_manufacturing industry_wholesaletrade industry_retailtrade industry_transportation industry_information industry_financialservices industry_Management industry_SocialServices industry_ArtHotelEntertainment industry_other industry_publicservices TRIPS Population_BTS PopulationAtHome trips trips_pP trip_length_mean trips1 trips13 trips35 trips510 trips1025 trips2550 trips50100 trips100250 trips250500 trips500 public_holiday msa  CRIMES crimes_number Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property CRIMES_CHARACTERISTICS location_residence location_outdoor location_other location_commerical daytime_crime_AA daytime_crime_Murder daytime_crime_Rape daytime_crime_Robbery daytime_crime_Burglary daytime_crime_Larcency daytime_crime_MVT property_value AGENCY_INFOS agency_population policeforce agency_pop_share
	
	*********************
	// Save matched
	save ACS_BTS_NIBRS_MSA_`wave'.dta, replace
	*********************
	

	**********************************************************************************************
	// 2.b) Match with Population Weights for multi-msa and via County for Non-MSA observations //
	**********************************************************************************************
	restore
	
	******************************************
	// i. Extract Multi-MSA Observations
	******************************************
	// drop matched results
	drop if _merge == 3
	drop _merge
	
	preserve
	
	// Extract Non-Matched multi MSA NIBRS obs
	drop if Non_Msa == 1
	
	*********************
	// Save Multi-MSA non-matched
	tempfile NIBRS_MSA_Multi_`wave'
	save `NIBRS_MSA_Multi_`wave''.dta, replace
	*********************
	
	**************************************************
	// 2.b.Non-MSA) NON-MSA Observations
	**************************************************
	restore			
	
	// Drop MSA obs
	drop if Non_Msa == 0
	
	// replace Area_Name with msa name
	replace Area_Name = msa
	replace state = msa_state
	// And set msa to Non-MSA
	replace msa = "Non-MSA"
			
	// Split Area name, creating one observation for each county
	split Area_Name, parse(";") gen(county)
	
	// reshape the dataset, so that we have one observation for each county
	reshape long county, i(Area_Name state day month) j(county_number)
	
	// creates 4 obs per original one, since nibrs_obs have up to 4 counties, delete those without a county
	drop if missing(county)
		
	// gen variable indicating if observation has now muiltiple
	bys Area_Name state: egen counties = max(county_number)
	gen id_long = 0
	replace id_long = 1 if counties >= 2
	drop counties
	
	// rename county and Area_Name for the merge - swap them
	rename (county Area_Name) (Area_Name county)
		
	// trim Area Name of trailing/leading spaces
	replace Area_Name = strtrim(Area_Name)
		
	// merge original ACS-BTS Data
	merge m:1 Area_Name state using `ACS_County_POP_`wave'', update
	
	// drop unused counties from ACS
	drop if _merge == 2
	drop if _merge == 1 & `wave' == 1
	drop _merge
	
	// generate the maximum population within a nibrs_obs
	bys county state day month: egen pop_sum = sum(PopulationTotal) if id_long == 1
	
	// gen a share variable, this can later be used (after merge, to distribute observations)
	gen pop_share = PopulationTotal / pop_sum if id_long == 1
	
	drop pop_sum 	
	
	// reweight observations based on the popualtion share
	local crime_vars crimes_number Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property location_residence location_outdoor location_other location_commerical daytime_crime_AA daytime_crime_Murder daytime_crime_Rape daytime_crime_Robbery daytime_crime_Burglary daytime_crime_Larcency daytime_crime_MVT property_value agency_population policeforce
	foreach var in `crime_vars' {
			replace `var' = `var' * pop_share if id_long == 1		
	}	

	// due to rescaling we also have to rescale agency_population and policeforce
	foreach var in agency_population policeforce {
		bys Area_Name state day month: egen `var'_sum = sum(`var')
		bys Area_Name state: egen `var'_max = max(`var'_sum)
		replace `var' = `var'_max
		drop `var'_max
	}

	********************************************************************************
	// i. Collapse NON-MSA Observations to a single day-month-county-observation  
	********************************************************************************
	collapse (sum) crimes_number property_value location_residence location_outdoor location_other location_commerical Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property daytime_crime*, by(agency_population policeforce day month state Area_Name msa)
	
	// merge with ACS-BTS Data	
	merge 1:1 Area_Name state day month using `ACS_BTS_County_`wave'', update replace	
	
	// drop unmatches ACS-BTS observations
	drop if _merge == 2
	drop _merge	
	
	**************
	// save Matched Observations
	tempfile NIBRS_MSA_County_`wave'_PopWeighted
	save `NIBRS_MSA_County_`wave'_PopWeighted', replace
	**************
	
	
	*********************************
	// 2.b.Multi-MSA). MULTI-MSA Observations
	*********************************
	
	********************************
	// i. Create MSA Population Data
	********************************
	drop _all
	
	// Load in ACS Data to create a Population Dataset
	use ACS_MSA_`wave'
	
	// remove unused vars
	keep Area_Name state PopulationTotal
	
	// trim Area Name of trailing/leading spaces
	replace Area_Name = strtrim(Area_Name)
	replace state = strtrim(state)
	
	// replace "." in Area Name such as St. Clair (these "." are not included in the FBI Data)	
	replace Area_Name = subinstr(Area_Name, ".", "", .)
	
	********************
	// save MSA Popualtion Data
	tempfile  ACS_MSA_POP_`wave'
	save `ACS_MSA_POP_`wave'', replace
	********************
	
	********************************
	// ii. Prepare Multi-MSA Data
	********************************
	drop _all	
	use `NIBRS_MSA_Multi_`wave''.dta	
	
	// Split MSA and MSA_state´
	split msa, parse(";") 
	split msa_state, parse(";")
	
	replace msa1 = msa1 + "; " + msa_state1
	replace msa2 = msa2 + "; " + msa_state2
	
	drop msa_state1 msa_state2
	rename (msa msa_state) (msa_combined msa_state_combined)
	
	// reshape the dataset, so that we have one observation for each county
	reshape long msa, i(msa_combined msa_state_combined day month) j(msa_number)
	
	// Split MSA and Extract State
	split msa, parse(";") 
	
	replace Area_Name = msa1
	replace state = msa2
	
	// Trim Strings for matching
	replace Area_Name = strtrim(Area_Name)
	replace Area_Name = strupper(Area_Name)
	replace state = strtrim(state)
	
	drop msa msa1 msa2

	**************************************************
	// iii. merge Multi-MSA Data with ACTS-BTS Data
	**************************************************
	merge m:1 Area_Name state using `ACS_MSA_POP_`wave'', update
	
	// drop unused counties from ACS
	drop if _merge == 2
	drop if _merge == 1 & `wave' == 1
	drop _merge
	
	// generate the maximum population within a Agency - sum is sufficient, as for each observation due to shape, there are exactly one observation per msa/county
	bys msa_combined state day month: egen pop_sum = sum(PopulationTotal)
	
	// gen a share variable, this can later be used (after merge, to distribute observations)
	gen pop_share = PopulationTotal / pop_sum
	
	drop pop_sum 	
	
	// Weight observations based on the popualtion share
	local crime_vars crimes_number Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property location_residence location_outdoor location_other location_commerical daytime_crime_AA daytime_crime_Murder daytime_crime_Rape daytime_crime_Robbery daytime_crime_Burglary daytime_crime_Larcency daytime_crime_MVT property_value agency_population policeforce
	foreach var in `crime_vars' {
			replace `var' = `var' * pop_share	
	}
		
		
	**************************************************
	// 2.b.All) Append MSA Datasets 
	**************************************************
	**************************************************
	// i. Combine Mulit-MSA with Singel-MSA Data
	**************************************************		
	append using ACS_BTS_NIBRS_MSA_`wave'
	
	// due to rescaling we also have to rescale agency_population and policeforce
	foreach var in agency_population policeforce {
		bys Area_Name state day month: egen `var'_sum = sum(`var')
		bys Area_Name state: egen `var'_max = max(`var'_sum)
		replace `var' = `var'_max
		drop `var'_max
	}
	
	****************************************************************************
	// ii. Collapse Mulit-MSA with Singel-MSA Data to day/month/msa observation
	****************************************************************************
	collapse (sum) crimes_number property_value location_residence location_outdoor location_other location_commerical Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property daytime_crime*, by(agency_population policeforce day month state Area_Name)
	
	// merge with ACS-BTS Data	
	merge 1:1 Area_Name state day month using `ACS_BTS_MSA_`wave'', assert( 2 3)
	
	// Gen MSA variables
	replace  msa = Area_Name if missing(msa)
	replace msa_state = state if missing(state)
	
	drop if _merge == 2
	drop _merge	
	
	**************************************************
	// iii. Combine Non-MSA with MSA Data
	**************************************************
	append using `NIBRS_MSA_County_`wave'_PopWeighted'

	// Calculate Agency Coverage - Agency-pop_share
	// First replace 0 population as missing, data issue
	replace agency_population = . if agency_population == 0
	
	// now generate the share
	gen agency_pop_share = min(agency_population / PopulationTotal, 1) if !missing(agency_population)	
	
	***************
	// Order variables
	***************
	// regenerating the split-vars
	foreach var in CRIMES CRIMES_CHARACTERISTICS AGENCY_INFOS {
	gen `var' = .
	}
	
	order Area_Name state month day day_of_week week free_day weekend POPULATION PopulationTotal PopulationMale Population16over Population18over Population20to24 Population25to34 Population35to44 Population45to54 Population55to59 Population60to64 Population65over PopulationAgeMedian RACE Race_White Race_Black Race_Native Race_Asian Race_Other Race_Latino WORK_POPULATION WAPopulation LFPR armedforces UER WORKER_CLASS Worker_Wage Worker_Gov Worker_Self_Emp EDUCATION Educ_Enrolment Educ_NoHighschool Educ_Highschool Educ_Bachelor HH_INCOME HH_below10000 HH_10000to14999 HH_15000to24999 HH_25000to34999 HH_35000to49999 HH_50000to74999 HH_75000to99999 HH_100000to149999 HH_150000to199999 HH_200000above HH__Median_Income HH__Mean_Income HH_with_earning HH_with_socialsecurity HH_with_pension HH_suppl_security_inc HH_cashassistance Poverty_FoodstrampSNAP Poverty_Line_all Poverty_Line_kids HEALTH Health_Insured Health_Public HH_CHARACTERISTICS HH_Size_Mean HH_Single HH_Married_Cohabiting HH_withkids HH_with65 HH_computer HH_broadbandinternet COMMUTING commute_alone commute_carpool commute_publictransportation commute_walked commute_other commute_workingfromhome commute_traveltime_mean VEHICLES vehicle_None vehicle_One vehicle_Two vehicle_ThreeorMore HOUSING Housing_Units_Total Housing_VacancyRate OwnerOccupied_Share Rooms_Median House_MedianValue_OwnerOccupied Rent_Gross_Median NEIGHBORS Neighbor_None Neighbor_1 Neighbor_2to3 Neighbor_4to18 Neighbor_19plus Neighbor_other BUILDINGS Buldings_New Buldings_Aged Buldings_Old OCCUPATION occupation_management occupation_service occupation_salesoffice occupation_BuildingRessources occupation_ProductionTransport INDUSTRY industry_agriculture industry_construction industry_manufacturing industry_wholesaletrade industry_retailtrade industry_transportation industry_information industry_financialservices industry_Management industry_SocialServices industry_ArtHotelEntertainment industry_other industry_publicservices TRIPS Population_BTS PopulationAtHome trips trips_pP trip_length_mean trips1 trips13 trips35 trips510 trips1025 trips2550 trips50100 trips100250 trips250500 trips500 public_holiday msa  CRIMES crimes_number Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property CRIMES_CHARACTERISTICS location_residence location_outdoor location_other location_commerical daytime_crime_AA daytime_crime_Murder daytime_crime_Rape daytime_crime_Robbery daytime_crime_Burglary daytime_crime_Larcency daytime_crime_MVT property_value AGENCY_INFOS agency_population policeforce agency_pop_share
	
	************************
	// Save Final Dataset //
	************************
	save ACS_BTS_NIBRS_MSA_PopWeighted_`wave'.dta,replace
	************************
}

*/
