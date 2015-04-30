FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.14.29"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_DEFAULT = "standard/swi-mdm9x15-yocto-1.7"
KBRANCH = "${KBRANCH_DEFAULT}"
KMETA="meta-yocto-1.7"

KSRC_linux_yocto_3_14 := "${THISDIR}/../../../../linux-yocto-3.14"
SRC_URI = "git://${KSRC_linux_yocto_3_14};protocol=file;branch=${KBRANCH},${KMETA};name=machine,meta"

COMPATIBLE_MACHINE_swi-mdm9x15 = "(swi-mdm9x15)"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine = "${SRCREV}"
SRCREV_machine_pn-linux-yocto_swi-mdm9x15 ?= "${AUTOREV}"
SRCREV_meta_pn-linux-yocto_swi-mdm9x15 ?= "${AUTOREV}"

do_patch_prepend(){
	if [ "${KBRANCH}" != "standard/base" ]; then
		updateme_flags="--branch ${KBRANCH}"
	fi
}

# Make the bootimg image file using the information available in the sysroot...
do_bootimg[depends] += "mkbootimg-native:do_populate_sysroot"

BOOTIMG_NAME_2k ?= "boot-yocto-mdm9x15-${DATETIME}.2k.img"
BOOTIMG_NAME_4k ?= "boot-yocto-mdm9x15-${DATETIME}.4k.img"

gen_bootimg() {
    image_flags=$1
    image_name=$2
    image_link=$3
    page_size=$4

    page_size2=$(expr $page_size - 1)
    kernel_size=$(awk --non-decimal-data '/ _end/ {end="0x" $1} /_stext/ {beg="0x" $1} END {size1=end-beg+'$page_size'; size=and(size1,compl('$page_size2')); printf("%#x",size)}' ${B}/System.map)
    kernel_img=${B}/arch/arm/boot/${KERNEL_IMAGETYPE}

    ls -al $kernel_img

    if ! [ -e "${DEPLOY_DIR_IMAGE}" ]; then
        mkdir -p ${DEPLOY_DIR_IMAGE}
    fi

    ${STAGING_DIR_NATIVE}/usr/bin/mkbootimg --kernel $kernel_img \
        --ramdisk /dev/null \
        --cmdline "${KERNEL_BOOT_OPTIONS}" \
        --base 0x40800000 \
        $image_flags \
        --ramdisk_offset $kernel_size \
        --output ${DEPLOY_DIR_IMAGE}/$image_name

    ln -sf $image_name ${DEPLOY_DIR_IMAGE}/$image_link
}

do_bootimg() {
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" "${BOOTIMG_NAME_2k}" boot-yocto-mdm9x15.2k.img 2048
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" "${BOOTIMG_NAME_4k}" boot-yocto-mdm9x15.4k.img 4096

    # Default to 4k
    cd ${DEPLOY_DIR_IMAGE}
    ln -sf ${BOOTIMG_NAME_4k} boot-yocto-mdm9x15.img
    ln -sf boot-yocto-mdm9x15.img kernel
}

addtask bootimg after do_compile before do_build

do_tag_config() {
    sed -i '/LOCALVERSION/s/=".*+/="-/' .config
}

addtask tag_config after do_configure before do_kernel_configcheck

