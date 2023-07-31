import numpy as np
import csv
import json

def csv_to_json(csv_file, json_file):
    # Read the CSV file
    with open(csv_file, 'r') as file:
        reader = csv.DictReader(file)
        data = list(reader)
    
    # Write the JSON file
    with open(json_file, 'w') as file:
        json.dump(data, file, indent=4)
def percentage_difference(arr1, arr2):
    abs_diff = np.abs(arr1 - arr2)
    avg = (arr1 + arr2) / 2
    percentage_diff = (abs_diff / avg) * 100
    return percentage_diff
