************************
// Weather Station Transform
************************
/*
    Created on 20.5.2021
    @author: Florian Fickler
    Goal:
        1. Clean weather data
		2. transform data for merge with county-level data

    To-Do for it to run:
        set working directory (line 16)
*/

// Set working directory
cd  "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\WIP\weather_data"

************************
// 1. Clean Raw Station Data
************************
	// Import Data
	import delimited "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\WIP\weather_data\climatedata.csv", varnames(1)
	// Dataset covers 28.061 Stations

	// Note about meassurements:
	// Temps - in C
	// Snow & Percipitation in mm

	************************
	// 1.a) Preliminary Work
	************************	
		// Remove empty weather Stations and headers
		// Stations without any observations only have the header 
		drop if station == "STATION" 

		// Create Date Variables
		// transfer date to a stata redable value
		gen eventdate = date(date, "YMD")

		// create a variable indicating the day-number of the entry (1-365) for 2019
		gen day_year = doy(eventdate)

		drop eventdate date 

		// Handle Download Errors
		drop if missing(day_year)
		// Affects 4 downloads - negelegible

		// destring all data variables
		foreach var of varlist prcp snow tmax tmin tvag {
			destring `var', replace
		}


	************************
	// 1.b) Missing Observations
	************************
		// Average Temperature has no entries - therefore drop from dataset
		drop tvag

		// Tmin, tmax are missing for 63.93% of the station data  - lets see at county level
		// Snow is only missing for 46.42% - might impute 0's at county level
		// prcp only misses for 7.21% - likely to be very few observations when collapsed

		// Two values, for which min-temp is larger than max temp -> move to missing
		gen t_diff = tmax - tmin
		replace tmax = . if t_diff <0
		replace tmin = . if t_diff <0

		// Some observations report tmin, but no tmax
		// This seems to be an error, or at least inconsistent -> missing
		replace tmin = . if missing(tmax) // affects 2.510 observations

*********************
// Save the raw but cleaned weather station data
// This should be a baseline if different geographic entitites (such as MSA are used later)
*********************
save Weather_Stations_Clean.dta, replace


************************
// 2. Merge with Location Data
************************
	// Merge with reverse-geocoded location data
	// For this data, the coordinates of the stations have been used to find their respective counties(cities/towns in Virginia)
	merge m:1 station using station_data.dta, keepusing(county state)
	
	
************************
// 3. Collapse to County-Day-Observations
************************
	// mean ignores missings, and only computes the mean of non-missing observations
	collapse (mean) prcp snow tmax tmin tvag, by(state county day_year)
	
	// rename county to Area_Name for merge
	rename county Area_Name
	
	
**************************************************************************
// 5. Weather-County-Dataset
**************************************************************************
	// Here, 2 & 4 are ignored. Rather working with the base-line version saved at the end of 1 some changes to county-names are executed before the merge
	drop _all

	// Import reverse geocoded data 
	import delimited "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\WIP\weather_data\geo_data_county.csv", varnames(1) 

	// Drop pythons list index
	drop v1
	
	
	************************
	// 5.a) Preliminary Work
	************************
		// Find errors -> e.g. no county/city/town data
		// For Entries not on this level the entry is the following "State: Statename" or "Country: USA"
		gen non_data = 1 if strpos(county, ":") != 0
		drop if non_data == 1 // 7 observations
		drop non_data
		
		// For consistency replace county names with upper letters only
		replace county = strupper(county)

	
	************************
	// 5.b) Merge Stations-Geo-Data with Weather Data and State Data
	************************
		// Merge location and weather station data
		// Since not all stations have entries, only those with entries later need to be merged with the dataset
		// This reduces the ammount of special cases we need to deal with
		
		// Merge with Weather Data
		merge 1:m station using Weather_Stations_Clean.dta, assert(1 3)
		// Assert 1 3 -> needs to match or be part of the master (e.g. deleted station due to lacking observations)
		
		// 15.503 are not matched from master - meaning, those stations have no weather data.
		drop if _merge == 1
		drop _merge		
		// From the original 1040 distinct counties, 997 remain - good cut!
		// -> 33 distinct areas without a county indicator!
		
		// Merge with original station data, this data includes the state indicator
		merge m:1 station using station_data.dta, assert(2 3)
		drop if _merge== 2 // same stations as above (merge == 1)
		drop _merge latitude longitude
		
	
	************************
	// 5.c) County Name - String adjustments
	************************	
		// Look for entries that are not a county
		gen non_county = 1 if strpos(county, "COUNTY") == 0 // 187 observations (44 distinct)

		// Only 3 States have entries that are not a county
		// non state only 1 in Colorado (0.5%), Waschington (4.3%) and Virginia (95.1%)
		// Checking is done State by State
		
		*************
		// COLORADO
		replace county = "YUMA" if non_county == 1 & state =="CO" // unincorportaed town, that is lcoated there
		replace non_county = . if state =="CO" & county =="YUMA"
		
		*************
		// WASCHINGTON
		replace county = "OKANOGAN" if state =="WA" & county == "OROVILLE"
		replace county = "OKANOGAN" if state =="WA" & county == "TWISP"
		replace non_county = . if state =="WA" & county =="OKANOGAN"
		
		*************
		// VIRGINIA
		// remove brackets from City entry
		// replace (CITY) with CITY
		replace county = subinstr(county, "(CITY)", "CITY", 1) if state == "VA" & non_county==1

		// case whise work
		replace county = "ALEXANDRIA CITY" if state =="VA" & county == "ALEXANDRIA"
		replace county = "BUENA VISTA CITY" if state =="VA" & county == "BUENA VISTA"
		replace county = "CHARLOTTESVILLE CITY" if state =="VA" & county == "CHARLOTTESVILLE"
		replace county = "CHESAPEAKE CITY" if state =="VA" & county == "CHESAPEAKE"
		replace county = "DANVILLE CITY" if state =="VA" & county == "DANVILLE"
		replace county = "EMPORIA CITY" if state =="VA" & county == "EMPORIA"
		replace county = "FREDERICKSBURG CITY" if state =="VA" & county == "FREDERICKSBURG"
		replace county = "GALAX CITY" if state =="VA" & county == "GALAX"
		replace county = "HAMPTON CITY" if state =="VA" & county == "HAMPTON"
		replace county = "HOPEWELL CITY" if state =="VA" & county == "HOPEWELL"
		replace county = "LEXINGTON CITY" if state =="VA" & county == "LEXINGTON"
		replace county = "MANASSAS CITY" if state =="VA" & county == "MANASSAS"
		replace county = "NEWPORT NEWS CITY" if state =="VA" & county == "NEWPORT NEWS"
		replace county = "NORFOLK CITY" if state =="VA" & county == "NORFOLK"
		replace county = "PETERSBURG CITY" if state =="VA" & county == "PETERSBURG"
		replace county = "POQUOSON CITY" if state =="VA" & county == "POQUOSON"
		replace county = "PORTSMOUTH CITY" if state =="VA" & county == "PORTSMOUTH"
		replace county = "STAUNTON CITY" if state =="VA" & county == "STAUNTON"
		replace county = "SUFFOLK CITY" if state =="VA" & county == "SUFFOLK"
		replace county = "VIRGINIA BEACH CITY" if state =="VA" & county == "VIRGINIA BEACH"
		replace county = "WAYNESBORO CITY" if state =="VA" & county == "WAYNESBORO"
		replace county = "CHESAPEAKE CITY" if state =="VA" & county == "CHESAPEAKE"
		replace county = "WINCHESTER CITY" if state =="VA" & county == "WINCHESTER"

		// Drop non-county indicator
		drop non_county
		
		// Replacing String to match other datasets
		// rename county variable
		rename county Area_Name
		
		// remove "county" from the entries only leaving the actual name
		replace Area_Name = subinstr(Area_Name, "COUNTY", "", .)		

		// change saint to its short form
		replace Area_Name = subinstr(Area_Name, "SAINT", "ST", .)
		
		// clean broomfield, as it has some string attached to it
		replace Area_Name = "BROOMFIELD" if strpos(Area_Name, "BROOMFIELD") != 0
		
		// Trim the string of leading/lagging spaces
		replace Area_Name = strtrim(Area_Name)
		

		*********************
		// Save the now cleaned and merged weather station data
		*********************
		save weather_county_merged.dta, replace
		
		
	************************
	// 5.d) Collapsing Data
	************************
		// drop unused variables
		drop geom station

		// collapse to day-county observations
		collapse (mean) prcp snow tmax tmin, by(Area_Name state day_year)	
		// reduces by about 1.000 obs (from 515.000) !!! NOT true anymore get new number

		*********************
		// Save the finalized data
		*********************
		save weather_county_day.dta, replace

		// Note:
		// RONAOKE and RICHMOND are both as CITY and (not) in the data, so hard to judge 
		 
