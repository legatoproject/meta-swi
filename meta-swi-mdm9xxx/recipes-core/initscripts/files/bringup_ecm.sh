#!/bin/sh
# Copyright 2012 Sierra Wireless
#
# Bring up ecm (i.e. developer interface)

SYSTEM_BIN_PATH=/legato/systems/current/bin
DNSMASQ_LEASE_FILE=/var/lib/misc/dnsmasq.leases

# The f_ecm/*addr (MAC addr file) can be in various places
MAC_ADDR_FILE_1=/sys/devices/virtual/android_usb/android0/f_ecm/ecm_ethaddr
MAC_ADDR_FILE_2=/sys/devices/virtual/android_usb/android0/f_ecm/native_ethaddr
MAC_ADDR_FILE_3=/sys/kernel/config/usb_gadget/g1/functions/ecm.usb0/host_addr

ecm_mac_addr_files="$MAC_ADDR_FILE_1 $MAC_ADDR_FILE_2 $MAC_ADDR_FILE_3"

set_host_mac_file()
{
   for ecm_test_path in $ecm_mac_addr_files; do
       if [ -f $ecm_test_path ]; then
            ecm_mac_file="$ecm_test_path"
            break
       fi
   done
}

ecm_dhcp_conf=/etc/dnsmasq.d/dnsmasq.ecm.conf
ecm_conf=/etc/legato/ecm.conf

# adds the necessary configs to the dhcp server
config_dhcp()
{
    local host_addr=$1
    local ecm_if=$2
    echo "dhcp-range=interface:$ecm_if,$host_addr,$host_addr,12h" >>$ecm_dhcp_conf
    echo "dhcp-option=$ecm_if,3" >>$ecm_dhcp_conf
    echo "dhcp-option=$ecm_if,6" >>$ecm_dhcp_conf
}

write_config()
{
    local targ_addr=$1
    local host_addr=$2
    local mask=$3

    echo "Do not edit this file." > $ecm_conf
    echo "Use configEcm command to change these configs." >> $ecm_conf
    echo "" >> $ecm_conf
    echo "target.ipV4: $targ_addr" >> $ecm_conf
    echo "host.ipV4: $host_addr" >> $ecm_conf
    echo "netmask.ipV4: $mask" >> $ecm_conf
}

remove_dhcp_config()
{
    local ecm_if=$1
    local find="interface:$ecm_if,"

    # Only remove the file if the device that is going down matches
    # that one that had been configured in the file.
    if [ -e $ecm_dhcp_conf ] && grep -F $find $ecm_dhcp_conf > /dev/null ; then
        rm -f $ecm_dhcp_conf
    fi
}

restart_ecm()
{
    /etc/init.d/usb restart

    # we need to clean out the leases database ourselves and it seems we
    # need to delete the file completely!! Just clearing the entry doesn't work and
    # dhcp_release doesn't work.
    /etc/init.d/dnsmasq stop
    rm -f /var/lib/misc/dnsmasq.leases
    /etc/init.d/dnsmasq start
}

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
    mac_addr=`cat $ecm_mac_file`
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

IPTablesUpDown()
{
    local ecm_if=$1
    local AorD=$2

    # (Dis)allow IPv4 SSH, PING and DHCP over ECM interface.
    iptables $AorD INPUT -i $ecm_if -p tcp -m tcp --dport 22 -j ACCEPT
    iptables $AorD INPUT -i $ecm_if -p icmp -m icmp --icmp-type 8 -j ACCEPT
    iptables $AorD INPUT -i $ecm_if -p udp --dport 67:68 --sport 67:68 -j ACCEPT

    # (Dis)allow IPv6 PING and DHCP over ECM interface.
    ip6tables $AorD INPUT -i $ecm_if -p tcp -m tcp --dport 22 -j ACCEPT
    ip6tables $AorD INPUT -i $ecm_if -p ipv6-icmp -m icmp6 --icmpv6-type 128 -j ACCEPT
    ip6tables $AorD INPUT -i $ecm_if -p udp --dport 67:68 --sport 67:68 -j ACCEPT
}

IsPreviouslyConfiguredDevice()
{
    local ecm_if=$1
}

BringUpEcm()
{
    local gmode1=/sys/class/android_usb/android0/functions
    local gmode2=/sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration
    local ecm_if
    local gadget_mode

    if [ -f $gmode1 ]; then
        gadget_mode=$gmode1
    elif [ -f $gmode2 ]; then
        gadget_mode=$gmode2
    else
        echo "$0: no gadget mode file."
	return 1
    fi

    if [ "$ACTION" == add -a "$DEVTYPE" == gadget ]; then
        # we have been called from a hotplug handler;
        # DEVPATH has the device info for us:
        ecm_if=$(basename "$DEVPATH")

        # If the PCONFIG flag is set then change the default IP address
        if [ -f /mnt/userrw/PCONFIG ]
        then
            ecm_default_ip=192.168.200.1
        else
            ecm_default_ip=192.168.2.2
        fi

        # only do this if ecm or eem are part of usb composition
        if [ -f $gadget_mode ]; then
            ecm=$(egrep -i "e[ce]m" ${gadget_mode})
            if [ ! -z "$ecm" ]; then
                # If the configuration file doesn't exists, create a default one
                if [ ! -f /mnt/userrw/PCONFIG ] && [ ! -f $ecm_conf ]; then
                    targ_addr="192.168.2.2"
                    host_addr="192.168.2.3"
                    mask="255.255.255.0"

                    write_config $targ_addr $host_addr $mask
                    config_dhcp "$host_addr" $ecm_if
                    restart_ecm
                fi
                if [ -f $ecm_conf ]; then
                    # Read configuration from the (already created) config file
                    ecm_netmask=$( BringUpEcm_get_param netmask.ipV4 )
                    ecm_target_ip4=$( BringUpEcm_get_param target.ipV4 )

                    set_host_mac_file
                    if [ -f "$ecm_mac_file" ]; then
                        CreateLeaseFileRestartDnsmasq
                    fi
                else
                    # Config file doesn't exist.  Use defaults.
                    ecm_netmask=255.255.255.0
                    ecm_target_ip4=$ecm_default_ip
                fi
                ifconfig $ecm_if $ecm_target_ip4 netmask $ecm_netmask up
            fi

            # Add ECM-related firewall rules.
            IPTablesUpDown $ecm_if -A
        fi
    elif [ "$ACTION" == remove -a "$DEVTYPE" == gadget ]; then
        # we have been called from a hotplug handler to remove
        # DEVPATH has the device info for us:
        ecm_if=$(basename "$DEVPATH")

        # Take out ECM-related firewall rules.
        IPTablesUpDown $ecm_if -D

        # Remove config file
        remove_dhcp_config $ecm_if
    else
        echo "$0: must be called from hotplug."
        return 1
    fi
}

BringUpEcm
