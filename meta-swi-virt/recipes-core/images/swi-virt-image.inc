inherit swi-image-minimal

INC_PR = "r0"

FSTYPE_VIRT ?= "squashfs-lzo"

# Tool to recognize the platform
IMAGE_INSTALL_append = " bsinfo-stub"

# Kernel modules
IMAGE_INSTALL_append = " kernel-module-softdog"

# Add eventual legato dependency
DEPENDS += "${@check_legato_pkg(d)}"

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
        echo 'CMDLINE="rootfs.dev=/dev/sda1 rootfs.wait=true rootfs.type=squashfs"' >> $CFG
    else
        echo "CMDLINE='rootfs.dev=/dev/sda1 rootfs.wait=true rootfs.type=${FSTYPE_VIRT}'" >> $CFG
    fi

    if [[ "${VIRT_ARCH}" == "x86" ]]; then
        echo 'ARG_TARGET="-machine q35 -m 192M"' >> $CFG
        echo 'ROOTFS_METHOD=-hda' >> $CFG
        echo 'CONSOLE_TTY=ttyS0' >> $CFG

    elif [[ "${VIRT_ARCH}" == "arm" ]]; then
        echo 'ARG_TARGET="-machine versatilepb -m 192M"' >> $CFG
        echo 'ROOTFS_METHOD=-hda' >> $CFG
        echo 'CONSOLE_TTY=ttyS0' >> $CFG
    fi

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
