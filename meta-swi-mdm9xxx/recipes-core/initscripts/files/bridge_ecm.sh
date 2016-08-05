#!/bin/sh
# Copyright 2016 Sierra Wireless
#
# Bridge ECM/EEM to wired network interface

bridge_if=br0

# Check that we have brctl (and ifconfig) installed
[ -x /usr/sbin/brctl ] || exit 0
[ -x /sbin/ifconfig ] || exit 0

# Find wired interface, assume it's eth0
eth_if=$(ls /sys/class/net/ | grep eth0)
[ ! -z $eth_if ] || exit 0

# Find USB ECM interface
ecm_if=$(ls -1 /sys/class/net/ | egrep '(e[ec]m|usb)0')
[ ! -z $ecm_if ] || exit 0

# Create bridge
/usr/sbin/brctl addbr $bridge_if || exit 0

# Enslave interfaces
/usr/sbin/brctl addif $bridge_if $eth_if || exit 0
/usr/sbin/brctl addif $bridge_if $ecm_if || exit 0

# Make sure interfaces don't use IP
/sbin/ifconfig $eth_if 0.0.0.0
/sbin/ifconfig $ecm_if 0.0.0.0

# Enable bridge
/sbin/ifconfig $bridge_if up

