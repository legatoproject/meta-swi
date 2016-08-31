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

# This is where old startup lived. We can try this if we we don't have new startup.
COMPAT_STARTUP=/etc/init.d/startlegato-compat.sh


case "$1" in
    start)

        mount -o bind $LEGATO_MNT /legato
        if [ -x $LEGATO_START ]
        then
            $LEGATO_START
        else
            $COMPAT_STARTUP start
        fi

        ;;

    stop)
        # Do something to stop Legato
        echo "Legato shutdown sequence"
        if [ -x $LEGATO_START ]
        then
            $LEGATO_START stop
        else
            $COMPAT_STARTUP stop
        fi
        umount /legato
        ;;

    *)
        exit 1
        ;;

esac

echo Finished Legato Start/Stop Sequence

