INC_PR = "r0"

inherit ubi-image
inherit set-files-attr

create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2

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

    for rootfs_type in squashfs; do
        ubinize_cfg="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.${rootfs_type}.ubinize.cfg"
        image_path="${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${rootfs_type}"

        create_ubinize_config ${ubinize_cfg} ${rootfs_type}

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
    prepare_ubi_ps '4k'

    # Default image (no bs suffix) to 4k + squashfs
    ubi_link_path_def="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.squashfs.4k.ubi"

    ubi_link_path="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.4k.ubi"
    rm -f $ubi_link_path
    ln -s $(basename $ubi_link_path_def) $ubi_link_path

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
