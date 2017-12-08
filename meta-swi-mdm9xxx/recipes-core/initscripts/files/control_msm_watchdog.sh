#!/bin/sh
###############################################################
# Script to control msm_watchdog
#
# Copyright (C) Sierra Wireless, Inc
###############################################################

# Import run environment
source /etc/run.env

# Detect WDT Device if WDT_DEVICE is not defined
if [ -z "$WDT_DEVICE" ] || [ ! -d "$WDT_DEVICE" ] ; then
    WDT_DEVICE=$(find /sys/devices -maxdepth 1 -name "*.qcom,wdt")
fi

# Exit if WDT device is not found
if [ -z "$WDT_DEVICE" ]; then
    echo "Unsupported platform"
    exit 1
fi

# Set msm_watchdog barktime attribute parameter
WDT_TIMEOUT_ATTR=$WDT_DEVICE/barktime

# The stop kick msm_watchdog attribute parameter
WDT_STOPKICK_ATTR=$WDT_DEVICE/stopautokick

# Feed msm_watchdog attribute parameter
WDT_FEED_ATTR=$WDT_DEVICE/kick

# Feed msm_watchdog attribute parameter
LPM_SLEEP_DISABLE_ATTR=/sys/module/lpm_levels/parameters/sleep_disabled

# Set LPM sleep disabled state.
set_lpm_sleep_disabled_state()
{
    local is_disable=$1
    if [ -e ${LPM_SLEEP_DISABLE_ATTR} ] ; then
        echo ${is_disable} > ${LPM_SLEEP_DISABLE_ATTR}
    else
        swi_log "The ${LPM_SLEEP_DISABLE_ATTR} was absence!"
    fi
}

# Set MSM_WATCHDOG barktime.
set_barktime_msm_watchdog()
{
    local barktime=$1

    if [ "${barktime}" = "" ] ; then
            swi_log "The value of barktime was null value!"
            return 0
    fi

    # The registers of WDOG_BARK_TIME and WDOG_BITE_TIME have 0:19
    # bits to save time, and the value of WDOG_BARK_TIME/WDOG_BITE_TIME
    # is equal to time*32765, so the maximum value of WDOG_BARK_TIME/WDOG_BITE_TIME
    # is 32s. But the value of WDOG_BITE_TIME is equal to the value
    # of WDOG_BARK_TIME plus 3, so the maximum value of WDOG_BARK_TIME is 29.
    if [[ "${barktime}" -gt "29" || "${barktime}" -lt "0" ]] ; then
            swi_log "The value of barktime was unreliable!"
            return 0
    fi

    if [ -e ${WDT_TIMEOUT_ATTR} ] ; then
        echo ${barktime} > ${WDT_TIMEOUT_ATTR}
    else
        swi_log "The ${WDT_TIMEOUT_ATTR} was absence!"
    fi
}

# Stop kick MSM_WATCHDOG.
stop_auto_kick_msm_watchdog()
{
    local lpm_sleep_disable=1

    # Beacause AP non-secure wdt counter will be reset to 0 when board
    # fall into any low power mode, including WFI.
    # As a result, AP non-secure wdt cannot bite and bark once arm A7
    # falls into WFI and the the wdt counter is reset to 0 (and it is
    # hardware implementation that we cannot change).
    # So, if we want to make the WDT bark when timeout, we need to disabled
    # the LPM sleep mode.
    set_lpm_sleep_disabled_state ${lpm_sleep_disable}

    if [ -e ${WDT_STOPKICK_ATTR} ] ; then
        echo 1 > ${WDT_STOPKICK_ATTR}
    else
        swi_log "The ${WDT_STOPKICK_ATTR} was absence!"
    fi
}

# Start kick MSM_WATCHDOG.
start_auto_kick_msm_watchdog()
{
    local lpm_sleep_disable=0

    # When we start msm_watchdog auto kicking, firstly, we need to enable
    # the LPM sleep mode.
    set_lpm_sleep_disabled_state ${lpm_sleep_disable}

    if [ -e ${WDT_STOPKICK_ATTR} ] ; then
        echo 0 > ${WDT_STOPKICK_ATTR}
    else
        swi_log "The ${WDT_STOPKICK_ATTR} was absence!"
    fi
}

# Feed MSM_WATCHDOG one time.
kick_once_msm_watchdog()
{
    if [ -e ${WDT_FEED_ATTR} ] ; then
        echo 1 > ${WDT_FEED_ATTR}
    else
        swi_log "The ${WDT_FEED_ATTR} was absence!"
    fi
}

#
# Execution operation here.
#
case "$1" in
    stopautokick)
        stop_auto_kick_msm_watchdog
    ;;

    startautokick)
        start_auto_kick_msm_watchdog
    ;;

    kick)
        kick_once_msm_watchdog
    ;;

    setbarktime)
        set_barktime_msm_watchdog $2
    ;;

    *)
        echo "Usage: ${this_e} {stopautokick | startautokick | kick | setbarktime}"
        exit 1
    ;;
esac
