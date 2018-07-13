# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
  import re

  pv = d.getVar('PV', True)
  srcuri = d.getVar('SRC_URI', True)

  # Handle version 2.28
  if re.match('2.[12][0-8]', pv):
    d.setVar('SRC_URI', srcuri + \
             ' file://CVE-2018-7738.patch')
}
