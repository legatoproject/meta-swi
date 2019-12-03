FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

python() {
  import re

  pv = d.getVar('PV', True)
  srcuri = d.getVar('SRC_URI', True)

  # Handle version 4.2.1
  if re.match('4.[12]', pv):
    d.setVar('SRC_URI', srcuri + \
             ' file://0001-Simplify-getulong.patch' \
             ' file://0001-Fix-a-resource-leak-in-libmis-idmapping.c.patch' \
             ' file://0002-get_map_ranges-initialize-argidx-to-0-at-top-of-loop.patch' \
             ' file://0003-get_map_ranges-check-for-overflow.patch' \
             ' file://0004-passwd-Add-prefix-parameter-for-shadow-file.patch' \
             ' file://0005-Do-not-use-real-lckpwdf.patch' \
             ' file://CVE-2017-12424.patch' )
}

EXTRA_OEMAKE_append += "CPPFLAGS+=-DDISABLE_REAL_LCKPWDF"

do_install_append() {
    sed -i 's/MOTD_FILE/#MOTD_FILE/g' ${D}${sysconfdir}/login.defs
}
