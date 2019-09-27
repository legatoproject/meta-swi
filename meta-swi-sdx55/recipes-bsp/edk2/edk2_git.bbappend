inherit localgit

LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=3775480a712fc46a69647678acb234cb"

SRCREV = "${AUTOREV}"

FILESPATH_remove = "${WORKSPACE}/bootable/bootloader/"
SRC_URI = ""
SRC_DIR = "${EDK2_REPO}"
BOOTLOADER_OUT = "${WORKDIR}/out"

S = "${WORKDIR}/edk2"

EXTRA_OEMAKE_append = " 'BOOTLOADER_OUT=${BOOTLOADER_OUT}'"

DEPENDS_append = " llvm-arm-toolchain-native"

do_compile_prepend() {

    # DM: gcc 8 implements '-fmacro-prefix-map', and among other debug things,
    # this switch is embedded in DEBUG_PREFIX_MAP, which is declared in
    # poky/meta/conf/bitbake.conf . Since we have gcc 5.4.0 on Ubuntu 16.04
    # compilation will fail.
    gcc_ver=$( gcc --version | grep "gcc " | awk -F' ' '{ print $4 }' | sed -e 's/\.//g' )
    if [ $gcc_ver -lt 800 ] ; then
        dummy=${@d.setVar('DEBUG_PREFIX_MAP_remove', '-fmacro-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${EXTENDPE}${PV}-${PR}')}
    fi
}

do_install() {
    # makefile contains ABL_FV_ELF variable which stores final binary to
    # root directory of edk2 build. We need to install it to standard location,
    # because deploy method is looking for it there.
    install -m 644 ${BOOTLOADER_OUT}/../../abl.elf -D ${D}/boot/abl.elf
    rm -f ${WORKDIR}/out/../../abl.elf
}

do_tag_edk2() {
    if [ -z "${FW_VERSION}" ]; then
        if [ -d ${EDK2_REPO} ]; then
            cd ${EDK2_REPO}
            FW_VERSION=$(git describe --tag)
        fi
    fi

    echo "#define EDK2_VERSION  \"${FW_VERSION}\"" >${S}/QcomModulePkg/Library/BootLib/sierra_edk2version.h
}
addtask do_tag_edk2 before do_compile after do_configure

