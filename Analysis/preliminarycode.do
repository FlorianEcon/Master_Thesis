// Code Brackets for change

/* IMPLEMENTED (at least once!)

// Line 250+ of merger - integrating new population distribution mechanism
// After number of counties are extracted (and a dummy is created)
// Or after merge with county data

// calculate the covered pop of one county agencies
bys Area_Name state: egen coverd_pop_temp = max(agency_population) if id_long == 0 
bys Area_Name state: egen coverd_pop = max(coverd_pop_temp)
gen net_pop = PopulationTotal - coverd_pop if id_long == 1
replace net_pop = 0 if net_pop < 0
drop coverd_pop coverd_pop_temp


	// generate the maximum population within a nibrs_obs
	// # drop the day month?
	bys id_NIBRS day month: egen pop_sum = sum(net_pop) if id_long == 1
	drop if pop_sum == 0 // (2LEA - 6 obs)
	
	// gen a share variable, this can later be used (after merge, to distribute observations)
	gen pop_share = net_pop / pop_sum if id_long == 1
	drop pop_sum
	
	// Analytical - needs to be 1 for all obs
	// bys id_NIBRS day month: egen sum_share = sum(pop_share) if id_long == 1
	// sum sum_share
	// drop sum_share
	
	
	// reweight observations based on the popualtion share
	local crime_vars crimes_number Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property location_residence location_outdoor location_other location_commerical daytime_crime_AA daytime_crime_Murder daytime_crime_Rape daytime_crime_Robbery daytime_crime_Burglary daytime_crime_Larcency daytime_crime_MVT property_value agency_population policeforce
	foreach var in `crime_vars' {
			replace `var' = `var' * pop_share if id_long == 1		
	}

*/


// Merge Code for LAUS + NOOA

// Finally we add Unemployment and Weather Data to our dataset



// NOOA Weather Data
// we first need to create a day of the year indicator
		// Create Date Variables
		gen str_date = string(day) + "/" + string(month) + "/2019"
		generate eventdate = date(str_date, "DMY")

		// create a variable indicating the day-number of the entry (1-365) for 2019
		gen day_year = doy(eventdate)

		drop eventdate str_date 

merge 1:1 Area_Name state day_year using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\weather_county_day.dta"

// drop observations only contained in the Weather data - these vary with the version of ACS used
drop if _merge == 2
drop _merge

// LAUS unemployment data
merge m:1 Area_Name state month using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\Laus_Month.dta"

// As before, drop unused observations from using - these vary with the version of ACS used
drop if _merge==2
drop _merge




	
	
	