
do_install() {
    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        local dm_hash_filename="${DEPLOY_DIR_IMAGE}/tmp.parameter.txt"
        ROOTHASH=$(cat $dm_hash_filename | grep ROOTHASH | awk -F'=' '{printf $2}')
        sed -i 's/^.*ROOTHASH=.*$/ROOTHASH='${ROOTHASH}'/g' ${WORKDIR}/init.sh
    fi

    install -m 0755 ${WORKDIR}/init.sh ${D}/init
}

do_install[depends] += "mdm9x50-image-minimal:do_rootfs"
