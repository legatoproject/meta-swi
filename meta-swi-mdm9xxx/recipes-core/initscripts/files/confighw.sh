#!/bin/sh
# Copyright (c) 2012-2016 Sierra Wireless
#

source /etc/run.env

# TYPE contains h/w type
TYPE=`bsinfo -st`

LDO5VAL=0

# Set Random Number Generator
set_rng()
{
    local rng_device=/dev/hwrng
    local random_dev=/dev/random
    local write_wakeup_threshold_new=0
    local entropy_avail=0
    local write_wakeup_threshold=0
    local poolsize=0

    # There is no point doing any of this, if there is no HWRNG
    # device. This is not a bad thing, it just means that we cannot do it.
    if [ ! -c ${rng_device} ] ; then
        swi_log "HW RNG device ${rng_device} is not available."
        return 0
    fi

    entropy_avail=$( cat /proc/sys/kernel/random/entropy_avail )
    write_wakeup_threshold=$( cat /proc/sys/kernel/random/write_wakeup_threshold )
    poolsize=$( cat /proc/sys/kernel/random/poolsize )

    # Make it at least 75% of the pool size.
    write_wakeup_threshold_new=$((${poolsize}*75/100))

    # In the typical system without HW RNG, entropy_avail will be
    # less than write_wakeup_threshold upon boot. This is because not much
    # randomness is available in the system right after boot.
    # And this is exactly how we are going to determine if kernel is seeding
    # entropy pool internally (kernel 3.17 and later) or not.
    if [ ${entropy_avail} -lt ${write_wakeup_threshold} ] ; then
        swi_log "Available entropy is small (${entropy_avail}) and it needs rngd boost"
        /usr/sbin/rngd -o ${random_dev} -r ${rng_device}
    else
        # We just need to increase wakeup threshold to known level.
        swi_log "Kernel internal entropy pool filler is available, increasing write_wakeup_threshold to ${write_wakeup_threshold_new}"
        echo ${write_wakeup_threshold_new} > /proc/sys/kernel/random/write_wakeup_threshold
    fi

    return 0
}

if [ t${TYPE} = 't02' ]; then
	# MHS detected
	LDO5VAL=1
	modprobe sierra-mhs
	modprobe ebi2_lcd
	modprobe ili9341
	modprobe tsc2007
fi
if [ t${TYPE} = 't08' ]; then
	# USB detected
	modprobe sierra-usb
	modprobe spi_qsd
	modprobe sh1106
fi

# Avoid unnecessary error printing
if [ -e "/sys/module/kernel/parameters/ldo5" ]; then
	# WP710x devices detected
	if [ t${TYPE} = 't09' ] || [ t${TYPE} = 't0A' ] || [ t${TYPE} = 't0B' ] || [ t${TYPE} = 't1C' ] || [ t${TYPE} = 't1D' ] || [ t${TYPE} = 't1E' ] ; then
		# LDO5 is needed for UART2
		LDO5VAL=1
	fi

	echo ${LDO5VAL} > /sys/module/kernel/parameters/ldo5
fi

# Provide helper to access tty for AT
if [ -e "/dev/smd8" ] && ! [ -e "/dev/ttyAT" ]; then
	ln -s "/dev/smd8" "/dev/ttyAT"
fi

# This is loosely related to hardware, as it may deal with hardware RNG.
# If it needs to be moved, it must be executed early in the boot process.
set_rng
if [ $? -ne 0 ] ; then return 1 ; fi
