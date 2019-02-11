#!/bin/sh
# Copyright (C) Sierra Wireless Inc. Use of this work is subject to license.
# Dragan Marinkovic (dmarinkovi@sierrawireless.com)
#
# Setup script for QCA9377 chipset.
#
# It will handle:
# * Start WiFi
# * Stop WiFi
# * Start WiFi in client mode
# * Start WiFi in AP mode
# * Start and stop BT.
#
# At this time, it is assuming single instance of WiFi and single instance
# of BT functionality.
#
# The way to call this executable:
#
#   qca9377 <service> <mode> <action>
#
# service - "wifi" or "bt"
# action - "start" or "stop"
# mode - "client" or "ap"

# Currently, this implementation works for MangOH Red with WP76
# module only.
#

# import run environment
source /etc/run.env

# The name of this script. This is mandatory for 'swi_log' as well.
this_e=$( basename $0 )

# Only partial lock
run_lock="/var/lock/${this_e}_"

# WiFi lock. System could run in only one mode at the time
# (e.g. "ap" or "client").
run_wifi_lock=/var/lock/${this_e}_wifi.lock

# BT lock
run_bt_lock=/var/lock/${this_e}_bt.lock

# Serial port and BT communication.
bt_chipset=qca
bt_port_prefix=/dev
bt_port=$bt_port_prefix/ttyHS0
bt_port_speed=3000000
bt_port_tout=120
bt_port_ctrl=flow

# qca wifi module name
qca_wifi_mod=wlan

# cfg80211 module name
cfg_wifi_mod=cfg80211

# Ip address required for AP mode. It must be in range
# specified in dnsmasq.conf .
ap_mode_ip="192.168.43.1"

# Must be the same as in hostapd and dnsmasq config files.
interface=wlan0

# To add the rule: iptables -A $fwrule
# To remove the rule: iptables -D $fwrule
fwrule="INPUT -i $interface -p udp --dport 67:68 --sport 67:68 -j ACCEPT"

#
# Some useful methods
#

# How to use this command
usage()
{
cat << EOF

  Usage:
    $this_e <service> <mode> <action>

  Where:
    service - "wifi" or "bt"
    mode - "client" or "ap" for WiFi, and serial port for BT (e.g. ttyHSx or default)
    action - "start" or "stop"
EOF

    return $SWI_OK
}

# Check if operation is locked.
is_locked()
{
    local ret=$SWI_FALSE

    if [ -f $run_lock ] ; then
        ret=$SWI_TRUE
    fi

    return $ret
}

# Set operation lock
set_lock()
{
    touch $run_lock

    return $SWI_OK
}

# Remove operation lock
clear_lock()
{
    rm -f $run_lock

    return $SWI_OK
}

# Load kernel module required for WiFi operation
load_wifi_modules()
{
    local ret=$SWI_OK
    local clogging_hide_warn=3
    local clogging=

    # Kernel module warnings may be confusing, hide them.
    clogging=$( cat /proc/sys/kernel/printk | awk '{ print $1 }' )
    echo $clogging_hide_warn >/proc/sys/kernel/printk

    # If module is already loaded, modprobe
    # will not complain about it, it will
    # silently exit with 0.
    modprobe $qca_wifi_mod
    if [ $? -ne 0 ] ; then
        ret=$SWI_ERR
    fi

    echo $clogging >/proc/sys/kernel/printk

    return $ret
}

# Remove QCA kernel WiFi module.
rm_wifi_modules()
{
    local ret=$SWI_OK
    local clogging_hide_warn=3
    local clogging=

    # Kernel module warnings may be confusing, hide them.
    clogging=$( cat /proc/sys/kernel/printk | awk '{ print $1 }' )
    echo $clogging_hide_warn >/proc/sys/kernel/printk

    # If it fails, there is nothing we could do about it, so
    # do not return an error.
    rmmod $qca_wifi_mod >/dev/null 2>&1
    rmmod $cfg_wifi_mod >/dev/null 2>&1

    echo $clogging >/proc/sys/kernel/printk

    return $ret
}

# Remove BT kernel modules, if these are not used.
rm_bt_modules()
{
    local ret=$SWI_OK

    # If these could not be removed, there is really nothing we could do about
    # it, so keep quiet.
    rmmod bnep  >/dev/null 2>&1
    rmmod hci_uart  >/dev/null 2>&1
    rmmod bluetooth  >/dev/null 2>&1

    return $ret
}

