#!/bin/sh
#
# Copyright (c) 2019 Sierra Wireless Inc.
# Add here mounts of the file systems needed early in the boot process.
# This file is reserved for system use, because system file systems typically
# need more flexibility when it comes down to mount paths and error handling.
# Customer file system mounts should go to fstab or elsewhere.
#
# import run environment
source /etc/run.env

# This executable
this_e=$( basename -- $0 )

# UBIFS mount options. Platforms may or may not have quota support. Hence, quota
# support must be separated from the rest of the default options.
UBI_MNTOPT_DEFAULT="sync"

# Wait until file shows up. Note that this will wait on any file and there
# will be no distinction between regular or device file. While covering wide
# range of cases, we may need to restrict this to device files in the future.
# Limit the time spent here to about 3 sec. If file does not show up for 3 sec.
# it will probably never show up.
wait_on_file()
{
    local cntmax=150
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

# Get mtd device number which corresponds to mtd partition name.
# Parameters:
#    $1 - mtd partition name
#
# If there is an error, negative number will be returned.
get_mtdpart_dev_num()
{
    local mtd_part_name=${1}
    local mtd_dev_num=
    local err=$SWI_ERR_MAX

    if [ -z ${mtd_part_name} ] ; then
        swi_log "MTD partition name is empty."
        return ${err}
    fi

    mtd_dev_num=$( cat /proc/mtd | \
                   grep ${mtd_part_name} -w | \
                   awk '{print $1}' | \
                   sed 's/://g' | \
                   grep -o "[0-9]*" )

    if [ -z ${mtd_dev_num} ] ; then
        swi_log "MTD partition ${mtd_part_name} device number is not available."
        mtd_dev_num=${err}
    fi

    return ${mtd_dev_num}
}

# Create single ubi volume. Parameters:
#   $1 - mtd partition name
#   $2 - ubi device number
#   $3 - ubi volume number associated with ubi device number
#   $4 - ubi volume name
#   $5 - ubi volume size. If not specified, whole MTD device will be used.
create_single_ubi_vol()
{
    local mtd_part_name=$1
    local ubi_dev_num=$2
    local ubi_vol_num=$3
    local ubi_vol_name=$4
    local ubi_vol_size=$5

    local mtd_dev_num=-1
    local ret=${SWI_OK}

    get_mtdpart_dev_num ${mtd_part_name}
    mtd_dev_num=$?
    if [ ${mtd_dev_num} -eq $SWI_ERR_MAX ] ; then
        # Error obtaining mtd device number, get out.
        return ${SWI_ERR}
    fi

    # Format MTD device for UBI use.
    ubiformat /dev/mtd${mtd_dev_num} -y

    if [ $? -ne 0 ] ; then
        swi_log "Cannot format mtd${mtd_dev_num}"
        return ${SWI_ERR}
    fi

    # Make link between physical and logical UBI device. If device does not
    # show up, tough luck.
    ubiattach -m ${mtd_dev_num} -d ${ubi_dev_num}
    if [ $? -ne 0 ] ; then
        swi_log "Unable to attach mtd partition ${mtd_part_name} to UBI logical device ${ubi_dev_num}"
        return ${SWI_ERR}
    fi
    wait_on_file "/dev/ubi${ubi_dev_num}"
    if [ $? -ne ${SWI_OK} ] ; then
        swi_log "Tired of waiting on /dev/ubi${ubi_dev_num}, exiting."
        return ${SWI_ERR}
    fi

    # If volume size is not specified, whole device will be used.
    if [ -z "${ubi_vol_size}" ] ; then
        ubi_vol_size=$( ubinfo -d ${ubi_dev_num} | \
                               grep "Amount of available logical eraseblocks" | \
                               awk '{ print $9 }' | \
                               xargs printf "%.0f" )
        if [ ${ubi_vol_size} -gt 0 ] ; then
            # Make sure that rounding is taken into account, otherwise mkvol
            # may fail.
            ubi_vol_size=$( echo $(( ${ubi_vol_size} - 1 )) )
        fi
    fi

    # Now, make UBI volume. If vol size happens to be 0 (small flash partition)
    # mkvol will fail, which is perfectly fine.
    swi_log "Making single volume, size ${ubi_vol_size}MiB on UBI device number ${ubi_dev_num}..."
    ubimkvol /dev/ubi${ubi_dev_num} -N ${ubi_vol_name} -s ${ubi_vol_size}MiB
    if [ $? -ne 0 ] ; then
        swi_log "Cannot make UBI volume ${ubi_vol_name} on UBI device number ${ubi_dev_num}"
        ret=${SWI_ERR}
    fi

    # Make sure detach happens. ubifs mount will attach it again.
    ubidetach -m ${mtd_dev_num}

    return ${ret}
}

# Generic function to mount ubi filesystems. Parameters:
#   $1 - mtd partition name
#   $2 - file system mount point
#   $3 - file system type to mount
#   $4 - ubi logical device number
#   $5 - ubi logical volume number
#   $6 - ubifs mount options (default ones should be excluded)
mount_ubifs()
{
    local mtd_part_name=$1
    local mntpt=$2
    local fstype=$3
    local ubi_dev_num=$4
    local ubi_vol_num=$5
    local ubifs_mnt_options=$6

    local mtd_dev_num=
    local ubi_dev_vol_pair=${ubi_dev_num}_${ubi_vol_num}
    local ret=${SWI_OK}
    local ubidev_name=ubi

    # Get mtd device number
    get_mtdpart_dev_num ${mtd_part_name}
    mtd_dev_num=$?
    if [ ${mtd_dev_num} -eq $SWI_ERR_MAX ] ; then
        # Error obtaining mtd device number, get out.
        return ${SWI_ERR}
    fi

    # Make link between physical and logical UBI device. If device does not
    # show up, we need to exit.

    # If device exist do not detach and then attach again - save boot up time
    if ! [ -c "/dev/ubi${ubi_dev_num}" ]; then
        ubiattach -m ${mtd_dev_num} -d ${ubi_dev_num}
        if [ $? -ne 0 ] ; then
            swi_log "Unable to attach mtd partition ${mtd_part_name} to UBI logical device ${ubi_dev_num}"
            return ${SWI_ERR}
        fi
        wait_on_file "/dev/ubi${ubi_dev_vol_pair}"
        if [ $? -ne ${SWI_OK} ] ; then
            swi_log "Tired of waiting on /dev/ubi${ubi_dev_vol_pair}, exiting."
            ubidetach -m ${mtd_dev_num}
            return ${SWI_ERR}
        fi
    fi

    mount -t ${fstype} /dev/${ubidev_name}${ubi_dev_vol_pair} ${mntpt} \
          -o${UBI_MNTOPT_DEFAULT},${ubifs_mnt_options}
    if [ $? -ne 0 ] ; then
        # detach will release block device as well.
        swi_log "Unable to mount /dev/${ubidev_name}${ubi_dev_vol_pair} onto ${mntpt}."
        ubidetach -m ${mtd_dev_num}
        return ${SWI_ERR}
    fi

    return ${ret}
}

# Try to mount R/W UBIFS using various mount options. The reason for this is that
# some of the platforms are UBIFS capable, but do not have quota support.
# Always try to mount with quota support first. Parameters:
#   $1 - mtd partition name
#   $2 - file system mount point
#   $3 - UBI logical device number
#   $4 - UBI volume associated with UBI logical device number
mount_ubifs_multi_mount_options()
{
    local mtd_part_name=$1
    local mntpt=$2
    local ubi_dev_num=$3
    local ubi_vol_num=$4

    local ubifs_mount_option="rw"
    swi_log "Trying to mount UBIFS on ${mntpt} using [${ubifs_mount_option}] mount options..."
    mount_ubifs ${mtd_part_name} ${mntpt} \
                ubifs ${ubi_dev_num} ${ubi_vol_num} "${ubifs_mount_option}"
    if [ $? -eq ${SWI_OK} ]; then
        swi_log "UBIFS volume successfully mounted on ${mntpt}"
        return ${SWI_OK}
    fi

    return ${SWI_ERR}
}

# Mount userrw file system using UBIFS.
mount_early_userrw_start()
{
    local mtd_part_name=${USERRW_MTDEV_NAME}
    local mntpt=${USERRW_MTDEV_MOUNTPOINT}
    local mtd_dev_num=

    if [ -z "$mntpt" ]; then
        return ${SWI_OK}
    fi

    if [ -z "$mtd_part_name" ]; then
        swi_log "Userrw part name does not exist"
        return ${SWI_OK}
    fi

    swi_log "Mounting ${mtd_part_name} file system as UBIFS"
    # Try to mount existing UBIFS partition first.
    mount_ubifs_multi_mount_options ${mtd_part_name} \
                                    ${mntpt} \
                                    ${UBI_USERRW_DEVNUM} \
                                    ${UBI_USERRW_VOLNUM}
    if [ $? -eq ${SWI_OK} ] ; then
        swi_log "${mtd_part_name} mounted to ${mntpt}"
        return ${SWI_OK}
    fi

    # That did not work, so we need to force this partition to be single
    # volume UBIFS .
    swi_log "Formatting ${mtd_part_name} as UBIFS partition"
    create_single_ubi_vol ${mtd_part_name} ${UBI_USERRW_DEVNUM} \
                          ${UBI_USERRW_VOLNUM} ${UBI_USERRW_VOLNAME}
    if [ $? -ne ${SWI_OK} ] ; then
         # UBI volume creation failed
         swi_log "Failed formatting ${mtd_part_name}"
         return ${SWI_ERR}
    fi

    # Now we mount UBIFS volume created above.
    mount_ubifs_multi_mount_options ${mtd_part_name} \
                                    ${mntpt} \
                                    ${UBI_USERRW_DEVNUM} \
                                    ${UBI_USERRW_VOLNUM}
    if [ $? -ne ${SWI_OK} ] ; then
        # UBI volume creation failed
        swi_log "Failed mounting ${mtd_part_name} to ${mntpt}"
        return ${SWI_ERR}
    fi

    # user partition is ubifs now.
    swi_log "${mtd_part_name} mounted to ${mntpt}"

    return ${SWI_OK}
}


#
# Execution starts here.
#
eval mount_early_userrw_start

exit 0
