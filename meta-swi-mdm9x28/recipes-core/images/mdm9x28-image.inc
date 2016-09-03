DEPENDS += " \
        virtual/lk \
        mtd-utils-native \
        cryptsetup-native"

INC_PR = "r0"

inherit ubi-image
inherit dm-verity-hash
inherit set-files-attr

IMAGE_INSTALL += "start-scripts-find-partitions"
IMAGE_INSTALL += "start-scripts-firmware-links"
IMAGE_INSTALL += "cryptsetup"

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL += "busybox-mdev"

# Tools and helpers for i2c development
IMAGE_INSTALL += "i2c-tools"

# Only add Legato if this is a LEGATO_BUILD
def check_legato_pkg(d):
    legato_build = d.getVar('LEGATO_BUILD', True) or "false"
    if legato_build == "true":
        return "legato-image"
    return ""

DEPENDS += "${@check_legato_pkg(d)}"

# Stubs
IMAGE_INSTALL += "bsinfo-stub"

# Add some extra packages for tool integration
IMAGE_INSTALL += "lttng-ust"
#IMAGE_INSTALL += "lttng-modules"

IMAGE_INSTALL += "embms-kernel"
IMAGE_INSTALL += "kernel-modules"

create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        local dm_hash_path=$3
    fi

    local rootfs_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${rootfs_type}"

    echo \[sysfs_volume\] > $cfg_path
    echo mode=ubi >> $cfg_path
    echo image="$rootfs_path" >> $cfg_path
    echo vol_id=0 >> $cfg_path

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        # Dm-verity work with read only file system
        echo vol_type=static >> $cfg_path
    else
        echo vol_type=dynamic >> $cfg_path
        if [[ "${rootfs_type}" != "squashfs" ]]; then
            echo vol_size="${UBI_ROOTFS_SIZE}" >> $cfg_path
        fi
    fi

    echo vol_name=rootfs >> $cfg_path

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        # dm-verity hash tree table followed after the rootfs
        # Init scripts will check this partition during boot up
        if [[  -e ${dm_hash_path} ]]; then
            echo >> $cfg_path
            echo \[hash_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_hash_path" >> $cfg_path
            echo vol_id=1 >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=hash >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
        fi
    fi
}

backup_hash_for_initramfs() {
    local rootfs_type=$1
    local dm_hash_filename=$2
    ROOTHASH=$(cat $dm_hash_filename | grep Root | awk -F' ' '{printf $3}')
    sed -i 's/^.*ROOTHASH=.*$/ROOTHASH='${ROOTHASH}'/g' ${DEPLOY_DIR_IMAGE}/tmp.parameter.txt
    sed -i 's/^.*CUR_UBI_VOL=.*$/CUR_UBI_VOL='${rootfs_type}'/g' ${DEPLOY_DIR_IMAGE}/tmp.parameter.txt
}

prepare_ubi_ps() {
    local page_size=$1
    local dm_hash_path=

    for rootfs_type in ubifs squashfs; do

        if [[ "${rootfs_type}" != "squashfs" ]]; then
            local ubinize_cfg="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${page_size}.${rootfs_type}.ubinize_cfg"
            local image_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${page_size}.${rootfs_type}"
        else
            local ubinize_cfg="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${rootfs_type}.ubinize_cfg"
            local image_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${rootfs_type}"
        fi

        if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
            dm_hash_path="${image_path}.hash"
            local dm_hash_filename="${dm_hash_path}.txt"

            if [[ ! -e ${dm_hash_filename} ]]; then
                # Now Dm-verity only work with squashfs
                if [[ "${rootfs_type}" = "squashfs" ]]; then
                    # During build initramfs, bb file will get root hash from "tmp.parameter.txt" and
                    # write it to the start up scripts which will be attached to the boot image.

                    echo "DM_VERITY_ENCRYPT=on" > ${DEPLOY_DIR_IMAGE}/tmp.parameter.txt
                    echo "CUR_UBI_VOL=" >> ${DEPLOY_DIR_IMAGE}/tmp.parameter.txt
                    echo "ROOTHASH=" >> ${DEPLOY_DIR_IMAGE}/tmp.parameter.txt
                    create_dm_verity_hash $image_path ${dm_hash_path} ${dm_hash_filename}
                    backup_hash_for_initramfs ${rootfs_type} ${dm_hash_filename}
                fi
            fi
        fi

        if [[ "${rootfs_type}" != "squashfs" ]]; then
            create_ubinize_config ${ubinize_cfg} ${page_size}.${rootfs_type} ${dm_hash_path}
        else
            create_ubinize_config ${ubinize_cfg} ${rootfs_type} ${dm_hash_path}
        fi

        local ubi_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${rootfs_type}.${page_size}.ubi"
        local ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${rootfs_type}.${page_size}.ubi"

        create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
    done
}

# Create UBI images
prepare_ubi() {
    prepare_ubi_ps '2k'
    prepare_ubi_ps '4k'

    # Default image (no bs suffix) to 4k + squashfs
    ubi_link_path_def="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.squashfs.4k.ubi"
    ubi_link_path_def_2k="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.squashfs.2k.ubi"

    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.ubi"
    ubi_link_path_2k="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.2k.ubi"

    rm -f $ubi_link_path $ubi_link_path_2k
    ln -s $(basename $ubi_link_path_def) $ubi_link_path
    ln -s $(basename $ubi_link_path_def_2k) $ubi_link_path_2k

    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path
}

do_rootfs[postfuncs] += "prepare_ubi"

default_rootfs_ps() {
    # Default rootfs to ubi for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.ubi  ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.default

    # Default rootfs to 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.default
}

do_rootfs[postfuncs] += "default_rootfs_ps"

# Re-enable fetch & unpack tasks, because of bug(s) in Yocto 1.6 .
do_fetch2[dirs] = "${DL_DIR}"
python do_fetch2() {
    bb.build.exec_func('base_do_fetch', d)
}

addtask fetch2

do_unpack2[dirs] = "${WORKDIR}"
python do_unpack2() {
    bb.build.exec_func('base_do_unpack', d)
}

addtask unpack2 before do_rootfs

do_setfileattr() {
    if [[ "x${SMACK_ATTR_NAME}" != "x" ]]; then
        if [[ "x${SMACK_ATTR_VALUE}" != "x" ]]; then
            set_file_attr ${IMAGE_ROOTFS}
        fi
    fi
}

IMAGE_PREPROCESS_COMMAND += "do_setfileattr"
