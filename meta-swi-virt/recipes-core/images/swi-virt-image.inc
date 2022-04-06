inherit swi-image-minimal

INC_PR = "r0"

FSTYPE_VIRT ?= "squashfs-lzo"

# Tool to recognize the platform
IMAGE_INSTALL:append = " bsinfo-stub"

# Kernel modules
IMAGE_INSTALL:append = " kernel-module-softdog"

# Add eventual legato dependency
DEPENDS += "${@check_legato_pkg(d, "legato-image")}"

# Add timezone related packages
IMAGE_INSTALL:append = " tzdata"
IMAGE_INSTALL:append = " tzone-utils"

append_cfg_json() {
    echo "$1" >> $CFG_JSON
}

# Prepare a package with kernel + hdd image + config
do_prepare_qemu_pkg[depends] += "virtual/kernel:do_deploy"
do_prepare_qemu_pkg() {
    export LEGATO_TARGET="$(echo ${LEGATO_ROOTFS_TARGETS} | awk '{print $1}')"
    if [ -z "$LEGATO_TARGET" ]; then
        exit 1
    fi

    IMG_BASENAME="img-$LEGATO_TARGET"
    IMG_NAME="$IMG_BASENAME-$(date +"%Y%m%d-%H%M")"

    CFG=qemu-config
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

    # QEmu Config (shell)
    touch $CFG

    # Kernel
    KERNEL=kernel
    if [[ "${FSTYPE_VIRT}" == "squashfs"* ]]; then
        CMDLINE="rootfstype=ramfs rootfs.dev=/dev/sda1 rootfs.wait=true rootfs.type=squashfs" >> $CFG
    else
        CMDLINE="rootfstype=ramfs rootfs.dev=/dev/sda1 rootfs.wait=true rootfs.type=${FSTYPE_VIRT}" >> $CFG
    fi
    echo "CMDLINE='$CMDLINE'" >> $CFG

    # Console
    CONSOLE_TTY="$(echo ${SERIAL_CONSOLE} | awk '{print $2}')"
    CONSOLE_BAUDRATE="$(echo ${SERIAL_CONSOLE} | awk '{print $1}')"
    echo "CONSOLE_TTY=$CONSOLE_TTY" >> $CFG

    # Machine
    MEM="192"
    if [[ "${VIRT_ARCH}" == "x86" ]]; then
        MACHINE="q35"
    elif [[ "${VIRT_ARCH}" == "arm" ]]; then
        MACHINE="versatilepb"
    fi
    echo "ARG_TARGET='-machine $MACHINE -m $MEM'" >> $CFG

    # Rootfs
    ROOTFS=rootfs.qcow2
    ROOTFS_METHOD="-hda"
    echo "ROOTFS_METHOD=$ROOTFS_METHOD" >> $CFG

    # ... IMA
    if [[ "${IMA_BUILD}" == "true" ]]; then
        echo 'IMA_BUILD=1' >> $CFG
        echo "IMA_KERNEL_CMDLINE_OPTIONS='${IMA_KERNEL_CMDLINE_OPTIONS}'" >> $CFG
    fi

    # Network
    NET_DRV="virtio"
    echo "NET_DRV=$NET_DRV" >> $CFG

    # QEmu Config (JSON)
    append_cfg_json "{"
    append_cfg_json '    "files": {'
    append_cfg_json '        "kernel": {'
    append_cfg_json '            "name": "'$KERNEL'"'
    append_cfg_json '        },'
    append_cfg_json '        "rootfs": {'
    append_cfg_json '            "name": "'$ROOTFS'",'
    append_cfg_json '            "method": "'$ROOTFS_METHOD'"'
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

    # Kernel
    cp -H "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin" "$QEMU_DIR/$KERNEL"

    # Hard drive
    dd if=/dev/zero of=hda.raw bs=1M count=1k

    # Partitions
    touch part.sch
    # part 1 = rootfs
    echo ",+,L,-" >> part.sch
    sfdisk --force hda.raw < part.sch

    fdisk -l hda.raw

    sfdisk -d hda.raw

    OFFSET_1=$(sfdisk -d hda.raw |grep hda.raw1 |awk '{print $4}' |sed 's/,//g')
    SIZE_1=$(sfdisk -d hda.raw |grep hda.raw1 |awk '{print $6}' |sed 's/,//g')

    echo "Part 1 | of $OFFSET_1 | sz $SIZE_1"

    SECTOR_SZ=512

    ROOTFS_IMG="${PN}-${MACHINE}.${FSTYPE_VIRT}"
    echo "Managing rootfs: ${ROOTFS_IMG}"
    cp ${DEPLOY_DIR_IMAGE}/${ROOTFS_IMG} rootfs.${FSTYPE_VIRT}
    if [[ "${FSTYPE_VIRT}" == "ext"* ]]; then
        e2fsck -p rootfs.${FSTYPE_VIRT}
        resize2fs rootfs.${FSTYPE_VIRT} "$SIZE_1"s
    fi

    dd if=rootfs.${FSTYPE_VIRT} conv=notrunc of=hda.raw bs=$SECTOR_SZ seek=$OFFSET_1 count=$SIZE_1

    fdisk -l hda.raw

    qemu-img convert -f raw -O qcow2 hda.raw $ROOTFS

    # Package
    tar jcf "$IMG_NAME.tar.bz2" $CFG $CFG_JSON $KERNEL $ROOTFS

    # Deploy
    cp "$IMG_NAME.tar.bz2" "${DEPLOY_DIR_IMAGE}/"
    ln -sf "$IMG_NAME.tar.bz2" "${DEPLOY_DIR_IMAGE}/$IMG_BASENAME.tar.bz2"
}

addtask prepare_qemu_pkg after do_image_complete before do_build

## Sign rootfs using IMA/EVM tools
# Highly inspired from https://github.com/intel/meta-intel-iot-security/blob/master/meta-integrity/classes/ima-evm-rootfs.bbclass

# evmctl must have been installed first.
do_rootfs[depends] += "ima-evm-utils-native:do_populate_sysroot"

# Sign all regular files by default.
IMA_EVM_ROOTFS_SIGNED ?= ". -type f"
# Hash nothing by default.
IMA_EVM_ROOTFS_HASHED ?= ". -maxdepth 0 -false"

fakeroot ima_evm_sign_rootfs() {
    if [[ "${IMA_BUILD}" != "true" ]]; then
        return
    fi

    echo "Signing rootfs"

    if [ -z "${IMA_PRIV_KEY}" ] || [ ! -e "${IMA_PRIV_KEY}" ]; then
        echo "Missing IMA private key"
        exit 1
    fi

    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${STAGING_LIBDIR_NATIVE}

    cd "${IMAGE_ROOTFS}"

    # Sign file with private IMA key. EVM not supported at the moment.
    bbnote "IMA/EVM: signing files 'find ${IMA_EVM_ROOTFS_SIGNED}' with private key '${IMA_PRIV_KEY}'"
    find ${IMA_EVM_ROOTFS_SIGNED} > "${B}/rootfs.signed"
    while read -r -u 10 f; do
        evmctl ima_sign --key ${IMA_PRIV_KEY} $f
    done 10< "${B}/rootfs.signed"

    bbnote "IMA/EVM: hashing files 'find ${IMA_EVM_ROOTFS_HASHED}'"
    find ${IMA_EVM_ROOTFS_HASHED} > "${B}/rootfs.hashed"
    while read -r -u 10 f; do
        evmctl ima_hash $f
    done 10< "${B}/rootfs.hashed"
}

IMAGE_PREPROCESS_COMMAND:append = " ima_evm_sign_rootfs; "

