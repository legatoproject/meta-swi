SUMMARY = "ima-evm-utils"
DESCRIPTION = "The evmctl utility can be used for producing and \
verifying digital signatures, which are used by Linux kernel \
integrity subsystem (IMA/EVM). It can be also used to import keys \
into the kernel keyring. More about this utility could be found \
at http://linux-ima.sourceforge.net/evmctl.1.html . "

# Where to Find additional files (patches, etc.).
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Local non-yocto variables.
PV_MAJOR = "1.0"
PV_MINOR = ""

# Package revision number. Change "r" number if you change
# anything in this package (e.g. add patch, remove patch,
# change dependencies, etc.).
PR = "r1"

HOMEPAGE = "https://sourceforge.net/projects/linux-ima"
SECTION = "console"
LICENSE = "GPL-2.0-with-OpenSSL-exception"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

# Compile time package dependencies.
DEPENDS = "keyutils openssl attr"

# Where to find source code for this package. We could've
# used tarball, but tarball is made from sources tagged
# in git repo, and we will use it.
SRC_URI = "git://git.code.sf.net/p/linux-ima/ima-evm-utils;tag=v${PV_MAJOR};protocol=https"

# We really do not need man pages. In addition, its build is creating
# problems.
SRC_URI += "file://0001-no-manpages.patch"

inherit autotools gettext pkgconfig

# Fix "QA Issue: No GNU_HASH in the elf binary" problem
INSANE_SKIP_${PN} = "ldflags"

S = "${WORKDIR}/git"

# Need to find libkeyutils so library
EXTRA_OEMAKE = "LDFLAGS=-L${STAGING_LIBDIR} -lkeyutils"

do_install_append() {
    # For now, just create empty  directories in /etc
    install -d ${D}${sysconfdir}/ima
    install -d ${D}${sysconfdir}/keys
}

BBCLASSEXTEND = "native nativesdk"
