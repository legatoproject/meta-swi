inherit kernel kernel-yocto kernel-src-install android-signing

DESCRIPTION = "CAF Linux Kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"

do_deploy[depends] += "dtbtool-native:do_populate_sysroot mkbootimg-native:do_populate_sysroot"

DEPENDS += "ima-support-tools-native gcc"
DEPENDS += " mkbootimg-native dtbtool-native openssl-native kern-tools-native"
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""

LDFLAGS:aarch64 = "-O1 --hash-style=gnu --as-needed"

DEPENDS:append:aarch64 = " libgcc"
KERNEL_CC:append:aarch64 = " ${TOOLCHAIN_OPTIONS}"
KERNEL_LD:append:aarch64 = " ${TOOLCHAIN_OPTIONS}"

# Update KERNEL_CC for Linux kernel build to run wrapper script.
KERNEL_CC:prepend = "${LINUX_REPO_DIR}/scripts/gcc-wrapper.py "

KERNEL_PRIORITY           = "9001"
# Add V=1 to KERNEL_EXTRA_ARGS for verbose
KERNEL_EXTRA_ARGS        += "O=${B}"


LINUX_REPO_DIR_PARENT = "${@os.path.dirname(d.getVar('LINUX_REPO_DIR', False))}"
LINUX_REPO_DIR_BASE = "${@os.path.basename(d.getVar('LINUX_REPO_DIR', False))}"
FILESPATH:prepend = "${LINUX_REPO_DIR_PARENT}:"
SRC_URI = "file://${LINUX_REPO_DIR_BASE} \
          "

PACKAGE_ARCH = "${MACHINE_ARCH}"
PACKAGES = "${KERNEL_PACKAGE_NAME} ${KERNEL_PACKAGE_NAME}-base ${KERNEL_PACKAGE_NAME}-vmlinux ${KERNEL_PACKAGE_NAME}-dev ${KERNEL_PACKAGE_NAME}-dbg ${KERNEL_PACKAGE_NAME}-modules"

KBRANCH ?= ""
KMETA = "kernel-meta"
KMACHINE ?= "${MACHINE}"
KCONFIG_MODE = "--alldefconfig"
KBUILD_DEFCONFIG ?= "${KERNEL_CONFIG}"
LINUX_VERSION_EXTENSION = "${@['-perf', ''][d.getVar('VARIANT', True) == ('' or 'debug')]}"

do_kernel_checkout[noexec] = "1"

# extra task for configuration checks
addtask kernel_configcheck after do_configure before do_compile

do_unpack:append() {
    wrkdir = d.getVar('WORKDIR', True)
    srcdir = d.getVar('S', True)
    os.system("mkdir -p %s" % (srcdir))
    os.system("cp -drl %s/kernel/. %s/." % (wrkdir, srcdir))
}

# Use this to include the IMA kernel key into the trusted keyring
IMA_INCLUDE_KERNEL_KEY ?= "true"
# As per note in kernel CONFIG_SYSTEM_TRUSTED_KEYS option:
# NOTE: If you previously provided keys for the system keyring in the
# form of DER-encoded *.x509 files in the top-level build directory,
# those are no longer used. You will need to set this option instead.
IMA_LOCAL_CA_PEM = "${@os.path.basename(d.getVar('IMA_LOCAL_CA_X509', False))}"
KERNEL_EXTRA_ARGS += "${@oe.utils.conditional('IMA_BUILD', 'true', 'CONFIG_SYSTEM_TRUSTED_KEYS=\"${IMA_LOCAL_CA_PEM}\"', '', d)}"

