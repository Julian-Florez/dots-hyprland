#!/run/current-system/sw/bin/python3
import os
import json
import sys
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/tasks']

TODO_PATH = os.path.expanduser('~/.local/state/quickshell/user/todo.json')

# Persistent configuration directory outside of the quickshell config directory
CONFIG_DIR = os.path.expanduser('~/.config/google-tasks-sync')
os.makedirs(CONFIG_DIR, exist_ok=True)

TOKEN_PATH = os.path.join(CONFIG_DIR, 'google_tasks_token.json')
CLIENT_SECRETS_PATH = os.path.join(CONFIG_DIR, 'client_secrets.json')
SYNCED_IDS_PATH = os.path.join(CONFIG_DIR, 'google_tasks_synced_ids.json')

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

def list_all_pages(request_factory, item_key):
    """Fetch every page returned by a Google Tasks collection endpoint."""
    items = []
    page_token = None
    while True:
        response = request_factory(page_token).execute()
        items.extend(response.get(item_key, []))
        page_token = response.get('nextPageToken')
        if not page_token:
            return items

def fetch_all_remote_tasks(service):
    """Return tasks from every task list, including completed and hidden ones."""
    task_lists = list_all_pages(
        lambda page_token: service.tasklists().list(maxResults=100, pageToken=page_token),
        'items'
    )

    # A new account may have no list returned yet; @default remains valid.
    if not task_lists:
        task_lists = [{'id': '@default'}]

    remote_tasks = []
    for task_list in task_lists:
        task_list_id = task_list['id']
        tasks = list_all_pages(
            lambda page_token, task_list_id=task_list_id: service.tasks().list(
                tasklist=task_list_id,
                maxResults=100,
                showCompleted=True,
                showHidden=True,
                pageToken=page_token,
            ),
            'items'
        )
        for task in tasks:
            task['_tasklistId'] = task_list_id
            remote_tasks.append(task)

    return remote_tasks

