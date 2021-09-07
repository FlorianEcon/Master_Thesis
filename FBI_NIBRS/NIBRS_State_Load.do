************************
// NIBRS_State_Load
************************
/*
    Created on 25.3.2021
    @author: Florian Fickler
    Goal:
        1. Load NIBRS data for each state
			1.a) This means, loading in different subsets of data and merging them to a state-dataset
		2. Adjust entries
		3. Merge State-Data to a NIBRS dataset
*/

clear all
***************
// LOAD Data //
***************

// Set up local with Prostalcodes of States wantes (here share >= 80%)
local postal `"AR MA OK OH WA CT CO SD MT ND RI NC ID OR KS MI VT NH WV IA KY SC TN VA"'

foreach state in `postal'{
    // set cd for each state's data
	cd "C:/Users/Flori/OneDrive/Desktop/Uni/Emma/NIBRS_State/`state'-2019/`state'"
	drop _all
	// import agency file
	import delimited "agencies.csv"
	// Drop unused Vars
	keep agency_id ncic_agency_name state_postal_abbr population pedmale_officerpedmale_civilian  pedfemale_civilianpedfemale_offi county_name msa_name ucr_agency_name agency_type_name

	//might drop agency name later - use here to check
	
	// Create a police force variable from the female and male variables
	gen policeforce = pedmale_officerpedmale_civilian + pedfemale_civilianpedfemale_offi
	drop pedfemale_civilianpedfemale_offi pedmale_officerpedmale_civilian
	//reame Population such that it later can be compared to population on a county level
	rename population agency_population
	rename county_name county
	rename state_postal_abbr state
	rename msa_name msa
	
	// replace missing agency names with ucr names
	replace ncic_agency_name = ucr_agency_name if missing(ncic_agency_name)
	drop ucr_agency_name
	
	// save agency data
	save "agencies_dta.dta", replace
	drop _all
	
	// load in incident data
	import delimited "NIBRS_incident.csv"
	
	// drop unused vars
	keep agency_id incident_id incident_date incident_hour
	
	// extract day and month from date
	gen day = substr(incident_date, 1, 2)
	gen month = substr(incident_date, 4, 3)
	
	// Change string month to number
	local i=1
	foreach m in `c(Mons)' {
		replace month = "`i'" if month == upper("`m'")
		local ++i
	}
	//destring
	destring month, replace
	destring day, replace
	drop incident_date
	
	save "NIBRS_incident_data.dta", replace
	drop _all
	
	// load in offense data
	import delimited "NIBRS_OFFENSE.csv"
	
	//drop unused vars
	keep incident_id offense_type_id location_id  method_entry_code

	// Data adjustmends
	***************
	// Attempt_Complete_Flag Dummy
	//rename attempt_complete_flag successfull
	//replace successfull = "1" if successfull == "C"
	//replace successfull = "0" if successfull == "A"
	//destring successfull, replace
	//label define successfull 1 "Complete" 0 "Attempt" // move this and add it
		
	// Entry Method
	//replace method_entry_code = "1" if method_entry_code == "F"
	//replace method_entry_code = "0" if method_entry_code == "N"
	//destring method_entry_code, replace
	//rename method_entry_code  forced_entry
	
	***************
	// Location Type

	// Residence Crime
	gen location_residence = 0
	replace location_residence = 1 if location_id == 20 // residence/home
	label var location_residence "Incident Location - Residence"
	
	/* Currently only residential in use
	// Outdoor
	gen location_outdoor = 0
	replace location_outdoor = 1 if inlist(location_id, 10,13,16,18, 31,38,39)
	label var location_outdoor "Incident Location - Outdoor-Streets"
	
	// Other Educ Public (and missing)
	gen location_other = 0
	replace location_other = 1 if inlist(location_id, 0,6,25,26,42,44,47, 11,15,22,32,37,40,41,45,4) | missing(location_id)
	label var location_other "Incident Location - Other-Public-Educ"
	
	// Comerical
	gen location_commerical = 0
	replace location_commerical = 1 if !inlist(location_id, 11,15,22,32,37,40,41,45,4, 0,6,25,26,42,44,47, 10,13,16,18, 31,38,39, 20)
	label var location_commerical "Incident Location - Comerical"
	*/
	***************
	// Offense Type

	// Violent Crimes
	gen Offense_AA = 0
	replace Offense_AA = 1 if offense_type_id == 27
	label var Offense_AA "Aggrevated Assault"

	gen Offense_Murder = 0
	replace Offense_Murder = 1 if offense_type_id == 32
	label var Offense_Murder "Murder and Nonnegligens Manslauter"

	gen Offense_Rape = 0
	replace Offense_Rape = 1 if offense_type_id == 36
	label var Offense_Rape "Rape"

	gen Offense_Robbery = 0
	replace Offense_Robbery = 1 if offense_type_id == 40
	label var Offense_Robbery "Robbery"

	// Property Crimes (w/o Arson)
	gen Offense_Burglary = 0
	replace Offense_Burglary = 1 if offense_type_id == 49
	label var Offense_Burglary "Burgerly"

	gen Offense_Larcency = 0
	replace Offense_Larcency = 1 if inlist(offense_type_id, 58,7,13,14,18,23,45,47,50)
	label var Offense_Larcency "Larcency/Theft Offenses"

	gen Offense_MVT = 0
	replace Offense_MVT = 1 if offense_type_id == 21
	label var Offense_MVT "Motor Vehicle Theft"


	// Aggregate Dummies
	gen Offense_FBI_Violent = 0
	replace Offense_FBI_Violent = 1 if inlist(offense_type_id, 27,32,36,40)
	label var Offense_FBI_Violent "Violent Crimes - FBI Definition"

	gen Offense_FBI_Property = 0
	replace Offense_FBI_Property = 1 if inlist(offense_type_id, 49,21,58,7,13,14,18,23,45,47,50)
	label var Offense_FBI_Property "Property Crimes - FBI Definition"


	// drop other incidents - not used for the analysis
	drop if Offense_FBI_Property == 0 & Offense_FBI_Violent == 0
	drop offense_type_id
	
	save "NIBRS_OFFENSE_data.dta", replace
	
	//Merge Offense and Incident Data
	// merge has to be m:1 as there can be more than one offense related to an incident
	merge m:1 incident_id using "NIBRS_incident_data.dta", gen(offense_indicent_merge) assert(2 3)
	// assert checks, that all offenses are matched with incidents
	// it is allowed, that incidents have no offenses (dropped in the offenese data)
	// those observations are now dropped
	drop if offense_indicent_merge == 2
	drop offense_indicent_merge
	
	// save Incident_Offense Data
	save "NIBRS_IO_Data.dta", replace
	drop _all
	
	// Load in Property Data	
	import delimited "NIBRS_PROPERTY.csv"
	
	// drop unused vars
	keep property_id incident_id prop_loss_id
	
	// only keep obs where something was stolen 7 = stolen/etc
	keep if prop_loss_id == 7
	drop prop_loss_id
	
	//save Property data
	save "NIBRS_Property_data.dta", replace
	drop _all
	
	// load in property value data
	import delimited "NIBRS_PROPERTY_DESC.csv"
	
	// drop unused vars
	keep property_id property_value
	
	//drop if no value is included
	drop if missing(property_value)
	
	// collapse the datasat over property id
	// create one observation for each property_id with the total value stolen
	collapse (sum) property_value, by(property_id)
	
	save "NIBRS_Property_Value_data.dta", replace
	merge 1:1 property_id using "NIBRS_Property_data.dta", gen(Property_Value_merge)
	// Here assert checks if matched or in master, master meaning, that there is no property entry for the value, which means, that it wasn't stolen/etc but rather destroyed, burned or recovered or similar
	drop if Property_Value_merge == 1
	drop if Property_Value_merge == 2
	drop Property_Value_merge
	
	
	drop property_id
	save "NIBRS_PV_data.dta", replace
	
	
	// merge Property Data with INcident-Offense Data
	// doing 1:m now, as incident_id is not unique (multiple offense for one id, )
	merge 1:m incident_id using "NIBRS_IO_Data.dta", gen(Incident_Property_merge)
	// assert not needed as all three can be possible
	// only master - stolen but not one of the federal crimes
	// only using - federal crime but no property
	// matched - both
	// drop if value but not federal crime
	drop if Incident_Property_merge == 1 
	drop Incident_Property_merge
	
	// save incident offense property data
	save "NIBRS_IOP_data", replace
	
	// merge with agencie information
	// merging m:1 as many incidents can occur at one agency
	merge m:1 agency_id using "agencies_dta.dta", gen(Incident_Agency_merge) assert(2 3)
	
	save "C:/Users/Flori/OneDrive/Desktop/Uni/Emma/Dataset/Intermediate Files/NIBRS_State/NIBRS_`state'.dta", replace
	drop _all
}

