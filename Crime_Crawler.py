'''
Name: Crime_Crawler
Author: Florian Fickler
Purpose: Simple crawler to access the API set up by the FBI
Goal: Create summary statistics for each police Agency in the USA in 2019
To-Do for it to run: 
                         set working directory (line 19)
                        define api_key (line 26)
'''

######################
# Import Packages
######################
import requests
# import pandas as pd
import json
import os

# Set working directory key:
    # Replace XXX and enter own directory !
os.chdir(r"XXX")


######################
# Set-Up
######################
# Set API
api = "https://api.usa.gov/crime/fbi/sapi/api/"

# Set API key:
    # Replace XXX and enter own API key!
api_key = "?API_KEY="

# Find national statstics under the following link
# National statistics are used to compare data and check consitency
# view-source:https://api.usa.gov/crime/fbi/sapi/api/participation/national?api_key=RL2ibVnF8avidfQfAWrtS5I6OMbphWan2bjmxY23


######################
# Building a 2 layer dict with Agency information and an ORI-code List
######################
# create a List with all ORI-codes, those are needed later for the API requests
# Ori's are unique identification codes for each agency

def get_oris():
    # Construct URL for Request
    url_agency = api + "agencies" + api_key

    # Make request and convert to json for access
    agencies_info = requests.get(url_agency).json()

    # Create a List with Ori_codes, to loop through for later URL's
    ori_codes = []
    for l1, l2 in agencies_info.items():
        for l2, l3 in l2.items():
            for key, info in l3.items():
                if key == 'ori':
                    ori_codes.append(info)

    # Take second and third layer of dict for agency iformation
    #  {ori : {vars : values}}
    data = {}
    for l1, l2 in agencies_info.items():
        for l2, l3 in l2.items():
            data.update({l2: l3})
    return ori_codes, data


# Execute oris funtction, to get List with ORI codes and Dict with summary data for all agencies
ori_codes, data_agency = get_oris()
# Data Structure of data_agency:
# {ori: {var : value}}
# Data Structure of ori_codes
# List


######################
# Getting Summary Information about Crimes in 2019 for each Agency
######################

def crime_year():
    crime_dict = {}
    for j in range(len(ori_codes)):
        # for j in range(10):  # For testing purpose with limited number of agencies
        # Create URL
        url_summary = api + "summarized/agencies/" + ori_codes[j] + "/offenses/2019/2019" + api_key

        # Download data for each agency
        r_code = requests.get(url_summary).json()

        # Initialize Offense dictionary
        offenses = {}

        # Loop through all entries of of crimes in each dict (varying length)
        for i in range(len(r_code['results'])):
            # Extract the following information: crime name, number of cases, and cleared cases
            crime_name = r_code['results'][i].get('offense')
            crime_actual = r_code['results'][i].get('actual')
            crime_cleared = r_code['results'][i].get('cleared')

            # Calculate the share of cleared; -2 as code for no actual cases and as divide by zero exemtpion
            if crime_actual == 0:
                clearance_rate = -2
            else:
                clearance_rate = crime_cleared / crime_actual

            # Update offense dict with data
            offenses.update({crime_name + "_actual_2019": crime_actual, crime_name + "_cleared_2019": clearance_rate, crime_name + "_clearingRate_2019": clearance_rate})

        # Update Crime Dict with offense dict
        crime_dict[ori_codes[j]] = offenses

    # Play sound when finished
    print('\007')
    return crime_dict


# Execute crime_year frunction to get data on actual cases and cleared cases for each crime in each agency.
data_crime_summary = crime_year()
# {ori: {crime : value_year}} -> This is all SRS DATA and does not contain any information from the new reporting system NIBRS!


######################
# Merge Function to merge two dicts with the same first layer (ORI-code) but different second layer (variables & values) without overwriting
######################

def merge(a, b, path=None):
    "merges b into a"
    if path is None:
        path = []
    for key in b:
        if key in a:
            if isinstance(a[key], dict) and isinstance(b[key], dict):
                merge(a[key], b[key], path + [str(key)])
            elif a[key] == b[key]:
                pass  # same leaf value
            else:
                raise Exception('Conflict at %s' % '.'.join(path + [str(key)]))
        else:
            a[key] = b[key]
    return a


# Merge Agency summary data and crime summary data for 2019 (latter might be usefull for a cross county yoy comparison, and to look clearing rate)
FBI_data = merge(data_agency, data_crime_summary)


######################
# Police Employment Data
######################

def police_emp():
    # Initalize employment dictionary
    emp_dict = {}

    for j in range(len(ori_codes)):

        # Not all Agencies report employment numbers
        # These will later be imputed as missing, for now just handle exception by printing out their numbers
        try:
            # Create URL
            url_summary = api + "police-employment/agencies/" + ori_codes[j] + "/2019/2019" + api_key
            # Download data for each agency
            r_code = requests.get(url_summary).json()

            l1 = r_code.get("results")
            emp_dict[ori_codes[j]] = l1[0]  # Zero accesses the results which contain the actual numbers

        except:
            print("Error for Ori: " + j)
            pass

    # Play sound when finished
    print('\007')
    return emp_dict


