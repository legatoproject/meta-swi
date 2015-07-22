#!/bin/busybox sh

# Real root file system mount point.
ROOTFS_MNTPT="/mnt/rootfs"

# Default boot device
BOOTDEV="/dev/mtdblock2"

# Do not check & wait for boot device by default
BOOTWAIT=0

# Default partition type
BOOTTYPE="yaffs2"

# Default options
BOOTOPTS="rw,tags-ecc-off"

# Max size of /dev directory
DEVDIR_SIZE=262144

# This executable
#this_e=$( basename $0 )

#
# Helper functions
#

do_essential()
{
    local ret=0

    mount -t devtmpfs devtmpfs /dev
    exec 0</dev/console
    exec 1>/dev/console
    exec 2>/dev/console

    mount -t proc proc /proc -o smackfsdef=_

    mount -t sysfs sysfs /sys

    mount -t debugfs debugfs /sys/kernel/debug

    return ${ret}
}

# root file system partition must be called rootfs
set_boot_dev()
{
    local ret=0
    local mtd_part_name=rootfs
    local boot_opt=''

    if grep 'rootfs.type=' /proc/cmdline > /dev/null; then
        boot_opt=$(cat /proc/cmdline | sed -e 's/.* rootfs\.type=\([a-z0-9]*\) .*/\1/')
        if [ -n "$boot_opt" ]; then
            BOOTTYPE=$boot_opt
        fi
    fi

    if grep 'rootfs.opts=' /proc/cmdline > /dev/null; then 
        boot_opt=$(cat /proc/cmdline | sed -e 's/.* rootfs\.opts=\([a-z0-9,-_=]*\) .*/\1/')
        if [ -n "$boot_opt" ]; then
            BOOTOPTS=$boot_opt
        fi
    fi

    if grep 'rootfs.wait=true' /proc/cmdline > /dev/null; then
        BOOTWAIT=1
    fi

    if grep 'rootfs.dev=' /proc/cmdline > /dev/null; then 
        BOOTDEV=$(cat /proc/cmdline | sed -e 's/.* rootfs\.dev=\([/a-z0-9]*\) .*/\1/')
        if [ -n "$BOOTDEV" ]; then
            return ${ret}
        fi
    fi

    mtd_dev_num=$( cat /proc/mtd | \
                   grep ${mtd_part_name} | \
                   sed 's/mtd\([0-9]*\):.*/\1/' )

    BOOTDEV="/dev/mtdblock${mtd_dev_num}"

    if [ "$BOOTTYPE" != "yaffs2" ]; then

        # Detect ubi partition
        if dd if=/dev/mtd${mtd_dev_num} count=4 bs=1 2>/dev/null | grep 'UBI#' > /dev/null; then
            ubiattach -m ${mtd_dev_num} -d 0
            ubiblkvol --attach /dev/ubi0_0
            BOOTDEV="/dev/ubiblock0_0"

        # Fallback on yaffs2
        else
            BOOTTYPE="yaffs2"
            BOOTOPTS="rw,tags-ecc-off"
            return ${ret}
        fi
    fi

    return ${ret}
}

checkpoint_rootfs()
{
    local ret=0
    local mnt_time_ms=0

    mkdir -p ${ROOTFS_MNTPT}

    if [ $BOOTWAIT -eq 1 ]; then
        echo "Waiting for ${BOOTDEV}"
        while [ 1 ]; do
            if ! [ -e $BOOTDEV ]; then
                sleep 1
                echo -n '.'
            fi
        done
        echo
    fi

    echo "rootfs: dev ${BOOTDEV}"

    export mnt_time=$( time mount -t ${BOOTTYPE} ${BOOTDEV} ${ROOTFS_MNTPT} -o ${BOOTOPTS} 2>&1 | \
                       grep real | awk '{ print $3 }' | grep -oe '\([0-9.]*\)' )

    if [ $? -ne 0 ]; then
        echo "rootfs: mount failed"
        return 1
    fi

    mnt_time_ms=$( awk 'BEGIN{print ENVIRON["mnt_time"] * 1000}' )
    echo "rootfs: mounting took ${mnt_time_ms}ms"

    # If mount time takes longer than 500ms, force check-pointing.
    if [ ${mnt_time_ms} -gt 500 ] ; then

        # This makes file system check pointed.
        sync
    fi

    return ${ret}
}

# Check if root file system should be mounted read-only.
remount_rootfs_ro()
{
    local ret=0

    if grep "rootfs_ro=true" /proc/cmdline > /dev/null; then
        # echo "rootfs will be read-only."
        mount ${ROOTFS_MNTPT} -o remount,ro
    fi

    return ${ret}
}

create_devices()
{
    local ret=0

    # Mount mdev, kick hotplugging and start mdev.
    mount -t tmpfs mdev /dev -o rw,relatime,size=${DEVDIR_SIZE},mode=0755,smackfsdef='*'
    echo "/sbin/mdev" > /proc/sys/kernel/hotplug
    mdev -s

    # Show mqueue stuff.
    mkdir -p /dev/mqueue
    mount -t mqueue none /dev/mqueue -o smackfsdef='*'

    # mount devpts for consoles and such.
    mkdir -p /dev/pts
    mount -t devpts none /dev/pts -o mode=0620,gid=5,smackfsdef='*'

    # Mount shared memory.
    mkdir -p /dev/shm
    mount -t tmpfs tmpfs /dev/shm -o mode=0777,smackfsdef='*'

    return ${ret}
}

mount_tmpfs()
{
    local ret=0

    # Need /run to be volatile.
    mount -t tmpfs tmpfs ${ROOTFS_MNTPT}/run -o mode=0755,nodev,nosuid,strictatime,smackfsdef='_'

    # Need /var to be volatile.
    mount -t tmpfs tmpfs ${ROOTFS_MNTPT}/var -o mode=0755,nodev,nosuid,strictatime,smackfsdef='_'

    # Do not restrict the size this file system.
    mount -t tmpfs tmpfs ${ROOTFS_MNTPT}/tmp -o mode=0755,nodev,nosuid,strictatime,smackfsdef='_'

    return ${ret}
}

create_early_dirs()
{
    local ret=0

    mkdir -p ${ROOTFS_MNTPT}/var/run/dbus
    mkdir -p ${ROOTFS_MNTPT}/var/lock/subsys
    mkdir -p ${ROOTFS_MNTPT}/var/log
    mkdir -p ${ROOTFS_MNTPT}/var/lib/urandom

    return ${ret}
}

move_mounts_to_real_root()
{
    local ret=0

    mount --move /dev ${ROOTFS_MNTPT}/dev
    mount --move /proc ${ROOTFS_MNTPT}/proc
    mount --move /sys ${ROOTFS_MNTPT}/sys

    return ${ret}
}

switch_to_real_root()
{
    local ret=0

    exec switch_root ${ROOTFS_MNTPT} /sbin/init

    return ${ret}
}

init_main()
{
    local ret=0

    # list of methods to execute
    local method_list="
                       do_essential
                       set_boot_dev
                       checkpoint_rootfs
                       remount_rootfs_ro
                       create_devices
                       mount_tmpfs
                       create_early_dirs
                       move_mounts_to_real_root
                       switch_to_real_root
                      "

    for method in ${method_list} ; do
        # echo "${this_e}: Executing ${method}... "
        ${method}
        if [ $? -ne 0 ] ; then return 1 ; fi
    done

    return ${ret}
}

#
# Entry point.
#
init_main
if [ $? -ne 0 ] ; then
    echo "System error!"
    exit 1
fi

