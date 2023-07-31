import json

# Read the input JSON file
with open('allcontainerdata.json', 'r') as f:
    data = json.load(f)

# Extract the desired fields from each object in the "imageDetails" array
new_data = []
for image in data['imageDetails']:
    new_image = {
        'repositoryName': image['repositoryName'],
        'imageTags': image['imageTags'],
        'imageSizeInBytes': image['imageSizeInBytes'],
        'imagePushedAt': image['imagePushedAt']
    }
    new_data.append(new_image)

# Create a new JSON file with the extracted information
with open('allrepo.json', 'w') as f:
    json.dump(new_data, f, indent=4)