# Add firewall rule needed for dnsmasq to honor DHCP
# requests.
open_fw()
{
    local ret=$SWI_OK

    iptables -A $fwrule

    return $ret
}

# Remove firewall rule needed for dnsmasq
close_fw()
{
    local ret=$SWI_OK

    # Do not care about complaints.
    iptables -D $fwrule >/dev/null 2>&1

    return $ret
}

# Check environment
check_env()
{
    local ret=${SWI_OK}
    local service=$1
    local mode=$2
    local action=$3
    local clogging_hide_warn=3
    local clogging=

    # Check if services are correct.
    if [ "x$service" != "xwifi" -a \
         "x$service" != "xbt" ] ; then
        swi_log "Only wifi and bt services are supported at this time."
        usage
        return $SWI_ERR
    fi

    # This is global variable, needs to be structured certain way, so be careful.
    run_lock="${run_lock}${service}.lock"

    # Only start and stop actions are supported.
    if [ "x$action" != "xstart" -a \
         "x$action" != "xstop" ] ; then
        swi_log "Action [$action] is not supported."
        usage
        return $SWI_ERR
    fi

    # Need to check if mode of operation os correct. Since BT does not
    # have mode as wifi does, we would need to check this for wifi
    # and BT separately.

    # Check WiFi modes.
    if [ "x$service" = "xwifi" ] ; then
        # Only ap or client modes are supported.
        if [ "x$mode" != "xap" -a \
             "x$mode" != "xclient" ] ; then
            swi_log "Wifi mode [$mode] is not supported."
            usage
            return $SWI_ERR
        fi
    fi

    # For bluetooth, mode has different meaning, it's actually
    # a serial port to use.
    if [ "x$service" = "xbt" ] ; then
        # If "default" was on the command line, use default
        # specified in this executable.
        if [ "x$mode" != "xdefault" ] ; then
            bt_port=$bt_port_prefix/$mode
        fi

        if [ ! -c $bt_port ] ; then
            swi_log "BT port [$bt_port] does not exist."
            usage
            return $SWI_ERR
        fi
    fi

    # If we are required to stop, there is no real reason to
    # check for anything else.
    if [ "x$action" = "xstop" ] ; then
        return $SWI_OK
    fi

    # If lock exists, we cannot run (action is "start").
    is_locked
    if [ $? -eq $SWI_TRUE ] ; then
        swi_log "Run lock exists, stop the running system first."
        return $SWI_ERR
    else
        # There is no run lock, so create one.
        set_lock
    fi

    # Hide warnings on the console.
    clogging=$( cat /proc/sys/kernel/printk | awk '{ print $1 }' )
    echo $clogging_hide_warn >/proc/sys/kernel/printk

    # Enable all GPIOs on all EXPANDERs
    gpioexp 1 1 enable >/dev/null
    if [ $? -ne 0 ] ; then
        swi_log "Cannot enable GPIOs".
        clear_lock
        echo $clogging >/proc/sys/kernel/printk
        return $SWI_ERR
    fi

    # Let's see if this is the right platform for us. For example,
    # We are not going to pretend that we are capable of running
    # on MangOH green.
    gpioexp 3 4 output normal high >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
        swi_log "This is not MangOH Red platform, giving up."
        clear_lock
        echo $clogging >/proc/sys/kernel/printk
        return $SWI_ERR
    fi

    echo $clogging >/proc/sys/kernel/printk

    return $ret
}

