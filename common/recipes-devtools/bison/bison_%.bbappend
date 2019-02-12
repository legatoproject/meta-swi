FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

python() {
  import re

  pv = d.getVar('PV', True)
  srcuri = d.getVar('SRC_URI', True)

  # Handle version 3.0.4
  if re.match('3.0.4', pv):
    d.setVar('SRC_URI', srcuri + \
             ' file://gnulib.patch' )
}
