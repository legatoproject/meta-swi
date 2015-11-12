inherit kernel localgit

DESCRIPTION = "QuIC Linux Kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"
COMPATIBLE_MACHINE = "(swi-mdm9x40)"

# Provide a config baseline for things so the kernel will build...
KERNEL_DEFCONFIG ?= "mdm9640_defconfig"

SRC_DIR = "${WORKSPACE}/../../kernel"

LINUX_VERSION ?= "3.10.49"
PV = "${LINUX_VERSION}+git${GITSHA}"
PR = "r1"

uses_modules () {
    grep -q -i -e '^CONFIG_MODULES=y$' "${O}/.config"
}

do_configure_prepend () {
    cp ${S}/arch/arm/configs/${KERNEL_DEFCONFIG} ${WORKDIR}/defconfig
}

do_install_append() {
    oe_runmake headers_install O=${D}/usr/src/kernel
    rm -rf ${D}/usr/src/kernel/scripts
}

# ???
do_deploy_append_dtb() {
    KERNEL_VERSION=$(sed -r 's/#define UTS_RELEASE "(.*)"/\1/' ${S}/include/generated/utsrelease.h)

    set -x

    # Make bootimage
    dtb_files=$(find ${S}/arch/arm/boot/dts -iname *${MACHINE_DTS_NAME}*.dtb | awk -F/ '{print $NF}' | awk -F[.][d] '{print $1}')

    # Create separate images with dtb appended to zImage for all targets.
    for d in ${dtb_files}; do
       targets=`echo ${d#${MACHINE_DTS_NAME}-}`
       cat ${KERNEL_OUTPUT} ${S}/arch/arm/boot/dts/${d}.dtb > ${DEPLOYDIR}/dtb-zImage-${KERNEL_VERSION}-${targets}
    done

    ${STAGING_BINDIR_NATIVE}/dtbtool ${DEPLOYDIR} -s ${PAGE_SIZE} -o ${DEPLOYDIR}/masterDTB -p ${DEPLOYDIR} -v

     __cmdparams='noinitrd  rw console=ttyHSL0,115200,n8 androidboot.hardware=qcom ehci-hcd.park=3 msm_rtb.filter=0x37'

    if [ "${BASEMACHINE_QCOM}" != "mdm9640" ]; then
        __cmdparams+=' rootfstype=yaffs2'
    fi

    cmdparams=`echo ${__cmdparams}`

    # Updated base address according to new memory map.
    ${STAGING_BINDIR_NATIVE}/mkbootimg \
        --kernel ${KERNEL_OUTPUT} \
        --dt ${DEPLOYDIR}/masterDTB \
        --ramdisk /dev/null \
        --cmdline "${cmdparams}" \
        --pagesize ${PAGE_SIZE} \
        --base ${MACHINE_KERNEL_BASE} \
        --tags-addr ${MACHINE_KERNEL_TAGS_OFFSET} \
        --ramdisk_offset 0x0 \
        --output ${DEPLOYDIR}/${MACHINE}-boot.img
}