# Set all GPIOs to support QCA IoT operation
set_gpios()
{
    local ret=$SWI_OK

    # Set IOT0_GPIO2 = 1 (WP GPIO13)
    if [ ! -d /sys/class/gpio/gpio13 ] ; then
        swi_log "Setting up IOT0_GPIO2 = 1 (WP GPIO13)..."
        echo 13 >/sys/class/gpio/export
        echo out >/sys/class/gpio/gpio13/direction
        echo 1 >/sys/class/gpio/gpio13/value
    fi

    # Set IOT0_GPIO3 = 1 (WP GPIO7)
    if [ ! -d /sys/class/gpio/gpio7 ] ; then
        swi_log "Setting up IOT0_GPIO3 = 1 (WP GPIO7)..."
        echo 7 >/sys/class/gpio/export
        echo out >/sys/class/gpio/gpio7/direction
        echo 1 >/sys/class/gpio/gpio7/value
    fi

    # Set IOT0_RESET = 1 (WP GPIO2)
    if [ ! -d /sys/class/gpio/gpio2 ] ; then
        swi_log "Setting up IOT0_RESET = 1 (WP GPIO2)..."
        echo 2 >/sys/class/gpio/export
        echo out >/sys/class/gpio/gpio2/direction
        echo 1 >/sys/class/gpio/gpio2/value
    fi

    # Clear SDIO_SEL, GPIO#9/EXPANDER#1 - Select the SDIO
    swi_log "Clearing SDIO_SEL, GPIO#9/EXPANDER#1, selecting the SDIO..."
    gpioexp 1 9 output normal low >/dev/null 2>&1

    # Set IOT0_GPIO4 = 1 (WP GPIO8)
    if [ ! -d /sys/class/gpio/gpio8 ] ; then
        swi_log "Setting up IOT0_GPIO4 = 1 (WP GPIO8)..."
        echo 8 >/sys/class/gpio/export
        echo out >/sys/class/gpio/gpio8/direction
        echo 1 >/sys/class/gpio/gpio8/value
    fi

    # Set CARD_DETECT_IOT0 (WP GPIO33)
    if [ ! -d /sys/class/gpio/gpio33 ] ; then
        swi_log "Setting up CARD_DETECT_IOT0 (WP GPIO33)..."
        echo 33 >/sys/class/gpio/export
        echo in >/sys/class/gpio/gpio33/direction
    fi

    # Need to wait for GPIOs to stabilize before returning.
    sleep 1

    return $ret
}

# Clear all GPIOs previously set (more like hide them).
clear_gpios()
{
    local ret=$SWI_OK

    # Clear IOT0_GPIO2 = 1 (WP GPIO13)
    if [ -d /sys/class/gpio/gpio13 ] ; then
        swi_log "Clearing IOT0_GPIO2 = 1 (WP GPIO13)..."
        echo 13 >/sys/class/gpio/unexport
    fi

    # Clear IOT0_GPIO3 = 1 (WP GPIO7)
    if [ -d /sys/class/gpio/gpio7 ] ; then
        swi_log "Clearing up IOT0_GPIO3 = 1 (WP GPIO7)..."
        echo 7 >/sys/class/gpio/unexport
    fi

    # Clear IOT0_RESET = 1 (WP GPIO2)
    if [ -d /sys/class/gpio/gpio2 ] ; then
        swi_log "Clearing IOT0_RESET = 1 (WP GPIO2)..."
        echo 2 >/sys/class/gpio/unexport
    fi

    # Clear IOT0_GPIO4 = 1 (WP GPIO8)
    if [ -d /sys/class/gpio/gpio8 ] ; then
        swi_log "Clearing IOT0_GPIO4 = 1 (WP GPIO8)..."
        echo 8 >/sys/class/gpio/unexport
    fi

    # Clear CARD_DETECT_IOT0 (WP GPIO33)
    if [ -d /sys/class/gpio/gpio33 ] ; then
        swi_log "Clearing CARD_DETECT_IOT0 (WP GPIO33)..."
        echo 33 >/sys/class/gpio/unexport
    fi

    return $ret
}

