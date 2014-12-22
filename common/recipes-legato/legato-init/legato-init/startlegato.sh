#!/bin/sh
# Copyright 2013 Sierra Wireless
#
# Provides a hook for legato into the init scripts


STARTUP_DIR=/mnt/flash/startup
STOP_FILE1=".STOPLEGATO"
STOP_FILE2="STOPLEGATO"
PRE_INSTALL_DIR=/mnt/legato/usr/local/bin

case "$1" in
    start)

        # Check for a new uninitialized install
        if [ -x $PRE_INSTALL_DIR/legato ]
        then
            $PRE_INSTALL_DIR/legato bootcheck
        fi

        echo "Legato start sequence"
        # Make sure the directory actually exists
        if [ ! -d $STARTUP_DIR ]
        then
          echo "Startup directory not found. Exiting Legato startup"
          exit 0
        fi

        # Check our directory to see if there is anything to run
        files=`ls $STARTUP_DIR`
        cd $STARTUP_DIR

        if [ -f $STOP_FILE1 -o -f $STOP_FILE2 ]
        then
          echo "Legato startup sequence aborted"
          exit 0
        else
          echo "stop file not present ... continuing"
        fi

        fgfiles=`echo $files | grep fg_`
        bgfiles=`echo $files | grep -v fg_`

        for file in $fgfiles
        do
          # Execute these files in the foreground
          if [ -x $file -a -f $file -a -O $file ]
          then
            echo "Executing $file"
            ./${file}
          fi
        done

        # Now handle the background ones
        for file in $bgfiles
        do
          # Execute these files in the foreground
          if [ -x $file -a -f $file -a -O $file ]
          then
            echo "Executing $file in the background"
            ./${file} &
          fi
        done

        if [ -x $PRE_INSTALL_DIR/legato ]
        then
            $PRE_INSTALL_DIR/legato postbootcheck
        fi
        ;;

    stop)
        # Do something to stop Legato
        echo "Legato shutdown sequence"
        if [ -f /usr/local/bin/legato ]
        then 
            /usr/local/bin/legato stop
        fi
        ;;

    *)
        exit 1
        ;;

esac

echo Finished Legato Sequence

