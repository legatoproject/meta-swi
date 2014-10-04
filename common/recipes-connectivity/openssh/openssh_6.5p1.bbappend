FILES_${PN}-sftp-server += "/usr/libexec"
FILES_${PN}-sftp-server += "/usr/libexec/sftp-server"

do_install_append () {
    install -m 0755 -d ${D}${bindir}/../libexec
    ln -s ${libexecdir}/sftp-server ${D}/${bindir}/../libexec/sftp-server
}
