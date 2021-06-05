# Master_Thesis

In this repository I will publish all cde related to my master thesis in economics at the University of Mannheim.

In my thesis, I'm matching criminal, movement and census data on the county level to analyse the effect that changes in movement have on criminal activity through the in the literature named "opportunity chanel".

# Goal
The files in this repository create different files, which taken together allow to analyse the different aspects and interactions between movement and criminal patterns on a daily level.
While Python is used for many crude computations and web-based services such as accessing different API's, the econometric analysis is done in STATA.

# Data Structure

## FBI UCR
Accessing, downloading and transforming data from the FBI's UCR API.
This data covers yearly and monthly crimes based on the UCR reporting system.
Further, data on each agency, such as employment numbers and the amount of population covered by an agency are included

For more information see the following link:
https://crime-data-explorer.fr.cloud.gov/pages/docApi

## NOOA
This data includes daily weather data for each weather station in the USA as reported in the "daily-summaries" file provided by NOOA
The steations are then matched to their respective counties by reverse geocoding

For more information see the following link:
https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation

## ACS
The American Community Survey as a product of the US-Census and provides several socio-economic indicators on different geographical levels throughout the USA.
In the following, I concentrate both on County and MSA level data.

For more information see the following link:
https://www.census.gov/programs-surveys/acs/data.html

## Trips Data
The Maryland Institute of Technology provides trips data. This data is publicly available through the Bereau of Transportation statistics.
This data is available daily and on County level.

For more information see the following link:
https://data.bts.gov/Research-and-Statistics/Trips-by-Distance/w96p-f2qv
