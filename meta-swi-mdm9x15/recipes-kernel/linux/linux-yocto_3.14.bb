require recipes-kernel/linux/linux-yocto.inc

inherit kernel-src-install

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PV = "3.14.79"
LINUX_VERSION = "${PV}"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"

KBRANCH_DEFAULT_MDM9X15 ?= "standard/swi-mdm9x15-yocto-1.7-ref"
KBRANCH_swi-mdm9x15 = "${KBRANCH_DEFAULT_MDM9X15}"

# Provide a config baseline for things so the kernel will build...
KBUILD_DEFCONFIG ?= "mdm9615_defconfig"

KMETA_DEFAULT_MDM9X15 ?= "meta-yocto-1.7-ref"
KMETA = "${KMETA_DEFAULT_MDM9X15}"

KSRC_linux_yocto_3_14 := "${LINUX_REPO_DIR}/.git"
SRC_URI = "git://${KSRC_linux_yocto_3_14};protocol=file;branch=${KBRANCH},${KMETA};name=machine,meta"

COMPATIBLE_MACHINE_swi-mdm9x15 = "(swi-mdm9x15)"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine = "${SRCREV}"
SRCREV_machine_pn-linux-yocto_swi-mdm9x15 ?= "${AUTOREV}"
SRCREV_meta_pn-linux-yocto_swi-mdm9x15 ?= "${AUTOREV}"

# Tell yocto to build device tree.
KERNEL_DEVICETREE = "${KERNEL_DEVICE_TREE_BLOB_NAME}"

# The following was removed from the kernel class between Yocto 1.7 and 2.2.
# We need our non-sanitized kernel headers in the sysroot it because our apps
# need them.
python sysroot_stage_all () {
    oe.path.copyhardlinktree(d.expand("${D}${KERNEL_SRC_PATH}"), d.expand("${SYSROOT_DESTDIR}${KERNEL_SRC_PATH}"))
}

do_patch_prepend(){
    if [ "${KBRANCH}" != "standard/base" ]; then
        updateme_flags="--branch ${KBRANCH}"
    fi
}

# Make the bootimg image file using the information available in the sysroot...
do_bootimg[depends] += "mkbootimg-native:do_populate_sysroot"
do_bootimg[depends] += "mdm9x15-image-initramfs:do_image_complete"

# Note that @{DATETIME} isn't a BitBake variable expansion;
# see do_bootimg for the crude substitution we do with sed.
# Originally we had the ${DATETIME} variable here.
# What this "fake variable" achieves is a stable base hash across reparses:
# BitBake only ever sees the literal text @{DATETIME},
# so the hash doesn't change. In Yocto 1.7 we didn't see a
# problem, but newer Yocto diagnoses situations when the inputs
# to a task appear to change upon a second parse, changing the
# hash, which occurs if ${DATETIME} is mixed in.
BOOTIMG_NAME_2k ?= "boot-yocto-mdm9x15-@{DATETIME}.2k"
BOOTIMG_NAME_4k ?= "boot-yocto-mdm9x15-@{DATETIME}.4k"

