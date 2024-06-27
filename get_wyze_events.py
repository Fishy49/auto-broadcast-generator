import os
import json
from datetime import datetime, timedelta
from wyze_sdk import Client
from wyze_sdk.errors import WyzeApiError

# Function to write data to JSON file
def write_tokens_to_file(access_token, refresh_token):
    data = {
        "access_token": access_token,
        "refresh_token": refresh_token
    }
    with open("wyze_credentials.json", 'w+') as json_file:
        json.dump(data, json_file, indent=4)

# Function to read data from JSON file
def read_tokens_from_file():
    with open("wyze_credentials.json", 'r') as json_file:
        data = json.load(json_file)
    return data.get('access_token'), data.get('refresh_token')

def populate_tokens():
    response = Client().login(
        email=os.environ['WYZE_EMAIL'],
        password=os.environ['WYZE_PASSWORD'],
        key_id=os.environ['WYZE_KEY_ID'],
        api_key=os.environ['WYZE_API_KEY']
    )
    write_tokens_to_file(response['access_token'], response['refresh_token'])

access_token, refresh_token = read_tokens_from_file()

if(access_token == ""):
    populate_tokens()
    access_token, refresh_token = read_tokens_from_file()

client = Client(token=access_token, refresh_token=refresh_token)

# Do a test of the current tokens
try:
    client.cameras.list()
except WyzeApiError as e:
    if(str(e).startswith("The access token has expired")):
        resp = client.refresh_token()
        write_tokens_to_file(resp.data['data']['access_token'], resp.data['data']['refresh_token'])
        access_token, refresh_token = read_tokens_from_file()
        client = Client(token=access_token, refresh_token=refresh_token)

backyard_mac = "AN_RSCW_D03F2765FA3C"
street_corner_mac = "AN_RSCW_80482C03F506"
dining_room_mac = "D03F27A8B7AB"
doorbell_mac = "80482C26E464"

macs = [backyard_mac, street_corner_mac, dining_room_mac, doorbell_mac]

camera_names = {
    "AN_RSCW_D03F2765FA3C": "Backyard Camera",
    "AN_RSCW_80482C03F506": "Street Corner Camera",
    "D03F27A8B7AB": "Dining Room Camera",
    "80482C26E464": "Front Doorbell"
}

now = datetime.now()
twelve_hours_ago = now - timedelta(hours=12)

try:
    output_format = []
    for mac in macs:
        events = client.events.list(device_ids=[mac], begin=twelve_hours_ago)
        for event in events:
            output_format.append(
                {
                    "camera_name": camera_names[event.mac],
                    "alarm_type": event.alarm_type.description,
                    "tags": list(map(lambda tag: tag.description, event.tags)),
                    "time": event.time
                }
            )
except WyzeApiError as e:
    # You will get a WyzeApiError if the request failed
    print(f"Got an error: {e}")

print(json.dumps(output_format))