# Police employment
police_employment = police_emp()
# {ori: {employment : value}}

# Merge Police Data in Dataset
FBI_data = merge(FBI_data, police_employment)


######################
# Monthly Crime Data
######################

def month_crime():
    # Initalize monthly crime dictionary
    crimes_month_dict = {}

    for j in range(len(ori_codes)):
        # Create URL
        url_summary = api + "data/arrest/agencies/offense/" + ori_codes[j] + "/monthly/2019/2019" + api_key

        # Download data for each agency
        r_code = requests.get(url_summary).json()

        # Extract restults as List containing dictionaries with entries for each month
        # Note: Not all agencies report for all 12 month!
        l1 = r_code.get("results")

        # To obtain data only on Agencies that report for all month uncomment the following
        # Jump to next Ori Code if the Agency does not provide information for all month
        # if len(l1) != 12:
        #     continue

        # Initalize month dictionary
        month = {}
        for i in range(len(l1)):
            # Access each of the month to get the data (might do as dict-comprehension)
            # Define the month_id as the number of the month (1-12)
            month_id = l1[i].get("month_num")

            # Update the month dictionary with the associated crime data
            month.update({month_id: {"aggravated_assault": l1[i].get("aggravated_assault"),
                                     "burglary": l1[i].get('burglary'),
                                     "larceny": l1[i].get('larceny'),
                                     "motor_vehicle_theft": l1[i].get('mvt'),
                                     "murder": l1[i].get('murder'),
                                     "rape": l1[i].get('rape'),
                                     "robbery": l1[i].get('robbery'),
                                     "simple_assault": l1[i].get('simple_assault'),
                                     "stolen_property": l1[i].get('stolen_property')}})

        # Insert the month data dictionary into the crimes_month dictionary with its associated ORI code
        crimes_month_dict[ori_codes[j]] = month

    # Play sound when finished
    print("\007")
    return crimes_month_dict


# Execute Crime_year frunction to get data on actual cases and cleared cases for each crime in each agency.
crime_data_monthly = month_crime()
# {ori: {month: {crime: value_month}}}


'''  For now only a subset of crimes is extracted
    below is an extended version that could be implemented to extract more crimes:

                month.update({month_id: {"aggravated_assault": l1[i].get("aggravated_assault"),
                                     "arson": l1[i].get('arson'),
                                     "burglary": l1[i].get('burglary'),
                                     "drug_possesion": l1[i].get('drug_poss_subtotal'),
                                     "drug_sales": l1[i].get('drug_sales_subtotal'),
                                     "gambling": l1[i].get('g_t'),
                                     "larceny": l1[i].get('larceny'),
                                     "motor_vehicle_theft": l1[i].get('mvt'),
                                     "murder": l1[i].get('murder'),
                                     "prostitution": l1[i].get('prostitution'),
                                     "rape": l1[i].get('rape'),
                                     "robbery": l1[i].get('robbery'),
                                     "simple_assault": l1[i].get('simple_assault'),
                                     "stolen_property": l1[i].get('stolen_property'),
                                     "fraud": l1[i].get('fraud')}})
'''

# Currently merges via ORI-codes, one could also reshape the data to have fewer layers and then merge accordingly
FBI_data = merge(FBI_data, crime_data_monthly)

#######################
# Supplemental Data on Value of Stolen Goods
#######################

# def supp_values():
#     supplemental_dict = {}

#     # go through the ori codes and get the data
#     for j in range(len(ori_codes)):
#     # for j in range(10):  # test code
#         # Create URL
#         url = api + "data/supplemental/agency/" + ori_codes[j] + "/property_type/2019/2019" + api_key

#         # Download Data
#         r = requests.get(url).json()

#         # Get the results layer
#         l1 = r.get('results')

# Currently excluded

######################
# Agency Level - Population
######################

def agency_pop():
    # Initalize population dictionary
    pop_dict = {}

    for j in range(len(ori_codes)):
        # Create URL
        url_summary = api + "/participation/agencies/" + ori_codes[j] + api_key

        # Download data for each agency
        r_code = requests.get(url_summary).json()

        # Access results
        l1 = r_code.get("results")

        # initialize population dictionary for 2019
        pop_2019 = {}

        # Access  results and update pop_2019 dictionary
        pop_2019.update({"population": l1[0].get("population"),
                         "published": l1[0].get('published'),
                         "srs_submitting": l1[0].get('srs_submitting')})

        # Parse the population data into the population_dictionary under its associated ORI code
        pop_dict[ori_codes[j]] = pop_2019

    # Play sound when finished
    print('\007')
    return pop_dict


# Police employment
agency_population = agency_pop()
# {ori: {employment : value}}

# Merge Police Data in Dataset
FBI_data = merge(FBI_data, agency_population)


#############
# Utilities
# Save & load function
############

############
# Save Data

# Change Name to Current Content

# json = json.dumps(crime_data_monthly)
# f = open("crime_data_monthly.json", "w")
# f.write(json)
# f.close()

############
# Load in Data

# data_crime_summary = json.load(open('data_crime_summary.json', 'r'))