// local might need to be redefined if working only in this part of the code or create a (sub-)set with different states
local postal `"AR MA OK OH WA CT CO SD MT ND RI NC ID OR KS MI VT NH WV IA KY SC TN VA"'
// loop through all used states and append
foreach file in `postal'{
	
	append using "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\NIBRS_State\NIBRS_`file'.dta"
}
**************************
// Change cd to Data-Folder for NIBRS
cd "C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\Intermediate Files\NIBRS_Data"
// Save Final dataset
save NIBRS_DATA_raw.dta, replace
**************************

*********************
// Generate a smaler Dataset
// Including daily entries per crime
// by county, day, month

// Collapse Main dataset
*********************
// first some other utilities

// gen a dummy = 1 to count number of collapsed observations
gen crimes_number = Offense_FBI_Property + Offense_FBI_Violent

// drop observations with missing crimes_number
// mostly agencies with crimes that are not part of this work
// e.g. Park Ranger, DEA, School Police, Natural Ressources; State Police; Transport Police
drop if missing(crimes_number) // 577 Observations


// generate a daytime dummy for each crime
foreach var in AA Murder Rape Robbery Burglary Larcency MVT {
	gen daytime_crime_`var' = 0
	replace daytime_crime_`var'  = 1 if inrange(incident_hour, 5,17) & Offense_`var' == 1
}


