************************
// BTS_Load
************************
/*
    Created on 15.3.2021
    @author: Florian Fickler
    Goal:
        1. Clean BTS-Trips data - County level
		2. Adjust data for merge with Area_Name on the county level

*/

// set cd
cd "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset"
use ".\Intermediate Files\BTS\BTS_Trips.dta"

// Only keep County Data
drop if level == "State"
drop level

// rename postal code variable
rename statepostalcode state


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

// adjust and rename county name variable
rename countyname Area_Name 
replace Area_Name = subinstr(Area_Name, "County", "", .)

// replace with upper case letters to match with FBI data
replace Area_Name = strupper(Area_Name)

// gen a popualtion coverage data
gen Population_BTS = populationstayingathome + populationnotstayingathome

// create a share for staying at home
replace populationstayingathome = populationstayingathome / Population_BTS
rename populationstayingathome PopulationAtHome
drop populationnotstayingathome

// rename the number of trips to trips
rename numberof* *

// generate additional statistics for trips
// trips per person
gen trips_pP = trips / Population_BTS

// mean trip-length (assuming uniform distribution and topcodingat 500)
gen trip_length_mean = 0.5*trips1 + 2*trips13 + 4*trips35 + 7.5*trips510 + 17.5*trips1025 + 37.5*trips2550 + 75*trips50100 + 175*trips100250 + 325*trips250500 + 500*trips500
replace trip_length_mean = trip_length_mean / trips

******************
// Order Dataset and create empty split vars
******************
// Split Variables
gen TRIPS = .

// order the data in the a meaningful way
order state Area_Name month day TRIPS Population_BTS PopulationAtHome  trips trips_pP trip_length_mean trips1 trips13 trips35 trips510 trips1025 trips2550 trips50100 trips100250 trips250500 trips500



******************
// Save dataset
******************
save BTS_Data.dta, replace