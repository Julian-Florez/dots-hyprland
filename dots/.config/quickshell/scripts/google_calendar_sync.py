#!/run/current-system/sw/bin/python3
import os
import json
import sys
import datetime
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = [
    'https://www.googleapis.com/auth/tasks',
    'https://www.googleapis.com/auth/calendar.readonly'
]

# Shared configuration paths
CONFIG_DIR = os.path.expanduser('~/.config/google-tasks-sync')
TOKEN_PATH = os.path.join(CONFIG_DIR, 'google_tasks_token.json')
CLIENT_SECRETS_PATH = os.path.join(CONFIG_DIR, 'client_secrets.json')
CALENDAR_EVENTS_PATH = os.path.expanduser('~/.local/state/quickshell/user/calendar_events.json')

def authenticate():
    creds = None
    if os.path.exists(TOKEN_PATH):
        try:
            creds = Credentials.from_authorized_user_file(TOKEN_PATH, SCOPES)
        except Exception:
            creds = None
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except Exception:
                creds = None
        
        if not creds:
            if not os.path.exists(CLIENT_SECRETS_PATH):
                print(f"ERROR_MISSING_SECRETS: {CLIENT_SECRETS_PATH}")
                sys.exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_PATH, SCOPES)
            creds = flow.run_local_server(port=0)
            
        with open(TOKEN_PATH, 'w') as token:
            token.write(creds.to_json())
            
    return creds

def sync_calendar():
    creds = authenticate()
    service = build('calendar', 'v3', credentials=creds)
    
    # Fetch events for the next 30 days
    now = datetime.datetime.utcnow().isoformat() + 'Z'
    time_max = (datetime.datetime.utcnow() + datetime.timedelta(days=30)).isoformat() + 'Z'
    
    try:
        events_result = service.events().list(
            calendarId='primary', 
            timeMin=now,
            timeMax=time_max,
            singleEvents=True,
            orderBy='startTime'
        ).execute()
        events = events_result.get('items', [])
    except Exception as e:
        print(f"Error fetching calendar events: {e}")
        return

    parsed_events = []
    for event in events:
        summary = event.get('summary', Translation.tr('Untitled Event') if 'Translation' in globals() else 'Untitled Event')
        start = event.get('start', {})
        end = event.get('end', {})
        
        # Check if all-day event
        if 'date' in start:
            date_str = start['date']
            parsed_events.append({
                "title": summary,
                "date": date_str,
                "startTime": "All day",
                "endTime": "",
                "allDay": True
            })
        elif 'dateTime' in start:
            # Parse datetime string, e.g. "2026-07-28T10:00:00-05:00"
            dt_start = datetime.datetime.fromisoformat(start['dateTime'])
            dt_end = datetime.datetime.fromisoformat(end['dateTime'])
            
            parsed_events.append({
                "title": summary,
                "date": dt_start.strftime('%Y-%m-%d'),
                "startTime": dt_start.strftime('%H:%M'),
                "endTime": dt_end.strftime('%H:%M'),
                "allDay": False
            })

    # Ensure parent directory exists
    os.makedirs(os.path.dirname(CALENDAR_EVENTS_PATH), exist_ok=True)
    with open(CALENDAR_EVENTS_PATH, 'w') as f:
        json.dump(parsed_events, f, indent=4)
        
    print("Calendar events synchronized successfully.")

if __name__ == '__main__':
    sync_calendar()
