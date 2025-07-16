#!/bin/bash

# Prompt the user for the upper limit and read the input.
read -p "Enter the upper limit: " limit

# Check if the input is a positive integer.
if ! [[ "$limit" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Input must be a positive integer." >&2
    exit 1
fi

# Generate and output the random number.
echo $((RANDOM % limit + 1))