#!/bin/sh
# Copyright (c) Sierra Wireless, Inc.
#
# Provides a hook for legato into the init scripts

if [ -e "/etc/run.env" ]; then
    source /etc/run.env
fi

FLASH_MOUNTPOINT=${FLASH_MOUNTPOINT:-/mnt/flash}
FLASH_MOUNTPOINT_LEGATO=${FLASH_MOUNTPOINT_LEGATO:-/mnt/legato}

if [ -e "${FLASH_MOUNTPOINT_LEGATO}/systems/current/read-only" ]
then
    export PATH=/legato/systems/current/bin:$PATH
    LEGATO_START=/legato/systems/current/bin/start
    LEGATO_MNT=${FLASH_MOUNTPOINT_LEGATO}
else
    LEGATO_START=${FLASH_MOUNTPOINT_LEGATO}/start
    LEGATO_MNT=${FLASH_MOUNTPOINT}/legato

    # Create mountpoint in case it doesn't already exists.
    mkdir -p ${LEGATO_MNT}
fi

case "$1" in
    start)
        echo "Legato start sequence"

        umount /legato 2>/dev/null
        mount -o bind $LEGATO_MNT /legato

        test -x $LEGATO_START && $LEGATO_START
        ;;

    stop)
        # Do something to stop Legato
        echo "Legato shutdown sequence"
        test -x $LEGATO_START && $LEGATO_START stop
        umount /legato
        ;;

    *)
        exit 1
        ;;

esac

echo "Finished Legato $1 Sequence"
