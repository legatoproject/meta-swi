# Instead of starting tcf-agent in an init script, we will start it in a "Developer Mode" app.
# Therefore any installation of init scripts or .service files done in
# poky/meta/recipes-devtools/tcf-agent/tcf-agent_git.bb are undone here.
#
# What we are trying to achieve is to have the tcf-agent executable on the target, but we do not
# want to install it as a service and be in any of the init scripts.


# We have to neuter this function in update-rc.d.bbclass because the absence of init.d scripts (from
# do_install_append) will cause the generation of some "postinsts" scripts which we don't want.
populate_packages_updatercd() {
}

# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://legato_identify.patch \
           "
# Prevent dependency on bash
RDEPENDS_${PN} = ""
CFLAGS += " -DTERMINALS_NO_LOGIN=0"

# Undo what do_install did
do_install_append() {
    rm -rf ${D}${sysconfdir}/init.d/
    rm -rf ${D}${systemd_unitdir}/system
}
