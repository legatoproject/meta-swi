#!/bin/sh
# Copyright (c) 2014 Sierra Wireless
#

DEVICE=/dev/usb_link

case "$1" in
    start)
        if [ -x /usr/bin/linkmon ] && [ -c ${DEVICE} ]
        then
            echo "${DEVICE}" > /sys/power/wake_lock
            echo -n "Starting linkmon: "
            start-stop-daemon -S -b -a /usr/bin/linkmon -- ${DEVICE}
            echo "done"
        fi

        # Enable the autosleep feature
        if [ -f /sys/power/autosleep ]
        then
            echo mem > /sys/power/autosleep
            true
        fi
        ;;
    stop)
        echo off > /sys/power/autosleep
        echo -n "Stopping linkmon: "
        start-stop-daemon -K -n linkmon
        echo "done"
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        exit 1
        ;;
esac

exit 0
