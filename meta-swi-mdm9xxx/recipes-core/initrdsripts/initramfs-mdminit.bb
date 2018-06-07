SUMMARY = "Mdm9xxx initramfs init scripts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
DEPENDS = "virtual/kernel"

SRC_URI = "file://init.sh \
          "

# init.sh requires run.env
RDEPENDS_${PN} += "initscripts-runenv"
RDEPENDS_${PN} += "busybox"

PR = "r11"

do_install() {
    install -d ${D}/etc
    install -m 0755 ${WORKDIR}/init.sh ${D}/init
}

FILES_${PN} += " /init "

# Due to kernel depdendency
PACKAGE_ARCH = "${MACHINE_ARCH}"

