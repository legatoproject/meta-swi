FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://autobuilder.conf"

do_compile_append() {
    # Copy extra conf files
    cp ${WORKDIR}/*.conf ${S}/${sysconfdir}/opkg/
}