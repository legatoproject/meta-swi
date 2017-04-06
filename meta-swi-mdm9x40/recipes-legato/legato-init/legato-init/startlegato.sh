#!/bin/sh
# Copyright (c) Sierra Wireless, Inc.
#
# Provides a hook for legato into the init scripts

umount /legato
if [ -e /mnt/legato/systems/current/read-only ]
then
    export PATH=/legato/systems/current/bin:$PATH
    LEGATO_START=/legato/systems/current/bin/start
    LEGATO_MNT=/mnt/legato
else
    LEGATO_START=/mnt/legato/start
    LEGATO_MNT=/mnt/flash/legato
fi


case "$1" in
    start)
        echo "Legato start sequence"
        mount -o bind $LEGATO_MNT /legato
        $LEGATO_START
        ;;

    stop)
        # Do something to stop Legato
        echo "Legato shutdown sequence"
        $LEGATO_START stop
        umount /legato
        ;;

    *)
        exit 1
        ;;

esac

echo "Finished Legato $1 Sequence"
