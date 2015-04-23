INITSCRIPT_PARAMS = ""

pkg_postinst_${PN} () {
        [ -n "$D" ] && OPT="-r $D" || OPT="-s"
        update-rc.d $OPT -f run-postinsts remove
        update-rc.d $OPT -f run-postinsts.service remove
}
