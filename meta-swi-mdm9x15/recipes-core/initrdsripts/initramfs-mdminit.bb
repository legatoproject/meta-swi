SUMMARY = "Mdm9x15 image init script"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
DEPENDS = "virtual/kernel"
SRC_URI = "file://init-mdm9x15.sh"

PR = "r11"

do_install() {
        install -m 0755 ${WORKDIR}/init-mdm9x15.sh ${D}/init
}

FILES_${PN} += " /init "

# Due to kernel depdendency
PACKAGE_ARCH = "${MACHINE_ARCH}"
