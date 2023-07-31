import datetime
import json
from dateutil.parser import parse
import matplotlib.pyplot as plt

import numpy as np

# Read the input JSON file
with open('repodata/allrepo.json', 'r') as f:
    image_data = json.load(f)

# Calculate the date thresholds
today = datetime.datetime.now(datetime.timezone.utc)
one_month_ago = today - datetime.timedelta(days=30)
one_year_ago = today - datetime.timedelta(days=365)
current_month = datetime.datetime(today.year, today.month, 1, tzinfo=datetime.timezone.utc)
months = []

# Group imageSizeInBytes by month of imagePushedAt without applying tactic
grouped_data_no_tactic = {}
# Iterate over each month of the last one year
while current_month >= one_year_ago:
    month_year = current_month.strftime('%Y-%m')
    months.append(month_year)

    # Calculate the cumulative sum for the current month
    cumulative_sum = 0.0

    for image in image_data:
        pushed_at = parse(image['imagePushedAt']).replace(tzinfo=datetime.timezone.utc)

        # Check if the image matches the tag patterns and was pushed within the respective date ranges
        if pushed_at.year <= current_month.year and pushed_at.month <= current_month.month:
            daily_value = image['imageSizeInBytes'] / (1024 ** 4)  # Convert to terabytes
            multiplier = 1.2 * 24 * 1.135 * 3 / 1000 # estimate energy consumption
            cumulative_sum += daily_value * multiplier

    grouped_data_no_tactic[month_year] = cumulative_sum
    # Move to the previous month
    current_month = current_month.replace(day=1) - datetime.timedelta(days=1)


# Group imageSizeInBytes by month of imagePushedAt applying tactic
grouped_data_with_tactic = {}
current_month2 = datetime.datetime(today.year, today.month, 1, tzinfo=datetime.timezone.utc)
current_month_date = current_month2.date()
monthly_sums = []  # Array to store the accumulated monthly sums

# Iterate over each month of the last one year
while current_month2 >= one_year_ago:
    month_year = current_month2.strftime('%Y-%m')
    # Define the date range for images within 1 month from the current month
    start_date_0 = current_month2 - datetime.timedelta(days=30)
    start_date_1 = current_month2 - datetime.timedelta(days=365)

    end_date = current_month2

    # Calculate the cumulative sum for the current month
    cumulative_sum = 0.0

    for image in image_data:
        pushed_at = parse(image['imagePushedAt']).replace(tzinfo=datetime.timezone.utc)

        # Group imageSizeInBytes by date for images with imageTags like "0.*" not older than 1 month
        if any(tag.startswith('0.') for tag in image['imageTags']) and start_date_0 <= pushed_at <= end_date:
            daily_value = image['imageSizeInBytes'] / (1024 ** 4)  # Convert to terabytes
            multiplier = 1.2 * 24 * 1.135 * 3 / 1000 # Convert to watthour
            cumulative_sum += daily_value * multiplier

        # Group imageSizeInBytes by date for images with imageTags like "1.*" not older than 1 year
        if any(tag.startswith('1.') for tag in image['imageTags']) and start_date_1 <= pushed_at <= end_date:
            daily_value_1 = image['imageSizeInBytes'] / (1024 ** 4)  # Convert to terabytes
            multiplier_1 = 1.2 * 24 * 1.135 * 3 / 1000 # estimate energy consumption in watthour
            cumulative_sum += daily_value_1 * multiplier_1

    grouped_data_with_tactic[month_year] = cumulative_sum

    # Move to the previous month
    current_month2 = current_month2.replace(day=1) - datetime.timedelta(days=1)


# Prepare the data for plotting - without tactic
cumulative_sums_without_tactic = []
sum_total = 0
for date, data in sorted(grouped_data_no_tactic.items()):
    sum_total += data
    cumulative_sums_without_tactic.append(sum_total * 1000) #in watt-hour

# Prepare the data for plotting - with tactic
cumulative_sums_with_tactic = []
sum_total = 0
for date, data in sorted(grouped_data_with_tactic.items()):
    sum_total += data
    cumulative_sums_with_tactic.append(sum_total * 1000)



print(cumulative_sums_without_tactic)

print(cumulative_sums_with_tactic)