def sync_tasks():
    creds = authenticate()
    service = build('tasks', 'v1', credentials=creds)
    
    # 1. Read local todo.json
    local_tasks = []
    if os.path.exists(TODO_PATH):
        try:
            with open(TODO_PATH, 'r') as f:
                local_tasks = json.load(f)
        except Exception:
            local_tasks = []
            
    # Normalize and deduplicate local tasks
    seen_ids = set()
    seen_contents = set()
    deduped_local_tasks = []
    for t in local_tasks:
        if 'id' not in t:
            t['id'] = None
        
        t_id = t['id']
        t_content = t.get('content', '')
        
        if t_id is not None:
            if t_id not in seen_ids:
                seen_ids.add(t_id)
                deduped_local_tasks.append(t)
        else:
            if t_content not in seen_contents:
                seen_contents.add(t_content)
                deduped_local_tasks.append(t)
                
    local_tasks = deduped_local_tasks
            
    # Load previously synced states (maps ID -> done status)
    synced_states = {}
    if os.path.exists(SYNCED_IDS_PATH):
        try:
            with open(SYNCED_IDS_PATH, 'r') as f:
                synced_states = json.load(f)
        except Exception:
            synced_states = {}
            
    # If synced_ids was stored as a list previously, convert to dict
    if isinstance(synced_states, list):
        synced_states = {task_id: False for task_id in synced_states}

    # 2. Fetch every page from every Google Tasks list.
    try:
        remote_tasks = fetch_all_remote_tasks(service)
    except Exception as e:
        print(f"Error fetching remote tasks: {e}")
        return

    local_by_id = {t['id']: t for t in local_tasks if t['id'] is not None}
    remote_by_id = {t['id']: t for t in remote_tasks}
    
    # Pre-identify local tasks without ID to match them by title and prevent duplicates
    new_local_tasks = [t for t in local_tasks if t.get('id') is None]
    matched_new_locals = {}
    
    updated_local_tasks = []
    remote_updates = []
    
    # Sync remote changes to local
    for r_task in remote_tasks:
        r_id = r_task['id']
        r_tasklist_id = r_task['_tasklistId']
        r_title = r_task.get('title', '')
        r_done = r_task.get('status') == 'completed'
        r_deleted = r_task.get('deleted', False)
        
        if r_deleted:
            continue
            
        # Match by ID or fallback to matching by title for new local tasks
        l_task = None
        if r_id in local_by_id:
            l_task = local_by_id[r_id]
            l_task['tasklistId'] = r_tasklist_id
        else:
            # Fallback title match
            for l_t in new_local_tasks:
                if (r_tasklist_id == '@default' and l_t not in matched_new_locals.values()
                        and l_t['content'] == r_title):
                    l_task = l_t
                    l_task['id'] = r_id
                    l_task['tasklistId'] = r_tasklist_id
                    local_by_id[r_id] = l_task
                    matched_new_locals[r_id] = l_task
                    print(f"Matched new local task '{r_title}' to remote task by title.")
                    break
            
        if l_task is not None:
            sync_key = f"{r_tasklist_id}:{r_id}"
            # Accept state written by the previous default-list-only version.
            last_done = synced_states.get(sync_key, synced_states.get(r_id))
            
            if last_done is not None:
                # 3-way merge logic
                if l_task['done'] != last_done and r_done == last_done:
                    # Changed locally, push to remote
                    print(f"Task status changed locally: {r_title} -> {l_task['done']}")
                    remote_updates.append(l_task)
                elif r_done != last_done and l_task['done'] == last_done:
                    # Changed remotely, update local
                    print(f"Task status changed remotely: {r_title} -> {r_done}")
                    l_task['done'] = r_done
                elif l_task['done'] != r_done:
                    # Both changed, conflict: let remote win
                    l_task['done'] = r_done
            else:
                # No sync state, align local with remote status
                l_task['done'] = r_done
                
            l_task['content'] = r_title
            updated_local_tasks.append(l_task)
        else:
            # Remote task is not in local list
            if f"{r_tasklist_id}:{r_id}" in synced_states or r_id in synced_states:
                # It was previously synced, meaning it was deleted locally!
                # So we delete it on remote Google Tasks
                try:
                    service.tasks().delete(tasklist=r_tasklist_id, task=r_id).execute()
                    print(f"Deleted task on Google Tasks: {r_title}")
                except Exception as e:
                    print(f"Error deleting task on remote: {e}")
            else:
                # New task from another device
                new_l = {
                    "content": r_title,
                    "done": r_done,
                    "id": r_id,
                    "tasklistId": r_tasklist_id,
                }
                updated_local_tasks.append(new_l)

    # Upload local tasks that don't have an ID
    for l_task in local_tasks:
        if l_task.get('id') is None:
            task_body = {
                'title': l_task['content'],
                'status': 'completed' if l_task['done'] else 'needsAction'
            }
            try:
                r_new = service.tasks().insert(tasklist='@default', body=task_body).execute()
                l_task['id'] = r_new['id']
                l_task['tasklistId'] = '@default'
                updated_local_tasks.append(l_task)
            except Exception as e:
                print(f"Error creating remote task: {e}")
                updated_local_tasks.append(l_task)
        elif l_task['id'] not in remote_by_id:
            pass
            
    # Push local changes back to remote
    for l_task in remote_updates:
        body = {
            'id': l_task['id'],
            'title': l_task['content'],
            'status': 'completed' if l_task['done'] else 'needsAction'
        }
        try:
            service.tasks().update(tasklist=l_task.get('tasklistId', '@default'), task=l_task['id'], body=body).execute()
        except Exception as e:
            print(f"Error updating remote task status: {e}")

    # Ensure parent directory exists
    os.makedirs(os.path.dirname(TODO_PATH), exist_ok=True)
    with open(TODO_PATH, 'w') as f:
        json.dump(updated_local_tasks, f, indent=4)
        
    # Save the dictionary of current synced IDs and states for deletion tracking
    new_synced_states = {
        f"{t.get('tasklistId', '@default')}:{t['id']}": t['done']
        for t in updated_local_tasks if t.get('id') is not None
    }
    with open(SYNCED_IDS_PATH, 'w') as f:
        json.dump(new_synced_states, f)
        
    print("Tasks synchronized successfully.")

if __name__ == '__main__':
    sync_tasks()
