# Opportunity makes a Thief
A geospatial analysis of criminal activity - Master Thesis

## Overview

This repository is complementary to my master thesis in economics at the University of Mannheim.
In the thesis, I revisit the structural unemployment model by Cantor and Land (1985) and propose a reevaluation of the two channels proposed through their respective mechanisms. Concentrating on the "opportunity channel," this repository includes additional information on the data used throughout the thesis. Moreover, both the code to create the county-level dataset, which we use for our estimation, and the code that contains the estimations themselves are included.

Throughout, two programs are used. The accessing of web-based services and most graphs are done in Python, whereas the econometric analysis, most tables, and the largest portion of the data cleaning are done in Stata.

## Folder Structure

Each folder contains the respective code and information on how to compute the basic version of its data source. Since I do not own the right to redistribute these data, the links from which they can be obtained are included in this readme. The "Analysis" folder then contains the code which combines all these sources to produce one dataset containing daily county-level observations. Additionally, the code for running the estimations and making the raw version of the tables are included here as well. Finally, in the folder "Graphics," the figures included in the papers and their required code are displayed.

## FBI UCR
I am accessing, downloading, and transforming data from the FBI's UCR API.
This data covers yearly and monthly crimes based on the UCR reporting system.
Further, data on each agency, such as employment numbers and the population covered by an agency, are included.
The UCR also provides us with valuable statistics regarding criminal activity within the USA.

For more information and the API used to download the data, see the following link:
https://crime-data-explorer.app.cloud.gov/pages/docApi

## FBI NIBRS
As the UCR, NIBRS provides criminal statistics on an agency level. NIBRS, however, has the advantage that each offense has its own entry, which includes the day and the time of the day the offense was committed in addition to a location code.
Using this dataset, we can create daily observations on an agency level, which we will, in a later step, match to the countries in which these agencies are active.

For more information and to download the data through the website rather than the API from above, see:
https://crime-data-explorer.app.cloud.gov/pages/downloads#nibrs-downloads

## LAUS
The Local Area Unemployment Statistics provided by the Bureau of Labor Statistics are used as a high-quality data source for monthly unemployment data on small geographical levels. To obtain the dataset we use, their website offers a code-list that allows the matching of their time-series IDs to their respective area, in our case, the county.

For more information and the data, see the following link:
https://www.bls.gov/lau/lausad.htm


## Trips Data
The Maryland Transportation Institute and Center for Advanced Transportation Technology Laboratory provides the TRIPS dataset together with the Bureau of Transportation Statistics. This is inferred from mobile device usage and calculates measures indicating the daily mobility behavior within a county. We use this dataset to extract the number of per person trips and the share of the population that stays at home. These variables are used to proxy the change in criminal opportunities through which the opportunity channel works.

For more information and the data, see the following link:
https://data.bts.gov/Research-and-Statistics/Trips-by-Distance/w96p-f2qv


## NOOA
This data includes daily weather data for each weather station in the USA as reported in the "daily-summaries" file provided by NOOA.
We then use a reverse geo-matching algorithm and use the coordinates provided for each of the stations to match them to their respective counties. Since stations are usually not active for all 365 days in the sample, we compute the average value of precipitation across all active stations within a county so that our final daily county-level observations have fewer missings.

For more information, see the following link:
https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation

## ACS
The American Community Survey is a product of the US Census and provides several socio-economic indicators on different geographical levels throughout the USA.
While we obtained county and MSA-level observations from the ACS, our later fixed effects approach does not allow us to include any of these measures as they lack any within variation. Nonetheless, we leave the data in the final dataset so that future research can quickly adapt our approach and might utilize such macro data if additional years become available for analysis.

For more information and data, see the following link:
https://www.census.gov/programs-surveys/acs/data.html
