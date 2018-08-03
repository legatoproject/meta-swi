PACKAGECONFIG_remove = "gnutls"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
    import re

    pv = d.getVar('PV', True)
    srcuri = d.getVar('SRC_URI', True)

    # Handle versions ~ 2.7
    if re.match('2.7', pv):
        d.setVar('SRC_URI', srcuri + ' file://memfd-header-detect.diff')
}
