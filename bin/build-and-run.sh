#!/bin/sh

set -e

if [ -z "$1" ]; then
	cmd=$(basename "$0")
	echo "Format: $cmd distro [release=latest] [build_with_compose=no] [skip_tests=no]"
	exit 1
fi

# Use a default compose if one exists.
[ -e docker-compose.yml ]      && compose_file="docker-compose.yml"
[ -e docker-compose.yaml ]     && compose_file="docker-compose.yaml"
[ -e compose.yml ]             && compose_file="compose.yml"
[ -e compose.yaml ]            && compose_file="compose.yaml"

# From: https://docs.docker.com/docker-hub/repos/manage/builds/automated-testing/#set-up-automated-test-files
# To set up your automated tests, create a docker-compose.test.yml file which defines a sut service that lists the tests to be run.
# The docker-compose.test.yml file should be located in the same directory that contains the Dockerfile used to build the image.
# So, prefer this file if it exists.
[ -e docker-compose.test.yml ] && compose_file="docker-compose.test.yml"

# Default to building with podman build, unless the build with compose option is yes.
builder="podman"
[ "$3" = "yes" ] && builder="compose"

# If the build with compose option has not been set and the compose file has
# a build section then default to building with compose.
[ -z "$3" ] && grep -q "build:" "${compose_file}" 2>/dev/null && builder="compose"

export DISTRO="${1:-fedora}"
export RELEASE="${2:-latest}"
BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
export BUILD_DATE
VCS_REF="$(git rev-parse --short HEAD)"
export VCS_REF
export BUILD_ARGS="--build-arg DISTRO=${DISTRO} --build-arg RELEASE=${RELEASE} --build-arg BUILD_DATE=${BUILD_DATE} --build-arg VCS_REF=${VCS_REF}"

echo "Building the application."

image=$(basename "$PWD")
# shellcheck disable=SC2086
if [ "${builder}" = "podman" ]; then
	echo "Building with podman."
	echo "podman build -t lochnerr/${image}:${DISTRO}-${RELEASE} $BUILD_ARGS -f Dockerfile-${DISTRO}"
	podman build -t "lochnerr/${image}:${DISTRO}-${RELEASE}" $BUILD_ARGS -f Dockerfile-"${DISTRO}" || err="yes"
else
	echo "Building with compose."
	echo "Using compose file: ${compose_file}."
	echo "podman-compose -f ${compose_file} build $BUILD_ARGS"
	podman-compose -f docker-compose.test.yml build $BUILD_ARGS || err="yes"
fi
if [ "$err" = "yes" ]; then
	echo "ERROR: Build failed."
	exit 1
fi

if [ "${4:-no}" = "yes" ]; then
	echo "Skipping tests."
	exit 0
fi

echo "Removing any unit test containers from a previous run."
podman-compose -f docker-compose.test.yml down

# Delete test volumes if needed before runnning tests.
deletes=
[ -e bin/delete-volumes ] && deletes="bin/delete-volumes"
[ -e delete-volumes ]     && deletes="delete-volumes"
if [ -n "${deletes}" ]; then
	echo "Sourcing volume deletes from ${deletes}."
	# shellcheck source=bin/delete-volumes
	. "${deletes}"
fi

echo "Starting the unit test containers."
podman-compose --podman-run-args='--systemd=always' -f docker-compose.test.yml up

echo "Removing the unit test containers."
podman-compose -f docker-compose.test.yml down

exit 0