gen_bootimg() {
    image_flags=$1
    image_name=$2
    image_link=$3
    page_size=$4

    set -xe

    page_size2=$(expr $page_size - 1)

    system_map_path="${SYSROOT_DESTDIR}${KERNEL_SRC_PATH}/System.map-${KERNEL_VERSION}"
    if [[ "${KERNEL_VERSION}" == "None" ]]; then
        system_map_path=$(ls -1t "${SYSROOT_DESTDIR}${KERNEL_SRC_PATH}/System.map-*" | head -1)
    fi

    kernel_size=$(awk --non-decimal-data '/ _end/ {end="0x" $1} /_stext/ {beg="0x" $1} END {size1=end-beg+'$page_size'; size=and(size1,compl('$page_size2')); printf("%#x",size)}' $system_map_path)
    kernel_img=${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}
    kernel_img=$(readlink -f $kernel_img)
    kernel_img_dtree=${kernel_img}
    ls -al $kernel_img

    if ! [ -e "${DEPLOY_DIR_IMAGE}" ]; then
        mkdir -p ${DEPLOY_DIR_IMAGE}
    fi

    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img_initramfs=${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
        kernel_img_initramfs=$(readlink -f $kernel_img_initramfs)
        kernel_img_dtree=${kernel_img_initramfs}
        ls -al $kernel_img_initramfs
    fi

    # If blob name is empty, there is no device tree support.
    # If there is device tree support, run the command only
    # if blob needs to be attached to the kernel.
    if [ "${KERNEL_DEVICE_TREE_BLOB_NAME}" != "" -a \
         "${KERNEL_ATTACHED_DEVICE_TREE}" -eq 1 ] ; then
        # Yocto 2.5: DTB file name has kernel image type prepended.
        if [ -e ${DEPLOY_DIR_IMAGE}/${KERNEL_DEVICE_TREE_BLOB_NAME} ] ; then
            cat ${DEPLOY_DIR_IMAGE}/${KERNEL_DEVICE_TREE_BLOB_NAME} >>${kernel_img_dtree}
        else
            cat ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${KERNEL_DEVICE_TREE_BLOB_NAME} >>${kernel_img_dtree}
        fi
    fi

    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then

        # Initramfs
        ${STAGING_BINDIR_NATIVE}/mkbootimg \
            --kernel $kernel_img_initramfs \
            --cmdline "${KERNEL_BOOT_OPTIONS_RAMDISK}" \
            --base 0x40800000 \
            $image_flags \
            --ramdisk "NONE" \
            --ramdisk_offset $kernel_size \
            --output ${DEPLOY_DIR_IMAGE}/${image_name}.initramfs.img

        ln -sf ${image_name}.initramfs.img ${DEPLOY_DIR_IMAGE}/${image_link}.initramfs.img

        # Default to initramfs
        ln -sf ${image_name}.initramfs.img ${DEPLOY_DIR_IMAGE}/${image_name}.img
        ln -sf ${image_name}.img ${DEPLOY_DIR_IMAGE}/${image_link}.img
    else
        # No ramdisk
        ${STAGING_BINDIR_NATIVE}/mkbootimg \
            --kernel $kernel_img \
            --cmdline "${KERNEL_BOOT_OPTIONS}" \
            --base 0x40800000 \
            $image_flags \
            --ramdisk "NONE" \
            --ramdisk_offset $kernel_size \
            --output ${DEPLOY_DIR_IMAGE}/${image_name}.noramdisk.img

        ln -sf ${image_name}.noramdisk.img ${DEPLOY_DIR_IMAGE}/${image_link}.noramdisk.img

        # With ramdisk
        ${STAGING_BINDIR_NATIVE}/mkbootimg \
            --kernel $kernel_img \
            --cmdline "${KERNEL_BOOT_OPTIONS_RAMDISK}" \
            --base 0x40800000 \
            $image_flags \
            --ramdisk ${DEPLOY_DIR_IMAGE}/mdm9x15-image-initramfs-swi-mdm9x15.cpio.gz \
            --ramdisk_offset $kernel_size \
            --output ${DEPLOY_DIR_IMAGE}/${image_name}.ramdisk.img

        ln -sf ${image_name}.ramdisk.img ${DEPLOY_DIR_IMAGE}/${image_link}.ramdisk.img

        # Default to ramdisk
        ln -sf ${image_name}.ramdisk.img ${DEPLOY_DIR_IMAGE}/${image_name}.img
        ln -sf ${image_name}.img ${DEPLOY_DIR_IMAGE}/${image_link}.img
    fi
}

do_bootimg() {
    date=$(date +"%Y%m%d%H%M%S")
    image_name_2k=$(echo ${BOOTIMG_NAME_2k} | sed -e s/@{DATETIME}/$date/)
    image_name_4k=$(echo ${BOOTIMG_NAME_4k} | sed -e s/@{DATETIME}/$date/)

    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" $image_name_2k boot-yocto-mdm9x15.2k 2048
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" $image_name_4k boot-yocto-mdm9x15.4k 4096

    # Default to 4k
    cd ${DEPLOY_DIR_IMAGE}
    ln -sf boot-yocto-mdm9x15.4k.img boot-yocto-mdm9x15.img
    ln -sf boot-yocto-mdm9x15.img kernel
    echo "${KERNEL_VERSION} $(date +'%Y/%m/%d %H:%M:%S')" >> kernel.version
}

addtask bootimg after do_deploy before do_build

do_tag_config() {
    cd ${KBUILD_OUTPUT}
    sed -i '/LOCALVERSION/s/=".*+/="-/' .config
}

do_configure_prepend() {
    cp ${S}/arch/arm/configs/${KBUILD_DEFCONFIG} ${WORKDIR}/defconfig
}

do_install_append() {
    kernel_src_install
}

addtask tag_config after do_configure before do_kernel_configcheck
