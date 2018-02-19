SUMMARY = "IMA scripts"
DESCRIPTION = "IMA supporting scripts responsible for signing, \
key generation, etc. These should be required on host machine \
only."

# Where to find additional files (patches, etc.).
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Package revision number. Change "r" number if you change
# anything in this package (e.g. add patch, remove patch,
# change dependencies, etc.).
PR = "r0"

HOMEPAGE = ""
LICENSE = "GPLv2"
# Make sure that there is 'file://../COPYING...' in order to avoid
# "LIC_FILES_CHKSUM points to an invalid file" error. This is because
# there is no *.tar.gz source bundle (which we do not really
# need), COPYING file is stored in files directory, and as any other patches
# and additional files in build directory, is stored one dir above
# ima-scripts-1.0 directory (which in this case is empty).
LIC_FILES_CHKSUM = "file://../COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

# Where to find source code for this package.
SRC_URI = "file://COPYING"
SRC_URI += "file://ima-gen-keys.sh"
SRC_URI += "file://ima-sign.sh"

do_install() {
    # Install key generation util.
    install -m 0755 ${WORKDIR}/ima-gen-keys.sh -D ${D}${bindir}/ima-gen-keys.sh

    # Install signage util.
    install -m 0755 ${WORKDIR}/ima-sign.sh -D ${D}${bindir}/ima-sign.sh
}

RDEPENDS_${PN} = "bsdtar attr ima-evm-utils openssl"
