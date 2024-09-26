#!/bin/sh

set -e

echo "Removing any unit test containers from a previous run."
podman-compose -f docker-compose.test.yml down

echo "Building the application."
podman build -t lochnerr/systemd .

echo "Starting the unit test containers."
podman-compose --podman-run-args='--systemd=always' -f docker-compose.test.yml up

echo "Removing the unit test containers."
podman-compose -f docker-compose.test.yml down

exit 0

