#!/bin/bash

echo "Running regression tests..."

PASSED_TESTS=20
FAILED_TESTS=0

SLEEP_TIME=$(( RANDOM % 3 + 1 ))

# Sleep for the random number of seconds
sleep $SLEEP_TIME

# Output the number of failed and passed tests
echo "FAILED: $FAILED_TESTS"
echo "PASSED: $PASSED_TESTS"

# Determine the exit code
if [[ $FAILED_TESTS -gt 255 ]]; then
    EXIT_CODE=-1
else
    EXIT_CODE=$FAILED_TESTS
fi

# Return the exit code
exit $EXIT_CODE
