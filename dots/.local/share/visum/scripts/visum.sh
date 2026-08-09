#!/usr/bin/env bash

# Ensure config directory exists
mkdir -p ~/.config/visum/
touch ~/.config/visum/visum.conf

if [ "$1" == "" ]; then
  echo "Error: No file path provided." >&2
  exit 1
fi

FILEPATH=$(realpath "$1")
if [ ! -f "$FILEPATH" ]; then
  echo "Error: File '$FILEPATH' does not exist." >&2
  exit 1
fi

PORT_FILE="$HOME/.config/visum/port"
SERVER_PID_FILE="$HOME/.config/visum/server.pid"
SSH_PID_FILE="$HOME/.config/visum/ssh.pid"
LOCALHOSTRUN_URL_FILE="/tmp/visum_localhostrun.txt"

# Some filenames contain spaces and special characters which need to be encoded
URL_ENCODED_FILEPATH=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$FILEPATH'''))")

# Get public IP for Auth key
get_public_ip() {
  local ip=""
  # Try fast curl first
  ip=$(curl -s --max-time 3 icanhazip.com 2>/dev/null)
  if [ -z "$ip" ]; then
    ip=$(curl -s --max-time 3 api.ipify.org 2>/dev/null)
  fi
  if [ -z "$ip" ]; then
    ip="127.0.0.1"
  fi
  echo "$ip" | tr -d '[:space:]'
}

PUBLIC_IP=$(get_public_ip)

# Default base office viewer
BASE_OFFICE_URL="http://view.officeapps.live.com/op/view.aspx?src="
VISUM_PREFERRED_OFFICE=$(awk -F '=' '/VISUM_PREFERRED_OFFICE/{print $2}' ~/.config/visum/visum.conf 2>/dev/null | tr -d '[:space:]')

if [ "$VISUM_PREFERRED_OFFICE" == "GOOGLE_OFFICE" ]; then
  BASE_OFFICE_URL="https://docs.google.com/viewer?url="
fi

get_remote_server_url() {
  if [ -f "$LOCALHOSTRUN_URL_FILE" ]; then
    grep -oE 'https://[a-zA-Z0-9.-]+\.lhr\.life' "$LOCALHOSTRUN_URL_FILE" | head -n 1
  fi
}

# Check if processes are running
server_running=false
if [ -f "$PORT_FILE" ] && [ -f "$SERVER_PID_FILE" ] && [ -f "$SSH_PID_FILE" ]; then
  PORT=$(cat "$PORT_FILE")
  PY_SERVER_PID=$(cat "$SERVER_PID_FILE")
  SSH_PID=$(cat "$SSH_PID_FILE")

  if kill -0 "$PY_SERVER_PID" 2>/dev/null && kill -0 "$SSH_PID" 2>/dev/null; then
    server_running=true
  else
    # Clean up dead processes
    kill -9 "$PY_SERVER_PID" 2>/dev/null
    kill -9 "$SSH_PID" 2>/dev/null
  fi
fi

if [ "$server_running" = false ]; then
  # Find a random available port
  # Fallback to standard range if ss/comm fail
  PORT=$(comm -23 <(seq 49152 65535 | sort) <(ss -Htan 2>/dev/null | awk '{print $4}' | cut -d':' -f2 | sort -u) 2>/dev/null | shuf | head -n 1)
  if [ -z "$PORT" ]; then
    PORT=$((49152 + RANDOM % 16383))
  fi

  # Clean old logs
  rm -f "$LOCALHOSTRUN_URL_FILE"

  # Start Python server
  nohup python3 "$HOME/.local/share/visum/scripts/server.py" "$PORT" </dev/null >/tmp/visum_server.log 2>&1 &
  PY_SERVER_PID=$!
  disown "$PY_SERVER_PID" 2>/dev/null
  echo "$PY_SERVER_PID" > "$SERVER_PID_FILE"

  # Start SSH forwarding in the background
  nohup ssh -n -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" -R 80:localhost:"$PORT" ssh.localhost.run > "$LOCALHOSTRUN_URL_FILE" 2>&1 &
  SSH_PID=$!
  disown "$SSH_PID" 2>/dev/null
  echo "$SSH_PID" > "$SSH_PID_FILE"
  echo "$PORT" > "$PORT_FILE"
fi

# Wait for localhost.run to give us the URL
REMOTE_SERVER_URL=""
for i in $(seq 1 40); do
  REMOTE_SERVER_URL=$(get_remote_server_url)
  if [ -n "$REMOTE_SERVER_URL" ]; then
    break
  fi
  # Verify background processes are still running while we wait
  if ! kill -0 "$PY_SERVER_PID" 2>/dev/null || ! kill -0 "$SSH_PID" 2>/dev/null; then
    echo "Error: Local server or SSH tunnel crashed during initialization." >&2
    exit 1
  fi
  sleep 0.25
done

if [ -z "$REMOTE_SERVER_URL" ]; then
  echo "Error: Failed to obtain public URL from localhost.run." >&2
  exit 1
fi

# Print final URL to stdout
echo "${BASE_OFFICE_URL}${REMOTE_SERVER_URL}${URL_ENCODED_FILEPATH}?key=${PUBLIC_IP}"