# Start qca BT service.
# For now, this does nothing.
qca_bt_start()
{
    local ret=$SWI_OK
    local attached=0
    local ser_dev=$( basename $bt_port )
    local used_ser_dev=""
    local bt_devs=""
    local bt_service=""

    # set gpios
    set_gpios
    if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    # Do we have to start hciattach? There could be multiple serial devices,
    # however, these could be attached to only one corresponding physical
    # BT device each. At this time, I could not find a way to break that
    # connection. So, I need to determine if serial device to be used
    # is already attached to any of the BT devices.
    if [ -d /sys/class/bluetooth ] ; then
        # The list of already used BT devices is located here.
        bt_devs=$( ls /sys/class/bluetooth )
    fi

    # Check the current BT+serial port binding
    if [ "x$bt_devs" != "x" ] ; then
        for bt_dev in $bt_devs ; do
            used_ser_dev=$( cat /sys/class/bluetooth/$bt_dev/device/uevent | grep DEVNAME | awk -F'=' '{print $2}' )
            if [ "x$used_ser_dev" = "x$ser_dev" ] ; then
                swi_log "serial device [$ser_dev] already attached to [$bt_dev], will skip attach."
                attached=1
            fi
        done
    fi

    # If we are here, all is good and we can bind serial port to BT device
    if [ $attached -eq 0 ] ; then
        hciattach $bt_port $bt_chipset $bt_port_speed -t $bt_port_tout $bt_port_ctrl
        if [ $? -ne 0 ] ; then return $SWI_ERR ; fi
    fi

    # Now, we need to start bluetoothd service. Startup exec will take care
    # of already running process: if it's already running it will just exit,
    # and leave already running process running.
    /etc/init.d/bluetooth start
   if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    return $ret
}

# Stop qca BT service.
# For now, this does nothing.
qca_bt_stop()
{
    local ret=$SWI_OK
    local ser_dev=$2
    local used_ser_dev=""
    local pid=""
    local tmp=""

    # If someone just set "default" on the command line,
    # we need to translate this to real serial device.
    if [ "x$ser_dev" = "xdefault" ] ; then
        ser_dev=$( basename $bt_port )
    fi

    # Stop bluetooth daemon
    /etc/init.d/bluetooth stop

    # Kill relevant hciattach instance. In order to do that,
    # I need to know what's the serial port.
    used_ser_dev=$( ps -ef | grep hciattach | grep -v grep | awk '{print $9}' | awk -F'/' '{print $3}' )
    if [ "x$used_ser_dev" = "x$ser_dev" ] ; then
        pid=$( ps -ef | grep hciattach | grep -v grep | grep $used_ser_dev | awk '{print $2'} )
        kill $pid
        # Make sure that system is stable before continuing.
        sleep 1
    fi

    # Try to remove kernel modules. That would be actually possible only in the case
    # that no other hciattach instance is running, so check it before removing
    # kernel modules.
    tmp=$( ps -ef | grep hciattach | grep -v grep )
    if [ "x$tmp" = "x" ] ; then
        # Kernel modules could be removed.
        rm_bt_modules
    fi

    # Clear gpios only if wifi is not running. We need
    # some of these pins to stay intact on IoT interface.
    if [ ! -f $run_wifi_lock ] ; then
        clear_gpios
    fi

    return $ret
}

# Start QCA in AP mode.
qca_wifi_start_ap()
{
    local ret=$SWI_OK

    # Bring standard services down
    /etc/init.d/hostapd stop >/dev/null 2>&1
    /etc/init.d/dnsmasq stop >/dev/null 2>&1

    # Set IP address.
    ifconfig $interface down
    ifconfig $interface $ap_mode_ip up

    # Set hostapd. We need to merge standard and not so standard
    # parts of config file first.
    cat /etc/hostapd.conf /etc/hostapd-part-qca.conf >/tmp/hostapd.conf

    # Run it as a daemon.
    hostapd -B /tmp/hostapd.conf

    # Run dnsmasq as a daemon.
    dnsmasq -C /etc/dnsmasq-qca.conf

    # Open firewall to allow dhcp requests
    open_fw

    return $ret
}

# Stop QCA AP mode.
qca_wifi_stop_ap()
{
    local ret=$SWI_OK

    # Close firewall
    close_fw

    # Bring services down
    /etc/init.d/dnsmasq stop >/dev/null 2>&1
    /etc/init.d/hostapd stop >/dev/null 2>&1

    # Clear IP address.
    ifconfig $interface down

    # Run default dnsmasq (it's automatically started at boot time).
    /etc/init.d/dnsmasq start

    return $ret
}

# Stop QCA WiFi if in client mode.
qca_wifi_stop_client()
{
    stop_wpa_supplicant

    return $SWI_OK
}

# Start wpa supplicant, which is required if device is operating in
# client mode.
start_wpa_supplicant()
{
    local ret=$SWI_OK

    # Run it as daemon.
    wpa_supplicant -B -Dnl80211 -i$interface -c /etc/wpa_supplicant.conf
    if [ $? -ne 0 ] ; then ret=$SWI_ERR ; fi

    return $ret
}

