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
'''

######################
# Import Packages
######################
import os
import pandas as pd
import plotly.graph_objects as go
import plotly.io as pio
pio.renderers.default='browser'

# Set working directory:
os.chdir(r"C:\Users\Flori\OneDrive\Documents\GitHub\Crime-Data\Master_Thesis\Graphics")


########################
### NIBRS Share MAP ####
########################
# Would be nice to add Sample indicator to Graph

# Import data
data = pd.read_csv('Nibrs_Coverage.csv')

# Change string to numeric and missing to "nan"
data["Share"] = pd.to_numeric(data["Share"])


# Define Color scale
scl = [[0.0, '#fee391'], [0.2, '#fee391'], [0.21, '#fec44f'], [0.4, '#fec44f'],
       [0.41, '#fe9929'],  [0.60, '#fe9929'], [0.61, '#d95f0e'],
       [0.80, '#d95f0e'], [0.81, '#993404'], [1.0, '#993404']]


# Create Graph with US-States and their Share in NIBRS participation
fig = go.Figure(data=go.Choropleth(
    locations=data['State-Code'],  # Spatial coordinates
    z=data['Share'],  # Data to be color-coded
    locationmode='USA-states',  # Set of locations match entries in `locations`
    text=data['State'],  # Change hover text to state names
    colorscale=scl,
    colorbar_title="NIBRS Share",
    marker=dict(line=dict(color='rgb(255,255,255)', width=2))
))

# Update Layout
fig.update_layout(
    geo_scope='usa',  # Limit map scope to USA
    font=dict(size=30)
)

# Print Figure
fig.show()
