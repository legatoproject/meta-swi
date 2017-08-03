#!/bin/busybox sh

# Real root file system mount point.
ROOTFS_MNTPT="/mnt/rootfs"

# dm-verity default off
DM_VERITY_ENCRYPT=off
DM_ROOTFS_MOUNT_POINT="/dev/mapper/rt"
DM_ROOTFS_DEV_NAME="rt"

# This strings will be change by build.sh when Dm-verity is enabled
ROOTHASH=

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

# Current boot system flag in dual system
DS_LINUX_SUB_SYSTEM_FLAG=0

# swidssd is used during boot sequence to aid image swap.
# 'swidssd read' will return 100 if system is booting up using boot image set one,
# or 200 if system is booting up using boot image set two.
# 'swidssd write' is used to indicate bad image set using bad image set flag
# (please see DS_BAD_ROOTFS_1_MASK and DS_BAD_ROOTFS_2_MASK).
# 'swidssd write' will return 0 on successful write, (-1) otherwise.
# If swidssd is missing, stub executable will always return (1) to indicate that
# swidssd is not available on the system.

# If swidssd is missing, it will be replaced with '/bin/false'
# which will always return '1' to indicate that swidssd is not
# available. So, return code '1' must be treated as special,
# and cannot be used by swidssd .
SWIDSSD=/usr/bin/swidssd
if [ ! -x ${SWIDSSD} ] ; then
   SWIDSSD="/bin/false"
fi

# Flag to mount system 1
DS_SYSTEM_1_FLAG=100

# Flag to mount system 2
DS_SYSTEM_2_FLAG=200

# Mask of bad rootfs 1
DS_BAD_ROOTFS_1_MASK=8000

# Mask of bad rootfs 2
DS_BAD_ROOTFS_2_MASK=10000

# Set some important global variables.
SWI_OK=0
SWI_ERR=1
SWI_TRUE=1
SWI_FALSE=0

# Used in security authentication.
# Note: SWI_OK=0 and SWI_ERR=1 are also used.
SWI_SEC_NONE=2
SWI_AUTH_PASS=3
SWI_AUTH_FAIL=4

# DM-Verity UBI image contains 3 UBI partitions: ubix_0 - ubix_2.
# Secure version contains 5 UBI partitions: ubix_0 - ubix_4.
# ubix_0 -- file system squashfs image (squashfs on top of UBI).
# ubix_1 -- hash tree of squashfs image (binary,generated by veritysetup)
# ubix_2 -- root hash (ascii hex,generated by veritysetup)
# ubix_3 -- root hash after signature (binary)
# ubix_4 -- cert chain (some of the keys, used for signature)
UBI_IMAGE_VOLNUM=0
UBI_HASH_VOLNUM=1
UBI_RHASH_VOLNUM=2
UBI_SRH_VOLNUM=3
UBI_CERT_VOLNUM=4

# Secure version contains 5 UBI partitions: ubix_0 - ubix_4.
# And this structure should be same as the tools used for signature.
DM_SEC_UBI_VOL_COUNT=5

# If ROOTFS partition (or part of it) is mounted as UBI partition
# type (UBIFS, SQUASHFS-on-top-of-ubi, etc.), this is the
# device number which should be used.
UBI_ROOTFS_DEVNUM=0

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

