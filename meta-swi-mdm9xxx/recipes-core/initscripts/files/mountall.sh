#!/bin/sh
### BEGIN INIT INFO
# Provides:          mountall
# Required-Start:    mountvirtfs
# Required-Stop: 
# Default-Start:     S
# Default-Stop:
# Short-Description: Mount all filesystems.
# Description:
### END INIT INFO

source /etc/run.env

SMACK_PATH=/legato/smack

# Create directories for bind-mounts(done via fstab) required by legato.
mkdir -p /mnt/flash/legato
mkdir -p /mnt/flash/home

#
# Mount local filesystems in /etc/fstab. For some reason, people
# might want to mount "proc" several times, and mount -v complains
# about this. So we mount "proc" filesystems without -v.
#
test "$VERBOSE" != no && echo "Mounting local filesystems..."
mount -at nonfs,nosmbfs,noncpfs 2>/dev/null

#
# We might have mounted something over /dev, see if /dev/initctl is there.
#
if test ! -p /dev/initctl
then
	rm -f /dev/initctl
	mknod -m 600 /dev/initctl p
fi

#
# Do the smackfs mount.
#
if ! grep -F $SMACK_PATH /etc/mtab | grep -w -qs smackfs
then
    # Directory /legato should be properly mounted(via fstab) at this point.
    # So create mountpoint and mount smackfs.
    mkdir -p $SMACK_PATH
    mount -t smackfs smack $SMACK_PATH
fi

# Set the SMACK label for /dev/null and /dev/zero to "*" so that everyone have access to them.
setfattr -n security.SMACK64  -v "*" /dev/null
setfattr -n security.SMACK64  -v "*" /dev/zero
# Only allow the "framework" label to access the Legato directory.
setfattr -n security.SMACK64 -v "framework" /legato

: exit 0
