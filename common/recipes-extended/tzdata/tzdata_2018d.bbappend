# DM, FIXME: tzdata recipe was "borrowed" from poky 2.5. However, d.getVar methods in Y2.2 and Y2.5
# are different. This change is here to allow proper compilation of tzdata in Y2.2 environment.
CONFFILES_${PN} += "${@ "${sysconfdir}/timezone" if bb.utils.to_boolean(d.getVar('INSTALL_TIMEZONE_FILE', True)) else "" }"