# This function is used to check secure mode or do security authentication
# acroding to the input parameters.
#
# Check secure mode:
# The utility swi_auth read the fuse from specify register, and return
# secure or non-secure.
#
# Security authentication:
# The utility will verify the signature of the image in the ubi partitions
# ubix_2 ~ ubix_4.
#
# If in secure mode, the following images format is expected.
# ubix_0 -- file system squashfs image (squashfs on top of UBI).
# ubix_1 -- hash tree of squashfs image (binary,generated by veritysetup)
# ubix_2 -- root hash (ascii hex,generated by veritysetup)
# ubix_3 -- root hash after signature (binary)
# ubix_4 -- cert chain (some of the keys, used for signature)
#
# Here is the usage for the utility swi_auth
# swi_auth [fuse|nfuse] [ubi_dev_num] [platform]
#    fuse - only check secure mode, return secure or non-secure
#    nfuse - skip checking secure mode, only do security authentication
#    ubi_dev_num - ubix (do security authentication need this parameter)
#    platform - 9x40,9x28,9x15. default is 9x40
# return:
#    1 ~ 3 - error code
#    4 - non-secure mode
#    5 - secure mode
#    6 - authentication successful
#
# Check security authentication. Parameters:
#   $1 - ubi logical device number
#   $2 - mtd partition number
#   $3 - support not UBI image in this mtd partition:
#      - ${SWI_TRUE}: Only check security when it is UBI image
#      - ${SWI_FALSE}:Not UBI image is not allowed for security CPU
check_security_auth()
{
    local ubi_dev_num=$1
    local mtd_dev_num=$2
    local support_not_ubi=$3
    local ret_auth=${SWI_AUTH_FAIL}
    local ubi_vol_total_num=0
    local auth_cmd="/usr/bin/swi_auth"

    # UBI volume devices for root-hash, signature-root-hash and cert-chain
    local ubi_rhash_dev=/dev/ubi${ubi_dev_num}_${UBI_RHASH_VOLNUM}
    local ubi_srh_dev=/dev/ubi${ubi_dev_num}_${UBI_SRH_VOLNUM}
    local ubi_cert_dev=/dev/ubi${ubi_dev_num}_${UBI_CERT_VOLNUM}
    local ubi_dev_list=

    if ! [ -x ${auth_cmd} ] ; then
        echo "File ${auth_cmd} does not exist or is not executable."
        return ${SWI_ERR}
    fi

    # Read fuse from register to get secure mode.
    ${auth_cmd} fuse
    ret_auth=$?
    if [ ${ret_auth} -eq 4 ] ; then
        # Any other errors should continue to avoid secure hole.
        echo "Non-secure."
        return ${SWI_SEC_NONE}
    fi

    # Secure version should work with UBI, Otherwise, return authentication fail.
    # But some of the partitions allow customers not to use, E.g legato, for these
    # kinds of partition,if it is not UBI format we won't do security authentication
    # for it.
    get_asc_of_ubi_magic_num ${mtd_dev_num}
    if [ $? -ne ${SWI_TRUE} ] ; then
        if [ ${support_not_ubi} -eq ${SWI_TRUE} ] ; then
            return ${SWI_ERR}
        else
            echo "Cannot find UBI container on MTD ${mtd_dev_num}."
            return ${SWI_AUTH_FAIL}
        fi
    fi

    # Make link between physical and logical UBI device.
    ubiattach -m ${mtd_dev_num} -d ${ubi_dev_num}
    if [ $? -ne 0 ] ; then
        echo "Unable to attach mtd ${mtd_dev_num} to UBI logical device ${ubi_dev_num}."
        return ${SWI_AUTH_FAIL}
    fi

    # There is a known issue:
    # (Please look at "mtd-utils/tests/ubi-tests/README.udev" for detail.)
    # There is a problem with udev: when a volume is created, there is a delay
    # before corresponding /dev/ubiX_Y device node is created by udev, so some
    # tests fail because of this. The symptom is error messages like
    # "cannot open /dev/ubi0_0".
    # We meet this issue here:
    # There is a low probability that when the last volumes of UBI
    # is ready but some of the other volumes are not ready.
    # E.g ubix_4 is ready, but ubix_2 or ubix_3 is not ready.
    # So here we need to check if all the UBI volumes are ready which
    # are needed at the following step for security authentication.
    ubi_dev_list="
                  ${ubi_rhash_dev}
                  ${ubi_srh_dev}
                  ${ubi_cert_dev}
                  "
    for ubi_dev in ${ubi_dev_list} ; do
        wait_on_file "${ubi_dev}"
        if [ $? -ne ${SWI_OK} ] ; then
            echo "Tired of waiting on ${ubi_dev}."
            return ${SWI_AUTH_FAIL}
        fi
    done

    # Do authentication and handle the result.
    ${auth_cmd} nfuse ubi${ubi_dev_num}
    ret_auth=$?
    case "${ret_auth}" in
        6)
            # This is secure version should work with UBI.
            echo "Secure version."
            ubi_vol_total_num=$(cat /sys/class/ubi/ubi${ubi_dev_num}/volumes_count)
            if [ ${ubi_vol_total_num} != "${DM_SEC_UBI_VOL_COUNT}" ] ; then
                echo "DM verity with secure version should has $DM_SEC_UBI_VOL_COUNT UBI volumes."
                return ${SWI_AUTH_FAIL}
            fi
            return ${SWI_AUTH_PASS}
        ;;
        *)
            echo "Authentication failure, error: ${ret_auth}"
            return  ${SWI_AUTH_FAIL}
        ;;
    esac
}

