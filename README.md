# Master_Thesis

In this repository I will publish all cde related to my master thesis in economics at the University of Mannheim.

In my thesis, I'm matching criminal, movement and census data on the county level to analyse the effect that changes in movement have on criminal activity through the in the literature named "opportunity chanel".

# Goal
The files in this repository create different files, which taken together allow to analyse the different aspects and interactions between movement and criminal patterns on a daily level.
While Python is used for many crude computations and web-based services such as accessing different API's, the econometric analysis is done in STATA.

# Data Structure

For now, the folders are all seperate and produce their own "final" versions of the respective file. The folder "Analysis" will then merge them and include a file to run regressions.
A main-file to run the different Stata-codes at once will be provided in the future.

## Note
- Files are still subject to change!
- Some documentation and coments are still missing in FBI-NIBRS
- Files in Analysis are not yet finished and the folder should only be seen as a work in progress

## FBI UCR
Accessing, downloading and transforming data from the FBI's UCR API.
This data covers yearly and monthly crimes based on the UCR reporting system.
Further, data on each agency, such as employment numbers and the amount of population covered by an agency are included

For more information and data see the following link:
https://crime-data-explorer.fr.cloud.gov/pages/docApi

## FBI NIBRS
As the UCR, NIBRS provides criminal statistics on an agency level. The advantage of NIBRS is however, that each criminal offense has it's own entry.
This allows to create a daily dataset indicating the number of crimes that happened within an agency including their time and location_id (e.g. residential)

For more information and data the link provided above

## NOOA
This data includes daily weather data for each weather station in the USA as reported in the "daily-summaries" file provided by NOOA
The steations are then matched to their respective counties by reverse geocoding

For more information see the following link:
https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation

## ACS
The American Community Survey as a product of the US-Census and provides several socio-economic indicators on different geographical levels throughout the USA.
In the following, I concentrate both on County and MSA level data.

For more information and data see the following link:
https://www.census.gov/programs-surveys/acs/data.html

## Trips Data
The Maryland Institute of Technology provides trips data. This data is publicly available through the Bereau of Transportation statistics.
This data is available daily and on County level.

For more information and data see the following link:
https://data.bts.gov/Research-and-Statistics/Trips-by-Distance/w96p-f2qv


## LAUS
The local area unemployment statistics provided by the BLS are a supplementary data source which might end up connecting movement patterns to local unemployment levels.
LAUS includes county level monthly unemployment rates. To obtain the final dataset, their website offers a code-list which allows the matching of their time-series IDs to their respective area (county)

For more information and data see the following link:
https://www.bls.gov/lau/lausad.htm
