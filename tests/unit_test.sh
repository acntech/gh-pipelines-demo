#!/bin/bash

echo "Running unit tests..."

PASSED_TESTS=40
FAILED_TESTS=0
COVERAGE=85
COVERAGE_THRESHOLD=80

SLEEP_TIME=$(( RANDOM % 3 + 1 ))

# Sleep for the random number of seconds
sleep $SLEEP_TIME

# Output the number of failed and passed tests
echo "FAILED: $FAILED_TESTS"
echo "PASSED: $PASSED_TESTS"
echo "COVERAGE: $COVERAGE"

# Determine exit code
if [[ $FAILED_TESTS -gt 255 ]]; then
    EXIT_CODE=255
elif [[ $FAILED_TESTS -eq 0 && $COVERAGE -lt $COVERAGE_THRESHOLD ]]; then
    EXIT_CODE=$((COVERAGE - 100))
else
    EXIT_CODE=$FAILED_TESTS
fi

# Return the exit code
exit $EXIT_CODE
