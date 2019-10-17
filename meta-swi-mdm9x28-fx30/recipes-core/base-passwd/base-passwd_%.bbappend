# DM, FIXME: I do not think this is necessary.
do_install_append () {
    sed -i 's/root::0:0:root:\/home\/root:\/bin\/sh/root::0:0:root:\/home\/root:\/usr\/sbin\/loginNagger/' ${D}${datadir}/base-passwd/passwd.master
}
