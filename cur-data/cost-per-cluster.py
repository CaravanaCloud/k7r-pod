#!/usr/bin/env python3
import glob
import os
import json
import pandas as pd

print("hello world ")
# Check pandas version
print(pd.__version__)

csv_files = glob.glob("../data/**/*.csv.gz", recursive=True)

csv_count = len(csv_files)

if csv_count == 0:
    print("No CSV files found")
    exit()

# Initialize an empty list to hold the dataframes
dfs = []

# Load each CSV file and append it to the list of dataframes
for file in csv_files:
    df = pd.read_csv(file, compression='gzip', header=0, sep=',', quotechar='"')
    dfs.append(df)

# Concatenate all dataframes into one
df = pd.concat(dfs, ignore_index=True)

# Remove unnecessary columns
columns = ['bill_payer_account_id', 
        'identity_line_item_id', 
        'resource_tags',
        'pricing_public_on_demand_cost']
df = df[columns]

# Remove untagged rows
df = df[df['resource_tags'] != '{}']

# Parse tags
df['resource_tags'] = df['resource_tags'].apply(json.loads)
df[['user_name', 
    'cluster_name',
    'user_cluster_name' ]] = df['resource_tags'].apply(
    lambda x: pd.Series({
        'user_name': x.get('user_name'), 
        'cluster_name': x.get('cluster_name'),
        'user_cluster_name': x.get('user_cluster_name')
    }))

# Cleanup data
# Remove empty user name
df = df[df['user_name'].notnull()]

# Print results
df = df.groupby('user_name')['pricing_public_on_demand_cost'].sum().reset_index()



print(df)