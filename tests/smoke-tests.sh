#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <host> <port> <expected_version> <expected_env>"
  exit 1
fi

# Assign command-line arguments to variables
HOST="$1"
PORT="$2"
EXPECTED_VERSION="$3"
EXPECTED_ENV="$4"

# Set variables for sleep duration and maximum loop attempts
SLEEP_DURATION=1  # seconds
MAX_ATTEMPTS=10

echo "Running smoke tests..."

# Smoke test to check if the port is open
echo "Testing deployment on [host:port]: $HOST:$PORT"

# Loop to check if the port is open, retrying up to MAX_ATTEMPTS times
for (( i=1; i<=MAX_ATTEMPTS; i++ )); do
  echo "Attempt $i: Checking if port $PORT is open..."

  # Check if the port is open using netcat (nc)
  nc -zv $HOST $PORT && break

  # If the command fails, wait for SLEEP_DURATION before retrying
  echo "Port $PORT is not open, retrying in $SLEEP_DURATION second(s)..."
  sleep $SLEEP_DURATION

  # If this is the last attempt and it still fails, exit with an error
  if [ $i -eq $MAX_ATTEMPTS ]; then
    echo "Port $PORT is not open after $MAX_ATTEMPTS attempts. Exiting."
    exit 1
  fi
done

# If the smoke test passed, proceed to check the version and environment in the HTML output
echo "Curling the service at http://$HOST:$PORT"

# Fetch the HTML output
HTML_OUTPUT=$(curl --fail --silent http://$HOST:$PORT)

# Check if the expected version and environment are in the HTML output
echo "$HTML_OUTPUT" | grep -q "$EXPECTED_VERSION" && echo "$HTML_OUTPUT" | grep -q "$EXPECTED_ENV"

if [ $? -eq 0 ]; then
  echo "Version $EXPECTED_VERSION and environment $EXPECTED_ENV found in HTML output. Deployment successful."
else
  echo "Version $EXPECTED_VERSION or environment $EXPECTED_ENV not found in HTML output. Deployment failed."
  exit 1
fi
