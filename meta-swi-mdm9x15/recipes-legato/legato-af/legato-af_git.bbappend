DEPENDS += "yaffs2-utils"
DEPENDS += "alsa-intf"
DEPENDS += "qmi"
DEPENDS += "qmi-framework"
DEPENDS += "sierra"
DEPENDS += "loc-api"

do_install_append() {
    # Generate the framework images
    targs=$(ls -1 ${S}/build)
    for target in ${targs}; do
        DIMG="${WORKDIR}/img_${target}"
        rm -fr ${DIMG}
        mkdir ${DIMG}
        cp -R ${S}/build/${target}/staging/* ${DIMG}/
        mkyaffs2image -c 4096 -s 160 ${DIMG}/ ${DEPLOY_DIR_IMAGE}/legato_af_${target}.yaffs2
    done
}

