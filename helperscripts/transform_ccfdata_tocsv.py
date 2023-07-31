import json
from matplotlib import pyplot as plt
import numpy as np

def aggregate(target_service_name, target_applications):
    # Load the JSON data from the file
    with open('ccfjsonresult.json') as file:
        data = json.load(file)

    # List to store the kilowatthours values
    kilowatthours_values = []
    watthours_values = []

    # Iterate over the data
    for entry in data:
        service_estimates = entry['serviceEstimates']
        for estimate in service_estimates:
            application = estimate['tags'].get('user:Application')
            service_name = estimate['serviceName']
            kilowatthours = estimate['kilowattHours']
            if service_name == target_service_name and application in target_applications:
                kilowatthours_values.append(kilowatthours)
                watthours_values.append(kilowatthours*1000)
    # print(watthours_values)
    # print("____________________________________________________________________________________")
    # mean_value = sum(watthours_values) / len(watthours_values) if watthours_values else 0
    # return mean_value
    return watthours_values


def create_bar_chart(values1, values2, labels):
    # Set the width of the bars
    bar_width = 0.35

    # Create an array for the x-axis positions of the bars
    x = np.arange(len(labels))

    # Create the bar chart
    plt.bar(x - bar_width/2, values1, width=bar_width, label='Container')
    plt.bar(x + bar_width/2, values2, width=bar_width, label='Serverless')

    # Set the title and labels
    plt.title('Container vs Serverless')
    plt.xlabel('Concurrent Users')
    plt.ylabel('Energy Consumption in Watt-Hour')

    # Set the X-axis tick labels
    plt.xticks(x, labels)

    # Add a legend
    plt.legend()

    # Display the chart
    plt.show()


def create_bar_chartb(values1, values2, values3, labels):
    # Set the width of the bars
    bar_width = 0.25

    # Create an array for the x-axis positions of the bars
    x = np.arange(len(labels))

    # Create the bar chart
    plt.bar(x - bar_width, values1, width=bar_width, label='No Tactic')
    plt.bar(x, values2, width=bar_width, label='Tactic 1')
    plt.bar(x + bar_width, values3, width=bar_width, label='Tactic 2')

    # Set the title and labels
    plt.title('Impact of Tactics on App-A')
    plt.xlabel('Concurrent Users')
    plt.ylabel('Energy Consumption in Watt-Hour')

    # Set the X-axis tick labels
    plt.xticks(x, labels)

    # Add a legend
    plt.legend()

    # Display the chart
    plt.show()

def calculate_statistics(data):
    minimum = np.min(data)
    first_quartile = np.percentile(data, 25)
    median = np.median(data)
    mean = np.mean(data)
    third_quartile = np.percentile(data, 75)
    maximum = np.max(data)
    standard_deviation = np.std(data)

    return mean, minimum, first_quartile, median, third_quartile, maximum, standard_deviation




# Define the target serviceName
lambda_name = "AWSLambda"
# lambda_name = "AmazonApiGateway"
container_name = "AmazonECS"