// generate a residential dummy for each crime
foreach var in AA Murder Rape Robbery Burglary Larcency MVT {
	gen residential_`var' = 0
	replace residential_`var'  = 1 if location_residence == 1 & Offense_`var' == 1
}

// Collapse to a single day-month-agency-observation
// First collapse using agency_population and policeforce as groups
// This keeps these variables, and basically creates one observation per agency
collapse (sum) crimes_number property_value location_residence Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property daytime_crime* residential_*, by(day month state county msa  agency_population policeforce)

// Now collapse such that for each day/month/county we have one observation
// This second collapse also sums up the agency_population and policeforce.
// The first collapse is needed, cause o.w. one agency can have multiple entries within a day, and its pop/force would be counted multiple times
collapse (sum) crimes_number property_value location_residence Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property daytime_crime* residential_* agency_population policeforce, by(day month state county msa)


// Rescale the variables
replace property_value = property_value / Offense_FBI_Property if Offense_FBI_Property != 0
label variable property_value "average property stolen in a property crime"


// split the msa variable into the name and the states
// first split multiple msa
split msa, parse(";")

foreach var in msa1 msa2 {
    split `var', parse(",")
	drop `var'
}
// replace msa only with the msa names
replace msa = msa11
replace msa = msa11 + "; " + msa21 if !missing(msa21)

// generate a new variable giving the respective states to the msa names
gen msa_state = msa12
replace msa_state = msa12 + "; " + msa22 if !missing(msa22)

// dummy indicating if an agency has multiple msa's
gen multi_msa = 0
replace  multi_msa = 1 if !missing(msa22)

drop msa11 msa12 msa21 msa22

// multi state MSA
gen multi_state_msa = 0
replace  multi_state_msa = 1 if strpos(msa_state, "-") != 0


// multi county dummy
gen multi_county = 0
replace  multi_county = 1 if strpos(county, ";") != 0

