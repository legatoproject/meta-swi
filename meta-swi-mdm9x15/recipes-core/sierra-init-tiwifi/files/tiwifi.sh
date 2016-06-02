#!/bin/sh
# Copyright (C) Sierra Wireless Inc. Use of this work is subject to license.
#
# TI wireless wl18xx specific applications start or stop here
# TI WIFI IoT board is managed by SDIO/MMC bus. Some signals need to be set
# and managed before the SDIO/MMC module is inserted.
# TI WIFI IoT conflicts with others devices using the SDIO/MMC bus

export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin

ti_wifi_start() {
    # Add mdev rule for crda
    grep crda /etc/mdev.conf > /dev/null
    if [ $? -ne 0 ]; then
       echo "\$COUNTRY=.. root:root 0660 */sbin/crda" >> /etc/mdev.conf
    fi
    lsmod | grep wlcore >/dev/null
    if [ $? -ne 0 ]; then
       # Check if MMC/SDIO module is inserted. Because WIFI use SDIO/MMC bus
       # we need to remove the SDIO/MMC module
       lsmod | grep msm_sdcc >/dev/null
       if [ $? -eq 0 ]; then
          grep -q mmcblk /proc/mounts
          if [ $? -ne 0 ]; then
             rmmod msm_sdcc
          else
             false
          fi
          if [ $? -ne 0 ]; then
             # Unable to remove. May be others devices use SDIO/MMC bus
             echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
             echo "Unable to remove the SDIO/MMC module... May be in use ?"
             echo "Please, free all SDIO/MMC devices before using TI WIFI."
             echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
             exit 127
          fi
       fi

       # Set IOT0_GPIO2 = 1 (WP GPIO33)
       [ -d /sys/class/gpio/gpio33 ] || echo 33 >/sys/class/gpio/export
       echo out >/sys/class/gpio/gpio33/direction
       echo 1 >/sys/class/gpio/gpio33/value

       # Enable all GPIOs on all EXPANDERs
       gpioexp 1 1 enable >/dev/null || exit 127
       # Clear SDIO_SEL, GPIO#13/EXPANDER#1 - Select the SDIO
       gpioexp 1 13 output normal low >/dev/null || exit 127
       # Set IOTO_RESET, GPIO#4/EXPANDER#3 - IOT0 Reset signal is disabled
       gpioexp 3 4 output normal high >/dev/null || exit 127

       # Set IOT0_GPIO4 = 1 (WP GPIO8)
       [ -d /sys/class/gpio/gpio8 ] || echo 8 >/sys/class/gpio/export
       echo out >/sys/class/gpio/gpio8/direction
       echo 1 >/sys/class/gpio/gpio8/value

       modprobe msm_sdcc || exit 127

       modprobe wlcore || exit 127
       modprobe wlcore_sdio || exit 127
       modprobe wl18xx || exit 127
    fi
    sleep 5
    ifconfig -a | grep wlan0 >/dev/null
    if [ $? -ne 0 ] ; then
        echo "Failed to start TI wifi"; exit 127
    fi
    ifconfig wlan0 up >/dev/null
    if [ $? -ne 0 ] ; then
        echo "Failed to start TI wifi"; exit 127
    fi
}

ti_wifi_stop() {
    ifconfig | grep wlan0 >/dev/null
    if [ $? -eq 0 ]; then
       ifconfig wlan0 down
    fi
    lsmod | grep wlcore >/dev/null
    if [ $? -eq 0 ]; then
       rmmod wl18xx || exit 127
       rmmod wlcore_sdio || exit 127
       rmmod wlcore || exit 127
       rmmod mac80211 || exit 127
       rmmod cfg80211 || exit 127
       rmmod compat || exit 127

       rmmod msm-sdcc || exit 127

       # Reset IOT0_GPIO4 = 0 (WP GPIO8)
       echo 0 >/sys/class/gpio/gpio8/value
       # Clear IOTO_RESET, GPIO#4/EXPANDER#3 - IOT0 Reset signal is enabled
       gpioexp 3 4 output normal low >/dev/null || exit 127
       # Set SDIO_SEL, GPIO#13/EXPANDER#1 - Deselect the SDIO
       gpioexp 1 13 output normal high >/dev/null || exit 127
       # Reset IOT0_GPIO2 = 0 (WP GPIO33)
       echo 0 >/sys/class/gpio/gpio33/value

       # Insert MMC/SDIO module
       modprobe msm_sdcc || exit 127
    fi
}

case "$1" in
    start)
        ti_wifi_start
        ;;
    stop)
        ti_wifi_stop
        ;;
    restart)
        ti_wifi_stop
        ti_wifi_start
        ;;
    *)
        exit 1
        ;;
esac

exit 0
