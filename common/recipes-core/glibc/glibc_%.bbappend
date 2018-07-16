# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
  import re

  pv = d.getVar('PV', True)
  srcuri = d.getVar('SRC_URI', True)

  # Handle version 2.24
  if re.match('2.2[0-4]', pv):
    d.setVar('SRC_URI', srcuri + \
             ' file://CVE-2018-6485.patch' \
             ' file://CVE-2017-15804.patch' \
             ' file://CVE-2018-1000001.patch' \
             ' file://CVE-2017-12133.patch ')
}
