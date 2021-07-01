'''
    Created: 1.7.2021
    Name: Data_Section_Graphs
    Author: Florian Fickler
    Goal:
            Make some neat Graphs for the Data section of the Paper
            Including:
                USA - Map with NIBRS shares and Sample indicator
                Contour plot for Crime within each State(or County if possible)
                Contour plot for Trips? - coudl be in the same Graph as the one about crimes

    To-Do for it to run:
                         set working directory (line 25)
                         define api_key (line 26)
'''

######################
# Import Packages
######################
import os
import pandas as pd
import plotly.graph_objects as go

# Set working directory:
os.chdir(r"C:\Users\Flori\OneDrive\Documents\GitHub\Crime-Data\Master_Thesis\Graphics")


########################
### NIBRS Share MAP ####
########################
# Would be nice to add Sample indicator to Graph

# Import data
data = pd.read_csv('Nibrs_Coverage.csv')#

# Change string to numeric and missing to "nan"
data["Share"] = pd.to_numeric(data["Share"])

# Create Graph with US-States and their Share in NIBRS participation
fig = go.Figure(data=go.Choropleth(
    locations=data['State-Code'],  # Spatial coordinates
    z=data['Share'],  # Data to be color-coded
    locationmode='USA-states',  # Set of locations match entries in `locations`
    text=data['State'],  # Change hover text to state names
    colorscal='Reds',
    colorbar_title="NIBRS Share",
))

# Update Layout
fig.update_layout(
    title_text='Agencies Participating in NIBRS',
    geo_scope='usa',  # Limit map scope to USA
)

# Print Figure
fig.show()