# Generic function to active DM verity feature. Parameters:
#   $1 - ubi logical device number
#   $2 - ubi logical volume number for raw image
#   $3 - ubi logical volume number for hash bin
#   $4 - ubi logical volume number for root hash
#   $5 - DM verity device name for the partition
mount_as_dm_verity() {
    local ubi_dev_num=$1
    local ubi_vol_num_image=$2
    local ubi_vol_num_hash=$3
    local ubi_vol_num_rhash=$4
    local dm_device_name=$5
    local root_hash=

    # UBI partitions for squashfs image, hash and root-hash
    local ubi_img_dev=/dev/ubi${ubi_dev_num}_${ubi_vol_num_image}
    local ubi_hash_dev=/dev/ubi${ubi_dev_num}_${ubi_vol_num_hash}
    local ubi_rhash_dev=/dev/ubi${ubi_dev_num}_${ubi_vol_num_rhash}

    local ubi_img_block_dev=/dev/ubiblock${ubi_dev_num}_${ubi_vol_num_image}
    local ubi_hash_block_dev=/dev/ubiblock${ubi_dev_num}_${ubi_vol_num_hash}

    if grep 'verity=on' /proc/cmdline > /dev/null; then
        DM_VERITY_ENCRYPT="on"
    fi

    if [ "x$DM_VERITY_ENCRYPT" != "xon" ]; then
        echo "DM verity is not enabled."
        return ${SWI_ERR}
    fi

    if ! [ -c "${ubi_rhash_dev}" ]; then
        echo "Cannot find root hash volume ${ubi_rhash_dev}."
        return ${SWI_ERR}
    fi

    DM_FLAG=$(dd if=${ubi_hash_dev} count=1 bs=4 2>/dev/null)
    if [ "x$DM_FLAG" != "xveri" ]; then
        echo "Cannot find hash volume ${ubi_hash_dev}."
        return ${SWI_ERR}
    fi

    # Create UBI block device for squashfs image
    if ! [ -b "${ubi_img_block_dev}" ]; then
        ubiblkvol -a ${ubi_img_dev}
        if [ $? -ne 0 ] ; then
            echo "Unable to create ${ubi_img_block_dev}."
            return ${SWI_ERR}
        fi
        wait_on_file "${ubi_img_block_dev}"
        if [ $? -ne ${SWI_OK} ] ; then
            echo "Tired of waiting on ${ubi_img_block_dev}, exiting."
            return ${SWI_ERR}
        fi
    fi

    # Dm-verity hash tree table is located on this volume, check it and prepare it for use.
    if ! [ -b "${ubi_hash_block_dev}" ]; then
        ubiblkvol -a ${ubi_hash_dev}
        if [ $? -ne 0 ] ; then
            echo "Unable to create ${ubi_hash_block_dev}."
            return ${SWI_ERR}
        fi
        wait_on_file "${ubi_hash_block_dev}"
        if [ $? -ne ${SWI_OK} ] ; then
            echo "Tired of waiting on ${ubi_hash_block_dev}, exiting."
            return ${SWI_ERR}
        fi
    fi

    # Get the root hash from rhash volume
    root_hash=$(dd if=${ubi_rhash_dev} count=1 bs=64 2>/dev/null)

    # Specific feature on this target: rootfs rhash stored in ${ROOTHASH}
    if [ ${ubi_dev_num} -eq ${UBI_ROOTFS_DEVNUM} ] ; then
        echo "rootfs roothash: ${ROOTHASH}"
        root_hash=${ROOTHASH}
    fi

    # Create Dm-verity layer
    veritysetup create ${dm_device_name} ${ubi_img_block_dev} ${ubi_hash_block_dev} ${root_hash}
    if [ $? -ne 0 ] ; then
        echo "Device: ${dm_device_name} ubiImgBlock:${ubi_img_block_dev} hashBlock:${ubi_hash_block_dev}"
        echo "root_hash:${root_hash}"
        echo "Dm-verity partition creation failed."
        return ${SWI_ERR}
    fi
    return ${SWI_OK}
}

