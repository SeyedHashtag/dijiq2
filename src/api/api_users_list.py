import os
import requests
import json
import random
import string
from dotenv import load_dotenv

class APIClient:
    def __init__(self):
        load_dotenv()
        
        self.base_url = os.getenv('URL')
        self.token = os.getenv('TOKEN')
        
        if not self.base_url.endswith('/'):
            self.base_url += '/'
            
        self.users_endpoint = f"{self.base_url}api/v1/users/"
        
        self.headers = {
            'accept': 'application/json',
            'Authorization': self.token
        }
    
    def get_users(self):
        try:
            response = requests.get(self.users_endpoint, headers=self.headers)
            response.raise_for_status()
            print(f"API Response: {response.text[:200]}...")
            try:
                return response.json()
            except json.JSONDecodeError:
                return response.text
        except requests.exceptions.RequestException as e:
            print(f"Error fetching users: {e}")
            return None
    
    def add_user(self, username, traffic_limit, expiration_days):
        data = {
            "username": username,
            "traffic_limit": traffic_limit,
            "expiration_days": expiration_days
        }
        
        post_headers = self.headers.copy()
        post_headers['Content-Type'] = 'application/json'
        
        try:
            print(f"Sending request to {self.users_endpoint} with data: {data}")
            response = requests.post(
                self.users_endpoint, 
                headers=post_headers, 
                json=data
            )
            print(f"API Response Status: {response.status_code}")
            print(f"API Response Body: {response.text[:200]}...")
            
            response.raise_for_status()
            
            try:
                return response.json()
            except json.JSONDecodeError:
                return response.text
                
        except requests.exceptions.RequestException as e:
            print(f"Error adding user: {e}")
            return None

def generate_random_username(length=8):
    """Generate a random username of specified length"""
    characters = string.ascii_lowercase + string.digits
    return ''.join(random.choice(characters) for _ in range(length))

def main():
    client = APIClient()
    
    print("Fetching existing users...")
    users = client.get_users()
    
    if users:
        if isinstance(users, list):
            print(f"\nTotal users: {len(users)}")
            print("\nUser List:")
            for i, user in enumerate(users, 1):
                print(f"{i}. Username: {user.get('username', 'N/A')}")
                print(f"   Traffic Limit: {user.get('traffic_limit', 'N/A')} bytes")
                print(f"   Expiration Days: {user.get('expiration_days', 'N/A')}")
                print(f"   Created At: {user.get('created_at', 'N/A')}")
                print()
        else:
            print(f"Unexpected response format: {type(users)}")
            print(users)
    else:
        print("Failed to retrieve users or no users found")

if __name__ == "__main__":
    main()