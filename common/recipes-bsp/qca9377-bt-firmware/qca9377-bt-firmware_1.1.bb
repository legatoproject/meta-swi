# Note, DM: For now, we are going to pull firmware files from local repository. The reason for
# doing that is that I could not find firmware files on codeaurora.org. However, I found them
# in boundarydevices.com repository on github, and they are allowed to be distributed as binaries
# without any changes. In addition, local and github firmware files are not the same, and we need
# to do some testing to claim that we could use boundarydevices firmware files.

DESCRIPTION = "Firmware for QCA9377 Bluetooth"
LICENSE = "QCA-TSPA"
LIC_FILES_CHKSUM = "file://../LICENSE.qca_firmware;md5=e8b1e9e8ce377ca5b2c1098e5690f470"

SRCREV = "5e4b71211ecbb79e7693d2ee07361847f5a0cb40"
BRANCH = "bd-sdmac-qcacld"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "file://firmware.conf"
SRC_URI += "\
            file://tfbtfw11.tlv \
            file://tfbtnv11.bin \
            file://LICENSE.qca_firmware \
           "
# For boundarydevices version.
# SRC_URI = "git://github.com/boundarydevices/qca-firmware.git;protocol=https;branch=${BRANCH}"

S = "${WORKDIR}/git"

# First is for local firmware files, the one bellow is for boundarydevices version.
FW_BIN_PATH = "${WORKDIR}"
# FW_BIN_PATH = "${S}/qca"

# If _PLATFORM_MDM_ is not defined in BlueZ, this bellow becomes 'firmware/qca'.
FW_TARGET_PATH = "firmware"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

PR = "r0"

FILES_${PN} = "${base_libdir}/${FW_TARGET_PATH}/tfbtfw11.tlv \
               ${base_libdir}/${FW_TARGET_PATH}/tfbtnv11.bin \
               ${sysconfdir}/bluetooth/firmware.conf \
               "

do_install() {
        install -m 0644 ${FW_BIN_PATH}/tfbtfw11.tlv -D ${D}${base_libdir}/${FW_TARGET_PATH}/tfbtfw11.tlv
        install -m 0644 ${FW_BIN_PATH}/tfbtnv11.bin -D ${D}${base_libdir}/${FW_TARGET_PATH}/tfbtnv11.bin
        install -m 0644 ${WORKDIR}/firmware.conf -D ${D}${sysconfdir}/bluetooth/firmware.conf
}