do_configure:prepend() {
    cp ${S}/arch/arm/configs/${KBUILD_DEFCONFIG} ${WORKDIR}/defconfig

    # Add ".system" public cert into kernel build area. Kernel build
    # will suck this cert in automatically.
    if [ "x${IMA_BUILD}" == "xtrue" ] && [ "x${IMA_INCLUDE_KERNEL_KEY}" == "xtrue" ] ; then
        echo "IMA: Installing ${IMA_LOCAL_CA_X509} in ${B} ..."
        # Convert key from DER to PEM format
        openssl x509 -inform der -in ${IMA_LOCAL_CA_X509} -out ${B}/${IMA_LOCAL_CA_PEM}
    fi

    oe_runmake_call -C ${S} ${KERNEL_EXTRA_ARGS} mrproper
    oe_runmake_call -C ${S} ARCH=${ARCH} ${KERNEL_EXTRA_ARGS} ${KBUILD_DEFCONFIG}

    # Add kernel config file snippets.
    for kconfig in ${KBUILD_DEFCONFIG_SNIPPETS} ; do
        cat ${kconfig} >>${B}/.config
    done
}


do_compile:append() {
    oe_runmake dtbs ${KERNEL_EXTRA_ARGS}
}

do_install:append() {
    kernel_src_install
}

sysroot_stage_all:append () {
        sysroot_stage_dir ${D}${KERNEL_SRC_PATH} ${SYSROOT_DESTDIR}${KERNEL_SRC_PATH}
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
BOOTIMG_NAME_2k ?= "boot-yocto-mdm9x28-@{DATETIME}.2k"
BOOTIMG_NAME_4k ?= "boot-yocto-mdm9x28-@{DATETIME}.4k"

MACHINE_KERNEL_BASE = "0x80000000"
MACHINE_KERNEL_TAGS_OFFSET = "0x81E00000"

# Append console parameters to command line. Use default if not already set.
SYSLINUX_DEFAULT_CONSOLE ?= "console=ttyMSM0,115200 console=ttyMSM1,115200"
KERNEL_BOOT_OPTIONS_RAMDISK =+ "${SYSLINUX_DEFAULT_CONSOLE}"
KERNEL_BOOT_OPTIONS =+ "${SYSLINUX_DEFAULT_CONSOLE}"

gen_master_dtb() {
    master_dtb_name=$1
    page_size=$2

    ${STAGING_BINDIR_NATIVE}/dtbtool \
        ${B}/arch/arm/boot/dts/ \
        -s $page_size \
        -o ${DEPLOYDIR}/$master_dtb_name \
        -p ${B}/scripts/dtc/ \
        -v

    if ! [ -e "${DEPLOYDIR}/$master_dtb_name" ]; then
        echo "Unable to generate $master_dtb_name"
        exit 1
    fi
}

do_deploy:prepend() {
    # Remove kernel binary mysteriously installed by previous steps
    if [ -f ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE} ] ; then
        rm -f ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}
    fi
}


