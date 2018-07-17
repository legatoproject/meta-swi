inherit autotools pkgconfig

DESCRIPTION = "hardware libhardware headers"
HOMEPAGE = "http://codeaurora.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://MODULE_LICENSE_APACHE2;md5=d41d8cd98f00b204e9800998ecf8427e"

# Tag LNX.LE.2.0.2-61193-9x15
SRCREV = "267df67ebf6ac7b29bf43fdfe9af41a64aec0036"
LIBHARDWARE_REPO = "git://codeaurora.org/platform/hardware/libhardware;branch=LNX.LE.2.1"
PR = "r0"

SRC_URI  = "${LIBHARDWARE_REPO} \
            file://autotools.patch "

S = "${WORKDIR}/git"

EXTRA_OEMAKE = "INCLUDES='-I${S}/include'"

DEPENDS = "system-core"

do_install_append () {
    install -d ${D}${includedir}
    install -m 0644 ${S}/include/hardware/gps.h -D ${D}${includedir}/hardware/gps.h
    install -m 0644 ${S}/include/hardware/hardware.h -D ${D}${includedir}/hardware/hardware.h
    install -m 0644 ${S}/include/hardware/gralloc.h -D ${D}${includedir}/hardware/gralloc.h
}

