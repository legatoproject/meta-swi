SUMMARY = "A small image just capable of allowing a device to boot and \
is suitable for development work and testing."

IMAGE_FEATURES += "dev-pkgs"

IMAGE_INSTALL = "packagegroup-core-boot ${ROOTFS_PKGMANAGE_BOOTSTRAP} ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_INSTALL += "util-linux"
IMAGE_INSTALL += "util-linux-blkid"
IMAGE_INSTALL += "util-linux-mount"
IMAGE_INSTALL += "nfs-utils-client"

# Add some extra packages for tool integration
IMAGE_INSTALL += "dropbear"
IMAGE_INSTALL += "strace"
IMAGE_INSTALL += "gdbserver"
IMAGE_INSTALL += "python-core"
IMAGE_INSTALL += "lttng-ust"

IMAGE_INSTALL += "iproute2"
IMAGE_INSTALL += "iptables"
IMAGE_INSTALL += "udev-cache"

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
# Note that this pulls bash back in
IMAGE_INSTALL += "openssh-sftp-server"
IMAGE_INSTALL += "tcf-agent"
IMAGE_INSTALL += "bash"

# Add some things for dev & system intg
IMAGE_INSTALL += "cmake"
IMAGE_INSTALL += "libopkg"

# Add legato startup
IMAGE_INSTALL += "legato-init"

# Prepare a package with kernel + hdd image
do_prepare_virt() {
    VIRT_DIR=${WORKDIR}/virt

    IMG_ARCH=x86
    IMG_NAME=img-virt-$IMG_ARCH

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
    dd if=/dev/zero of=hda.raw bs=1M count=1k
    
    # Kernel
    cp -H ${DEPLOY_DIR_IMAGE}/bzImage ${VIRT_DIR}/kernel

    # Partitions
    touch part.sch
    echo ",512,L,*" >> part.sch
    echo ",+,L,-" >> part.sch
    sfdisk -u M hda.raw < part.sch

    fdisk -l hda.raw

    sfdisk -d hda.raw

    OFFSET_1=$(sfdisk -d hda.raw |grep hda.raw1 |awk '{print $4}' |sed 's/,//g')
    SIZE_1=$(sfdisk -d hda.raw |grep hda.raw1 |awk '{print $6}' |sed 's/,//g')

    OFFSET_2=$(sfdisk -d hda.raw |grep hda.raw2 |awk '{print $4}' |sed 's/,//g')
    SIZE_2=$(sfdisk -d hda.raw |grep hda.raw2 |awk '{print $6}' |sed 's/,//g')

    SECTOR_SZ=512

    echo "$OFFSET_1 $SIZE_1"

    echo "Managing rootfs"
    cp ${DEPLOY_DIR_IMAGE}/swi-virt-image-dev-swi-virt.ext3 rootfs.ext3
    e2fsck -p rootfs.ext3
    resize2fs rootfs.ext3 "$SIZE_1"s

    dd if=rootfs.ext3 conv=notrunc of=hda.raw bs=$SECTOR_SZ seek=$OFFSET_1 count=$SIZE_1

    echo "Generating /mnt/flash"
    dd if=/dev/zero of=flash.ext3 bs=$SECTOR_SZ count=$SIZE_2
    mkfs.ext3 -F flash.ext3

    dd if=flash.ext3 conv=notrunc of=hda.raw bs=$SECTOR_SZ seek=$OFFSET_2 count=$SIZE_2

    fdisk -l hda.raw

    qemu-img convert -f raw -O qcow2 hda.raw rootfs.qcow2

    # release
    tar jcf $VIRT_NAME $KERNEL $ROOTFS

    cp $VIRT_NAME ${DEPLOY_DIR_IMAGE}

    cd ${DEPLOY_DIR_IMAGE}
    ln -sf $VIRT_NAME $IMG_NAME.tar.bz2
}

addtask prepare_virt after do_rootfs before do_build
