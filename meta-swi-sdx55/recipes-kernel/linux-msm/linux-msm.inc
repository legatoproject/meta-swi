inherit kernel kernel-yocto
#inherit qperf

DESCRIPTION = "CAF Linux Kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"

python __anonymous () {
  # Override KERNEL_IMAGETYPE_FOR_MAKE variable, which is internal
  # to kernel.bbclass. We override the variable as msm kernel can't
  # support alternate image builds
  if d.getVar("KERNEL_IMAGETYPE", True):
      d.setVar("KERNEL_IMAGETYPE_FOR_MAKE", "")
}

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
PACKAGES = "kernel kernel-base kernel-vmlinux kernel-dev kernel-modules"

KBRANCH ?= ""
KMETA = "kernel-meta"
KMACHINE ?= "${MACHINE}"
KCONFIG_MODE = "--alldefconfig"
KBUILD_DEFCONFIG ?= "${KERNEL_CONFIG}"
LINUX_VERSION_EXTENSION = "${@['-perf', ''][d.getVar('VARIANT', True) == ('' or 'debug')]}"

do_kernel_checkout[noexec] = "1"

# extra task for configuration checks
addtask kernel_configcheck after do_configure before do_compile

do_unpack_append() {
    wrkdir = d.getVar('WORKDIR', True)
    srcdir = d.getVar('S', True)
    os.system("mkdir -p %s" % (srcdir))
    os.system("cp -drl %s/kernel/. %s/." % (wrkdir, srcdir))
}

do_compile () {
    oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" ${KERNEL_EXTRA_ARGS} $use_alternate_initrd
}

do_deploy() {
    if [[ ${KERNEL_IMAGETYPE} != *-dtb ]]; then
        bberror "${PN}: Only appended DTB supported; Change KERNEL_IMAGETYPE to ${KERNEL_IMAGETYPE}-dtb in your kernel config."
        return
    fi

    if [ -f ${D}/${KERNEL_IMAGEDEST}/-${KERNEL_VERSION} ]; then
        mv ${D}/${KERNEL_IMAGEDEST}/-${KERNEL_VERSION} ${D}/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}-${KERNEL_VERSION}
    fi
}

# Put the zImage in the kernel-dev pkg
FILES_kernel-dev += "/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}-${KERNEL_VERSION}"

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
    fi

    echo "Kernel command line IMA options: [${IMA_KERNEL_CMDLINE_OPTIONS}]"
    echo "Kernel command line: [${KERNEL_BOOT_OPTIONS}]"

    kernel_img=${D}/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}-${KERNEL_VERSION}
    ls -al $kernel_img

    # No initramfs
    ${STAGING_BINDIR_NATIVE}/mkbootimg \
        --kernel $kernel_img \
        --ramdisk /dev/null \
        --cmdline "${KERNEL_BOOT_OPTIONS}" \
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
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" $image_name_2k boot-yocto-sdx55.2k masterDTB.2k 2048
    if [ $? -ne 0 ] ; then exit 1 ; fi
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" $image_name_4k boot-yocto-sdx55.4k masterDTB.4k 4096
    if [ $? -ne 0 ] ; then exit 1 ; fi
    ln -sf $image_name_4k.img ${DEPLOY_DIR_IMAGE}/boot-yocto-sdx55.img
    echo "${PV} $date" >> ${DEPLOY_DIR_IMAGE}/kernel.version
}

addtask bootimg after do_deploy before do_build
