#!/bin/sh
# Set hostname from /etc/hostname file. If the file doesn't exist
# or it is an empty file, try to construct hostname from information
# embedded in device.

# import run environment
source /etc/run.env

INFOTOOL=/usr/bin/ud_getusbinfo

if [ -f /etc/hostname -a -s /etc/hostname ]; then
    # Assign hostname from /etc/hostname
    hostname -F /etc/hostname
else
    # Try to provide a unique identifier
    if [ -e "/etc/machine-id" ]; then
        SERIAL=$(cat /etc/machine-id)
    elif [ -x "$INFOTOOL" ]; then
        # Try IMEI
        SERIAL="$($INFOTOOL IMEI)"
        if [ $? -ne 0 ] || [ -z "$SERIAL" ]; then
            # If IMEI is not available, try with SER
            SERIAL="$($INFOTOOL SER)"
            if [ $? -ne 0 ]; then
                # Fallback to no unique identifier
                SERIAL=""
            fi
        fi
    fi

    # Try to provide a name
    if [ -e "/etc/devicename" ]; then
        DEVICENAME=$(cat /etc/devicename)
    elif [ -x "$INFOTOOL" ]; then
        # Try NAME
        DEVICENAME="$($INFOTOOL PROD | tr ' ' '\n' | tail -1)"
        if [ -z "$DEVICENAME" ] || [[ "$DEVICENAME" == "Parameter" ]]; then
            # If PROD is not available, try with NAME
            DEVICENAME="$($INFOTOOL NAME | tr ' ' '\n' | tail -1)"
            if [ -z "$DEVICENAME" ] || [[ "$DEVICENAME" == "Parameter" ]]; then
                DEVICENAME=""
            fi
        fi
    fi

    # Default to "SWI"
    DEVICENAME=${DEVICENAME:-"SWI"}
    if [ -n "$SERIAL" ]; then
        HOSTNAME="${DEVICENAME}-${SERIAL}"
    else
        HOSTNAME="${DEVICENAME}"
    fi

    if ! hostname $HOSTNAME; then
        echo "Unable to set hostname" >2
    fi
fi

