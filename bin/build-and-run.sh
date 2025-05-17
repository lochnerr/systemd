#!/bin/sh

set -e

if [ -z "$1" ]; then
	cmd=$(basename "$0")
	echo "Format: $cmd distro [release=latest] [build_with_compose=no]"
	exit 1
fi

export DISTRO="${1:-fedora}"
export RELEASE="${2:-latest}"
export BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
export VCS_REF="$(git rev-parse --short HEAD)"
export BUILD_ARGS="--build-arg DISTRO=${DISTRO} --build-arg RELEASE=${RELEASE} --build-arg BUILD_DATE=${BUILD_DATE} --build-arg VCS_REF=${VCS_REF}"

echo "Building the application."
if [ "${3:-no}" = "no" ]; then
	echo "Building with podman."
	echo "podman build -t "lochnerr/$(basename "$PWD"):${DISTRO}-${RELEASE}" $BUILD_ARGS -f Dockerfile-"${DISTRO}""
	podman build -t "lochnerr/$(basename "$PWD"):${DISTRO}-${RELEASE}" $BUILD_ARGS -f Dockerfile-"${DISTRO}" || err="yes"
else
	echo "Building with compose."
	echo "podman-compose -f docker-compose.test.yml build $BUILD_ARGS"
	podman-compose -f docker-compose.test.yml build $BUILD_ARGS || err="yes"
fi
if [ "$err" = "yes" ]; then
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

