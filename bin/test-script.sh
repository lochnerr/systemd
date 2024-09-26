#!/bin/sh

# test-script.sh: Script used in system unit tests.  

echo "Running test $1 with output directory $2"

# If shared directory, give the result check process time to delete the output file.
[ -d /unittest ] && sleep 2s

# Notify the check process that the command has run.
echo $1 >$2/$1

# If no shared directory, there is nothing else to do.
[ ! -d /unittest ] && exit 0

# If INLINE, there is nothing else to do.
[ "$1" = "INLINE" ] && exit 0

# The result output has been written to the shared directory so terminate (poweroff) the container running this script.
systemctl poweroff

