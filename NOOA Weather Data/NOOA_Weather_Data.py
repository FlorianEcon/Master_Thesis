# -*- coding: utf-8 -*-
"""
    Created on 20.5.2021
    @author: Florian Fickler
    Goal:
        1. Downloading Weather Data via API for the following states:
            States: AR CO CT IA ID KS KY MA MI MT NC ND NH OH OK OR RI SC SD TN VA VT WA WV
        2. Saving total weather Data in 2019 by station #
        3. Using reverse-geocoding to transfer all Stations to their respective Counties
            a) If reverse geocoding does not provide county data (i.e. only city and state); access next larger data (state, country)
        4. Save as CSV

    To-Do for it to run:
        set working directory (line 34)
        set path with data (line 30 & 31)
"""

# Packages
import pandas as pd
import requests
from geopy.geocoders import Nominatim
from geopy.extra.rate_limiter import RateLimiter
import time
from copy import deepcopy
import os

# Obsolete packages
# import tqdm
# from tqdm._tqdm_notebook import tqdm_notebook
# import geopandas as gpd
# import geopy

# Set working directory:
    # Replace XXX and enter own directory
os.chdir(r"XXX")

# Set up the request url
# url1
# dataset defines the source of the data: daily-summaries
# dataTypes defines the variables downloaded from NOOA here: PRCP, SNOW, TMAX, TMIN, TVAG
url1 = "https://www.ncei.noaa.gov/access/services/data/v1?dataset=daily-summaries&dataTypes=PRCP,SNOW,TMAX,TMIN,TVAG&stations="
# url2
# start/end Date define the time range
# format the data format
# units the units of the downloaded data - here metric (o.w. imperial)
url2 = "&startDate=2019-01-01&endDate=2019-12-31&format=csv&units=metric"


# 1. Downloading Weather Station Data via API:
    # a) Get all Stations
        # This is already done seperately from the NOOA's website
        # -> read in csv
station_df = pd.read_csv(r".\stations_list.csv")

# Transform the stations data into a list
stations = station_df['station'].tolist()

# Initialize export
export = ""

# Loop through all stations
for i in range(len(stations)):
    # create an url for each station (they can also be downloaded in bulks, but data seems to have some inconsistency then)
    url = url1 + stations[i] + url2

    # Print station number to follow the program
    print(stations[i])

    # request object
    r_code = requests.get(url)

    # append the exported text into the export object
    export = export + r_code.text

# save climate data into csv
text_file = open(r'.\climatedata.csv', 'w')
text_file.write(export)
text_file.close()


#####
# Function to reverse geolocate the station
# Change user agent to use different services (e.g. google etc)

# Transform latitude and longitude into a coordinate
station_df['geom'] = station_df['latitude'].map(str) + ',' + station_df['longitude'].map(str)

# transfer them into a list of lists; thrid list only used as placeholder
listlist = station_df['geom'].tolist(), station_df['station'].tolist(), station_df['station'].tolist()

# Define Nominatim API from which to access information
locator = Nominatim(user_agent='myGeocoder')

# Loop through all ~30.000 station entries
for i in range(len(listlist[0])):
    # Print the current index with the station name and its location to keep track
    print(i, ': ', listlist[0][i], listlist[1][i])

    try:
        # Access the data via the locator function and access only the county value
        listlist[2][i] = locator.reverse(listlist[0][i]).raw['address']['county']
        # print the county entry to double check while running
        print(listlist[2][i])
        # short sleep timer, o.w. program might be blocked from server
        time.sleep(0.001)

    # Solve Key-Errors
    # Occur when no "county" entry exists
    except KeyError:
        # 1) try to get "town" data, only in Virginia (Townships are independent of a county)
        try:
            listlist[2][i] = locator.reverse(listlist[0][i]).raw['address']['town']
            print(listlist[2][i])
            time.sleep(0.001)
        except KeyError:
            # 2) try to get "city" data, only in Virginia (Cities are independent of a county)
            try:
                listlist[2][i] = locator.reverse(listlist[0][i]).raw['address']['city']
                print(listlist[2][i])
                time.sleep(0.001)
            except KeyError:
                # 3) If so far no result exists, the station usually is on water (great lakes, ocean)
                # 3.a) try "state" data (only for great lakes)
                try:
                    listlist[2][i] = locator.reverse(listlist[0][i]).raw['address']['state']
                    print(listlist[2][i])
                    time.sleep(0.001)
                except KeyError:
                    # 3.b) try "country" data (only for ocean)
                    listlist[2][i] = "COUNTRY: ", locator.reverse(listlist[0][i]).raw['address']['country']
                    print(listlist[2][i])
                    time.sleep(0.001)


# Transfer List of List into dataframe
loacation_df = pd.DataFrame(listlist).transpose()
loacation_df.columns = ['geom', 'station', 'county']

# Export CSV
loacation_df.to_csv(r'.\geo_data_county.csv')

#############
# Debugging #
#############
# During the download there might be some issues (now all shoudl be addressed by try-except)
# These usually have no entry that was looked for to extract its county

# Deebunging procedure:
    # 1) copy old data
    # 2) run the locator function on the coordinates that resolved in an error
    # 3) using station_loc, all data on this location is saved which is used to check its actual location
    # 4) Further:  check coordinates online (e.g. some stations are in the ocean and have therefore no county)

# Copy list if error occurs to save it while trying to solve it
first_list = deepcopy(listlist)

coordinates = '41.6833,-67.783302'
location = locator.reverse(coordinates)
location.raw

station_loc = location.raw
