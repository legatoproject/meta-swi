DEPENDS += " \
        virtual/lk \
        mtd-utils-native \
        cryptsetup-native \
        ima-evm-utils-native \
        libarchive-native"

INC_PR = "r0"

inherit ubi-image
inherit dm-verity-hash
inherit set-files-attr

IMAGE_INSTALL_append = " start-scripts-find-partitions"
IMAGE_INSTALL_append = " start-scripts-firmware-links"
IMAGE_INSTALL_append = " cryptsetup"

# Install busybox mdev instead of udev. This is
# here just as a reminder, because we are doing
# manual installation of mdev.
# IMAGE_INSTALL_append = " busybox-mdev"

# Add WiFi tools and scripts
IMAGE_INSTALL_append = " wpa-supplicant"
IMAGE_INSTALL_append = " hostapd"
IMAGE_INSTALL_append = " iw"
IMAGE_INSTALL_append = " ti-wifi-utils-wl18xx"
IMAGE_INSTALL_append = " crda"
IMAGE_INSTALL_append = " i2cgpioctl"
IMAGE_INSTALL_append = " sierra-init-tiwifi"

# QCA9377 support (only if it's enabled).
# Kernel module
IMAGE_INSTALL_append = " ${@bb.utils.contains('ENABLE_QCA9377', '1', ' qcacld-hl', '', d)}"
# Init script
IMAGE_INSTALL_append = " ${@bb.utils.contains('ENABLE_QCA9377', '1', ' sierra-init-qca9377', '', d)}"

# Add eventual legato dependency
DEPENDS += "${@check_legato_pkg(d, "legato-image")}"

IMAGE_INSTALL_append = " embms-kernel"
IMAGE_INSTALL_append = " kernel-modules"

# Add linkmon app to monitor USB link
IMAGE_INSTALL_append = " linkmon"

# Add replacements for busybox utils in order to properly handle
# extended file attributes.
IMAGE_INSTALL_append = " libarchive"

create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        local dm_hash_path=$3
        local dm_root_hash_path=$4
    fi

    local rootfs_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${rootfs_type}"

    echo \[sysfs_volume\] > $cfg_path
    echo mode=ubi >> $cfg_path
    echo image="$rootfs_path" >> $cfg_path
    echo vol_id=0 >> $cfg_path

    if [[ "${rootfs_type}" = "squashfs" ]]; then
        echo vol_type=static >> $cfg_path
    else
        echo vol_type=dynamic >> $cfg_path
        echo vol_size="${UBI_ROOTFS_SIZE}" >> $cfg_path
    fi

    echo vol_name=rootfs >> $cfg_path
    echo vol_alignment=1 >> $cfg_path

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        # dm-verity hash tree table followed after the rootfs
        # Init scripts will check this partition during boot up
        if [[ -s ${dm_hash_path} ]]; then
            echo >> $cfg_path
            echo \[hash_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_hash_path" >> $cfg_path
            echo vol_id=1 >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_hs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
        fi

        #  dm-verity root hash is following the hash
        if [[ -s ${dm_root_hash_path} ]]; then
            echo >> $cfg_path
            echo \[rh_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_root_hash_path" >> $cfg_path
            echo vol_id=2 >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_rhs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
        fi
    fi
}

get_dm_root_hash() {
    local dm_root_hash_path=$1
    local dm_hash_filename=$2
    local root_hash=$(cat ${dm_hash_filename} | grep Root | awk -F' ' '{printf $3}')
    echo ${root_hash} > ${dm_root_hash_path}
}

prepare_ubi_ps() {
    local page_size=$1
    local image_type=
    local ubinize_cfg=
    local image_path=
    local dm_hash_path=
    local dm_hash_filename=
    local dm_root_hash_path=
    local ubi_path=
    local ubi_link_path=

    for rootfs_type in ubifs squashfs; do

        if [[ "${rootfs_type}" != "squashfs" ]]; then
            image_type=${page_size}.${rootfs_type}
        else
            image_type=${rootfs_type}
        fi

        ubinize_cfg="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${image_type}.ubinize.cfg"
        image_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${image_type}"

        # Now Dm-verity only work with squashfs
        if [ "${DM_VERITY_ENCRYPT}" = "on" -a "${rootfs_type}" = "squashfs" ]; then
            dm_hash_path="${image_path}.hash"
            dm_hash_filename="${dm_hash_path}.txt"
            dm_root_hash_path="${DEPLOY_DIR_IMAGE}/rootfs.rhash"

            if [[ ! -e ${dm_hash_filename} ]]; then
                create_dm_verity_hash ${image_path} ${dm_hash_path} ${dm_hash_filename}
                get_dm_root_hash ${dm_root_hash_path} ${dm_hash_filename}
            fi
            create_ubinize_config ${ubinize_cfg} ${image_type} ${dm_hash_path} ${dm_root_hash_path}
        else
            create_ubinize_config ${ubinize_cfg} ${image_type}
        fi

        ubi_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${rootfs_type}.${page_size}.ubi"
        ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${rootfs_type}.${page_size}.ubi"

        create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
    done
}

yocto_squashfs_duct_tape() {
    # Hack: make symlink from our traditional deploy image
    # location that we had under Yocto 1.7 to the new squashfs
    # location established by Yocto 2.2's do_squashfs_image.
    # Why: without this, prepare_ubi_ps cannot find
    # ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.squashfs
    # The real fix is probably to standardize our custom image recipes
    # to all use IMGDEPLOYDIR.

    ln -sf \
        ${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.squashfs \
        ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.squashfs
}

do_image_complete[postfuncs] += "yocto_squashfs_duct_tape"

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

do_image_complete[postfuncs] += "prepare_ubi"

default_rootfs_ps() {
    # Default rootfs to ubi for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.ubi  ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.default

    # Default rootfs to 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.default
}

do_image_complete[postfuncs] += "default_rootfs_ps"

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

IMAGE_PREPROCESS_COMMAND += "do_setfileattr; "

require mdm9x28-image-cwe.inc
