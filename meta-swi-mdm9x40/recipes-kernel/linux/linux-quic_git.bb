inherit kernel

require recipes-kernel/linux-quic/linux-quic.inc
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"
COMPATIBLE_MACHINE = "(swi-mdm9x40)"

# Override KERNEL_CC for Linux kernel build
KERNEL_CC_prepend = "${LINUX_REPO_DIR}/scripts/gcc-wrapper.py "

# Default console device(s) appended to command line
SYSLINUX_DEFAULT_CONSOLE ?= "console=ttyHSL0,115200 console=ttyHSL1,115200"
KERNEL_BOOT_OPTIONS_RAMDISK =+ "${SYSLINUX_DEFAULT_CONSOLE}"
KERNEL_BOOT_OPTIONS =+ "${SYSLINUX_DEFAULT_CONSOLE}"

# Provide a config baseline for things so the kernel will build...
KBUILD_DEFCONFIG ?= "mdm9640_defconfig"
B = "${WORKDIR}/build"
KERNEL_EXTRA_ARGS        += "O=${B}"

# We split the LINUX_REPO_DIR path into a dirname and basename, so that
# that we can fetch it via SRC_URI. We need to fetch a specific name
# that is found in some directory listed in the FILESPATH search path.
LINUX_REPO_DIR_PARENT = "${@os.path.dirname(d.getVar('LINUX_REPO_DIR', False))}"
LINUX_REPO_DIR_BASE = "${@os.path.basename(d.getVar('LINUX_REPO_DIR', False))}"
FILESPATH_prepend = "${LINUX_REPO_DIR_PARENT}:"
SRC_URI = "file://${LINUX_REPO_DIR_BASE}"

do_deploy[depends] += "dtbtool-native:do_populate_sysroot mkbootimg-native:do_populate_sysroot"

do_unpack_append() {
    wrkdir = d.getVar('WORKDIR', True)
    srcdir = d.getVar('S', True)
    os.system("mkdir -p %s" % (srcdir))
    os.system("cp -drl %s/kernel/. %s/." % (wrkdir, srcdir))
}

do_configure_prepend() {
    cp ${S}/arch/arm/configs/${KBUILD_DEFCONFIG} ${WORKDIR}/defconfig

    oe_runmake_call -C ${S} ${KERNEL_EXTRA_ARGS} mrproper
    oe_runmake_call -C ${S} ARCH=${ARCH} ${KERNEL_EXTRA_ARGS} ${KBUILD_DEFCONFIG}
}

do_compile_append() {
    oe_runmake dtbs ${KERNEL_EXTRA_ARGS}
}

# The following was removed from the kernel class between Yocto 1.7 and 2.2.
# We need our non-sanitized kernel headers in the sysroot it because our apps
# need them.
python sysroot_stage_all () {
    oe.path.copyhardlinktree(d.expand("${D}${KERNEL_SRC_PATH}"), d.expand("${SYSROOT_DESTDIR}${KERNEL_SRC_PATH}"))
}

# Note that @{DATETIME} isn't a BitBake variable expansion;
# see do_bootimg for the crude substitution we do with sed.
# Originally we had the ${DATETIME} variable here.
# What this "fake variable" achieves is a stable base hash across reparses:
# BitBake only ever sees the literal text @{DATETIME},
# so the hash doesn't change. In Yocto 1.7 we didn't see a
# problem, but newer Yocto diagnoses situations when the inputs
# to a task appear to change upon a second parse, changing the
# hash, which occurs if ${DATETIME} is mixed in.
BOOTIMG_NAME_2k ?= "boot-yocto-mdm9x40-@{DATETIME}.2k"
BOOTIMG_NAME_4k ?= "boot-yocto-mdm9x40-@{DATETIME}.4k"

MACHINE_KERNEL_BASE = "0x81800000"
MACHINE_KERNEL_TAGS_OFFSET = "0x82a00000"

