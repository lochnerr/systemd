#!/bin/sh

# systemd-sut.sh: Script to run system unit tests for systemd container.

# Note: This can be run from the command line.

wait_for_result() {
  echo "Waiting for $1 result."
  err="true"
  for n in $(seq -s ' ' 5) ; do
    if [ -e ${DIR}/$1 ]; then
      err=
      echo "Got result $(cat ${DIR}/$1)."
      break
    fi
    sleep 1s
  done
  [ "$err" = "true" ] && errs=$((errs + 1))
}

# If there is a shared unit test directory, use it for the results.
DIR=""
[ -d /unittest ] && DIR="/unittest"
[ -z "$DIR" ] && DIR="$(mktemp -d /tmp/XXX)"

# Remove results from any prior runs.
rm -f $DIR/INLINE
rm -f $DIR/SERVICE

if [ ! -d /unittest ]; then
  BIN="$(dirname $(readlink -f $0))"
  echo "Executable dir is $BIN"
  export NO_INIT="true"
  $BIN/run-service $BIN/test-script.sh INLINE  $DIR
  export NO_INIT=
  $BIN/run-service $BIN/test-script.sh SERVICE $DIR
fi

errs=0
wait_for_result INLINE
wait_for_result SERVICE
echo "Info: Tests completed with $errs error(s)."

if [ ! -d /unittest ]; then
  echo "Removing directory $DIR."
  rm -rf $DIR
fi

exit $errs

