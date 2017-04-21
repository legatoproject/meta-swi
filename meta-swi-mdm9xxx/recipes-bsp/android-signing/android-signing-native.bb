inherit native

DESCRIPTION = "Boot image signing tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://make_key;startline=3;endline=15;md5=a88febf68a3c7652c25d2d7b5febaf9e"
PROVIDES = "android-signing-native"

SRCREV = "b5bafb74b7ab21c5f389572da62c6cd75c64dbdd"
PR = "r1"

# make sure this is in sync with the define in android-signing.bbclass
SHARED_DIR = "${D}/${base_prefix}/usr/share"
ANDROID_SIGNING_DIR = "${SHARED_DIR}/android-signing"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "git://github.com/SierraWireless/android-signing.git;protocol=https"
SRC_URI += "file://swi-readme.txt \
            file://swi-key-cwe.sh \
           "

S = "${WORKDIR}/git"

# Move the scripts to a work-shared directory as described by SIGNING_TOOLS_DIR
do_install() {
    install -d ${ANDROID_SIGNING_DIR}
    cp -r ${S}/* ${ANDROID_SIGNING_DIR}
    cp ${WORKDIR}/swi* ${ANDROID_SIGNING_DIR}
}

# don't run these functions
do_configure[noexec] = "1"
do_compile[noexec] = "1"