gen_master_dtb() {
    master_dtb_name=$1
    page_size=$2

    kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}
    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
    fi
    kernel_img=$(readlink -f $kernel_img)
    ls -al $kernel_img

    set -xe

    ver=$(sed -r 's/#define UTS_RELEASE "(.*)"/\1/' ${B}/include/generated/utsrelease.h)
    dtb_files=$(find ${B}/arch/arm/boot/dts/qcom -iname "*${BASEMACHINE_QCOM}*.dtb" | awk -F/ '{print $NF}' | awk -F[.][d] '{print $1}')

    # Create separate images with dtb appended to zImage for all targets.
    for d in ${dtb_files}; do
       targets=$(echo ${d#${BASEMACHINE_QCOM}-})
       cat $kernel_img ${B}/arch/arm/boot/dts/qcom/${d}.dtb > ${B}/arch/arm/boot/dts/dtb-zImage-${ver}-${targets}.dtb
    done

    ${STAGING_BINDIR_NATIVE}/dtbtool \
        ${B}/arch/arm/boot/dts/qcom/ \
        -s $page_size \
        -o ${DEPLOYDIR}/$master_dtb_name \
        -p ${B}/scripts/dtc/ \
        -v

    if ! [ -e "${DEPLOYDIR}/$master_dtb_name" ]; then
        echo "Unable to generate $master_dtb_name"
        exit 1
    fi
}

do_deploy_append() {
    gen_master_dtb masterDTB.2k 2048
    gen_master_dtb masterDTB.4k 4096
    cp ${B}/vmlinux ${DEPLOYDIR}/vmlinux
}

# Make the bootimg image file using the information available in the sysroot...
do_bootimg[depends] += "mkbootimg-native:do_populate_sysroot"
do_bootimg[depends] += "mdm9x40-image-initramfs:do_image_complete"

gen_bootimg() {
    image_flags=$1
    image_name=$2
    image_link=$3
    master_dtb_name=$4
    page_size=$5

    set -xe

    kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}
    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
    fi
    kernel_img=$(readlink -f $kernel_img)
    ls -al $kernel_img

    # Initramfs
    ${STAGING_BINDIR_NATIVE}/mkbootimg \
        --dt ${DEPLOYDIR}/$master_dtb_name \
        --kernel $kernel_img \
        --ramdisk /dev/null \
        --cmdline "${KERNEL_BOOT_OPTIONS_RAMDISK}" \
        --pagesize $page_size \
        --base ${MACHINE_KERNEL_BASE} \
        --tags-addr ${MACHINE_KERNEL_TAGS_OFFSET} \
        --ramdisk_offset 0x0 \
        --output ${DEPLOY_DIR_IMAGE}/${image_name}.img

    ln -sf ${image_name}.img ${DEPLOY_DIR_IMAGE}/${image_link}.img
}

do_bootimg() {
    date=$(date +"%Y%m%d%H%M%S")
    image_name_2k=$(echo ${BOOTIMG_NAME_2k} | sed -e s/@{DATETIME}/$date/)
    image_name_4k=$(echo ${BOOTIMG_NAME_4k} | sed -e s/@{DATETIME}/$date/)
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" $image_name_2k boot-yocto-mdm9x40.2k masterDTB.2k 2048
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" $image_name_4k boot-yocto-mdm9x40.4k masterDTB.4k 4096
    ln -sf $image_name_4k.img ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x40.img
    echo "${PV} $date" >> ${DEPLOY_DIR_IMAGE}/kernel.version
}

do_add_mbnhdr_and_hash() {
    # Append "mbn header" and "hash of kernel" to kernel image for data integrity check
    # "mbnhdr_data" is 40bytes mbn header data in hex string format
    mbnhdr_data="06000000030000000000000028000000200000002000000048000000000000004800000000000000"
    # Transfer data from hex string format to binary format "0x06,0x00,0x00,..." and write to a file.
    echo -n $mbnhdr_data | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf > ${DEPLOY_DIR_IMAGE}/boot_mbnhdr
    openssl dgst -sha256 -binary ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x40.2k.img > ${DEPLOY_DIR_IMAGE}/boot_hash.2k
    openssl dgst -sha256 -binary ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x40.4k.img > ${DEPLOY_DIR_IMAGE}/boot_hash.4k
    cat ${DEPLOY_DIR_IMAGE}/boot_mbnhdr ${DEPLOY_DIR_IMAGE}/boot_hash.2k >> ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x40.2k.img
    cat ${DEPLOY_DIR_IMAGE}/boot_mbnhdr ${DEPLOY_DIR_IMAGE}/boot_hash.4k >> ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x40.4k.img
}

addtask bootimg after do_deploy before do_build
addtask do_add_mbnhdr_and_hash after do_bootimg before do_build
