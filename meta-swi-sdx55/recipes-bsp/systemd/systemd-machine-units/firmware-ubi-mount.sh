#!/bin/sh
# Copyright (c) 2018, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials provided
#     with the distribution.
#   * Neither the name of The Linux Foundation nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# import run environment
source /etc/run.env

# Wait until device shows up. After testing, it spent about 6 msec to
# find the devices of /dev/ubi1_0 and /dev/ubiblock1_0. So, limit the
# maximum time spent here to about 60 msec.
wait_on_dev()
{
    local cntmax=20
    local ret=${SWI_OK}
    while [ ! "$1" "$2" ]; do
        # When sleep 3 msec, it actually sleep for 3~4 msec, so here
        # sleep 3 msec every cycle.
        usleep 3000
        cntmax=$( echo $(( ${cntmax} - 1 )) )
        if [ ${cntmax} -eq 0 ]; then
            ret=${SWI_ERR}
            break
        fi
    done
    return ${ret}
}

FindAndMountUBI () {
    partition=$1
    dir=$2
    extra_opts=$3

    mtd_block_number=`cat $mtd_file | grep -i $partition | sed 's/^mtd//' | awk -F ':' '{print $1}'`
    swi_log "MTD : Detected block device : $dir for $partition"
    mkdir -p $dir

    BOOTTYPE="ubifs"
    BOOTDEV="/dev/mtdblock${mtd_block_number}"
    BOOTOPTS="ro"

    # Detect ubi partition
    UBI_FLAG=$(dd if=/dev/mtd$mtd_block_number count=1 bs=4 2>/dev/null)
    if echo $UBI_FLAG | grep 'UBI#' > /dev/null; then
        if ! [ -e "/dev/ubi1_0" ]; then
            # UBI partition, attach device
            ubiattach -m ${mtd_block_number} -d 1 /dev/ubi_ctrl
            if [ $? -ne 0 ] ; then
                swi_log "Unable to attach mtd partition ${partition} to UBI logical device ${mtd_block_number}"
                return ${SWI_ERR}
            fi
            # Need to wait for the /dev/ubi1_0 device ready
            wait_on_dev "-c" "/dev/ubi1_0"
            if [ $? -ne ${SWI_OK} ]; then
                swi_log "Failed to wait on /dev/ubi1_0, exiting."
                return ${SWI_ERR}
            fi
        fi

        SQFS_FLAG=$(dd if=/dev/ubi1_0 count=1 bs=4 2>/dev/null)
        if echo $SQFS_FLAG | grep 'hsqs' > /dev/null; then
            # squashfs volume, create UBI block device
            if ! [ -e "/dev/ubiblock1_0" ]; then
                ubiblock --create /dev/ubi1_0
                # Need to wait for the block device ready
                wait_on_dev "-b" "/dev/ubiblock1_0"
                if [ $? -ne ${SWI_OK} ]; then
                    swi_log "Failed to wait on /dev/ubiblock1_0, exiting."
                    return ${SWI_ERR}
                fi
            fi
            BOOTTYPE=squashfs
            BOOTDEV="/dev/ubiblock1_0"
        else
            BOOTDEV="/dev/ubi1_0"
            BOOTOPTS="bulk_read"
        fi

    # Fallback on yaffs2
    else
        BOOTTYPE="yaffs2"
        BOOTOPTS="rw,tags-ecc-off"
    fi

    mount -t ${BOOTTYPE} ${BOOTDEV} $dir -o ${BOOTOPTS}$extra_opts
    if [ $? -ne 0 ] ; then
        swi_log "Unable to mount ${BOOTTYPE} onto ${BOOTDEV}."
        return ${SWI_ERR}
    fi
}

mtd_file=/proc/mtd
if [ -x /sbin/restorecon ]; then
    firmware_selinux_opt=",context=system_u:object_r:firmware_t:s0"
else
    firmware_selinux_opt=""
fi
eval FindAndMountUBI modem /firmware $firmware_selinux_opt

exit 0
