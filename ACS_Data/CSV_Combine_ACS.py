'''
    Created: 25.2.2021
    @ Florian Fickler
    Goal:
        This file should load in all the serperate ACS CSVs
        Do  basic data cleaning, excluding certain entries (e.g. Puerto Rico)
        Combine those CSVs and export them as one common dataset
    Taks:
        1) CSV'S have two rows of headers, second row is equal to the variable names
        2) Margin of Error Variables are not needed (for now) - delete them
        3) Reduce each CSV to the important variables (broader ones)
        4) Variable names are too long (for Stata), so best to trimm/rename them
        5) Save adjusted CSV's in a folder
        6) Merge all of those based on geographic id to one dataset
    To-Do for it to run:
                         set working directory (line 26)
                         set path with data (line 30 & 31)
'''

# Import packages
import os
from glob import glob
import pandas as pd
import fnmatch

# Set working directory:
    # Replace XXX and enter own directory
os.chdir(r"XXX")


# Define Paths
path_csv = r"C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey\MSA-Data\MSA-Data"
path_dataset = r"C:\Users\Flori\OneDrive\Desktop\Uni\Emma\American Community Survey\MSA-Data\ACS-MSA-5yr"

# load in files via glob
files = []
files.extend(glob(os.path.join(path_csv, "*.csv")))

# Loop through all CSV'S
for f in files:
    # Read in CSV as dataframe
    df_f = pd.read_csv(f, sep=',')

    # Loop through Columns
    for i in df_f.keys():
        # Drop Columns with Estiamte Ranges
        if fnmatch.fnmatch(i, "*M"):
            del df_f[i]

    # Loop through Rows
    for (j, k) in df_f.iterrows():
        # Drop Observations for Puerto Rico
        if fnmatch.fnmatch(k[1], "* Rico"):
            df_f.drop(axis=0, index=j, inplace=True)

    # Set id as index
    # df_f.set_index('GEO_ID', inplace = True)
    # Define new file name
    f_new = f[:-4] + "_new.csv"
    df_f.to_csv(f_new, index=False)
