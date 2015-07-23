FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.4.91"
LINUX_VERSION_EXTENSION = "${PV}"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"

KBRANCH_DEFAULT_MDM9X15 ?= "standard/swi-mdm9x15-yocto-1.6-swi"
KBRANCH_swi-mdm9x15 = "${KBRANCH_DEFAULT_MDM9X15}"

KMETA_DEFAULT_MDM9X15 ?= "meta-yocto-1.6-swi"
KMETA = "${KMETA_DEFAULT_MDM9X15}"

KSRC_linux_yocto_3_4 := "${LINUX_REPO_DIR}"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},${KMETA};name=machine,meta"

# Use latest commits from KBRANCH & KMETA
SRCREV_machine_swi-mdm9x15 = "${AUTOREV}"
SRCREV_meta_swi-mdm9x15 = "${AUTOREV}"

# Make the bootimg image file using the information available in the sysroot...
do_bootimg[depends] += "mkbootimg-native:do_populate_sysroot"
do_bootimg[depends] += "mdm9x15-image-initramfs:do_rootfs"

BOOTIMG_NAME_2k ?= "boot-yocto-mdm9x15-${DATETIME}.2k"
BOOTIMG_NAME_4k ?= "boot-yocto-mdm9x15-${DATETIME}.4k"

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
    ls -al $kernel_img

    if ! [ -e "${DEPLOY_DIR_IMAGE}" ]; then
        mkdir -p ${DEPLOY_DIR_IMAGE}
    fi

    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img_initramfs=${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
        kernel_img_initramfs=$(readlink -f $kernel_img_initramfs)
        ls -al $kernel_img_initramfs

        # Initramfs
        ${STAGING_DIR_NATIVE}/usr/bin/mkbootimg \
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
        ${STAGING_DIR_NATIVE}/usr/bin/mkbootimg \
            --kernel $kernel_img \
            --cmdline "${KERNEL_BOOT_OPTIONS}" \
            --base 0x40800000 \
            $image_flags \
            --ramdisk "NONE" \
            --ramdisk_offset $kernel_size \
            --output ${DEPLOY_DIR_IMAGE}/${image_name}.noramdisk.img

        ln -sf ${image_name}.noramdisk.img ${DEPLOY_DIR_IMAGE}/${image_link}.noramdisk.img

        # With ramdisk
        ${STAGING_DIR_NATIVE}/usr/bin/mkbootimg \
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
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" "${BOOTIMG_NAME_2k}" boot-yocto-mdm9x15.2k 2048
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" "${BOOTIMG_NAME_4k}" boot-yocto-mdm9x15.4k 4096

    # Default to 4k
    cd ${DEPLOY_DIR_IMAGE}
    ln -sf boot-yocto-mdm9x15.4k.img boot-yocto-mdm9x15.img
    ln -sf boot-yocto-mdm9x15.img kernel
}

addtask bootimg after do_deploy before do_build

do_tag_config() {
    sed -i '/LOCALVERSION/s/=".*+/="-/' .config
}

addtask tag_config after do_configure before do_kernel_configcheck

