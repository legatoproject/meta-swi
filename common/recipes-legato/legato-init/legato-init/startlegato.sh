#!/bin/sh
# Copyright (c) Sierra Wireless, Inc. Use of this work is subject to license.
#
# Provides a hook for legato into the init scripts
#
# The new legato start procedure begins at /mnt/legato/start
# If not found an attempt will be made to start an old style legato in case
# a user has accidentally installed new firmware in cwe without updating the built in legato.
# If this works it provides a chance for the user to correct the problem and upload a new cwe.
# No attempt will be made to install any old style Legato that may be found in the built in
# legato partition.

beginswith() { case $2 in $1*) true;; *) false;; esac; }

LEGATO_START=/mnt/legato/start

# This is where old startup lived. We can try this if we we don't have new startup.
STARTUP_DIR=/mnt/flash/startup

case "$1" in
    start)

        if [ -x $LEGATO_START ]
        then
            $LEGATO_START &
        else

            # Check for an old style startup and see if we can make it run.
            # This code will be removed in a not too distant future rootfs release.

            echo "WARNING: Valid Legato install not found."
            echo "Checking for legacy version and attempting alternate start up."
            # Make sure the directory actually exists
            if [ ! -d $STARTUP_DIR ]
            then
              echo "ERROR: Legato install missing, out of date or corrupted."
              echo "Exiting Legato startup."
              exit 0
            fi

            # Check our directory to see if there is anything to run
            files=`ls $STARTUP_DIR`
            cd $STARTUP_DIR

            # List the files in the order of their numeric id
            # Assumes fg_xx_script, or bg_xx_script where
            # xx identifies the start order

            files=`ls -1 | sort -k2 -t"_"`

            for file in $files
            do
              # Execute the files in order
              if [ -x $file -a -f $file -a -O $file ]
              then
                if beginswith fg_ "$file"; then
                  echo "Executing $file in foreground"
                  ./${file}
                elif beginswith bg_ "$file"; then
                  echo "Executing $file in background"
                  ./${file}&
                fi
              fi
            done

        fi
        ;;

    stop)
        # Do something to stop Legato
        echo "Legato shutdown sequence"
        if [ -x $LEGATO_START ]
        then
            $LEGATO_START stop
        else
            # We may have an old style legato install. Try to stop it.
            # This may not work but might as well try.
            # This code will be removed in a not too distant future rootfs release.
            echo "WARNING: Valid Legato install not found."
            echo "Checking for legacy version and attempting alternate shut down"
            if [ -f /usr/local/bin/legato ]
            then
                /usr/local/bin/legato stop
            else
                echo "ERROR: Legato install missing, out of date or corrupted."
            fi
        fi
        ;;

    *)
        exit 1
        ;;

esac

echo Finished Legato Start/Stop Sequence

