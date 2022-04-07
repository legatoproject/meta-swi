FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-passwd-Add-prefix-parameter-for-shadow-file.patch \
            file://0001-Do-not-use-real-lckpwdf.patch \
           "

EXTRA_OEMAKE:append = " CPPFLAGS+=-DDISABLE_REAL_LCKPWDF"

RDEPENDS:${PN}:remove = "util-linux-sulogin"

do_install:append() {
    sed -i 's/MOTD_FILE/#MOTD_FILE/g' ${D}${sysconfdir}/login.defs
}
