SUMMARY = "IMA scripts"
DESCRIPTION = "IMA supporting scripts responsible for signing, \
key generation, etc. These should be required on host machine \
only."

# Where to find additional files (patches, etc.).
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR = "r2"

HOMEPAGE = "https://github.com/legatoproject/ima-support-tools"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://./LICENSE;md5=9741c346eef56131163e13b9db1241b3"

# Provide reasonable default to fetch the scripts
IMA_SUPPORT_TOOLS_REPO = "git://github.com/legatoproject/ima-support-tools;protocol=https;branch=master"
SRCREV = "4a8bf89993e85c83f6db759ef03cda3e6edec41d"

# Where to find source code for this package.
SRC_URI = "${IMA_SUPPORT_TOOLS_REPO}"
S = "${WORKDIR}/git"

do_install() {
    # Install key generation util.
    install -m 0755 ${S}/ima-gen-keys.sh -D ${D}${bindir}/ima-gen-keys.sh

    # Install signage util.
    install -m 0755 ${S}/ima-sign.sh -D ${D}${bindir}/ima-sign.sh

    # Install IMA configuration file. This file is installed for reference only.
    if [ "x${IMA_BUILD}" == "xtrue" ] ; then
        install -m 0644 ${IMA_CONFIG} -D ${D}/${sysconfdir}/ima/config/$( basename ${IMA_CONFIG} )
    fi
}

RDEPENDS_${PN} = "bsdtar attr ima-evm-utils openssl"
