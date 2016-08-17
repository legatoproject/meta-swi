#!/bin/sh
# Copyright (c) Sierra Wireless, Inc. Use of this work is subject to license.
#
# Provides a hook for legato into the init scripts

LEGATO_START=/mnt/legato/start

case "$1" in
    start)
		echo "Legato start sequence"
        $LEGATO_START
        ;;

    stop)
        # Do something to stop Legato
        echo "Legato shutdown sequence"
        $LEGATO_START stop
        ;;

    *)
        exit 1
        ;;

esac

echo "Finished Legato $1 Sequence"
