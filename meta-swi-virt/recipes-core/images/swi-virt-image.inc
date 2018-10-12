inherit swi-image-minimal

INC_PR = "r0"

FSTYPE_VIRT ?= "squashfs-lzo"

# Tool to recognize the platform
IMAGE_INSTALL_append = " bsinfo-stub"

# Kernel modules
IMAGE_INSTALL_append = " kernel-module-softdog"

# Add eventual legato dependency
DEPENDS += "${@check_legato_pkg(d, "legato-image")}"

# Add timezone related packages
IMAGE_INSTALL_append = " tzdata"
IMAGE_INSTALL_append = " tzone-utils"

# Prepare a package with kernel + hdd image
do_prepare_virt[depends] += "virtual/kernel:do_deploy"
do_prepare_virt() {
    VIRT_DIR=${WORKDIR}/virt

    IMG_NAME=img-virt-${VIRT_ARCH}

    CFG=qemu-config
    KERNEL=kernel
    ROOTFS=rootfs.qcow2

    VIRT_NAME=$IMG_NAME-`date +"%Y%m%d-%H%M"`.tar.bz2

    echo "Staging: ${VIRT_DIR}"
    if [ -e "${VIRT_DIR}" ]; then
        rm -rf ${VIRT_DIR}
    fi
    mkdir ${VIRT_DIR}

    echo "Delivery: ${DEPLOY_DIR_IMAGE}"
    mkdir -p ${DEPLOY_DIR_IMAGE}

    cd ${VIRT_DIR}

    # QEmu Config
    touch $CFG

    if [[ "${FSTYPE_VIRT}" == "squashfs"* ]]; then
        echo 'CMDLINE="rootfstype=ramfs rootfs.dev=/dev/sda1 rootfs.wait=true rootfs.type=squashfs"' >> $CFG
    else
        echo "CMDLINE='rootfstype=ramfs rootfs.dev=/dev/sda1 rootfs.wait=true rootfs.type=${FSTYPE_VIRT}'" >> $CFG
    fi

    echo "CONSOLE_TTY=$(echo ${SERIAL_CONSOLE} | awk '{print $2}')" >> $CFG

    if [[ "${VIRT_ARCH}" == "x86" ]]; then
        echo 'ARG_TARGET="-machine q35 -m 192M"' >> $CFG
        echo 'ROOTFS_METHOD=-hda' >> $CFG

    elif [[ "${VIRT_ARCH}" == "arm" ]]; then
        echo 'ARG_TARGET="-machine versatilepb -m 192M"' >> $CFG
        echo 'ROOTFS_METHOD=-hda' >> $CFG
    fi

    # ... IMA
    if [[ "${IMA_BUILD}" == "true" ]]; then
        echo 'IMA_BUILD=1' >> $CFG
        echo "IMA_KERNEL_CMDLINE_OPTIONS=\"${IMA_KERNEL_CMDLINE_OPTIONS}\"" >> $CFG
    fi

    # Network
    echo "NET_DRV=virtio" >> $CFG

    # Kernel
    cp -H "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin" ${VIRT_DIR}/kernel

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

    qemu-img convert -f raw -O qcow2 hda.raw rootfs.qcow2

    # release
    tar jcf $VIRT_NAME $CFG $KERNEL $ROOTFS

    cp $VIRT_NAME ${DEPLOY_DIR_IMAGE}

    cd ${DEPLOY_DIR_IMAGE}
    ln -sf $VIRT_NAME $IMG_NAME.tar.bz2
}

addtask prepare_virt after do_image_complete before do_build

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

IMAGE_PREPROCESS_COMMAND_append = " ima_evm_sign_rootfs; "

