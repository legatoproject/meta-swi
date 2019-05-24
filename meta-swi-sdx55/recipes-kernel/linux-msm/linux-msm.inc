inherit kernel kernel-yocto
#inherit qperf
 
require recipes-kernel/linux-quic/linux-quic.inc

DESCRIPTION = "CAF Linux Kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"

DEPENDS += " mkbootimg-native openssl-native kern-tools-native"
RDEPENDS_${KERNEL_PACKAGE_NAME}-base = ""

LDFLAGS_aarch64 = "-O1 --hash-style=gnu --as-needed"

DEPENDS_append_aarch64 = " libgcc"
KERNEL_CC_append_aarch64 = " ${TOOLCHAIN_OPTIONS}"
KERNEL_LD_append_aarch64 = " ${TOOLCHAIN_OPTIONS}"

KERNEL_PRIORITY           = "9001"
# Add V=1 to KERNEL_EXTRA_ARGS for verbose
KERNEL_EXTRA_ARGS        += "O=${B}"

LINUX_REPO_DIR_PARENT = "${@os.path.dirname(d.getVar('LINUX_REPO_DIR', False))}"
LINUX_REPO_DIR_BASE = "${@os.path.basename(d.getVar('LINUX_REPO_DIR', False))}"
FILESPATH_prepend = "${LINUX_REPO_DIR_PARENT}:"
SRC_URI = "file://${LINUX_REPO_DIR_BASE} \
           ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'file://systemd.cfg', '', d)} \
           ${@bb.utils.contains('DISTRO_FEATURES', 'virtualization', 'file://virtualization.cfg', '', d)} \
           ${@bb.utils.contains('DISTRO_FEATURES', 'nand-squashfs', 'file://squashfs.cfg', '', d)} \
           "

PACKAGE_ARCH = "${MACHINE_ARCH}"
PACKAGES = "kernel kernel-base kernel-vmlinux kernel-dev kernel-dbg kernel-modules"

KBRANCH ?= ""
KMETA = "kernel-meta"
KMACHINE ?= "${MACHINE}"
KCONFIG_MODE = "--alldefconfig"
KBUILD_DEFCONFIG ?= "${KERNEL_CONFIG}"
LINUX_VERSION_EXTENSION = "${@['-perf', ''][d.getVar('VARIANT', True) == ('' or 'debug')]}"

do_kernel_checkout[noexec] = "1"

# extra task for configuration checks
addtask kernel_configcheck after do_configure before do_compile

# Note that @{DATETIME} isn't a BitBake variable expansion;
# see do_bootimg for the crude substitution we do with sed.
# Originally we had the ${DATETIME} variable here.
# What this "fake variable" achieves is a stable base hash across reparses:
# BitBake only ever sees the literal text @{DATETIME},
# so the hash doesn't change. In Yocto 1.7 we didn't see a
# problem, but newer Yocto diagnoses situations when the inputs
# to a task appear to change upon a second parse, changing the
# hash, which occurs if ${DATETIME} is mixed in.
BOOTIMG_NAME_2k ?= "boot-yocto-sdx55-@{DATETIME}.2k"
BOOTIMG_NAME_4k ?= "boot-yocto-sdx55-@{DATETIME}.4k"

do_unpack_append() {
    wrkdir = d.getVar('WORKDIR', True)
    srcdir = d.getVar('S', True)
    os.system("mkdir -p %s" % (srcdir))
    os.system("cp -drl %s/kernel/. %s/." % (wrkdir, srcdir))
}

do_compile () {
    oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" ${KERNEL_EXTRA_ARGS} $use_alternate_initrd
}

do_deploy_prepend() {
    if [[ ${KERNEL_IMAGETYPE} != *-dtb ]]; then
        bberror "${PN}: Only appended DTB supported; Change KERNEL_IMAGETYPE to ${KERNEL_IMAGETYPE}-dtb in your kernel config."
        return
    fi

    # Remove kernel binary mysteriously installed by previous steps
    if [ -f ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE} ] ; then
        rm -f ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}
    fi
}

# Put the zImage in the kernel-dev pkg
FILES_kernel-dev += "/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}-${KERNEL_VERSION}"

FILES_kernel-dbg += "${KERNEL_SRC_PATH}/arch/*/boot/*/.debug/*"

gen_bootimg() {
    image_flags=$1
    image_name=$2
    image_link=$3
    page_size=$4
    ret_ok=0
    ret_err=1

    set -xe

    # If IMA_BUILD is requested, IMA kernel command line options
    # must be available.
    if [ "x${IMA_BUILD}" == "xtrue" -a "x${IMA_KERNEL_CMDLINE_OPTIONS}" == "x" ] ; then
        echo "IMA build requested, but IMA_KERNEL_CMDLINE_OPTIONS variable is empty."
        return $ret_err
    else
        echo "Kernel command line IMA options: [${IMA_KERNEL_CMDLINE_OPTIONS}]"
    fi

    kernel_cmdline="${KERNEL_BOOT_OPTIONS}"
    kernel_img=${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${KERNEL_IMAGE_NAME}.bin
    if [ "x${INITRAMFS_IMAGE_BUNDLE}" = "x1" ] ; then
        kernel_cmdline="${KERNEL_BOOT_OPTIONS_RAMDISK}"
        kernel_img=${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${INITRAMFS_LINK_NAME}.bin
    fi
    kernel_img=`readlink -fn ${kernel_img}`
    ls -al $kernel_img
    echo "Kernel: [${kernel_img}]"
    echo "Kernel command line: [${kernel_cmdline}]"

    ${STAGING_BINDIR_NATIVE}/mkbootimg \
        --kernel $kernel_img \
        --ramdisk /dev/null \
        --cmdline "${kernel_cmdline}" \
        --board ${MACHINE} \
        --base ${MACHINE_KERNEL_BASE} \
        --pagesize $page_size \
        --tags-addr ${MACHINE_KERNEL_TAGS_OFFSET} \
        --ramdisk_offset 0x0 \
        --output ${DEPLOY_DIR_IMAGE}/${image_name}.img

    ln -sf ${image_name}.img ${DEPLOY_DIR_IMAGE}/${image_link}.img
}

do_bootimg() {
    date=$(date +"%Y%m%d%H%M%S")
    image_name_2k=$(echo ${BOOTIMG_NAME_2k} | sed -e s/@{DATETIME}/$date/)
    image_name_4k=$(echo ${BOOTIMG_NAME_4k} | sed -e s/@{DATETIME}/$date/)
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" $image_name_2k boot-yocto-sdx55.2k 2048
    if [ $? -ne 0 ] ; then exit 1 ; fi
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" $image_name_4k boot-yocto-sdx55.4k 4096
    if [ $? -ne 0 ] ; then exit 1 ; fi
    ln -sf $image_name_4k.img ${DEPLOY_DIR_IMAGE}/boot-yocto-sdx55.img
    echo "${PV} $date" >> ${DEPLOY_DIR_IMAGE}/kernel.version
}

addtask bootimg after do_deploy before do_build
