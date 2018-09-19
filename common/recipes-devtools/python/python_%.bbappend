# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
  import re

  pv = d.getVar('PV', True)
  srcuri = d.getVar('SRC_URI', True)

  # Handle version 2.7.12
  if re.match('2.7.[0-1][0-2]', pv):
    d.setVar('SRC_URI', srcuri + \
             ' file://CVE-2017-1000158.patch' \
             ' file://CVE-2018-1000030_1.patch' \
             ' file://CVE-2018-1000030_2.patch')

}
