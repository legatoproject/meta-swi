#!/bin/sh
# Copyright (C) Sierra Wireless Inc. Use of this work is subject to license.
#
# Simple setup script for QCA9277 chipset. Currently, it works for MangOH Red
# WP76 module only.
#
# Enable all GPIOs on all EXPANDERs
echo "Enable all GPIOs on all expanders..."
gpioexp 1 1 enable

# Set IOT0_GPIO2 = 1 (WP GPIO13)
echo "Set IOT0_GPIO2 = 1 (WP GPIO13)..."
[ -d /sys/class/gpio/gpio13 ] || echo 13 >/sys/class/gpio/export
echo out >/sys/class/gpio/gpio13/direction
echo 1 >/sys/class/gpio/gpio13/value

# Set IOT0_GPIO3 = 1 (WP GPIO7)
echo "Set IOT0_GPIO3 = 1 (WP GPIO7)..."
[ -d /sys/class/gpio/gpio7 ] || echo 7 >/sys/class/gpio/export
echo out >/sys/class/gpio/gpio7/direction
echo 1 >/sys/class/gpio/gpio7/value

# Set IOT0_RESET = 1 (WP GPIO2)
echo "Set IOT0_RESET = 1 (WP GPIO2)..."
[ -d /sys/class/gpio/gpio2 ] || echo 2 >/sys/class/gpio/export
echo out >/sys/class/gpio/gpio2/direction
echo 1 >/sys/class/gpio/gpio2/value

# Clear SDIO_SEL, GPIO#9/EXPANDER#1 - Select the SDIO
echo "Clear SDIO_SEL, GPIO#9/EXPANDER#1 - Select the SDIO..."
gpioexp 1 9 output normal low

# Set IOT0_GPIO4 = 1 (WP GPIO8)
echo "Set IOT0_GPIO4 = 1 (WP GPIO8)..."
[ -d /sys/class/gpio/gpio8 ] || echo 8 >/sys/class/gpio/export
echo out >/sys/class/gpio/gpio8/direction
echo 1 >/sys/class/gpio/gpio8/value

# Set CARD_DETECT_IOT0 (WP GPIO33)
echo "Set CARD_DETECT_IOT0 (WP GPIO33)..."
[ -d /sys/class/gpio/gpio33 ] || echo 33 >/sys/class/gpio/export
echo in >/sys/class/gpio/gpio33/direction

exit 0
