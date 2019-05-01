#!/bin/sh
# Copyright (C) Sierra Wireless Inc. Use of this work is subject to license.
#
# TI wireless wl18xx specific applications start or stop here
# TI WIFI IoT board is managed by SDIO/MMC bus. Some signals need to be set
# and managed before the SDIO/MMC module is inserted.
# TI WIFI IoT conflicts with others devices using the SDIO/MMC bus

# Some things are very specific to kernel version we are running.
KVERSION=

# Error codes required by Legato's own pa_wifi.sh. If for whatever reson you
# want to change these error codes, consult with Legato team first.

# Interface does not exist
TI_WIFI_PA_NO_IF_ERR=50

# Interface could not be brought up
TI_WIFI_PA_NO_IF_UP_ERR=100


# Make sure path thing is set properly.
export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin

GPIO_EXPORT=/sys/class/gpio/v2/alias_export
GPIO_UNEXPORT=/sys/class/gpio/v2/alias_unexport
GPIO_DIR=/sys/class/gpio/v2/aliases_exported/
if [ ! -e ${GPIO_EXPORT} ]; then
    GPIO_EXPORT=/sys/class/gpio/export
    GPIO_UNEXPORT=/sys/class/gpio/unexport
    GPIO_DIR=/sys/class/gpio/gpio
fi

# Extract kernel version
get_kversion()
{
    KVERSION=$( uname -r | awk -F. '{ print $1$2 }' )
}

ti_wifi_start() {
    # Add mdev rule for crda
    grep crda /etc/mdev.conf > /dev/null
    if [ $? -ne 0 ]; then
        (mount | grep -q " on /etc type ") || \
            (cp /etc/mdev.conf /tmp; mount -o bind /tmp/mdev.conf /etc/mdev.conf)
        echo "\$COUNTRY=.. root:root 0660 */sbin/crda" >> /etc/mdev.conf
    fi
    lsmod | grep wlcore >/dev/null
    if [ $? -ne 0 ]; then

        # This is only required for WP85, because kernel is different.
        if [ "${KVERSION}" = "314" ] ; then
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
        fi

        # Enable all GPIOs on all EXPANDERs
        gpioexp 1 1 enable >/dev/null || exit 127

        ### mangOH green has 3 expanders
        # Set IOTO_RESET, GPIO#4/EXPANDER#3 - IOT0 Reset signal is disabled
        gpioexp 3 4 output normal high >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "mangOH red board"

            # Set IOT0_GPIO2 = 1 (WP GPIO13)
            [ -d ${GPIO_DIR}13 ] || echo 13 >${GPIO_EXPORT}
            echo out >${GPIO_DIR}13/direction
            echo 1 >${GPIO_DIR}13/value

            # Set IOT0_RESET = 1 (WP GPIO2)
            [ -d ${GPIO_DIR}2 ] || echo 2 >${GPIO_EXPORT}
            echo out >${GPIO_DIR}2/direction
            echo 1 >${GPIO_DIR}2/value

            # Clear SDIO_SEL, GPIO#9/EXPANDER#1 - Select the SDIO
            gpioexp 1 9 output normal low >/dev/null || exit 127
        else
            echo "mangOH green board"

            # Set IOT0_GPIO2 = 1 (WP GPIO33)
            [ -d ${GPIO_DIR}33 ] || echo 33 >${GPIO_EXPORT}
            echo out >${GPIO_DIR}33/direction
            echo 1 >${GPIO_DIR}33/value

            # Clear SDIO_SEL, GPIO#13/EXPANDER#1 - Select the SDIO
            gpioexp 1 13 output normal low >/dev/null || exit 127
        fi

        # Kernel 3.14 only.
        if [ "${KVERSION}" = "314" ] ; then
            modprobe msm_sdcc || exit 127
        fi

        modprobe wlcore || exit 127
        modprobe wlcore_sdio || exit 127
        modprobe wl18xx || exit 127
    fi
    attempt=6
    for i in $(seq 1 ${attempt})
    do
        if [ $i -ne 1 ]; then
            sleep 1
        fi
        (ifconfig -a | grep wlan0 > /dev/null) && break
    done
    if [ $? -ne 0 ]; then
        echo "Failed to start TI wifi, interface does not exist."
        exit ${TI_WIFI_PA_NO_IF_ERR}
    fi
    ifconfig wlan0 up > /dev/null
    if [ $? -ne 0 ] ; then
        echo "Failed to start TI wifi, interface can not be brought up."
        exit ${TI_WIFI_PA_NO_IF_UP_ERR}
    fi
}

ti_wifi_stop() {

    local tmp=

    ifconfig | grep wlan0 >/dev/null
    if [ $? -eq 0 ]; then
        ifconfig wlan0 down
    fi
    lsmod | grep wlcore >/dev/null

    # If module unloading fails, it may be for different reasons: someone is
    # using it, cannot be unoaded because it crashed, etc. Since there is
    # nothing we can do about it, we should just continue on.
    if [ $? -eq 0 ]; then
        rmmod wl18xx >/dev/null 2>&1
        rmmod wlcore_sdio >/dev/null 2>&1
        rmmod wlcore >/dev/null 2>&1
        rmmod mac80211 >/dev/null 2>&1
        rmmod cfg80211 >/dev/null 2>&1

        # compat and msm_sdcc exist on kernel 3.14 only.
        if [ "${KVERSION}" = "314" ] ; then
            tmp=$( lsmod | grep "^compat " )
            if [ "x$tmp" != "x" ] ; then
                rmmod compat >/dev/null 2>&1
            fi

            rmmod msm_sdcc >/dev/null 2>&1
        fi

        # Clear IOTO_RESET, GPIO#4/EXPANDER#3 - IOT0 Reset signal is enabled
        gpioexp 3 4 output normal low >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "mangOH red board"
            # Set IOT0_RESET = 1 (WP GPIO2)
            echo 0 >${GPIO_DIR}2/value

            # Clear SDIO_SEL, GPIO#9/EXPANDER#1 - Deselect the SDIO
            gpioexp 1 9 output normal high >/dev/null || exit 127

            # Reset IOT0_GPIO2 = 0 (WP GPIO13)
            echo 0 >${GPIO_DIR}13/value

            echo 13 >${GPIO_UNEXPORT}
            echo 2 >${GPIO_UNEXPORT}
        else
            echo "mangOH green board"
            # Set SDIO_SEL, GPIO#13/EXPANDER#1 - Deselect the SDIO
            gpioexp 1 13 output normal high >/dev/null || exit 127

            # Reset IOT0_GPIO2 = 0 (WP GPIO33)
            echo 0 >${GPIO_DIR}33/value

            # Unexport the GPIO
            echo 33 >${GPIO_UNEXPORT}
       fi

       if [ "${KVERSION}" = "314" ] ; then
           # Insert MMC/SDIO module
           modprobe msm_sdcc || exit 127
       fi

    fi
}

# Get kernel version before doing anything else.
get_kversion

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
