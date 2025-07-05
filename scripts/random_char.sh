#!/bin/bash
#
# Outputs a single random alphanumeric character.
# Uses /dev/urandom for a source of randomness and tr to filter.

head -c 1024 /dev/urandom | tr -dc 'a-z0-9' | head -c 1
echo
