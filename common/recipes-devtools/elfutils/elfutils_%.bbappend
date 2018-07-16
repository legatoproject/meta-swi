# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
    import re

    pv = d.getVar('PV', True)
    srcuri = d.getVar('SRC_URI', True)

    # Handle versions ~ 0.166
    if re.match('0.1[6]', pv):
        d.setVar('SRC_URI', srcuri + \
                    ' file://CVE-2016-10254.patch' \
                    ' file://CVE-2016-10255.patch')
}

