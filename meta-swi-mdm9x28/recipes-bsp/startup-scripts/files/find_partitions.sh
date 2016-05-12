#!/bin/sh
# Copyright (c) 2014, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
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
#
# find_partitions        init.d script to dynamically find partitions
#

FindAndMountUBI () {
   partition=$1
   dir=$2
   mtd_block_number=`cat $mtd_file | grep -iw $partition | sed 's/^mtd//' | awk -F ':' '{print $1}'`
   echo "MTD : Detected block device : $dir for $partition"
   mkdir -p $dir

   BOOTTYPE="ubifs"
   BOOTDEV="/dev/mtdblock${mtd_block_number}"
   BOOTOPTS="ro"

   # Detect ubi partition
   UBI_FLAG=$(dd if=/dev/mtd$mtd_block_number count=4 bs=1 2>/dev/null)
   if echo $UBI_FLAG | grep 'UBI#' > /dev/null; then
        if ! [ -e "/dev/ubi1_0" ]; then
            # UBI partition, attach device
            ubiattach -m ${mtd_block_number} -d 1 /dev/ubi_ctrl
        fi
        SQFS_FLAG=$(dd if=/dev/ubi1_0 count=4 bs=1 2>/dev/null)
        if echo $SQFS_FLAG | grep 'hsqs' > /dev/null; then
            # squashfs volume, create UBI block device
            if ! [ -e "/dev/ubiblock1_0" ]; then
                ubiblkvol -a /dev/ubi1_0
                try_count=0
                # Need to wait for the block device ready
                while [ $try_count -lt 100 ]
                do
                    if [ -b /dev/ubiblock1_0 ]
                    then
                        break
                    else
                        usleep 10
                        try_count=`expr $try_count + 1`
                    fi
                done
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

    mount -t ${BOOTTYPE} ${BOOTDEV} $dir -o ${BOOTOPTS}
}

FindAndMountVolumeUBI () {
   volume_name=$1
   dir=$2
   mkdir -p $dir
   mount -t ubifs ubi0:$volume_name $dir -o bulk_read
}

FindAndMountEXT4 () {
   partition=$1
   dir=$2
   mmc_block_device=/dev/block/bootdevice/by-name/$partition
   echo "EMMC : Detected block device : $dir for $partition"
   mkdir -p $dir
   mount -t ext4 $mmc_block_device $dir -o relatime,data=ordered,noauto_da_alloc,discard
   echo "EMMC : Mounting of $mmc_block_device on $dir done"
}

emmc_dir=/dev/block/bootdevice/by-name
mtd_file=/proc/mtd

if [ -d $emmc_dir ]
then
        fstype="EXT4"
        eval FindAndMount${fstype} userdata /usr
        eval FindAndMount${fstype} cache /cache
else
        fstype="UBI"
        eval FindAndMountVolume${fstype} usrfs /usr
fi

eval FindAndMount${fstype} modem /firmware

exit 0
