**************
/// LAUS Data Transform
*************
/*
    Created on 25.5.2021
    @author: Florian Fickler
    Goal:
        1. Clean LAUS data
		2. Merge Laus Data to is Area (county)

    To-Do for it to run:
        set working directory (line 16)
*/

	// Set working directory
	cd  "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\WIP\"

	// have to get rid of a lot of string here
	// id needs to be timmed down to area-code and series id;
	// all entries need to get rid of theri (T) entries indicating that they have changed since they got entered in the system
	// then destring
	

************************
// 1. Clean Raw LAUS Data
************************
	// Import Data
	import delimited "LAUS_DATEN.txt", varnames(1) 

	
	************************
	// 1.a) Preliminary Work
	************************
		// Remove "(T)" from each observation
		// (T) indicates, that data has changed since it was first published by the BLS, this is true for !every! entry here.
		foreach var of varlist jan2019 feb2019 mar2019 apr2019 may2019 jun2019 jul2019 aug2019 sep2019 oct2019 nov2019 dec2019 {		
			replace `var' = subinstr(`var', "(T)", "", .)
			
			// destring the variable to numeric
			destring `var', replace
		}
	
	************************
	// 1.b) Extracting Unemployment Rates
	************************
		// All seriesid's have a lengths of 20
		// gen id_len =  strlen(seriesid) - CHECK all are 20 chars long
		
		// The seriesid for UER ends on 3 by convention
		// Identify those series and remove others

		// look for the 3 at the end of the string
		// Gives position of the last time the number 3 was found
		gen UER_3 = ustrrpos(seriesid,"3")

		// drop all series for which this is not the 20th entry
		drop if UER_3 != 20
		drop UER_3

		// Rename Variables to UER
		rename (jan2019 feb2019 mar2019 apr2019 may2019 jun2019 jul2019 aug2019 sep2019 oct2019 nov2019 dec2019) (UER1 UER2 UER3 UER4 UER5 UER6 UER7 UER8 UER9 UER10 UER11 UER12)
	
************************
// 2. Merge with Area data
************************
	************************
	// 2.a) Prepare seriesid for merge
	************************
		// Each seriesid starts with an indicator for the LAUS dataset "LAU" -> remove indicator
		replace seriesid = subinstr(seriesid, "LAU", "", 1)
		
		// As mentioned above, the end of the id indicates the variable (e.g UER)
		// The area seriesid is contained in the first 15 characters of the string
		gen area_code =  substr(seriesid,1,15)

	************************
	// 2.b) Merge
	************************
		// merge with area codes
		merge m:1 area_code using "Laus_areacodes.dta"

		drop if _merge != 3 // only 1 observation from PA
		
		// drop unused variables
		drop _merge seriesid area_code
	
	
************************
// 3. Prepare LAUS-Area-Data
************************
	// Extract County-Name and State-Name
	// split area text in area name und state
	split area_text, parse(",")
	drop area_text
	
	rename (area_text1 area_text2) (Area_Name state)

	// Adjust some Entries
	// here also has County/city entries
	replace Area_Name = subinstr(Area_Name, "County/city", "", .)
	replace Area_Name = subinstr(Area_Name, "County/town", "", .)
	replace Area_Name = subinstr(Area_Name, "County", "", .)
	replace Area_Name = subinstr(Area_Name, ".", "", .)

	// Trim the string of leading/lagging spaces
	replace Area_Name = strtrim(Area_Name)
	replace state = strtrim(state)

	// Replace with only capital leters
	replace Area_Name = strupper(Area_Name)

	// Reshape Data to month-County observations
	// reshape from wide to long
	reshape long UER, i(Area_Name state) j(month)

	rename UER UER_month

	*********************
	// Save the finalized data
	*********************
	save Laus_Month.dta, replace

