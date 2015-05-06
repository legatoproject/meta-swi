SUMMARY = "A small image just capable of allowing a device to boot and \
is suitable for development work and testing."

IMAGE_FEATURES += "dev-pkgs"

IMAGE_INSTALL = "packagegroup-core-boot ${ROOTFS_PKGMANAGE_BOOTSTRAP} ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

DEPENDS += "linux-yocto"

IMAGE_ROOTFS_SIZE ?= "8192"

FSTYPE_VIRT ?= "ext3"

IMAGE_INSTALL += "util-linux"
IMAGE_INSTALL += "util-linux-blkid"
IMAGE_INSTALL += "util-linux-mount"
IMAGE_INSTALL += "nfs-utils-client"
IMAGE_INSTALL += "procps"

# Add some extra packages for tool integration
IMAGE_INSTALL += "dropbear"
IMAGE_INSTALL += "strace"
IMAGE_INSTALL += "gdbserver"
IMAGE_INSTALL += "python-core"
IMAGE_INSTALL += "lttng-ust"

IMAGE_INSTALL += "iproute2"
IMAGE_INSTALL += "iptables"

IMAGE_INSTALL += "opkg"
IMAGE_INSTALL += "openssl"
IMAGE_INSTALL += "ppp"

# Adds an alternative to tar (bsdtar)
IMAGE_INSTALL += "libarchive"
IMAGE_INSTALL += "libarchive-bin"

# Enable (de)compression with bz2
IMAGE_INSTALL += "bzip2"

#Required for extended file attributes
IMAGE_INSTALL += "attr"

# Required for some Developer Studio features. 
# Not needed for production builds
IMAGE_INSTALL += "openssh-sftp-server"
IMAGE_INSTALL += "tcf-agent"

# Add some things for dev & system intg
IMAGE_INSTALL += "cmake"
IMAGE_INSTALL += "libopkg"

# Add legato startup
IMAGE_INSTALL += "legato-init"

# Require to provide some extended privileges
# to non-root processes
IMAGE_INSTALL += "libcap"

# Legato
IMAGE_INSTALL += "legato-af"

# Tool to recognize the platform
IMAGE_INSTALL += "bsinfo"

# Prepare a package with kernel + hdd image
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
    if [[ "${VIRT_ARCH}" == "x86" ]]; then
        echo 'CMDLINE="root=/dev/hda1 console=ttyS0 rw mem=128M"' >> $CFG
        echo 'ARG_TARGET=""' >> $CFG
        echo 'ROOTFS_METHOD=-hda' >> $CFG

    elif [[ "${VIRT_ARCH}" == "arm" ]]; then
        echo 'CMDLINE="root=/dev/sda1 console=ttyS0 rootwait mem=128M"' >> $CFG
        echo 'ARG_TARGET="-M versatilepb -m 128"' >> $CFG
        echo 'ROOTFS_METHOD=-hda' >> $CFG
    fi

    # Kernel
    cp -H ${ELF_KERNEL} ${VIRT_DIR}/kernel

    # Hard drive
    dd if=/dev/zero of=hda.raw bs=1M count=1k

    # Partitions
    touch part.sch
    # part 1 = rootfs
    echo ",512,L,*" >> part.sch
    # part 2 = /mnt/flash
    echo ",+,L,-" >> part.sch
    sfdisk -u M --force hda.raw < part.sch

    fdisk -l hda.raw

    sfdisk -d hda.raw

    OFFSET_1=$(sfdisk -d hda.raw |grep hda.raw1 |awk '{print $4}' |sed 's/,//g')
    SIZE_1=$(sfdisk -d hda.raw |grep hda.raw1 |awk '{print $6}' |sed 's/,//g')

    echo "Part 1 | of $OFFSET_1 | sz $SIZE_1"

    OFFSET_2=$(sfdisk -d hda.raw |grep hda.raw2 |awk '{print $4}' |sed 's/,//g')
    SIZE_2=$(sfdisk -d hda.raw |grep hda.raw2 |awk '{print $6}' |sed 's/,//g')

    echo "Part 2 | of $OFFSET_2 | sz $SIZE_2"

    SECTOR_SZ=512

    ROOTFS_IMG="${PN}-${MACHINE}.${FSTYPE_VIRT}"
    echo "Managing rootfs: ${ROOTFS_IMG}"
    cp ${DEPLOY_DIR_IMAGE}/${ROOTFS_IMG} rootfs.${FSTYPE_VIRT}
    e2fsck -p rootfs.${FSTYPE_VIRT}
    resize2fs rootfs.${FSTYPE_VIRT} "$SIZE_1"s

    dd if=rootfs.${FSTYPE_VIRT} conv=notrunc of=hda.raw bs=$SECTOR_SZ seek=$OFFSET_1 count=$SIZE_1

    echo "Generating /mnt/flash"
    dd if=/dev/zero of=flash.${FSTYPE_VIRT} bs=$SECTOR_SZ count=$SIZE_2
    mkfs.${FSTYPE_VIRT} -F flash.${FSTYPE_VIRT}

    dd if=flash.${FSTYPE_VIRT} conv=notrunc of=hda.raw bs=$SECTOR_SZ seek=$OFFSET_2 count=$SIZE_2

    fdisk -l hda.raw

    qemu-img convert -f raw -O qcow2 hda.raw rootfs.qcow2

    # release
    tar jcf $VIRT_NAME $CFG $KERNEL $ROOTFS

    cp $VIRT_NAME ${DEPLOY_DIR_IMAGE}

    cd ${DEPLOY_DIR_IMAGE}
    ln -sf $VIRT_NAME $IMG_NAME.tar.bz2
}

addtask prepare_virt after do_rootfs before do_build

