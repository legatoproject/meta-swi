inherit autotools linux-kernel-base
DESCRIPTION = "PIMD - Multicast Routing Daemon"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://LICENSE;md5=94f108f91fab720d62425770b70dd790"

PR = "r0"

do_configure() {
    :
}

SRCREV = "c4b1c9f4b5eaa70931d0f62f456ae10ac4c4a829"
SRC_URI = "git://github.com/troglobit/pimd.git;protocol=git \
           file://0001-pimb-multicast-support-on-network.patch"
           
S = "${WORKDIR}/git"

do_compile() {
  make
}

do_install() {
        make install DESTDIR=${D}
}

