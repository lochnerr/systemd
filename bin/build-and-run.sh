#!/bin/sh

set -e

BUILD="."
[ -n "$1" ] && BUILD="-f Dockerfile-$1"

echo "Building the application."
podman build -t lochnerr/systemd $BUILD
if [ "$?" -ne 0 ]; then
	echo "ERROR: Build failed."
	exit 1
fi

echo "Removing any unit test containers from a previous run."
podman-compose -f docker-compose.test.yml down

echo "Starting the unit test containers."
podman-compose --podman-run-args='--systemd=always' -f docker-compose.test.yml up

echo "Removing the unit test containers."
podman-compose -f docker-compose.test.yml down

exit 0

