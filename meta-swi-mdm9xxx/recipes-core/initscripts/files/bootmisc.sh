#!/bin/sh
### BEGIN INIT INFO
# Provides:          bootmisc
# Required-Start:    $local_fs mountvirtfs
# Required-Stop:     $local_fs
# Default-Start:     S
# Default-Stop:      0 6
# Short-Description: Misc and other.
### END INIT INFO

# Put a nologin file in /etc to prevent people from logging in before
# system startup is complete.
#
if test "$DELAYLOGIN" = yes
then
  echo "System bootup in progress - please wait" > /etc/nologin
  cp /etc/nologin /etc/nologin.boot
fi

#
# Set pseudo-terminal access permissions.
#
if test -c /dev/ttyp0
then
	chmod 666 /dev/tty[p-za-e][0-9a-f]
	chown root:tty /dev/tty[p-za-e][0-9a-f]
fi

#
# Apply /proc settings if defined
#
SYSCTL_CONF="/etc/sysctl.conf"
if [ -f "${SYSCTL_CONF}" ]
then
	if [ -x "/sbin/sysctl" ]
	then
		/sbin/sysctl -p "${SYSCTL_CONF}"
	else
		echo "To have ${SYSCTL_CONF} applied during boot, install package <procps>."
	fi
fi

#
# Update /etc/motd.
#
if test "$EDITMOTD" != no
then
	uname -a > /etc/motd.tmp
	sed 1d /etc/motd >> /etc/motd.tmp
	mv /etc/motd.tmp /etc/motd
fi

#
# This is as good a place as any for a sanity check
#
# Set the system clock from hardware clock
# If the timestamp is more recent than the current time,
# use the timestamp instead.
test -x /etc/init.d/hwclock.sh && /etc/init.d/hwclock.sh start
if test -e /etc/timestamp
then
	SYSTEMDATE=`date -u +%4Y%2m%2d%2H%2M`
	read TIMESTAMP < /etc/timestamp
	if [ ${TIMESTAMP} -gt $SYSTEMDATE ]; then
		date -u ${TIMESTAMP#????}${TIMESTAMP%????????}
		test -x /etc/init.d/hwclock.sh && /etc/init.d/hwclock.sh stop
	fi
fi
: exit 0
