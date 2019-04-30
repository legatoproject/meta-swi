inherit native

DESCRIPTION = "Boot image signing tool from Android"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://make_key;md5=f314bc0e3b3c2364e4bf36c1e8ef2c8b"
PROVIDES = "android-signing-native"

SRCREV = "${AUTOREV}"
PR = "r1"

# make sure this is in sync with the define in android-signing.bbclass
SHARED_DIR = "${D}/${base_prefix}/usr/share"
ANDROID_SIGNING_DIR = "${SHARED_DIR}/android-signing"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "git://github.com/braddu/android-signing.git;protocol=git"
SRC_URI += "file://swi-readme.txt \
            file://swi-key-cwe.sh \
            file://swi-keys.cwe \
           "

# copy certficiates for android-signing to use
#SRC_URI += "file://rootfs \
#            file://legato \
#           "

S = "${WORKDIR}/git"

# Move the scripts to a work-shared directory as described by SIGNING_TOOLS_DIR
do_install() {
    install -d ${ANDROID_SIGNING_DIR}
    cp -r ${S}/* ${ANDROID_SIGNING_DIR}
    cp ${WORKDIR}/swi* ${ANDROID_SIGNING_DIR}
    # copy certficiates for android-signing to use
    #cp -r ${WORKDIR}/rootfs ${ANDROID_SIGNING_DIR}/security
    #cp -r ${WORKDIR}/legato ${ANDROID_SIGNING_DIR}/security
}

# don't run these functions
do_configure[noexec] = "1"
do_compile[noexec] = "1"
