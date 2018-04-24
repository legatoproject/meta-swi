DEPENDS += " \
        mtd-utils-native \
        "

create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2

    local rootfs_path="${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.${rootfs_type}"

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
}

prepare_ubi_ps() {
    local page_size=$1
    local ubinize_cfg=
    local image_path=
    local dm_hash_path=
    local dm_hash_filename=
    local dm_root_hash_path=
    local ubi_path=
    local ubi_link_path=

    mkdir -p "${IMGDEPLOYDIR}"
    for rootfs_type in squashfs; do
        ubinize_cfg="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${rootfs_type}.ubinize.cfg"
        image_path="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${rootfs_type}"

        create_ubinize_config ${ubinize_cfg} ${rootfs_type}

        ubi_path="${IMGDEPLOYDIR}/${IMAGE_NAME}.${rootfs_type}.${page_size}.ubi"
        ubi_link_path="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${rootfs_type}.${page_size}.ubi"

        create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
    done
}


# Create UBI images
prepare_ubi() {
    prepare_ubi_ps '4k'

    cd ${IMGDEPLOYDIR}

    # Default image (no bs suffix) to 4k + squashfs
    ubi_link_path_def="${IMAGE_LINK_NAME}.squashfs.4k.ubi"

    ubi_link_path="${IMAGE_LINK_NAME}.4k.ubi"
    rm -f $ubi_link_path
    ln -s $ubi_link_path_def $ubi_link_path

    ubi_link_path="${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $ubi_link_path_def $ubi_link_path
}

default_rootfs_ps() {
    cd ${IMGDEPLOYDIR}

    # Default rootfs to ubi for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.ubi  ${IMAGE_LINK_NAME}.4k.default

    # Default rootfs to 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${IMAGE_LINK_NAME}.default
}
