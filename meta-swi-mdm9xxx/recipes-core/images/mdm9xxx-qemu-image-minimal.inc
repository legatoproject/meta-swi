blank_flashimage() {
    echo "Erasing flash image"
    (dd if=/dev/zero bs=1M count=256 | tr '\000' '\377' | dd of=${IMGDEPLOYDIR}/rawflash iflag=fullblock bs=1M count=256)
}

do_generate_flashimage() {
    if [[ "${QEMU_BUILD}" != "on" ]]; then
        return
    fi

    set -x

    blank_flashimage

    echo "Installing ROOTFS into flash image"
    dd if=${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${QEMU_ROOTFS_TYPE} of=${IMGDEPLOYDIR}/rawflash conv=notrunc bs=256K
    cp -f ${IMGDEPLOYDIR}/rawflash ${DEPLOY_DIR_IMAGE}/rawflash-yocto
    ln -sf rawflash-yocto ${DEPLOY_DIR_IMAGE}/rawflash

    if [[ "${LEGATO_BUILD}" == "true" ]]; then
        export LEGATO_TARGET="$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')"
        if [ -z "$LEGATO_TARGET" ]; then
            exit 1
        fi

        if [ -z "${FLASH_LEGATO_START}" ]; then
            echo "Start of the legato partition not defined"
            exit 1
        fi

        echo "Installing Legato into flash image"
        SEEK=$(echo "print(${FLASH_LEGATO_START}/(256*1024))" | python)
        QEMU_LEGATO_NAME="${DEPLOY_DIR_IMAGE}/legato-image.$LEGATO_TARGET.qemu.ubi"
        dd if=${QEMU_LEGATO_NAME} of=${IMGDEPLOYDIR}/rawflash bs=256K seek=$SEEK conv=notrunc
        cp -f ${IMGDEPLOYDIR}/rawflash ${DEPLOY_DIR_IMAGE}/rawflash-yocto-legato
        ln -sf rawflash-yocto-legato ${DEPLOY_DIR_IMAGE}/rawflash
    fi

    set +x
}

addtask generate_flashimage after do_image_complete before do_generate_cwe

append_cfg_json() {
    echo "$1" >> $CFG_JSON
}

# Prepare a package with kernel + rawflash + config
do_prepare_qemu_pkg[depends] += "virtual/kernel:do_deploy"
do_prepare_qemu_pkg[deptask] += "do_generate_flashimage"
do_prepare_qemu_pkg() {
    if [[ "${QEMU_BUILD}" != "on" ]]; then
        return
    fi

    set -x

    export LEGATO_TARGET="$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')"
    if [ -z "$LEGATO_TARGET" ]; then
        exit 1
    fi

    IMG_BASENAME="img-$LEGATO_TARGET"
    IMG_NAME="$IMG_BASENAME-$(date +"%Y%m%d-%H%M")"

    CFG_JSON=qemu.json

    QEMU_DIR=${WORKDIR}/virt
    echo "Staging: ${QEMU_DIR}"
    if [ -e "${QEMU_DIR}" ]; then
        rm -rf ${QEMU_DIR}
    fi
    mkdir ${QEMU_DIR}

    echo "Delivery: ${DEPLOY_DIR_IMAGE}"
    mkdir -p ${DEPLOY_DIR_IMAGE}

    cd ${QEMU_DIR}

    # Kernel
    KERNEL="zImage"
    CMDLINE="mem=160M ubi.mtd=0 ubi.block=0,rootfs root=/dev/ubiblock0_0 ro rootfstype=squashfs fudge_ro_rootfs=true user1_fs=ubifs lpj=1830912"
    cp "${DEPLOY_DIR_IMAGE}/$KERNEL" .

    # DTB
    DTB="mdm9607-swi-qemu.dtb"
    cp "${DEPLOY_DIR_IMAGE}/dtb/qcom/$DTB" .

    # Flash Image
    FLASH_IMG="rawflash"
    FLASH_INTERFACE="pflash"
    cp "${DEPLOY_DIR_IMAGE}/$FLASH_IMG" .

    # Machine
    MACHINE="msm9x28"
    MEM="192"

    # Console
    CONSOLE_TTY="ttyHSL1"
    CONSOLE_BAUDRATE="115200"

    # Network
    NET_DRV="smc91c111"

    # QEmu Config (JSON)
    append_cfg_json "{"
    append_cfg_json '    "files": {'
    append_cfg_json '        "kernel": {'
    append_cfg_json '            "name": "'$KERNEL'"'
    append_cfg_json '        },'
    append_cfg_json '        "device_tree": {'
    append_cfg_json '            "name": "'$DTB'"'
    append_cfg_json '        },'
    append_cfg_json '        "flash": {'
    append_cfg_json '            "name": "'$FLASH_IMG'",'
    append_cfg_json '            "interface": "'$FLASH_INTERFACE'",'
    append_cfg_json '            "partitions": {'
    append_cfg_json '                "lefwkro": {'
    append_cfg_json '                    "start": "'${FLASH_LEGATO_START}'",'
    append_cfg_json '                    "size": "'${FLASH_LEGATO_SIZE}'"'
    append_cfg_json '                }'
    append_cfg_json '            }'
    append_cfg_json '        }'
    append_cfg_json '    },'
    append_cfg_json '    "cmdline": "'"$CMDLINE"'",'

    if [[ "${IMA_BUILD}" == "true" ]]; then
        append_cfg_json '    "ima": {'
        append_cfg_json '        "signed": true,'
        append_cfg_json '        "cmdline": "'"${IMA_KERNEL_CMDLINE_OPTIONS}"'"'
        append_cfg_json '    },'
    fi

    append_cfg_json '    "machine": "'$MACHINE'",'
    append_cfg_json '    "memory": "'$MEM'",'
    append_cfg_json '    "console": {'
    append_cfg_json '        "tty": "'$CONSOLE_TTY'",'
    append_cfg_json '        "baudrate": "'$CONSOLE_BAUDRATE'"'
    append_cfg_json '    },'
    append_cfg_json '    "net": {'
    append_cfg_json '        "driver": "'$NET_DRV'"'
    append_cfg_json '    }'
    append_cfg_json '}'

    # Package
    tar jcf "$IMG_NAME.tar.bz2" $CFG $CFG_JSON $KERNEL $DTB $ROOTFS $FLASH_IMG

    # Deploy
    cp "$IMG_NAME.tar.bz2" "${DEPLOY_DIR_IMAGE}/"
    ln -sf $IMG_NAME.tar.bz2 "${DEPLOY_DIR_IMAGE}/$IMG_BASENAME.tar.bz2"

    set +x
}

addtask prepare_qemu_pkg after do_generate_flashimage before do_build
