TMPL_FLAGS ?= "-Dvirt"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://smack \
                   file://accesses \
                 "

do_install:append () {

    install -m 0644 ${WORKDIR}/accesses -D ${D}${sysconfdir}/smack/accesses
    install -D -m 0755 ${WORKDIR}/smack -D ${D}${sysconfdir}/init.d/smack

    update-rc.d -r ${D} -f smack remove
    update-rc.d -r ${D} smack start 08 S . stop 92 S .
}
