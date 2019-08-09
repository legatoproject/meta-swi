DEPENDS += " \
        edk2 \
        mtd-utils-native \
        cryptsetup-native \
        libarchive-native"

INC_PR = "r0"

inherit ubi-image
inherit dm-verity-hash
inherit set-files-attr

IMAGE_INSTALL_append = " start-scripts-firmware-links"

IMAGE_INSTALL_append = " kernel-modules"
IMAGE_INSTALL_append = " bsinfo-stub"
IMAGE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '' ,d)}"
IMAGE_INSTALL += "systemd-machine-units"
IMAGE_INSTALL += "system-core-adbd"
IMAGE_INSTALL += "system-core-usb"
IMAGE_INSTALL += "volatile-binds"
IMAGE_INSTALL += "strace"
IMAGE_INSTALL += "reboot-daemon"

create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2
    local vid=0

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        local dm_hash_path=$3
        local dm_root_hash_path=$4
    fi

    local rootfs_path="${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.${rootfs_type}"

    echo \[sysfs_volume\] > $cfg_path
    echo mode=ubi >> $cfg_path
    echo image="$rootfs_path" >> $cfg_path
    echo vol_id=$vid >> $cfg_path
    let vid+=1

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
            echo vol_id=$vid >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_hs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
            let vid+=1
        fi

        #  dm-verity root hash is following the hash
        if [[ -s ${dm_root_hash_path} ]]; then
            echo >> $cfg_path
            echo \[rh_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_root_hash_path" >> $cfg_path
            echo vol_id=$vid >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_rhs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
            let vid+=1
        fi
    fi
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

    mkdir -p "${IMGDEPLOYDIR}"

    for rootfs_type in ubifs squashfs; do
        image_type=${rootfs_type}
        if [[ "${rootfs_type}" != "squashfs" ]]; then
            image_type=${page_size}.${rootfs_type}
        fi

        ubinize_cfg="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${image_type}.ubinize.cfg"
        image_path="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${image_type}"

        # Now Dm-verity only work with squashfs
        if [ "${DM_VERITY_ENCRYPT}" = "on" -a "${rootfs_type}" = "squashfs" ]; then
            dm_hash_path="${image_path}.hash"
            dm_hash_filename="${dm_hash_path}.txt"
            dm_root_hash_path="${image_path}.rhash"

            if [[ ! -e ${dm_hash_filename} ]]; then
                create_dm_verity_hash "${image_path}" "${dm_hash_path}" "${dm_hash_filename}"
                get_dm_root_hash "${dm_root_hash_path}" "${dm_hash_filename}"
            fi
            create_ubinize_config ${ubinize_cfg} ${image_type} ${dm_hash_path} ${dm_root_hash_path}
        else
            create_ubinize_config ${ubinize_cfg} ${image_type}
        fi

        ubi_path="${IMGDEPLOYDIR}/${IMAGE_NAME}.${rootfs_type}.${page_size}.ubi"
        ubi_link_path="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${rootfs_type}.${page_size}.ubi"

        create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
    done
}

prepare_ubi() {
    prepare_ubi_ps '2k'
    prepare_ubi_ps '4k'

    cd ${IMGDEPLOYDIR}

    # Default image (no bs suffix) to 4k + squashfs
    ubi_link_path_def="${IMAGE_LINK_NAME}.squashfs.4k.ubi"
    ubi_link_path_def_2k="${IMAGE_LINK_NAME}.squashfs.2k.ubi"

    ubi_link_path="${IMAGE_LINK_NAME}.4k.ubi"
    ubi_link_path_2k="${IMAGE_LINK_NAME}.2k.ubi"

    rm -f $ubi_link_path $ubi_link_path_2k
    ln -s $ubi_link_path_def $ubi_link_path
    ln -s $ubi_link_path_def_2k $ubi_link_path_2k

    ubi_link_path="${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $ubi_link_path_def $ubi_link_path
}

do_image_complete[postfuncs] += "prepare_ubi"

default_rootfs_ps() {
    cd ${IMGDEPLOYDIR}

    # Default rootfs to ubi for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.ubi  ${IMAGE_LINK_NAME}.4k.default

    # Default rootfs to 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${IMAGE_LINK_NAME}.default
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

ROOTFS_POSTPROCESS_COMMAND_append = " gen_buildprop;"
EXTRA_IMAGE_FEATURES += "${@bb.utils.contains('DISTRO_FEATURES','ro-rootfs','read-only-rootfs','',d)}"
gen_buildprop() {
    mkdir -p ${IMAGE_ROOTFS}/cache
}

require mdm-image-cwe.inc
