inherit autotools pkgconfig

DESCRIPTION = "hardware libhardware headers"
HOMEPAGE = "http://codeaurora.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://MODULE_LICENSE_APACHE2;md5=d41d8cd98f00b204e9800998ecf8427e"

# Tag M9615AAAARNLZA1611263
SRCREV = "2935a5fc5bfd4b49303ab92463736e64a76266f5"
LIBHARDWARE_REPO = "git://codeaurora.org/platform/hardware/libhardware;branch=penguin"
PR = "r0"

SRC_URI  = "${LIBHARDWARE_REPO}"
SRC_URI += "file://autotools.patch"

S = "${WORKDIR}/git"

EXTRA_OEMAKE = "INCLUDES='-I${S}/include'"

DEPENDS = "system-core"

do_install_append () {
    install -d ${D}${includedir}
    install -m 0644 ${S}/include/hardware/gps.h -D ${D}${includedir}/hardware/gps.h
    install -m 0644 ${S}/include/hardware/hardware.h -D ${D}${includedir}/hardware/hardware.h
    install -m 0644 ${S}/include/hardware/gralloc.h -D ${D}${includedir}/hardware/gralloc.h
}

