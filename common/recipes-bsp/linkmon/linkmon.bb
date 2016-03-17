DESCRIPTION = "Implement a simple EPOLLWAKEUP for monitoring the USB connection"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://linkmon.c;beginline=5;endline=5;md5=e047aedf5977c10d0ef6d322620c280f"
PR="r1"

SRC_URI = "file://linkmon.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} linkmon.c -o linkmon
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 linkmon ${D}${bindir}
}