******************
// Order Dataset and create empty split vars
******************
// Split Variables
foreach var in CRIMES AGENCY_INFOS{
	gen `var' = .
}

// rename some variables for merging
rename county Area_Name
replace Area_Name = strtrim(Area_Name)

// Therea are obseravtions with a missing Area_Name entry
// Those observations are mostly tribal or state-police, as well as HWY_Patrol, Ariport/University Police or Capitol Police
// In total they encompass 10193 crimes in 2019 (0.0043%)
drop if missing(Area_Name)

// create a unique identifier for each NIBRS obs based on its county state
egen id_NIBRS = group(Area_Name state)

// order the data in the a meaningful way
order id_NIBRS state Area_Name multi_county msa msa_state multi_msa multi_state_msa day month CRIMES crimes_number location_residence Offense_FBI_Violent Offense_FBI_Property property_value Offense_AA daytime_crime_AA residential_AA Offense_Murder daytime_crime_Murder residential_Murder Offense_Rape daytime_crime_Rape residential_Rape Offense_Robbery daytime_crime_Robbery residential_Robbery Offense_Burglary daytime_crime_Burglary residential_Burglary Offense_Larcency daytime_crime_Larcency residential_Larcency Offense_MVT daytime_crime_MVT residential_MVT AGENCY_INFOS agency_population policeforce

**************************
// Save final Dataset
save C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\NIBRS_State_Data.dta, replace
**************************


/*
OLD Version:
Here I matched by agency, rather than county. This gives more observations and potentially would allow to use agency FE, however matching by county is much harder (as it does not uniquely identify and observation). To Circumvent m:m merging, I opted for the county level aggregation

*********************
// Generate a smaler Dataset
// Including daily entries per crime
// by agency, day, month


// keep old dataset in memory
preserve

// Generate a Dataset containing only the agency
drop property_value incident_id location_id forced_entry location_residence location_outdoor location_other location_commerical Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property incident_hour day month Incident_Agency_merge public_holiday day_of_week week weekend free_day

// drop duplicates
duplicates drop // leaves one observation per agency

**************************
// Save agency Data
save NIBRS_Data_agencies.dta, replace
**************************

// Restore old dataset with Crime Data
restore

// Collapse Main dataset
// first some other utilities

// gen a dummy = 1 to count number of collapsed observations
gen crimes_number = 1
// gen obs with property value
gen prop_obs = 0
replace prop_obs = 1 if property_value != .

// generate a daytime dummy for each crime
foreach var in AA Murder Rape Robbery Burglary Larcency MVT {
	gen daytime_crime_`var' = 0
	replace daytime_crime_`var'  = 1 if inrange(incident_hour, 8,18) & Offense_`var' == 1
}

// Collapse to a single day-month-agency- observation
collapse (sum) crimes_number prop_obs property_value location_residence location_outdoor location_other location_commerical Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property daytime_crime*, by(agency_id day month)

// Rescale the variables
replace property_value = property_value / prop_obs if prop_obs != 0
label variable property_value "average property stolen in a property crime"
drop prop_obs

// relative number of crimes at night as a share of crimes in the same offense category
foreach var in AA Murder Rape Robbery Burglary Larcency MVT {
	replace daytime_crime_`var'  = daytime_crime_`var' /  Offense_`var' if Offense_`var' != 0
}

// Agencies that did n ot report any crime
replace crimes_number = 0 if missing(day)



**************************
// Merge again with Agency Data
**************************

merge m:1 agency_id using NIBRS_Data_agencies.dta, nogen assert(3)
// asserts that all observations are matched

// split the msa variable into the name and the states
// first split multiple msa
split msa, parse(";")

foreach var in msa1 msa2 {
    split `var', parse(",")
	drop `var'
}
// replace msa only with the msa names
replace msa = msa11
replace msa = msa11 + "; " + msa21 if !missing(msa21)

// generate a new variable giving the respective states to the msa names
gen msa_state = msa12
replace msa_state = msa12 + "; " + msa22 if !missing(msa22)

// dummy indicating if an agency has multiple msa's
gen muli_msa = 1 if !missing(msa22)

drop msa11 msa12 msa21 msa22
******************
// Order Dataset and create empty split vars
******************
// Split Variables
foreach var in CRIMES CRIMES_CHARACTERISTICS AGENCY_INFOS{
	gen `var' = .
}

// rename some variables for convienence
rename (ncic_agency_name agency_type_name county) (agency_name agency_type Area_Name)

// order the data in the a meaningful way
order agency_id state Area_Name msa msa_state muli_msa day month CRIMES crimes_number Offense_AA Offense_Murder Offense_Rape Offense_Robbery Offense_Burglary Offense_Larcency Offense_MVT Offense_FBI_Violent Offense_FBI_Property CRIMES_CHARACTERISTICS location_residence location_outdoor location_other location_commerical daytime_crime_AA daytime_crime_Murder daytime_crime_Rape daytime_crime_Robbery daytime_crime_Burglary daytime_crime_Larcency daytime_crime_MVT property_value AGENCY_INFOS agency_name agency_type agency_population policeforce

**************************
// Save final Dataset
save C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\NIBRS_State_Data.dta, replace
**************************











