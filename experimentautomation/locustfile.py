import json
import random
from locust import HttpUser, TaskSet, task, constant
from locust import LoadTestShape


class UserTasks(TaskSet):
    @task(5)  
    def get_data(self):
        # GET endpoint are used more often
        self.client.get("/users")
    
    def get_data_list(self):
        response = self.client.get("/users")
        if response.ok:
            return json.loads(response.text)
        else:
            return []

    @task(1) # POST requests are used less frequently than GET
    def create_data(self):
        # replace with your POST endpoint and payload
        payload = {"name": "fola", "email": "fola@gmail", "address": "amsterdam", "school": "ssu", "color": "blue", "age": "old", "family": "phils", "company": "sbp"}
        self.client.post("/users", json=payload)

    @task(1) # PUT requests are used even less frequently but a bit more than POST
    def update_data(self):
        data = self.get_data_list()
        if data:
            item_id = random.choice(data)["id"]
            # replace with your PUT endpoint and payload
            payload = {"name": "Toba", "email": "toba@gmail", "address": "amsterdam", "school": "ssu", "color": "blue", "age": "old", "family": "phils", "company": "sbp"}
            self.client.put(f"/users/{item_id}", json=payload)
        else:
            # print a message indicating that there is no data to update
            print("No data to update. Skipping task.")

    @task(1) # DELETE requests are used the least frequently
    def delete_data(self):
        data = self.get_data_list()
        if data:
            item_id = random.choice(data)["id"]
            self.client.delete(f"/users/{item_id}")
        else:
            # print a message indicating that there is no data to delete
            print("No data to delete. Skipping task.")



class WebsiteUser(HttpUser):
    wait_time = constant(5)
    # wait_time = between(5, 15)
    tasks = [UserTasks]