# Stop wpa supplicant required if device in client mode.
stop_wpa_supplicant()
{
    local ret=$SWI_OK

    ps -ef | \
            grep -v grep | \
            grep wpa_supplicant | \
            awk '{ print $2 }' | \
            xargs kill -KILL >/dev/null 2>&1

    return $ret
}

# Obtain DHCP lease, if in client mode.
get_dhcp_lease()
{
    local ret=$SWI_OK

    # Try it 6 times and exit. This is required
    # to prevent endless retries and blocking of this executable.
    # If lease could not be obtained, most likelly
    # device would not be able to obtain it at all.
    udhcpc -i wlan0 -t 6 -n
    if [ $? -ne 0 ] ; then ret=$SWI_ERR ; fi

    return $ret
}

# Start QCA in client mode.
qca_wifi_start_client()
{
    local ret=$SWI_OK

    # Kill wpa_supplicant if it's already running (it should not be, but who knows)
    stop_wpa_supplicant

    # Now, run its new version.
    start_wpa_supplicant
    if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    # Obtain IP address from the server.
    get_dhcp_lease
    if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    return $ret
}

# Start QCA WiFi service
qca_wifi_start()
{
    local ret=$SWI_OK
    local mode=$2

    # set gpios
    set_gpios
    if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    # Load kernel modules
    load_wifi_modules
    if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    # Let's see which mode we should be running in.
    case $mode in

        ap )
            qca_wifi_start_ap
            ret=$?
        ;;

        client )
            qca_wifi_start_client
            ret=$?
        ;;

        *)
            swi_log "Mode [$mode] is not supported."
            usage
            ret=$SWI_ERR
        ;;

    esac

    return $ret

}

qca_wifi_stop()
{
    local ret=$SWI_OK
    local clogging=
    local mode=$2

    # Remove mode dependant stuff first.
    case $mode in

        ap )
            qca_wifi_stop_ap
            ret=$?
        ;;

        client )
            qca_wifi_stop_client
            ret=$?
        ;;

        *)
            swi_log "Warning: mode [$mode] is not supported."
        ;;

    esac

    # Remove WiFi related kernel modules
    rm_wifi_modules

    # Clear gpios only if bluetooth is not running. We need
    # some of these pins to stay intact on IoT interface.
    if [ ! -f $run_bt_lock ] ; then
        clear_gpios
    fi

    return $ret
}

# Handle BT service.
qca_bt()
{
    local ret=$SWI_OK
    local action=$3

    case $action in

        start )
            qca_bt_start "$@"
            ret=$?
            if [ $ret -ne 0 ] ; then
                # Failed to start, just clear everything.
                qca_bt_stop "$@"
                clear_lock
            fi
        ;;

        stop )
            qca_bt_stop "$@"
            ret=$?
            clear_lock
        ;;

        *)
            swi_log "Action [$action] not supported."
            usage
            ret=$SWI_ERR
        ;;

    esac

    return $ret
}

# Handle WiFi service.
qca_wifi()
{
    local ret=$SWI_OK
    local mode=$2
    local action=$3

    case $action in

        start )
            qca_wifi_start "$@"
            ret=$?
            if [ $ret -ne 0 ] ; then
                # Failed to start, just clear everything.
                qca_wifi_stop "$@"
                clear_lock
            fi
        ;;

        stop )
            qca_wifi_stop "$@"
            ret=$?
            clear_lock
        ;;

        *)
            swi_log "Action [$action] not supported."
            usage
            ret=$SWI_ERR
        ;;

    esac

    return $ret
}

# Execute command user wants.
exec_cmd()
{
    local service=$1
    local mode=$2
    local action=$3
    local ret=$SWI_OK

    case $service in

        wifi )
            qca_wifi "$@"
            ret=$?
        ;;

        bt )
            qca_bt "$@"
            ret=$?
        ;;

        *)
            swi_log "Service [$service] not supported."
            usage
            ret=$SWI_ERR
        ;;

    esac

    return $ret
}


# Main entry
main()
{
    local ret=$SWI_OK

    # Check if environment is sane
    check_env "$@"
    if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    exec_cmd "$@"
    if [ $? -ne 0 ] ; then return $SWI_ERR ; fi

    return $ret
}

# This is where it all begins.
main "$@"
exit $?