do_deploy:append() {
    kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}
    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
    fi
    kernel_img=$(readlink -f $kernel_img)
    ls -al $kernel_img

    set -xe

    ver=$(sed -r 's/#define UTS_RELEASE "(.*)"/\1/' ${B}/include/generated/utsrelease.h)
    dtb_files=$(find ${B}/arch/arm/boot/dts -iname "*${BASEMACHINE_QCOM}*.dtb" | awk -F/ '{print $NF}' | awk -F[.][d] '{print $1}')

    mkdir -p ${DEPLOYDIR}/dtb/qcom

    # Create separate images with dtb appended to zImage for all targets.
    # Also ship each dtb file individually
    for d in ${dtb_files}; do
        targets=$(echo ${d#${BASEMACHINE_QCOM}-})
	cat $kernel_img ${B}/arch/arm/boot/dts/${d}.dtb > ${B}/arch/arm/boot/dts/qcom/dtb-zImage-${ver}-${targets}.dtb
	cp ${B}/arch/arm/boot/dts/${d}.dtb ${DEPLOYDIR}/dtb/qcom
    done

    gen_master_dtb masterDTB.2k 2048
    gen_master_dtb masterDTB.4k 4096
    install -m 0644 vmlinux ${DEPLOY_DIR_IMAGE}
}


# Put the zImage in the kernel-dev pkg
FILES:${KERNEL_PACKAGE_NAME}-dev += "/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}-${KERNEL_VERSION}"

FILES:${KERNEL_PACKAGE_NAME}-dbg += "${KERNEL_SRC_PATH}/arch/*/boot/*/.debug/*"


python get_verity_key_id() {
    key_id = verity_key_id(d, "testkey")
    d.setVar("KEY_ID", key_id)
}

do_bootimg[prefuncs] += "${@bb.utils.contains('MACHINE_FEATURES', \
                          'android-verity', 'get_verity_key_id', '', d)}"

gen_bootimg() {
    image_flags=$1
    image_name=$2
    image_link=$3
    master_dtb_name=$4
    page_size=$5
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

    kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}
    kernel_cmdline="${KERNEL_BOOT_OPTIONS}"
    if [ "${INITRAMFS_IMAGE_BUNDLE}" -eq 1 ]; then
        kernel_img=${DEPLOYDIR}/${KERNEL_IMAGETYPE}-initramfs-${MACHINE}.bin
        kernel_cmdline="${KERNEL_BOOT_OPTIONS_RAMDISK}"
    fi

    kernel_img=`readlink -fn ${kernel_img}`
    ls -al $kernel_img

    # Initramfs
    ${STAGING_BINDIR_NATIVE}/mkbootimg \
        --dt ${DEPLOYDIR}/$master_dtb_name \
        --kernel $kernel_img \
        --ramdisk /dev/null \
        --cmdline "${kernel_cmdline}" \
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

    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_2K}" $image_name_2k boot-yocto-mdm9x28.2k masterDTB.2k 2048
    if [ $? -ne 0 ] ; then exit 1 ; fi
    gen_bootimg "${MKBOOTIMG_IMAGE_FLAGS_4K}" $image_name_4k boot-yocto-mdm9x28.4k masterDTB.4k 4096
    if [ $? -ne 0 ] ; then exit 1 ; fi

    ln -sf $image_name_4k.img ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.img

    install ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.2k.img ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.2k.img.unsigned
    install ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.4k.img ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.4k.img.unsigned

    # sign the image:
    android_signature_add /boot ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.2k.img.unsigned ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.2k.img.signed verity
    android_signature_add /boot ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.4k.img.unsigned ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.4k.img.signed verity

    ln -sf boot-yocto-mdm9x28.4k.img ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.img.unsigned

    echo "${PV} $date" >> ${DEPLOY_DIR_IMAGE}/kernel.version
}

do_add_mbnhdr_and_hash() {
    # Append "mbn header" and "hash of kernel" to kernel image for data integrity check
    # "mbnhdr_data" is 40bytes mbn header data in hex string format
    mbnhdr_data="06000000030000000000000028000000200000002000000048000000000000004800000000000000"
    # Transfer data from hex string format to binary format "0x06,0x00,0x00,..." and write to a file.
    echo -n $mbnhdr_data | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf > ${DEPLOY_DIR_IMAGE}/boot_mbnhdr
    openssl dgst -sha256 -binary ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.2k.img > ${DEPLOY_DIR_IMAGE}/boot_hash.2k
    openssl dgst -sha256 -binary ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.4k.img > ${DEPLOY_DIR_IMAGE}/boot_hash.4k
    cat ${DEPLOY_DIR_IMAGE}/boot_mbnhdr ${DEPLOY_DIR_IMAGE}/boot_hash.2k >> ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.2k.img
    cat ${DEPLOY_DIR_IMAGE}/boot_mbnhdr ${DEPLOY_DIR_IMAGE}/boot_hash.4k >> ${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.4k.img
}

addtask bootimg after do_deploy before do_build
addtask do_add_mbnhdr_and_hash after do_bootimg before do_build
