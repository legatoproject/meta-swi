#!/bin/busybox sh

# import run environment
source /etc/run.env

# Real root file system mount point.
ROOTFS_MNTPT="/mnt/rootfs"

# Default boot device
BOOTDEV=""

# Do not check & wait for boot device by default
BOOTWAIT=0

# Default partition type
BOOTTYPE="ubifs"

# Default options
BOOTOPTS="ro"

# Max size of /dev directory
DEVDIR_SIZE=262144

# This executable
#this_e=$( basename $0 )

# Set some important global variables.
SWI_OK=0
SWI_ERR=1
SWI_TRUE=1
SWI_FALSE=0

# Get ASCII of UBI magic number.
# Parameters:
#   $1 - mtd partition number
#
get_asc_of_ubi_magic_num()
{
    local mtd_dev_num=${1}
    local ret=${SWI_FALSE}

    if dd if=/dev/mtd${mtd_dev_num} count=1 bs=4 2>/dev/null | grep 'UBI#' > /dev/null; then
        ret=${SWI_TRUE}
    fi
    return ${ret}
}

# Wait until file shows up. Note that this will wait on any file and there
# will be no distinction between regular or device file. While covering wide
# range of cases, we may need to restrict this to device files in the future.
# Limit the time spent here to about 1 sec. If file does not show up for 1 sec.
# it will probably never show up.
wait_on_file()
{
    local cntmax=50
    local ret=${SWI_OK}

    while [ ! -e "$1" ] ; do
        usleep 20000
        cntmax=$( echo $(( ${cntmax} - 1 )) )
        if [ ${cntmax} -eq 0 ] ; then
            ret=${SWI_ERR}
            break
        fi
    done

    return ${ret}
}

#
# Helper functions
#

do_essential()
{
    local ret=0

    mount -t proc proc /proc -o smackfsdef=_

    mount -t devtmpfs devtmpfs /dev

    mount -t sysfs sysfs /sys

    mount -t debugfs debugfs /sys/kernel/debug

    return ${ret}
}

# root file system partition must be called rootfs
set_boot_dev()
{
    local ret=0
    local boot_opt=''

    if grep 'rootfs.type=' /proc/cmdline > /dev/null; then
        boot_opt=$(cat /proc/cmdline | sed -e 's/\(^\|.* \)rootfs\.type=\([a-z0-9]*\) .*/\2/')
        if [ -n "$boot_opt" ]; then
            BOOTTYPE=$boot_opt
        fi
    fi

    if grep 'rootfs.opts=' /proc/cmdline > /dev/null; then
        boot_opt=$(cat /proc/cmdline | sed -e 's/\(^\|.* \)rootfs\.opts=\([a-z0-9,-_=]*\) .*/\2/')
        if [ -n "$boot_opt" ]; then
            BOOTOPTS=$boot_opt
        fi
    fi

    if grep 'rootfs.wait=true' /proc/cmdline > /dev/null; then
        BOOTWAIT=1
    fi

    if grep 'rootfs.dev=' /proc/cmdline > /dev/null; then
        BOOTDEV=$(cat /proc/cmdline | sed -e 's/\(^\|.* \)rootfs\.dev=\([^ ]*\) .*/\2/')
        if [ -z "$BOOTDEV" ] || [[ "$BOOTDEV" == *rootfs.dev* ]]; then
            return ${SWI_ERR}
        fi

        return ${SWI_OK}
    fi

    return ${ret}
}

checkpoint_rootfs()
{
    local ret=0
    local mnt_time_ms=0

    mkdir -p ${ROOTFS_MNTPT}

    if [ $BOOTWAIT -eq 1 ]; then
        echo "rootfs: waiting for ${BOOTDEV}"
        while [ 1 ]; do
            if [ -e $BOOTDEV ]; then
                break
            fi

            sleep 1
            echo -n '.'
        done
        echo
    fi

    echo "rootfs: dev '${BOOTDEV}' '${BOOTTYPE}'"
    export mnt_time=$( time mount -t ${BOOTTYPE} ${BOOTDEV} ${ROOTFS_MNTPT} -o ${BOOTOPTS} 2>&1 | \
                       grep real | awk '{ print $3 }' | grep -oe '\([0-9.]*\)' )

    if ! [ -d "${ROOTFS_MNTPT}/bin" ]; then
        echo "rootfs: mount failed"

        if ! [ -e $BOOTDEV ]; then
            echo -n "rootfs: dev '${BOOTDEV}' does not exist"
        fi

        return 1
    fi

    mnt_time_ms=$( awk 'BEGIN{print ENVIRON["mnt_time"] * 1000}' )
    echo "rootfs: mounting took ${mnt_time_ms}ms"

    return ${ret}
}

# Check if root file system should be mounted read-only.
remount_rootfs_ro()
{
    local ret=0

    if grep "rootfs ro" /proc/mounts > /dev/null; then
        return ${ret}
    fi

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

ima_setup()
{
    local do_exec=""
    local ima_policy_file=/etc/ima/ima.policy
    local ret=0

    echo "ima: setting up IMA subsystem..."

    do_exec=$( cat /proc/cmdline | grep -ow "ima_appraise=\(fix\|enforce\|log\)" )

    if [ -z $do_exec ] ; then
        # Nothing we should do here, IMA is not enabled
        echo "ima: feature not supported"
        return 0
    fi

    # IMA is supported, check if policy file is available. If not, refuse to boot.
    if [ ! -f ${ima_policy_file} ] ; then
        echo "ima: policy file is not available"
        return 1
    fi

    # Mount linux security
    mount -t securityfs security /sys/kernel/security

    if [ -f /sys/kernel/security/ima/policy ] ; then
        (   set -e; \
            while read -r -u 10 i; do \
                if ! echo "$i" | grep -q -e '^#' -e '^ *$'; then \
                    if echo $i; then \
                        sleep ${bootparam_ima_delay:-0}; \
                    else \
                        echo "ima: invalid line in IMA policy: $i" >&2; \
                        exit 1; \
                    fi; \
                fi; \
            done ) 10<${ima_policy_file} >/sys/kernel/security/ima/policy
        if [ $? -ne 0 ]; then
            echo "ima: error loading IMA policy"
            ret=1
        fi
    else
        echo "ima: cannot update IMA policy, kernel policy entry is missing"
        ret=1
    fi

    umount /sys/kernel/security

    return $ret
}

init_main()
{
    local ret=0

    # list of methods to execute
    local method_list="
                       do_essential
                       ima_setup
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
        if [ $? -ne 0 ] ; then
            return 1
        fi
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

