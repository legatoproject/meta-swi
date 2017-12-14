#!/bin/sh
# Copyright 2016 Sierra Wireless
#
# Script to load modem image

#load modem image once modem partition is mounted

case "$1" in
    start)
        search_dir="/sys/bus/msm_subsys/devices/"
        for entry in `ls $search_dir`
        do
            subsys_temp=`cat $search_dir/$entry/name`
            if [ "$subsys_temp" == "modem" ]
            then
                # Send '1' to firmware_load to trigger Kernel load modem image to Q6.
                # The whole operation will take about 6s, running in background so that it will not
                # block the following startup scripts.
                echo 1 > $search_dir/$entry/firmware_load &
            fi
done
        ;;
    stop)
        # Currently Kernel doesn't support to stop modem. Keep placeholder so it can extend in the
        # future.
        ;;
    *)
        exit 1
        ;;
esac

exit 0
