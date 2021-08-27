'''
    Created: 24.8.2021
    Name: Contour Plot Graph
    Author: Florian Fickler
    Goal:
            Make some neat Graphs for the Data section of the Paper
            Including:
                Contour plot for Crime within each State(or County if possible)
                Contour plot for Trips? - coudl be in the same Graph as the one about crimes

'''
######################
# Import Packages
######################
import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np


# Set working directory:
os.chdir(r"C:\Users\Flori\OneDrive\Desktop\Uni\Emma\Dataset\graphs\Contour")


########################
### Contour Plot    ####
########################
# Import Data
data = pd.read_csv('contour_data_CSV.csv')

# Create arrays with lenght 24 (states) and 12(month)
Y = np.linspace(1, 24, 24)
X = np.linspace(1, 12, 12)

# Transform both into a meshgrid
X, Y = np.meshgrid(X, Y)


# First Only for Total Crimes
# pivot data to generate 1 row for each state - change values for different plots
Z_total = data.pivot(index='state_id', columns='month', values='crimes_number')

# Sort Data so that the lowest values in January are at the front
# Only for total crimes!
Z_total = Z_total.sort_values(by=1)

# Get Index from df for Crime_number
state_index = Z_total.index.tolist()

# Parse into a dict that has the order has value and the index as key
sorterIndex = dict(zip(state_index, range(len(state_index))))
# Sorter Index can be used to sort later dataframes in the same way


# Define List for all Crimes for which Plots are made
crime_list = ['crimes_number', 'location_residence', 'crimes_daytime',
              'Offense_FBI_Property', 'Offense_FBI_Violent', 'Offense_AA',
              'Offense_Murder', 'Offense_Rape', 'Offense_Robbery',
              'Offense_Larcency', 'Offense_Burglary', 'Offense_MVT']


# For loop for all crimes
for crime in crime_list:
    Z = data.pivot(index='state_id', columns='month', values=crime)

    # Map dictionary to Data and then sort by data
    Z['New Index'] = Z.index.map(sorterIndex)

    # Sort by Index and drop Index
    Z.sort_values('New Index', inplace=True)
    Z.drop('New Index', 1, inplace=True)

    # Create figure and add axis
    fig = plt.figure()
    ax = plt.subplot(111, projection='3d')

    # Plot Contourplot
    plot = ax.plot_surface(X=X, Y=Y, Z=Z, cmap='cividis', alpha=0.95)

    # Set a uniform angle to view from
    ax.view_init(elev=20, azim=-130)
    ax.dist = 10

    # Set Axis Label
    ax.set_xlabel(r'Month', labelpad=15)
    ax.set_ylabel(r'State', labelpad=15)

    # Save and show figure
    plt.savefig(crime + '.png', dpi=100, bbox_inches='tight')
#    plt.show()
