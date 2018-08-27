
do_install() {
    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        local dm_hash_filename="${DEPLOY_DIR_IMAGE}/rootfs.rhash"
        ROOTHASH=$(cat $dm_hash_filename)
        sed -i 's/^.*ROOTHASH=.*$/ROOTHASH='${ROOTHASH}'/g' ${WORKDIR}/init.sh
    fi

    install -m 0755 ${WORKDIR}/init.sh ${D}/init
}

# force do_install task to run for synchronizing roothash
do_install[nostamp] = "1"
do_install[depends] += "mdm9x28-image-minimal:do_image_complete"
