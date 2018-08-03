FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
    import re

    pv = d.getVar('PV', True)
    srcuri = d.getVar('SRC_URI', True)

    # Handle versions =1.43
    if re.match('^1.43$', pv):
        d.setVar('SRC_URI', srcuri + ' file://rename-copy-file-range.diff')
}
