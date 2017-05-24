#!/bin/sh
# Copyright 2012 Sierra Wireless
#
# Bring up ecm (i.e. developer interface)

SYSTEM_BIN_PATH=/legato/systems/current/bin
DNSMASQ_LEASE_FILE=/var/lib/misc/dnsmasq.leases
ECM_MAC_ADDR_FILE=/sys/devices/virtual/android_usb/android0/f_ecm/native_ethaddr

BringUpEcm_get_param()
{
    local line=$( grep "$1" $ecm_conf 2>/dev/null )
    echo ${line#*:}
}

#
# This function creates early lease file and restart dnsmasq to bringup ecm interface quickly.
#
CreateLeaseFileRestartDnsmasq()
{
    mac_addr=`cat $ECM_MAC_ADDR_FILE`
    host_ipv4_addr=$( BringUpEcm_get_param host.ipV4 )
    expiry_time=`date +'%s'`
    # Add 12 hour with current time to get lease expiry time.
    expiry_time=$((expiry_time + 3600 * 12))
    # Stop dnsmasq to avoid race condition.
    /etc/init.d/dnsmasq stop
    # Check whether this is an entry in dnsmasq lease file.
    if ! grep -i "$mac_addr" $DNSMASQ_LEASE_FILE > /dev/null 2>&1
    then
      # No entry in lease file. Create an entry and append it.
      echo "$expiry_time $mac_addr $host_ipv4_addr * *" >> $DNSMASQ_LEASE_FILE
    fi
    # Start dnsmasq again.
    /etc/init.d/dnsmasq start
}

BringUpEcm()
{
    gadget_mode=/sys/class/android_usb/android0/functions
    ecm_conf=/etc/legato/ecm.conf
    ecm_if=$(ls -1 /sys/class/net/ | egrep '(e[ec]m|usb)0')

    if [ -z "$ecm_if" ]; then
        return
    fi

    set -- $ecm_if
    if [ $# -gt 1 ]; then
        echo "ecm: warning, more than one ECM interface detected ($ecm_if)"
    fi
    ecm_if=$1

    # If the PCONFIG flag is set then change the default IP address
    if [ -f /mnt/userrw/PCONFIG ]
    then
        ecm_default_ip=192.168.200.1
    else
        ecm_default_ip=192.168.2.2
    fi

    # only do this if ecm or eem are part of usb composition
    if [ -f $gadget_mode ]; then
        ecm=$(egrep "e[ce]m" ${gadget_mode})
        if [ ! -z "$ecm" ]; then
            if [ -e "$SYSTEM_BIN_PATH/configEcm" ]; then
                # Upgrade to new ecm file layout for dnsmasq
                $SYSTEM_BIN_PATH/configEcm upgrade
                # If the configuration file doesn't exists, create a default one
                if [ ! -f /mnt/userrw/PCONFIG ] && [ ! -f $ecm_conf ]; then
                    $SYSTEM_BIN_PATH/configEcm default
                fi
            fi
            if [ -f $ecm_conf ]; then
                # Read configuration from the (now created) config file
                ecm_netmask=$( BringUpEcm_get_param netmask.ipV4 )
                ecm_target_ip4=$( BringUpEcm_get_param target.ipV4 )
                CreateLeaseFileRestartDnsmasq
            else
                # Config file doesn't exist.  Use defaults.
                ecm_netmask=255.255.255.0
                ecm_target_ip4=$ecm_default_ip
            fi

            ifconfig $ecm_if $ecm_target_ip4 netmask $ecm_netmask up

        fi
    fi
}


BringUpEcm &