#Update rootfs image status to share memory for dual system.
#Otherwise, it will do nothing.
record_rootfs_image_status()
{
    # If there is something wrong in rootfs image, regard it as bad rootfs.
    # Update it's status to shared memory. Swap system and reboot.
    # Don't need to check return value in this case.
    if [ $DS_LINUX_SUB_SYSTEM_FLAG -eq $DS_SYSTEM_2_FLAG ]; then
        # Set rootfs_2 bad flag to shared memory
        ${SWIDSSD} write $DS_BAD_ROOTFS_2_MASK
    elif [ $DS_LINUX_SUB_SYSTEM_FLAG -eq $DS_SYSTEM_1_FLAG ]; then
        # Set rootfs_1 bad flag to shared memory
        ${SWIDSSD} write $DS_BAD_ROOTFS_1_MASK
    fi
}

# root file system partition must be called rootfs
set_boot_dev()
{
    local ret=0
    local mtd_part_name='(rootfs|system)'
    local boot_opt=''
    local secure=${SWI_ERR}

    # ROOTFS image location
    local ubi_img_dev=/dev/ubi${UBI_ROOTFS_DEVNUM}_${UBI_IMAGE_VOLNUM}
    local ubi_img_blkdev=/dev/ubiblock${UBI_ROOTFS_DEVNUM}_${UBI_IMAGE_VOLNUM}

    # ROOTFS hash location
    local ubi_hash_dev=/dev/ubi${UBI_ROOTFS_DEVNUM}_${UBI_HASH_VOLNUM}

    # Get dual system flag from shared memory if swidssd exists
    ${SWIDSSD} read linux
    DS_LINUX_SUB_SYSTEM_FLAG=$?

    # Mount rootfs_2 if system_2 flag is set
    if [ $DS_LINUX_SUB_SYSTEM_FLAG -eq $DS_SYSTEM_2_FLAG ]; then
        mtd_part_name='(rootfs2|system2)'
    fi
    echo "mount root fs from partition $mtd_part_name"

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
    else
        if [ "$BOOTTYPE" == "yaffs2" ]; then
            BOOTOPTS="rw,tags-ecc-off"
        fi
    fi

    if grep 'rootfs.wait=true' /proc/cmdline > /dev/null; then
        BOOTWAIT=1
    fi

    if grep 'rootfs.dev=' /proc/cmdline > /dev/null; then
        BOOTDEV=$(cat /proc/cmdline | sed -e 's/.* rootfs\.dev=\([^ ]*\) .*/\1/')
        if [ -n "$BOOTDEV" ]; then
            return ${ret}
        fi
    fi

    mtd_dev_num=$( cat /proc/mtd | \
                   egrep "\"${mtd_part_name}\"" | \
                   sed 's/mtd\([0-9]*\):.*/\1/' )

    BOOTDEV="/dev/mtdblock${mtd_dev_num}"

    check_security_auth ${UBI_ROOTFS_DEVNUM} \
                        ${mtd_dev_num}       \
                        ${SWI_FALSE}
    secure=$?
    if [ ${secure} -eq ${SWI_AUTH_FAIL} ]; then
        # If security authentication failure, should not continue
        return ${SWI_ERR}
    fi

    if [ "$BOOTTYPE" != "yaffs2" ]; then

        get_asc_of_ubi_magic_num ${mtd_dev_num}
        if [ $? -eq ${SWI_TRUE} ] ; then
            if ! [ -c "${ubi_img_dev}" ]; then
                # UBI partition, attach device
                ubiattach -m ${mtd_dev_num} -d ${UBI_ROOTFS_DEVNUM}
                if [ $? -ne 0 ] ; then
                    echo "Unable to attach mtd${mtd_dev_num} to UBI logical device ${UBI_ROOTFS_DEVNUM}"
                    return ${SWI_ERR}
                fi
                # UBI static volume will takes more longer during ubiattach
                wait_on_file "${ubi_img_dev}"
                if [ $? -ne ${SWI_OK} ] ; then
                    echo "Tired of waiting on ${ubi_img_dev}, exiting."
                    return ${SWI_ERR}
                fi
            fi
            SQFS_FLAG=$(dd if=${ubi_img_dev} count=1 bs=4 2>/dev/null)
            if echo $SQFS_FLAG | grep 'hsqs' > /dev/null; then
                # squashfs volume, create UBI block device
                if ! [ -b "${ubi_img_blkdev}" ]; then
                    ubiblkvol --attach ${ubi_img_dev}
                fi
                if [ -c "${ubi_hash_dev}" ]; then
                    mount_as_dm_verity ${UBI_ROOTFS_DEVNUM}  \
                                       ${UBI_IMAGE_VOLNUM}   \
                                       ${UBI_HASH_VOLNUM}    \
                                       ${UBI_RHASH_VOLNUM}   \
                                       ${DM_ROOTFS_DEV_NAME}
                fi
                BOOTTYPE=squashfs
                BOOTDEV="${ubi_img_blkdev}"
            else
                BOOTDEV="${ubi_img_dev}"
                BOOTOPTS="bulk_read"
            fi
        elif echo $UBI_FLAG | grep 'hsqs' > /dev/null; then
            BOOTTYPE=squashfs
            BOOTOPTS=ro
        else
            # Fallback on yaffs2
            BOOTTYPE="yaffs2"
            BOOTOPTS="rw,tags-ecc-off"
        fi
    fi
    # Secure version should work with UBI + squashfs + dm-verity,
    # at this case we shall not continue if something is wrong with them.
    if [ ${secure} -eq ${SWI_AUTH_PASS} ]; then
        if ! [ -b ${DM_ROOTFS_MOUNT_POINT} ]; then
            echo "Something is wrong with DM-verity."
            return ${SWI_ERR}
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

    echo "rootfs: dev '${BOOTDEV}' '${BOOTTYPE}'"
    if [ -b ${DM_ROOTFS_MOUNT_POINT} ]; then
        echo "mount ${DM_ROOTFS_MOUNT_POINT}"
        mount -t squashfs ${DM_ROOTFS_MOUNT_POINT} ${ROOTFS_MNTPT} -oro
    else
        export mnt_time=$( time mount -t ${BOOTTYPE} ${BOOTDEV} ${ROOTFS_MNTPT} -o ${BOOTOPTS} 2>&1 | \
                        grep real | awk '{ print $3 }' | grep -oe '\([0-9.]*\)' )
    fi

    if ! [ -d "${ROOTFS_MNTPT}/bin" ]; then
        echo "rootfs: mount failed"

        if ! [ -e $BOOTDEV ]; then
            echo -n "rootfs: dev '${BOOTDEV}' does not exist"
        fi

        return 1
    fi

    mnt_time_ms=$( awk 'BEGIN{print ENVIRON["mnt_time"] * 1000}' )
    echo "rootfs: mounting took ${mnt_time_ms}ms"

    if [ "$BOOTTYPE" == "yaffs2" ]; then
        # If mount time takes longer than 500ms, force check-pointing.
        if [ ${mnt_time_ms} -gt 500 ] ; then

            # This makes file system check pointed.
            sync
        fi
    fi

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
        if [ $? -ne 0 ] ; then
            record_rootfs_image_status
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

